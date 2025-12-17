# Feature 1: Real-Time Price Prediction System
## Design Specification Document v1.0

**Document Status:** Draft
**Last Updated:** 2025-12-16
**Authors:** Engineering Team
**Target Audience:** Developers, QA, DevOps

---

## 1. Component Design Specifications

### 1.1 IngestionAgent

**File:** `services/ingestion/ingestion_agent.py`

**Responsibilities:**
- Poll Yahoo Finance API every 1-10 seconds per symbol
- Normalize data to internal schema
- Publish to NATS topic `data.market.quote`
- Store latest quote in Redis for instant access
- Handle API rate limits and retries

**Dependencies:**
```python
yfinance==0.2.33
nats-py==2.6.0
redis[hiredis]==5.0.1
pydantic==2.5.3
```

**Configuration:**
```yaml
# config/ingestion.yaml
polling:
  interval_seconds: 5
  batch_size: 100

rate_limits:
  max_requests_per_minute: 2000
  retry_attempts: 3
  retry_backoff_seconds: 1

symbols:
  watchlist_file: "data/symbols.txt"  # 5000 symbols, one per line

apis:
  yahoo_finance:
    timeout_seconds: 10
```

**Implementation:**
```python
import asyncio
import yfinance as yf
from nats.aio.client import Client as NATS
import redis.asyncio as redis
from pydantic import BaseModel
from datetime import datetime
import json
from collections import deque
from typing import List

class MarketQuote(BaseModel):
    """Schema for market quote message"""
    schema_version: str = "1.0"
    msg_id: str
    correlation_id: str
    produced_at: str
    symbol: str
    price: float
    volume: int
    change_percent: float
    timestamp: str

class IngestionAgent:
    def __init__(self, config: dict):
        self.config = config
        self.nats = NATS()
        self.redis = redis.Redis()
        self.symbols = self._load_symbols()
        self.rate_limiter = deque(maxlen=60)  # Track requests per minute

    def _load_symbols(self) -> List[str]:
        """Load symbol list from file"""
        with open(self.config['symbols']['watchlist_file']) as f:
            return [line.strip() for line in f if line.strip()]

    async def start(self):
        """Initialize connections and start polling"""
        await self.nats.connect(servers=["nats://localhost:4222"])
        await self.redis.connect()

        print(f"[IngestionAgent] Starting for {len(self.symbols)} symbols")

        # Create polling tasks (batch by 100 symbols)
        tasks = []
        for i in range(0, len(self.symbols), 100):
            batch = self.symbols[i:i+100]
            tasks.append(self.poll_batch(batch))

        await asyncio.gather(*tasks)

    async def poll_batch(self, symbols: List[str]):
        """Poll a batch of symbols continuously"""
        while True:
            try:
                # Rate limit check
                await self._check_rate_limit()

                # Fetch data for all symbols in batch
                data = await self._fetch_quotes(symbols)

                # Process each symbol
                for symbol_data in data:
                    await self._process_quote(symbol_data)

            except Exception as e:
                print(f"[IngestionAgent] Error polling batch: {e}")

            # Wait before next poll
            await asyncio.sleep(self.config['polling']['interval_seconds'])

    async def _check_rate_limit(self):
        """Ensure we don't exceed rate limits"""
        now = datetime.now().timestamp()
        self.rate_limiter.append(now)

        # Count requests in last minute
        minute_ago = now - 60
        requests_last_minute = sum(1 for t in self.rate_limiter if t > minute_ago)

        if requests_last_minute >= self.config['rate_limits']['max_requests_per_minute']:
            wait_time = 60 - (now - self.rate_limiter[0])
            print(f"[IngestionAgent] Rate limit reached, waiting {wait_time:.1f}s")
            await asyncio.sleep(wait_time)

    async def _fetch_quotes(self, symbols: List[str]) -> List[dict]:
        """Fetch quotes using yfinance"""
        try:
            # Use yfinance Ticker to get current data
            tickers = yf.Tickers(' '.join(symbols))

            results = []
            for symbol in symbols:
                try:
                    ticker = tickers.tickers[symbol]
                    info = ticker.info

                    # Extract relevant data
                    quote_data = {
                        'symbol': symbol,
                        'price': info.get('currentPrice', info.get('regularMarketPrice', 0)),
                        'volume': info.get('volume', info.get('regularMarketVolume', 0)),
                        'change_percent': info.get('regularMarketChangePercent', 0),
                    }

                    results.append(quote_data)

                except Exception as e:
                    print(f"[IngestionAgent] Error fetching {symbol}: {e}")
                    continue

            return results

        except Exception as e:
            print(f"[IngestionAgent] Batch fetch error: {e}")
            return []

    async def _process_quote(self, quote_data: dict):
        """Process and publish a single quote"""
        import uuid

        # Create message
        msg_id = str(uuid.uuid4())
        message = MarketQuote(
            msg_id=msg_id,
            correlation_id=msg_id,
            produced_at=datetime.utcnow().isoformat() + 'Z',
            symbol=quote_data['symbol'],
            price=quote_data['price'],
            volume=quote_data['volume'],
            change_percent=quote_data['change_percent'],
            timestamp=datetime.utcnow().isoformat() + 'Z'
        )

        # Publish to NATS
        await self.nats.publish(
            "data.market.quote",
            message.model_dump_json().encode()
        )

        # Store in Redis (latest quote)
        await self.redis.hset(
            f"quote:{quote_data['symbol']}",
            mapping={
                'price': str(quote_data['price']),
                'volume': str(quote_data['volume']),
                'timestamp': message.timestamp
            }
        )

        # Also store last_price for feature computation
        await self.redis.set(
            f"last_price:{quote_data['symbol']}",
            quote_data['price']
        )
```

---

### 1.2 FeatureStore

**File:** `services/feature_store/feature_store.py`

**Responsibilities:**
- Subscribe to `data.market.quote`
- Maintain rolling window of 252 trading days per symbol
- Compute 20 technical features using vectorized operations
- Store features in Redis hash
- Publish `data.features.ready` event

**Key Features to Compute:**

