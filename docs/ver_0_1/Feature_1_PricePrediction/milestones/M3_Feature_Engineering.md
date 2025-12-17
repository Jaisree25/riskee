# Milestone 3: Feature Engineering System

**Duration:** Week 3-4 (8 working days)
**Team:** Data Science + Backend (2-3 developers)
**Dependencies:** M2 (Data ingestion must be working)
**Status:** Not Started

---

## Objective

Build a real-time feature engineering system that consumes market data from NATS, computes 20 technical indicators using vectorized operations, and stores them in Redis for fast access by prediction models. The system must handle 5,000 symbols with sub-second latency per symbol.

---

## Success Criteria

- ✅ Compute all 20 technical features for each symbol
- ✅ Feature computation latency: <50ms per symbol (vectorized)
- ✅ Features stored in Redis with proper TTL (300 seconds)
- ✅ Rolling window data maintained (252 trading days)
- ✅ Feature validation ensures no NaN/Inf values
- ✅ System processes all symbols within 10 seconds of data arrival
- ✅ Feature freshness <2 seconds from market data arrival

---

## Task List

### 1. Feature Store Core Development
**Status:** Not Started

- [ ] **T1.1** - Set up FeatureStore project structure
  - [ ] Create `/services/feature_store` directory
  - [ ] Create `pyproject.toml` with dependencies (numpy, pandas, ta-lib, nats-py, redis)
  - [ ] Set up module structure (calculator, storage, validators)
  - [ ] Create main entry point (`main.py`)
  - **Assigned to:** Data Scientist
  - **Estimated time:** 2 hours
  - **Blocked by:** M2 completion

- [ ] **T1.2** - Implement NATS subscriber for market data
  - [ ] Subscribe to `data.market.quote` subject
  - [ ] Parse incoming market data messages
  - [ ] Validate message schema
  - [ ] Handle message acknowledgment
  - [ ] Implement error handling for malformed messages
  - **Assigned to:** Backend Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.1

- [ ] **T1.3** - Design rolling window data structure
  - [ ] Implement `RollingWindow` class using deque (252 days capacity)
  - [ ] Store OHLCV data (Open, High, Low, Close, Volume)
  - [ ] Implement efficient append operation
  - [ ] Implement data retrieval for feature calculation
  - [ ] Handle initialization for new symbols (cold start)
  - **Assigned to:** Data Scientist
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.2

- [ ] **T1.4** - Implement historical data loader
  - [ ] Fetch last 252 days of data from Yahoo Finance on startup
  - [ ] Populate rolling window for all 5,000 symbols
  - [ ] Handle missing historical data (newly listed stocks)
  - [ ] Store in TimescaleDB for persistence
  - [ ] Load from TimescaleDB on restart
  - **Assigned to:** Data Scientist
  - **Estimated time:** 5 hours
  - **Blocked by:** T1.3

---

### 2. Technical Feature Calculation
**Status:** Not Started

- [ ] **T2.1** - Implement return features (6 features)
  - [ ] `return_1d` = (P_t / P_{t-1}) - 1
  - [ ] `return_5d` = (P_t / P_{t-5}) - 1
  - [ ] `return_20d` = (P_t / P_{t-20}) - 1
  - [ ] `return_60d` = (P_t / P_{t-60}) - 1
  - [ ] `return_120d` = (P_t / P_{t-120}) - 1
  - [ ] `return_252d` = (P_t / P_{t-252}) - 1
  - [ ] Vectorize using NumPy for speed
  - **Assigned to:** Data Scientist
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.4

- [ ] **T2.2** - Implement volatility features (3 features)
  - [ ] `volatility_5d` = std(returns_5d) × √252
  - [ ] `volatility_20d` = std(returns_20d) × √252
  - [ ] `volatility_60d` = std(returns_60d) × √252
  - [ ] Use NumPy rolling std for efficiency
  - **Assigned to:** Data Scientist
  - **Estimated time:** 2 hours
  - **Blocked by:** T2.1

- [ ] **T2.3** - Implement volume features (3 features)
  - [ ] `volume_ratio_5d` = vol_t / mean(vol_{t-5..t})
  - [ ] `volume_ratio_20d` = vol_t / mean(vol_{t-20..t})
  - [ ] `dollar_volume` = price × volume
  - [ ] Handle zero volume edge cases
  - **Assigned to:** Data Scientist
  - **Estimated time:** 2 hours
  - **Blocked by:** T2.1