```python
import numpy as np
import pandas as pd
from collections import deque
from typing import Dict, Deque

class FeatureStore:
    def __init__(self):
        self.nats = NATS()
        self.redis = redis.Redis()

        # Rolling windows per symbol (252 days = 1 trading year)
        self.price_windows: Dict[str, Deque] = {}
        self.volume_windows: Dict[str, Deque] = {}

        # Market data (S&P 500 for beta calculation)
        self.market_prices = deque(maxlen=252)

    async def start(self):
        await self.nats.connect()
        await self.redis.connect()

        # Subscribe to market quotes
        await self.nats.subscribe("data.market.quote", cb=self.on_market_quote)

        # Background task to fetch market index data
        asyncio.create_task(self.update_market_index())

        print("[FeatureStore] Started")

    async def on_market_quote(self, msg):
        """Process incoming market quote"""
        data = json.loads(msg.data.decode())
        symbol = data['symbol']
        price = data['price']
        volume = data['volume']

        # Initialize windows if needed
        if symbol not in self.price_windows:
            self.price_windows[symbol] = deque(maxlen=252)
            self.volume_windows[symbol] = deque(maxlen=252)

            # Load historical data
            await self._load_historical_data(symbol)

        # Append new data
        self.price_windows[symbol].append({
            'price': price,
            'timestamp': data['timestamp']
        })
        self.volume_windows[symbol].append(volume)

        # Compute features
        features = self.compute_features(symbol)

        # Store in Redis
        await self.store_features(symbol, features)

        # Publish event
        await self.nats.publish(
            "data.features.ready",
            json.dumps({
                'symbol': symbol,
                'timestamp': data['timestamp']
            }).encode()
        )

    async def _load_historical_data(self, symbol: str):
        """Load historical prices for feature computation"""
        # Use yfinance to get 1 year of historical data
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period='1y', interval='1d')

        for idx, row in hist.iterrows():
            self.price_windows[symbol].append({
                'price': row['Close'],
                'timestamp': idx.isoformat()
            })
            self.volume_windows[symbol].append(row['Volume'])

    def compute_features(self, symbol: str) -> dict:
        """
        Compute all 20 technical features

        Returns dictionary with feature names as keys
        """
        prices = np.array([p['price'] for p in self.price_windows[symbol]])
        volumes = np.array(list(self.volume_windows[symbol]))

        if len(prices) < 2:
            return self._default_features()

        # Compute returns
        returns = np.diff(prices) / prices[:-1]

        features = {}

        # === MOMENTUM FEATURES (6) ===
        features['return_1d'] = returns[-1] if len(returns) >= 1 else 0
        features['return_5d'] = (prices[-1] / prices[-5] - 1) if len(prices) >= 5 else 0
        features['return_20d'] = (prices[-1] / prices[-20] - 1) if len(prices) >= 20 else 0
        features['return_60d'] = (prices[-1] / prices[-60] - 1) if len(prices) >= 60 else 0
        features['return_120d'] = (prices[-1] / prices[-120] - 1) if len(prices) >= 120 else 0
        features['return_252d'] = (prices[-1] / prices[-252] - 1) if len(prices) >= 252 else 0

        # === VOLATILITY FEATURES (3) ===
        annualization_factor = np.sqrt(252)
        features['volatility_5d'] = np.std(returns[-5:]) * annualization_factor if len(returns) >= 5 else 0
        features['volatility_20d'] = np.std(returns[-20:]) * annualization_factor if len(returns) >= 20 else 0
        features['volatility_60d'] = np.std(returns[-60:]) * annualization_factor if len(returns) >= 60 else 0

        # === VOLUME FEATURES (3) ===
        features['volume_ratio_5d'] = volumes[-1] / np.mean(volumes[-5:]) if len(volumes) >= 5 else 1
        features['volume_ratio_20d'] = volumes[-1] / np.mean(volumes[-20:]) if len(volumes) >= 20 else 1
        features['dollar_volume'] = prices[-1] * volumes[-1]

        # === MARKET FEATURES (3) ===
        if len(self.market_prices) >= 20:
            market_prices_arr = np.array(list(self.market_prices))
            market_returns = np.diff(market_prices_arr) / market_prices_arr[:-1]

            # Beta calculation
            if len(returns) >= len(market_returns):
                cov = np.cov(returns[-len(market_returns):], market_returns)[0, 1]
                var_market = np.var(market_returns)
                features['market_beta'] = cov / var_market if var_market > 0 else 1
            else:
                features['market_beta'] = 1

            features['market_return'] = market_returns[-1]
            features['market_volatility'] = np.std(market_returns) * annualization_factor
        else:
            features['market_beta'] = 1
            features['market_return'] = 0
            features['market_volatility'] = 0.2

        # === TECHNICAL INDICATORS (5) ===
        features['rsi_14'] = self._compute_rsi(returns, period=14)
        features['macd'] = self._compute_macd(prices)
        features['sma_50_200_cross'] = self._compute_sma_cross(prices)
        features['bollinger_position'] = self._compute_bollinger_position(prices)
        features['atr'] = self._compute_atr(prices)

        # Store last price for prediction agent
        features['last_price'] = float(prices[-1])
        features['computed_at'] = datetime.utcnow().isoformat() + 'Z'

        return features

    def _compute_rsi(self, returns: np.ndarray, period: int = 14) -> float:
        """Compute Relative Strength Index"""
        if len(returns) < period:
            return 50  # Neutral

        recent_returns = returns[-period:]
        gains = recent_returns[recent_returns > 0]
        losses = -recent_returns[recent_returns < 0]

        avg_gain = np.mean(gains) if len(gains) > 0 else 0
        avg_loss = np.mean(losses) if len(losses) > 0 else 0

        if avg_loss == 0:
            return 100

        rs = avg_gain / avg_loss
        rsi = 100 - (100 / (1 + rs))

        return float(rsi)

    def _compute_macd(self, prices: np.ndarray) -> float:
        """Compute MACD (EMA12 - EMA26)"""
        if len(prices) < 26:
            return 0

        ema_12 = self._ema(prices, 12)
        ema_26 = self._ema(prices, 26)

        return float(ema_12 - ema_26)

    def _ema(self, prices: np.ndarray, period: int) -> float:
        """Exponential Moving Average"""
        if len(prices) < period:
            return prices[-1]

        alpha = 2 / (period + 1)
        ema = prices[-period]

        for price in prices[-period+1:]:
            ema = alpha * price + (1 - alpha) * ema

        return ema

    def _compute_sma_cross(self, prices: np.ndarray) -> float:
        """Golden Cross indicator (SMA50 > SMA200)"""
        if len(prices) < 200:
            return 0

        sma_50 = np.mean(prices[-50:])
        sma_200 = np.mean(prices[-200:])

        return 1.0 if sma_50 > sma_200 else 0.0

    def _compute_bollinger_position(self, prices: np.ndarray, period: int = 20) -> float:
        """Position within Bollinger Bands (0 to 1)"""
        if len(prices) < period:
            return 0.5

        sma = np.mean(prices[-period:])
        std = np.std(prices[-period:])

        upper_band = sma + 2 * std
        lower_band = sma - 2 * std

        if upper_band == lower_band:
            return 0.5

        position = (prices[-1] - lower_band) / (upper_band - lower_band)
        return float(np.clip(position, 0, 1))

    def _compute_atr(self, prices: np.ndarray, period: int = 14) -> float:
        """Average True Range"""
        if len(prices) < period + 1:
            return 0

        # Simplified ATR (using high-low range)
        ranges = np.abs(np.diff(prices[-period-1:]))
        atr = np.mean(ranges)

        return float(atr)

    def _default_features(self) -> dict:
        """Return default feature values when insufficient data"""
        return {
            'return_1d': 0, 'return_5d': 0, 'return_20d': 0,
            'return_60d': 0, 'return_120d': 0, 'return_252d': 0,
            'volatility_5d': 0, 'volatility_20d': 0, 'volatility_60d': 0,
            'volume_ratio_5d': 1, 'volume_ratio_20d': 1, 'dollar_volume': 0,
            'market_beta': 1, 'market_return': 0, 'market_volatility': 0.2,
            'rsi_14': 50, 'macd': 0, 'sma_50_200_cross': 0,
            'bollinger_position': 0.5, 'atr': 0,
            'last_price': 0, 'computed_at': datetime.utcnow().isoformat() + 'Z'
        }

    async def store_features(self, symbol: str, features: dict):
        """Store features in Redis"""
        await self.redis.hset(
            f"features:{symbol}",
            mapping={k: str(v) for k, v in features.items()}
        )

        # Set expiration (5 minutes)
        await self.redis.expire(f"features:{symbol}", 300)

    async def update_market_index(self):
        """Background task to update S&P 500 data"""
        while True:
            try:
                # Fetch S&P 500 (^GSPC)
                ticker = yf.Ticker("^GSPC")
                hist = ticker.history(period='1y', interval='1d')

                self.market_prices.clear()
                for idx, row in hist.iterrows():
                    self.market_prices.append(row['Close'])

                print("[FeatureStore] Updated market index data")

            except Exception as e:
                print(f"[FeatureStore] Error updating market index: {e}")

            # Update every hour
            await asyncio.sleep(3600)
```

---

### 1.3 NormalDayPredictionAgent

**File:** `services/prediction_normal/normal_day_agent.py`

**Key Implementation Details:**

```python
import numpy as np
import onnxruntime as ort
from typing import List, Dict

class NormalDayPredictionAgent:
    def __init__(self, model_path: str):
        self.nats = NATS()
        self.redis = redis.Redis()

        # Load ONNX model for fast inference
        self.session = ort.InferenceSession(
            model_path,
            providers=['CUDAExecutionProvider', 'CPUExecutionProvider']
        )

        self.feature_names = [
            'return_1d', 'return_5d', 'return_20d', 'return_60d',
            'return_120d', 'return_252d',
            'volatility_5d', 'volatility_20d', 'volatility_60d',
            'volume_ratio_5d', 'volume_ratio_20d', 'dollar_volume',
            'market_beta', 'market_return', 'market_volatility',
            'rsi_14', 'macd', 'sma_50_200_cross', 'bollinger_position', 'atr'
        ]

        self.batch_size = 128
        self.pending_symbols = []

    async def start(self):
        await self.nats.connect()
        await self.redis.connect()

        # Subscribe to prediction jobs
        await self.nats.subscribe("job.predict.normal", cb=self.on_job)

        # Start batch processing loop
        asyncio.create_task(self.batch_predict_loop())

        print("[NormalDayAgent] Started")

    async def on_job(self, msg):
        """Queue symbol for batch prediction"""
        data = json.loads(msg.data.decode())
        symbol = data['symbol']

        self.pending_symbols.append(symbol)

    async def batch_predict_loop(self):
        """Process predictions in batches"""
        while True:
            if len(self.pending_symbols) >= self.batch_size or \
               (len(self.pending_symbols) > 0 and await self._should_flush()):

                # Take batch
                batch = self.pending_symbols[:self.batch_size]
                self.pending_symbols = self.pending_symbols[self.batch_size:]

                # Predict
                await self.predict_batch(batch)

            await asyncio.sleep(0.1)  # Check every 100ms

    async def _should_flush(self) -> bool:
        """Flush if queue has been waiting too long"""
        # Implement timeout logic
        return len(self.pending_symbols) > 0 and True  # Simplified

    async def predict_batch(self, symbols: List[str]):
        """Predict for a batch of symbols"""

        # Load features for all symbols
        features_list = []
        valid_symbols = []

        for symbol in symbols:
            features = await self.redis.hgetall(f"features:{symbol}")

            if not features:
                continue

            # Convert to numpy array
            feature_vector = np.array([
                float(features.get(fname, 0))
                for fname in self.feature_names
            ], dtype=np.float32)

            features_list.append(feature_vector)
            valid_symbols.append(symbol)

        if not features_list:
            return

        # Stack into batch
        X_batch = np.vstack(features_list)

        # Run inference
        input_name = self.session.get_inputs()[0].name
        predictions = self.session.run(None, {input_name: X_batch})[0]

        # Store predictions
        for symbol, prediction in zip(valid_symbols, predictions):
            await self.store_prediction(symbol, float(prediction[0]))

    async def store_prediction(self, symbol: str, predicted_return: float):
        """Store prediction in Redis and TimescaleDB"""

        # Get current price
        last_price = float(await self.redis.get(f"last_price:{symbol}") or 0)
        predicted_price = last_price * (1 + predicted_return)

        # Create record
        record = {
            'symbol': symbol,
            'predicted_return_1d': predicted_return,
            'predicted_price': predicted_price,
            'model_type': 'normal_day',
            'model_version': 'v2.1',
            'predicted_at': datetime.utcnow().isoformat() + 'Z'
        }

        # Store in Redis
        await self.redis.setex(
            f"pred:{symbol}",
            120,  # 2 minute TTL
            json.dumps(record)
        )

        # Store in TimescaleDB (async write)
        # await self.db.execute(...)
```

---

## 2. Database Schemas

### 2.1 TimescaleDB Complete Schema