- [ ] **T2.4** - Implement market-relative features (3 features)
  - [ ] Fetch S&P 500 (^GSPC) data as market proxy
  - [ ] `market_beta` = Cov(R_stock, R_market) / Var(R_market)
  - [ ] `market_return` = Return of S&P 500 index
  - [ ] `market_volatility` = std(S&P 500 returns) × √252
  - [ ] Cache market data (shared across all symbols)
  - **Assigned to:** Data Scientist
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.1

- [ ] **T2.5** - Implement technical indicators (5 features)
  - [ ] `rsi_14` = RSI formula (14-day) using ta-lib or custom
  - [ ] `macd` = EMA(12) - EMA(26)
  - [ ] `sma_50_200_cross` = 1 if SMA50 > SMA200 else 0
  - [ ] `bollinger_position` = (P - BB_lower) / (BB_upper - BB_lower)
  - [ ] `atr` = Average True Range (14-day)
  - [ ] Use ta-lib library for standard indicators
  - **Assigned to:** Data Scientist
  - **Estimated time:** 5 hours
  - **Blocked by:** T2.1

---

### 3. Feature Validation & Quality
**Status:** Not Started

- [ ] **T3.1** - Implement feature validators
  - [ ] Check for NaN values (replace with 0 or median)
  - [ ] Check for Inf values (cap at reasonable bounds)
  - [ ] Check for outliers (>5 sigma from mean) and clip
  - [ ] Validate all features are within expected ranges
  - [ ] Log validation failures
  - **Assigned to:** Data Scientist
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.5

- [ ] **T3.2** - Implement feature normalization
  - [ ] Apply z-score normalization where needed
  - [ ] Document normalization parameters
  - [ ] Handle edge cases (e.g., zero std dev)
  - [ ] Store normalization stats for inference
  - **Assigned to:** Data Scientist
  - **Estimated time:** 3 hours
  - **Blocked by:** T3.1

- [ ] **T3.3** - Create feature quality metrics
  - [ ] Track percentage of features with NaN
  - [ ] Track percentage of features with outliers
  - [ ] Track feature computation failures
  - [ ] Create Grafana dashboard panel
  - **Assigned to:** Data Scientist
  - **Estimated time:** 2 hours
  - **Blocked by:** T3.2

---

### 4. Redis Storage Layer
**Status:** Not Started

- [ ] **T4.1** - Implement Redis storage for features
  - [ ] Store features as Redis Hash: `features:{symbol}`
  - [ ] Set TTL: 300 seconds (5 minutes)
  - [ ] Use pipeline for batch writes (efficiency)
  - [ ] Handle Redis connection failures
  - **Assigned to:** Backend Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.5

- [ ] **T4.2** - Implement feature retrieval API
  - [ ] Create `get_features(symbol)` method
  - [ ] Return features as dictionary
  - [ ] Handle missing features (symbol not found)
  - [ ] Add caching layer (in-memory LRU cache)
  - **Assigned to:** Backend Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T4.1

- [ ] **T4.3** - Implement batch feature retrieval
  - [ ] Create `get_features_batch(symbols)` method
  - [ ] Use Redis MGET for efficiency
  - [ ] Return dict of symbol -> features
  - [ ] Handle partial failures
  - **Assigned to:** Backend Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T4.2

---

### 5. Historical Data Persistence
**Status:** Not Started

- [ ] **T5.1** - Design TimescaleDB schema for historical features
  - [ ] Create `feature_history` hypertable
  - [ ] Columns: symbol, timestamp, all 20 features
  - [ ] Create indexes (symbol, timestamp)
  - [ ] Set compression policy (7 days)
  - [ ] Set retention policy (90 days)
  - **Assigned to:** Backend Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T2.5

- [ ] **T5.2** - Implement feature persistence
  - [ ] Write features to TimescaleDB every 60 seconds
  - [ ] Use bulk insert for efficiency
  - [ ] Handle write failures gracefully
  - [ ] Don't block real-time processing
  - **Assigned to:** Backend Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T5.1