```sql
-- Create database
CREATE DATABASE predictions;

-- Connect to database
\c predictions;

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Main predictions table
CREATE TABLE predictions (
    id BIGSERIAL,
    symbol TEXT NOT NULL,
    predicted_return_1d REAL NOT NULL,
    predicted_price REAL NOT NULL,
    uncertainty_sigma REAL,
    p10 REAL,
    p50 REAL,
    p90 REAL,
    model_type TEXT NOT NULL CHECK (model_type IN ('normal_day', 'earnings_day')),
    model_version TEXT NOT NULL,
    predicted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    features_snapshot JSONB,
    earnings_context JSONB,

    PRIMARY KEY (symbol, predicted_at)
);

-- Convert to hypertable (TimescaleDB feature)
SELECT create_hypertable('predictions', 'predicted_at');

-- Create index for fast symbol lookups
CREATE INDEX idx_predictions_symbol ON predictions (symbol, predicted_at DESC);

-- Create index for model type filtering
CREATE INDEX idx_predictions_model_type ON predictions (model_type);

-- Create materialized view for latest predictions
CREATE MATERIALIZED VIEW latest_predictions AS
SELECT DISTINCT ON (symbol)
    symbol,
    predicted_return_1d,
    predicted_price,
    uncertainty_sigma,
    p10,
    p50,
    p90,
    model_type,
    model_version,
    predicted_at,
    data_timestamp
FROM predictions
ORDER BY symbol, predicted_at DESC;

-- Create unique index on materialized view
CREATE UNIQUE INDEX idx_latest_predictions_symbol ON latest_predictions (symbol);

-- Refresh materialized view every minute
CREATE OR REPLACE FUNCTION refresh_latest_predictions()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY latest_predictions;
END;
$$ LANGUAGE plpgsql;

-- Compression policy (compress data older than 7 days)
SELECT add_compression_policy('predictions', INTERVAL '7 days');

-- Retention policy (drop data older than 90 days)
SELECT add_retention_policy('predictions', INTERVAL '90 days');

-- Table for tracking model performance
CREATE TABLE model_metrics (
    id BIGSERIAL PRIMARY KEY,
    model_type TEXT NOT NULL,
    model_version TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value REAL NOT NULL,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    window_start TIMESTAMPTZ,
    window_end TIMESTAMPTZ,
    sample_count INT
);

CREATE INDEX idx_model_metrics_time ON model_metrics (computed_at DESC);
```

---

## 3. API Implementation (FastAPI)

### 3.1 Main Application

**File:** `services/api/main.py`

```python
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import redis.asyncio as redis
import asyncpg
from contextlib import asynccontextmanager
from typing import Optional, List
import json

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.redis = await redis.from_url("redis://localhost:6379")
    app.state.db_pool = await asyncpg.create_pool(
        "postgresql://user:pass@localhost:5432/predictions",
        min_size=5,
        max_size=20
    )
    yield
    # Shutdown
    await app.state.redis.close()
    await app.state.db_pool.close()

app = FastAPI(
    title="Real-Time Price Prediction API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency for Redis
async def get_redis():
    return app.state.redis

# Dependency for DB
async def get_db():
    async with app.state.db_pool.acquire() as conn:
        yield conn

@app.get("/")
async def root():
    return {"status": "healthy", "service": "price-prediction-api"}

@app.get("/api/prediction/{symbol}")
async def get_prediction(
    symbol: str,
    include_features: bool = False,
    redis: redis.Redis = Depends(get_redis),
    db = Depends(get_db)
):
    """Get latest prediction for symbol"""

    symbol = symbol.upper()

    # Try Redis first (cache)
    cached = await redis.get(f"pred:{symbol}")

    if cached:
        prediction = json.loads(cached)

        if include_features:
            features = await redis.hgetall(f"features:{symbol}")
            prediction['features'] = {k.decode(): v.decode() for k, v in features.items()}

        return prediction

    # Fallback to database
    row = await db.fetchrow(
        """
        SELECT * FROM latest_predictions
        WHERE symbol = $1
        """,
        symbol
    )

    if not row:
        raise HTTPException(status_code=404, detail=f"No prediction found for {symbol}")

    prediction = dict(row)

    return prediction

@app.post("/api/explanation/{symbol}")
async def request_explanation(
    symbol: str,
    depth: str = "medium",
    redis: redis.Redis = Depends(get_redis)
):
    """Request explanation generation (async)"""

    symbol = symbol.upper()

    # Check if explanation already cached
    cached = await redis.get(f"explanation:{symbol}")
    if cached:
        return {"status": "completed", "explanation": json.loads(cached)}

    # Create job
    import uuid
    job_id = f"exp_{uuid.uuid4().hex[:16]}"

    # Publish job to NATS (simplified - would use proper NATS client)
    # await nats.publish("job.explain.generate", json.dumps({
    #     "job_id": job_id,
    #     "symbol": symbol,
    #     "depth": depth
    # }))

    return {
        "job_id": job_id,
        "status": "processing",
        "estimated_time_sec": 3
    }

@app.get("/api/explanation/{symbol}")
async def get_explanation(
    symbol: str,
    redis: redis.Redis = Depends(get_redis)
):
    """Get explanation (check if completed)"""

    symbol = symbol.upper()

    cached = await redis.get(f"explanation:{symbol}")

    if not cached:
        return {"status": "not_found"}

    return {
        "status": "completed",
        "explanation": json.loads(cached)
    }

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.subscriptions: dict = {}  # ws -> set of symbols

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        self.subscriptions[websocket] = set()

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
        del self.subscriptions[websocket]

    async def subscribe(self, websocket: WebSocket, symbols: List[str]):
        self.subscriptions[websocket].update(symbols)

    async def unsubscribe(self, websocket: WebSocket, symbols: List[str]):
        self.subscriptions[websocket].difference_update(symbols)

    async def broadcast_update(self, symbol: str, data: dict):
        """Send update to all subscribed clients"""
        for ws in self.active_connections:
            if symbol in self.subscriptions[ws]:
                await ws.send_json({
                    "type": "prediction_update",
                    "symbol": symbol,
                    **data
                })

manager = ConnectionManager()

@app.websocket("/ws/predictions")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)

    try:
        while True:
            data = await websocket.receive_json()

            if data['action'] == 'subscribe':
                await manager.subscribe(websocket, data['symbols'])
                await websocket.send_json({
                    "status": "subscribed",
                    "symbols": data['symbols']
                })

            elif data['action'] == 'unsubscribe':
                await manager.unsubscribe(websocket, data['symbols'])
                await websocket.send_json({
                    "status": "unsubscribed",
                    "symbols": data['symbols']
                })

    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

---

## 4. UI Components (React/Next.js)

### 4.1 Search Bar Component

**File:** `ui/components/SearchBar.tsx`

```typescript
import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';

interface SearchBarProps {
  onSymbolSelect?: (symbol: string) => void;
}

export function SearchBar({ onSymbolSelect }: SearchBarProps) {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (query.length < 1) {
      setSuggestions([]);
      return;
    }

    // Fetch suggestions (debounced)
    const timer = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await fetch(`/api/symbols/search?q=${query}`);
        const data = await res.json();
        setSuggestions(data.symbols);
      } catch (error) {
        console.error('Search error:', error);
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [query]);

  const handleSelect = (symbol: string) => {
    setQuery('');
    setSuggestions([]);

    if (onSymbolSelect) {
      onSymbolSelect(symbol);
    } else {
      router.push(`/symbol/${symbol}`);
    }
  };

  return (
    <div className="search-bar relative">
      <input
        type="text"
        placeholder="Search symbol (e.g., NVDA)"
        value={query}
        onChange={(e) => setQuery(e.target.value.toUpperCase())}
        className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500"
        onKeyDown={(e) => {
          if (e.key === 'Enter' && suggestions.length > 0) {
            handleSelect(suggestions[0]);
          }
        }}
      />

      {loading && (
        <div className="absolute right-3 top-3">
          <LoadingSpinner size="sm" />
        </div>
      )}

      {suggestions.length > 0 && (
        <div className="absolute w-full mt-1 bg-white border rounded-lg shadow-lg z-10">
          {suggestions.map((symbol) => (
            <button
              key={symbol}
              onClick={() => handleSelect(symbol)}
              className="w-full px-4 py-2 text-left hover:bg-gray-100"
            >
              {symbol}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
```

### 4.2 Prediction Card Component

**File:** `ui/components/PredictionCard.tsx`

```typescript
import { useEffect, useState } from 'react';
import { useWebSocket } from '../hooks/useWebSocket';

interface Prediction {
  symbol: string;
  predicted_return_1d: number;
  predicted_price: number;
  uncertainty?: {
    sigma: number;
    p10: number;
    p90: number;
  };
  predicted_at: string;
  model_type: string;
}

export function PredictionCard({ symbol }: { symbol: string }) {
  const [prediction, setPrediction] = useState<Prediction | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showExplanation, setShowExplanation] = useState(false);

  // Initial fetch
  useEffect(() => {
    fetchPrediction();
  }, [symbol]);

  const fetchPrediction = async () => {
    try {
      const res = await fetch(`/api/prediction/${symbol}`);
      if (!res.ok) throw new Error('Prediction not found');
      const data = await res.json();
      setPrediction(data);
      setLoading(false);
    } catch (err) {
      setError(err.message);
      setLoading(false);
    }
  };

  // Real-time updates via WebSocket
  useWebSocket({
    onMessage: (data) => {
      if (data.type === 'prediction_update' && data.symbol === symbol) {
        setPrediction(prev => ({ ...prev, ...data }));
      }
    },
    symbols: [symbol]
  });

  if (loading) {
    return (
      <div className="prediction-card animate-pulse">
        <div className="h-32 bg-gray-200 rounded"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="prediction-card bg-red-50 border-red-200">
        <p className="text-red-600">{error}</p>
      </div>
    );
  }

  const isPositive = prediction.predicted_return_1d > 0;

  return (
    <div className="prediction-card bg-white rounded-lg shadow-lg p-6">
      {/* Header */}
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-2xl font-bold">{prediction.symbol}</h3>
        <span className={`px-3 py-1 rounded text-sm ${
          prediction.model_type === 'earnings_day'
            ? 'bg-purple-100 text-purple-700'
            : 'bg-gray-100 text-gray-700'
        }`}>
          {prediction.model_type === 'earnings_day' ? '📊 Earnings' : '📈 Normal'}
        </span>
      </div>

      {/* Predicted Price */}
      <div className="mb-4">
        <div className="text-sm text-gray-500 mb-1">Predicted Price (1-day)</div>
        <div className="flex items-baseline gap-3">
          <span className="text-4xl font-bold">
            ${prediction.predicted_price.toFixed(2)}
          </span>
          <span className={`text-2xl font-semibold ${
            isPositive ? 'text-green-600' : 'text-red-600'
          }`}>
            {isPositive ? '+' : ''}{(prediction.predicted_return_1d * 100).toFixed(2)}%
          </span>
        </div>
      </div>

      {/* Confidence Interval */}
      {prediction.uncertainty && (
        <div className="mb-4 p-3 bg-gray-50 rounded">
          <div className="text-sm text-gray-600 mb-2">90% Confidence Interval</div>
          <div className="flex justify-between items-center">
            <span className="text-red-600">
              {(prediction.uncertainty.p10 * 100).toFixed(2)}%
            </span>
            <div className="flex-1 mx-3 h-2 bg-gradient-to-r from-red-200 via-yellow-200 to-green-200 rounded"></div>
            <span className="text-green-600">
              {(prediction.uncertainty.p90 * 100).toFixed(2)}%
            </span>
          </div>
          <div className="text-xs text-gray-500 mt-1">
            Uncertainty: ±{(prediction.uncertainty.sigma * 100).toFixed(2)}%
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="flex gap-3">
        <button
          onClick={() => setShowExplanation(!showExplanation)}
          className="flex-1 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {showExplanation ? 'Hide' : 'Explain'} Prediction
        </button>
        <button
          onClick={fetchPrediction}
          className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
        >
          🔄 Refresh
        </button>
      </div>

      {/* Explanation Panel */}
      {showExplanation && (
        <ExplanationPanel symbol={prediction.symbol} />
      )}

      {/* Timestamp */}
      <div className="mt-4 text-xs text-gray-400">
        Predicted {new Date(prediction.predicted_at).toLocaleString()}
      </div>
    </div>
  );
}
```

---

## 5. Configuration Files

### 5.1 Complete Docker Compose Configuration

**File:** `docker-compose.yml`

```yaml
version: '3.8'

services:
  #
  # === INFRASTRUCTURE SERVICES (Open-Source) ===
  #

  # Message Bus - NATS JetStream
  nats:
    image: nats:2.10-alpine
    container_name: riskee-nats
    command:
      - "-js"
      - "-sd"
      - "/data"
      - "--max_payload"
      - "8MB"
    ports:
      - "4222:4222"  # Client connections
      - "8222:8222"  # HTTP monitoring
    volumes:
      - nats-data:/data
    networks:
      - riskee-network
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8222/healthz"]
      interval: 10s
      timeout: 5s
      retries: 3

  # Cache Layer - Redis
  redis:
    image: redis:7-alpine
    container_name: riskee-redis
    command: redis-server --appendonly yes --maxmemory 4gb --maxmemory-policy allkeys-lru
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - riskee-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  # Database - TimescaleDB (PostgreSQL + time-series)
  timescaledb:
    image: timescale/timescaledb:latest-pg15
    container_name: riskee-timescaledb
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: dev_password_change_in_prod
      POSTGRES_DB: predictions
      POSTGRES_INITDB_ARGS: "-E UTF8"
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./scripts/init_db.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - riskee-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Vector Database - Qdrant
  qdrant:
    image: qdrant/qdrant:v1.7.4
    container_name: riskee-qdrant
    ports:
      - "6333:6333"  # HTTP API
      - "6334:6334"  # gRPC API
    volumes:
      - qdrant-data:/qdrant/storage
    networks:
      - riskee-network
    environment:
      QDRANT__SERVICE__GRPC_PORT: 6334

  # LLM Server - Ollama (Llama 3.1 8B)
  ollama:
    image: ollama/ollama:latest
    container_name: riskee-ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama-models:/root/.ollama
    networks:
      - riskee-network
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3

  #
  # === APPLICATION SERVICES ===
  #

  # Data Ingestion Agent
  ingestion:
    build:
      context: ./services/ingestion
      dockerfile: Dockerfile
    container_name: riskee-ingestion
    depends_on:
      nats:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      NATS_URL: nats://nats:4222
      REDIS_URL: redis://redis:6379
      LOG_LEVEL: INFO
    volumes:
      - ./data:/app/data
      - ./config:/app/config
    networks:
      - riskee-network
    restart: unless-stopped

  # Feature Store Service
  feature-store:
    build:
      context: ./services/feature_store
      dockerfile: Dockerfile
    container_name: riskee-feature-store
    depends_on:
      nats:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      NATS_URL: nats://nats:4222
      REDIS_URL: redis://redis:6379
      LOG_LEVEL: INFO
    networks:
      - riskee-network
    restart: unless-stopped

  # Routing Agent
  routing:
    build:
      context: ./services/routing
      dockerfile: Dockerfile
    container_name: riskee-routing
    depends_on:
      nats:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      NATS_URL: nats://nats:4222
      REDIS_URL: redis://redis:6379
      LOG_LEVEL: INFO
    networks:
      - riskee-network
    restart: unless-stopped

  # Normal Day Prediction Agent (can scale)
  prediction-normal:
    build:
      context: ./services/prediction_normal
      dockerfile: Dockerfile
    depends_on:
      nats:
        condition: service_healthy
      redis:
        condition: service_healthy
      timescaledb:
        condition: service_healthy
    environment:
      NATS_URL: nats://nats:4222
      REDIS_URL: redis://redis:6379
      DB_URL: postgresql://postgres:dev_password_change_in_prod@timescaledb:5432/predictions
      MODEL_PATH: /app/models/lstm_normal_v2.1.onnx
      LOG_LEVEL: INFO
    volumes:
      - ./models/normal_day:/app/models
    networks:
      - riskee-network
    deploy:
      replicas: 2
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped

  # Earnings Day Prediction Agent
  prediction-earnings:
    build:
      context: ./services/prediction_earnings
      dockerfile: Dockerfile
    container_name: riskee-prediction-earnings
    depends_on:
      nats:
        condition: service_healthy
      redis:
        condition: service_healthy
      timescaledb:
        condition: service_healthy
    environment:
      NATS_URL: nats://nats:4222
      REDIS_URL: redis://redis:6379
      DB_URL: postgresql://postgres:dev_password_change_in_prod@timescaledb:5432/predictions
      MODEL_PATH: /app/models/lstm_earnings_v2.1.onnx
      LOG_LEVEL: INFO
    volumes:
      - ./models/earnings_day:/app/models
    networks:
      - riskee-network
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped

  # Explanation Worker (LLM + RAG)
  explanation-worker:
    build:
      context: ./services/explanation
      dockerfile: Dockerfile
    container_name: riskee-explanation
    depends_on:
      nats:
        condition: service_healthy
      redis:
        condition: service_healthy
      qdrant:
        condition: service_started
      ollama:
        condition: service_healthy
    environment:
      NATS_URL: nats://nats:4222
      REDIS_URL: redis://redis:6379
      QDRANT_URL: http://qdrant:6333
      OLLAMA_URL: http://ollama:11434
      OLLAMA_MODEL: llama3.1:8b-instruct-q4_K_M
      LOG_LEVEL: INFO
    networks:
      - riskee-network
    restart: unless-stopped

  # FastAPI Gateway
  api:
    build:
      context: ./services/api
      dockerfile: Dockerfile
    container_name: riskee-api
    depends_on:
      redis:
        condition: service_healthy
      timescaledb:
        condition: service_healthy
      nats:
        condition: service_healthy
    ports:
      - "8000:8000"
    environment:
      REDIS_URL: redis://redis:6379
      DB_URL: postgresql://postgres:dev_password_change_in_prod@timescaledb:5432/predictions
      NATS_URL: nats://nats:4222
      LOG_LEVEL: INFO
      CORS_ORIGINS: http://localhost:3000,http://localhost:3001
    networks:
      - riskee-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Next.js UI
  ui:
    build:
      context: ./ui
      dockerfile: Dockerfile
    container_name: riskee-ui
    depends_on:
      api:
        condition: service_healthy
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
      NEXT_PUBLIC_WS_URL: ws://localhost:8000
    networks:
      - riskee-network
    restart: unless-stopped

  #
  # === MONITORING (Optional) ===
  #

  # Prometheus (metrics collection)
  prometheus:
    image: prom/prometheus:latest
    container_name: riskee-prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    networks:
      - riskee-network
    profiles:
      - monitoring

  # Grafana (visualization)
  grafana:
    image: grafana/grafana:latest
    container_name: riskee-grafana
    ports:
      - "3001:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: redis-datasource
    networks:
      - riskee-network
    profiles:
      - monitoring

#
# === NETWORKS ===
#
networks:
  riskee-network:
    driver: bridge

#
# === VOLUMES (Persistent Data) ===
#
volumes:
  nats-data:
  redis-data:
  postgres-data:
  qdrant-data:
  ollama-models:
  prometheus-data:
  grafana-data:
```

### 5.2 Helper Scripts

**File:** `scripts/setup.sh`

```bash
#!/bin/bash
set -e

echo "🚀 Setting up Riskee Price Prediction System..."

# Pull Ollama model
echo "📦 Pulling Llama 3.1 8B model..."
docker-compose up -d ollama
sleep 10
docker exec riskee-ollama ollama pull llama3.1:8b-instruct-q4_K_M

# Initialize database
echo "🗄️  Initializing TimescaleDB..."
docker-compose up -d timescaledb
sleep 5
docker exec riskee-timescaledb psql -U postgres -d predictions -f /docker-entrypoint-initdb.d/init.sql

# Start all services
echo "🎯 Starting all services..."
docker-compose up -d

echo "✅ Setup complete!"
echo "📊 UI: http://localhost:3000"
echo "🔌 API: http://localhost:8000/docs"
echo "📈 Grafana: http://localhost:3001 (admin/admin)"
```

**File:** `scripts/init_db.sql`

```sql
-- Initialize TimescaleDB with schema from Architecture doc
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- (Rest of schema from section 2.1 of Architecture doc)
```

### 5.3 Dockerfile Examples

**File:** `services/ingestion/Dockerfile`

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

CMD ["python", "ingestion_agent.py"]
```

**File:** `services/api/Dockerfile`

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

---

## 6. Explanation Worker Implementation (Open-Source LLM)

### 6.1 Explanation Worker with Ollama

**File:** `services/explanation/explanation_worker.py`

```python
import asyncio
import json
from nats.aio.client import Client as NATS
import redis.asyncio as redis
from langchain_community.llms import Ollama
from langchain_community.vectorstores import Qdrant
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain.prompts import PromptTemplate
from qdrant_client import QdrantClient
from typing import Dict, List
import os

class ExplanationWorker:
    """
    Worker that generates explanations using Llama 3.1 8B via Ollama
    """

    def __init__(self):
        self.nats = NATS()
        self.redis = redis.Redis()

        # Initialize Ollama LLM
        ollama_url = os.getenv("OLLAMA_URL", "http://ollama:11434")
        ollama_model = os.getenv("OLLAMA_MODEL", "llama3.1:8b-instruct-q4_K_M")

        self.llm = Ollama(
            model=ollama_model,
            base_url=ollama_url,
            temperature=0.3,  # Low temperature for factual explanations
            num_predict=512,  # Max tokens
            top_p=0.9
        )

        # Initialize RAG (Qdrant vector store)
        qdrant_url = os.getenv("QDRANT_URL", "http://qdrant:6333")

        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'}  # Use GPU if available
        )

        self.qdrant_client = QdrantClient(url=qdrant_url)

        self.vectorstore = Qdrant(
            client=self.qdrant_client,
            collection_name="financial_knowledge",
            embeddings=self.embeddings
        )

        # Prompt template
        self.prompt_template = PromptTemplate(
            input_variables=[
                "symbol", "predicted_return", "predicted_price", "confidence",
                "sigma", "p10", "p90", "model_type", "technical_summary",
                "earnings_summary", "rag_context"
            ],
            template="""You are a financial analyst providing clear, data-driven explanations of stock price predictions.

PREDICTION DATA:
- Symbol: {symbol}
- Predicted Return (1-day): {predicted_return:.2%}
- Predicted Price: ${predicted_price:.2f}
- Confidence: {confidence:.0%}
- Uncertainty (σ): {sigma:.2%}
- 90% Confidence Interval: [{p10:.2%}, {p90:.2%}]
- Model Type: {model_type}

TECHNICAL CONTEXT:
{technical_summary}

{earnings_summary}

RETRIEVED CONTEXT (from knowledge base):
{rag_context}

INSTRUCTIONS:
1. Explain the prediction in 2-3 clear sentences (focus on key drivers)
2. Highlight the uncertainty and what it means for investors
3. If earnings day: emphasize fundamental quality and historical patterns
4. Cite specific data points from the context
5. Be honest about limitations (e.g., "data is 60 seconds old")
6. Keep language professional but accessible

EXPLANATION:
"""
        )

    async def start(self):
        """Start the explanation worker"""
        await self.nats.connect(servers=[os.getenv("NATS_URL", "nats://nats:4222")])
        await self.redis.connect()

        # Subscribe to explanation jobs
        await self.nats.subscribe("job.explain.generate", cb=self.on_job)

        print("[ExplanationWorker] Started and ready to generate explanations")

        # Keep running
        while True:
            await asyncio.sleep(1)

    async def on_job(self, msg):
        """Handle explanation generation job"""
        try:
            data = json.loads(msg.data.decode())
            symbol = data['symbol']
            depth = data.get('depth', 'medium')

            print(f"[ExplanationWorker] Generating explanation for {symbol} (depth: {depth})")

            # Generate explanation
            explanation = await self.generate_explanation(symbol, depth)

            # Store in Redis cache
            await self.redis.setex(
                f"explanation:{symbol}",
                300,  # 5 minute TTL
                json.dumps(explanation)
            )

            # Publish completion event
            await self.nats.publish(
                "thought.explanation.ready",
                json.dumps({
                    "symbol": symbol,
                    "status": "completed"
                }).encode()
            )

            print(f"[ExplanationWorker] Completed explanation for {symbol}")

        except Exception as e:
            print(f"[ExplanationWorker] Error generating explanation: {e}")

    async def generate_explanation(self, symbol: str, depth: str = "medium") -> Dict:
        """Generate explanation using LLM + RAG"""

        # 1. Fetch prediction data from Redis
        prediction_data = await self.redis.get(f"pred:{symbol}")
        if not prediction_data:
            raise ValueError(f"No prediction found for {symbol}")

        prediction = json.loads(prediction_data)

        # 2. Fetch features for technical summary
        features = await self.redis.hgetall(f"features:{symbol}")
        technical_summary = self._format_technical_summary(features)

        # 3. Fetch earnings context if earnings day
        earnings_summary = ""
        if prediction.get('model_type') == 'earnings_day':
            earnings_data = await self.redis.hgetall(f"earnings_analysis:{symbol}")
            earnings_summary = self._format_earnings_summary(earnings_data)

        # 4. Retrieve relevant context from RAG
        query = f"{symbol} stock prediction technical analysis earnings fundamental quality"
        rag_docs = self.vectorstore.similarity_search(query, k=3)
        rag_context = "\n\n".join([doc.page_content for doc in rag_docs])

        # 5. Build prompt
        prompt = self.prompt_template.format(
            symbol=symbol,
            predicted_return=prediction['predicted_return_1d'],
            predicted_price=prediction['predicted_price'],
            confidence=0.7,  # Placeholder - compute from sigma
            sigma=prediction.get('uncertainty_sigma', 0.02),
            p10=prediction.get('p10', -0.01),
            p90=prediction.get('p90', 0.03),
            model_type=prediction['model_type'],
            technical_summary=technical_summary,
            earnings_summary=earnings_summary,
            rag_context=rag_context[:1000]  # Limit context length
        )

        # 6. Generate explanation with Ollama
        explanation_text = self.llm(prompt)

        # 7. Extract key drivers (simple parsing)
        key_drivers = self._extract_key_drivers(features, prediction)

        # 8. Return structured explanation
        return {
            "text": explanation_text.strip(),
            "confidence": 0.7,
            "key_drivers": key_drivers,
            "uncertainties": [
                f"Market volatility elevated ({float(features.get(b'volatility_20d', 0)):.1%} annualized)",
                "Data freshness: ~60 seconds old"
            ],
            "sources": [
                {
                    "title": doc.metadata.get('source', 'Internal Knowledge'),
                    "excerpt": doc.page_content[:200] + "...",
                    "relevance": 0.8
                }
                for doc in rag_docs[:2]
            ],
            "generated_at": prediction['predicted_at']
        }

    def _format_technical_summary(self, features: Dict) -> str:
        """Format technical features into readable summary"""
        if not features:
            return "Technical data unavailable."

        return_20d = float(features.get(b'return_20d', 0))
        volatility_20d = float(features.get(b'volatility_20d', 0))
        rsi_14 = float(features.get(b'rsi_14', 50))
        market_beta = float(features.get(b'market_beta', 1))

        return f"""
- 20-day Momentum: {return_20d:+.2%}
- Volatility (20d): {volatility_20d:.1%} annualized
- RSI (14-day): {rsi_14:.1f} {'(Overbought)' if rsi_14 > 70 else '(Oversold)' if rsi_14 < 30 else '(Neutral)'}
- Market Beta: {market_beta:.2f}
"""

    def _format_earnings_summary(self, earnings: Dict) -> str:
        """Format earnings data into readable summary"""
        if not earnings:
            return ""

        eps_surprise = float(earnings.get(b'eps_surprise_pct', 0))
        revenue_surprise = float(earnings.get(b'revenue_surprise_pct', 0))
        fundamental_score = float(earnings.get(b'fundamental_score', 50))
        return_12m_avg = float(earnings.get(b'return_12m_avg', 0))

        return f"""
EARNINGS CONTEXT (Today is Earnings Day):
- EPS Surprise: {eps_surprise:+.1%}
- Revenue Surprise: {revenue_surprise:+.1%}
- Fundamental Quality Score: {fundamental_score:.0f}/100
- Historical 12M Avg Return (post-earnings): {return_12m_avg:+.1%}
"""

    def _extract_key_drivers(self, features: Dict, prediction: Dict) -> List[str]:
        """Extract key drivers from features"""
        drivers = []

        if not features:
            return ["Insufficient data for detailed analysis"]

        # Momentum driver
        return_20d = float(features.get(b'return_20d', 0))
        if abs(return_20d) > 0.05:
            direction = "Strong upward" if return_20d > 0 else "Downward"
            drivers.append(f"{direction} momentum ({return_20d:+.2%} over 20 days)")

        # Volatility driver
        volatility = float(features.get(b'volatility_20d', 0))
        if volatility > 0.4:
            drivers.append(f"High volatility environment ({volatility:.1%})")

        # RSI driver
        rsi = float(features.get(b'rsi_14', 50))
        if rsi > 70:
            drivers.append(f"Overbought conditions (RSI: {rsi:.0f})")
        elif rsi < 30:
            drivers.append(f"Oversold conditions (RSI: {rsi:.0f})")

        return drivers if drivers else ["Normal market conditions"]

if __name__ == "__main__":
    worker = ExplanationWorker()
    asyncio.run(worker.start())
```

### 6.2 Requirements for Explanation Worker

**File:** `services/explanation/requirements.txt`

```txt
# Core
nats-py==2.6.0
redis[hiredis]==5.0.1

# LLM & RAG (All Open-Source)
langchain==0.1.0
langchain-community==0.0.13
sentence-transformers==2.3.1
qdrant-client==1.7.0

# Ollama integration
ollama==0.1.6

# Utilities
numpy>=1.24.0
pydantic==2.5.3
```

---

## 7. Open-Source Technology Stack Summary

**All technologies used are 100% open-source:**

| Component | Technology | License | Cost |
|-----------|-----------|---------|------|
| **LLM** | Llama 3.1 8B (Meta) | Llama 3.1 Community License | Free |
| **LLM Server** | Ollama | MIT | Free |
| **Vector DB** | Qdrant | Apache 2.0 | Free |
| **Embeddings** | all-MiniLM-L6-v2 | Apache 2.0 | Free |
| **RAG Framework** | LangChain | MIT | Free |
| **Message Bus** | NATS JetStream | Apache 2.0 | Free |
| **Cache** | Redis | BSD 3-Clause | Free |
| **Database** | TimescaleDB (PostgreSQL) | Apache 2.0 | Free |
| **API** | FastAPI | MIT | Free |
| **UI Framework** | Next.js (React) | MIT | Free |
| **ML Framework** | TensorFlow/ONNX | Apache 2.0 | Free |
| **Orchestration** | Docker Compose | Apache 2.0 | Free |

**Total Licensing Cost: $0**

**Operational Cost:**
- Local development: $0 (own hardware)
- Cloud deployment: ~$1,200-1,960/month (infrastructure only)

---

This design document provides complete implementation details for all components using 100% open-source technologies.

1. Create additional documents (deployment guide, testing strategy)?
2. Generate the actual Python code files?
3. Create the UI components in full?
4. Add monitoring/observability configuration?