- [ ] **T5.3** - Implement feature backfill utility
  - [ ] Create script to recompute historical features
  - [ ] Process date range in batches
  - [ ] Store results in TimescaleDB
  - [ ] Used for model training data generation
  - **Assigned to:** Data Scientist
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.2

---

### 6. Performance Optimization
**Status:** Not Started

- [ ] **T6.1** - Vectorize feature calculations
  - [ ] Replace loops with NumPy array operations
  - [ ] Use pandas rolling windows
  - [ ] Pre-compute shared calculations (market data)
  - [ ] Profile and identify bottlenecks
  - **Assigned to:** Data Scientist
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.2

- [ ] **T6.2** - Implement parallel processing
  - [ ] Use multiprocessing for CPU-bound tasks
  - [ ] Process symbols in batches (100-500 per worker)
  - [ ] Configure worker pool size (CPU cores × 2)
  - [ ] Handle worker failures
  - **Assigned to:** Backend Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T6.1

- [ ] **T6.3** - Optimize memory usage
  - [ ] Use NumPy data types efficiently (float32 vs float64)
  - [ ] Implement rolling window size limits
  - [ ] Clear old data from memory
  - [ ] Monitor memory usage
  - **Assigned to:** Data Scientist
  - **Estimated time:** 3 hours
  - **Blocked by:** T6.2

---

### 7. Event Publishing
**Status:** Not Started

- [ ] **T7.1** - Publish features ready event
  - [ ] Publish to `data.features.ready` topic
  - [ ] Include symbol, timestamp, feature count
  - [ ] Use for triggering prediction pipeline
  - [ ] Handle publish failures
  - **Assigned to:** Backend Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T4.1

- [ ] **T7.2** - Implement feature change detection
  - [ ] Compare new features with previous values
  - [ ] Only publish if significant change (>1% delta)
  - [ ] Reduce downstream processing load
  - [ ] Log change statistics
  - **Assigned to:** Backend Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.1

---

### 8. Monitoring & Observability
**Status:** Not Started

- [ ] **T8.1** - Implement feature computation metrics
  - [ ] Histogram: feature computation latency per symbol
  - [ ] Counter: features computed successfully
  - [ ] Counter: feature computation failures
  - [ ] Gauge: rolling window size per symbol
  - [ ] Gauge: features freshness (time since last update)
  - **Assigned to:** Backend Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T6.3

- [ ] **T8.2** - Create Grafana dashboard for features
  - [ ] Panel: Feature computation latency (p50/p95/p99)
  - [ ] Panel: Features computed per second
  - [ ] Panel: Feature quality (% valid features)
  - [ ] Panel: Memory usage
  - [ ] Panel: Top 10 slowest symbols
  - **Assigned to:** Data Scientist
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.1

- [ ] **T8.3** - Implement alerting
  - [ ] Alert: Feature computation latency >100ms
  - [ ] Alert: Feature failure rate >1%
  - [ ] Alert: Memory usage >80%
  - [ ] Alert: Feature staleness >5 minutes
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T8.2

---

### 9. Testing
**Status:** Not Started

- [ ] **T9.1** - Write unit tests for feature calculators
  - [ ] Test each feature calculation with known inputs/outputs
  - [ ] Test edge cases (zero, negative, missing data)
  - [ ] Test vectorized vs loop implementation (same results)
  - [ ] Target: >90% code coverage
  - **Assigned to:** Data Scientist
  - **Estimated time:** 6 hours
  - **Blocked by:** T3.2

- [ ] **T9.2** - Write integration tests
  - [ ] Test end-to-end flow (NATS → features → Redis)
  - [ ] Test with real market data sample
  - [ ] Test rolling window updates
  - [ ] Test feature persistence to TimescaleDB
  - **Assigned to:** Backend Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T9.1

- [ ] **T9.3** - Performance testing
  - [ ] Test feature computation for 5,000 symbols
  - [ ] Measure latency per symbol (target: <50ms)
  - [ ] Measure total throughput (target: >100 symbols/sec)
  - [ ] Measure memory usage (target: <4GB)
  - [ ] Document bottlenecks
  - **Assigned to:** Data Scientist
  - **Estimated time:** 3 hours
  - **Blocked by:** T9.2

- [ ] **T9.4** - Validate feature quality
  - [ ] Compare computed features with reference implementation
  - [ ] Verify no NaN/Inf in production data
  - [ ] Validate against known stock examples (e.g., AAPL, NVDA)
  - [ ] Document feature distributions
  - **Assigned to:** Data Scientist
  - **Estimated time:** 4 hours
  - **Blocked by:** T9.3

---

### 10. Configuration & Deployment
**Status:** Not Started

- [ ] **T10.1** - Create configuration management
  - [ ] Create `config.yaml` for feature settings
  - [ ] Configure rolling window size (default: 252)
  - [ ] Configure feature calculation intervals
  - [ ] Document all configuration options
  - **Assigned to:** Backend Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.1

- [ ] **T10.2** - Create Docker image for FeatureStore
  - [ ] Create `Dockerfile` with Python 3.11 + NumPy
  - [ ] Install ta-lib library
  - [ ] Optimize image size
  - [ ] Add health check endpoint
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 3 hours
  - **Blocked by:** T10.1

- [ ] **T10.3** - Add FeatureStore to docker-compose
  - [ ] Add service definition to `docker-compose.yml`
  - [ ] Configure environment variables
  - [ ] Set resource limits (CPU: 4 cores, Memory: 8GB)
  - [ ] Configure restart policy
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T10.2

---

### 11. Documentation
**Status:** Not Started

- [ ] **T11.1** - Document feature engineering methodology
  - [ ] Document all 20 features (formulas, rationale)
  - [ ] Document normalization procedures
  - [ ] Document data quality checks
  - [ ] Create feature catalog with examples
  - **Assigned to:** Data Scientist
  - **Estimated time:** 4 hours
  - **Blocked by:** T9.4

- [ ] **T11.2** - Create operational runbook
  - [ ] How to add new features
  - [ ] How to backfill historical features
  - [ ] How to monitor feature quality
  - [ ] How to troubleshoot computation failures
  - **Assigned to:** Data Scientist
  - **Estimated time:** 3 hours
  - **Blocked by:** T11.1

- [ ] **T11.3** - Update API documentation
  - [ ] Document Redis feature schema
  - [ ] Document `data.features.ready` event
  - [ ] Add example feature retrieval code
  - **Assigned to:** Backend Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T11.1

---

## Deliverables

1. ✅ **FeatureStore service** - Computing features in real-time
2. ✅ **20 technical features** - All implemented and validated
3. ✅ **Redis storage** - Features accessible at <2ms latency
4. ✅ **Historical persistence** - Features stored in TimescaleDB
5. ✅ **Monitoring dashboard** - Feature quality metrics visible
6. ✅ **Test suite** - Unit and integration tests passing
7. ✅ **Documentation** - Feature catalog and runbook

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Feature calculation too slow (>50ms) | Vectorize with NumPy, use parallel processing, optimize algorithms |
| Memory usage too high (>8GB) | Use float32, limit rolling window size, implement garbage collection |
| Historical data missing for new symbols | Handle gracefully, use shorter windows, mark features as incomplete |
| ta-lib installation issues | Provide Docker image with pre-built ta-lib, document manual install |
| Feature quality issues (NaN/Inf) | Implement robust validation, use safe math operations, handle edge cases |

---

## Acceptance Criteria

- [ ] All 20 technical features computed correctly for 5,000 symbols
- [ ] Feature computation latency <50ms per symbol (p95)
- [ ] Features stored in Redis with correct TTL and schema
- [ ] No NaN or Inf values in production features
- [ ] System processes all symbols within 10 seconds of data arrival
- [ ] Memory usage <4GB under normal load
- [ ] All tests passing (unit, integration, performance)
- [ ] Monitoring dashboard shows feature quality metrics
- [ ] Documentation complete and reviewed

---

## Definition of Done

- [ ] All tasks marked as "Done"
- [ ] Code reviewed and merged to `develop` branch
- [ ] Test coverage >90%
- [ ] Performance benchmarks met (<50ms per symbol)
- [ ] Integration tests passing with real NATS and Redis
- [ ] Feature quality validated with real market data
- [ ] Grafana dashboard created and tested
- [ ] Documentation complete
- [ ] Demo completed showing live feature computation
- [ ] Tech Lead sign-off

---

**Milestone Owner:** Data Scientist
**Review Date:** End of Week 4
**Next Milestone:** M4 - ML Model Development & Training

[End of Milestone 3]
