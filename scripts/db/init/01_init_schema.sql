-- Feature 1: Real-Time Price Prediction System
-- TimescaleDB Initialization Script
-- This script runs automatically when the TimescaleDB container starts

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create predictions table (hypertable)
CREATE TABLE IF NOT EXISTS predictions (
    id BIGSERIAL,
    ticker VARCHAR(10) NOT NULL,
    prediction_time TIMESTAMPTZ NOT NULL,
    target_time TIMESTAMPTZ NOT NULL,
    predicted_price DECIMAL(15, 4) NOT NULL,
    confidence_score DECIMAL(5, 4) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    current_price DECIMAL(15, 4) NOT NULL,
    price_change_pct DECIMAL(8, 4),
    model_version VARCHAR(50) NOT NULL,
    agent_type VARCHAR(20) CHECK (agent_type IN ('normal', 'earnings')),
    features JSONB,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (prediction_time, ticker, id)
);

-- Convert to hypertable (partitioned by time)
SELECT create_hypertable('predictions', 'prediction_time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_predictions_ticker_time
    ON predictions (ticker, prediction_time DESC);

CREATE INDEX IF NOT EXISTS idx_predictions_target_time
    ON predictions (target_time);

CREATE INDEX IF NOT EXISTS idx_predictions_agent_type
    ON predictions (agent_type, prediction_time DESC);

CREATE INDEX IF NOT EXISTS idx_predictions_confidence
    ON predictions (confidence_score DESC, prediction_time DESC);

-- GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_predictions_metadata
    ON predictions USING GIN (metadata);

-- Create model_metrics table for tracking model performance
CREATE TABLE IF NOT EXISTS model_metrics (
    id BIGSERIAL,
    model_version VARCHAR(50) NOT NULL,
    agent_type VARCHAR(20) CHECK (agent_type IN ('normal', 'earnings')),
    metric_time TIMESTAMPTZ NOT NULL,
    ticker VARCHAR(10),
    mae DECIMAL(15, 4),
    rmse DECIMAL(15, 4),
    mape DECIMAL(8, 4),
    accuracy DECIMAL(5, 4),
    predictions_count INTEGER,
    avg_confidence DECIMAL(5, 4),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (metric_time, model_version, id)
);

-- Convert to hypertable
SELECT create_hypertable('model_metrics', 'metric_time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Create index for model performance queries
CREATE INDEX IF NOT EXISTS idx_model_metrics_version_time
    ON model_metrics (model_version, metric_time DESC);

CREATE INDEX IF NOT EXISTS idx_model_metrics_agent_type
    ON model_metrics (agent_type, metric_time DESC);

-- Create market_data table for storing raw market data
CREATE TABLE IF NOT EXISTS market_data (
    id BIGSERIAL,
    ticker VARCHAR(10) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    open DECIMAL(15, 4),
    high DECIMAL(15, 4),
    low DECIMAL(15, 4),
    close DECIMAL(15, 4) NOT NULL,
    volume BIGINT,
    source VARCHAR(50) NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (timestamp, ticker, id)
);

-- Convert to hypertable
SELECT create_hypertable('market_data', 'timestamp',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Create index for market data queries
CREATE INDEX IF NOT EXISTS idx_market_data_ticker_time
    ON market_data (ticker, timestamp DESC);

-- Create explanations table for LLM-generated explanations
CREATE TABLE IF NOT EXISTS explanations (
    id BIGSERIAL PRIMARY KEY,
    prediction_id BIGINT NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    explanation_text TEXT NOT NULL,
    llm_model VARCHAR(50) NOT NULL,
    generation_time TIMESTAMPTZ NOT NULL,
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    factors JSONB,
    sentiment_score DECIMAL(5, 4),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for explanation lookups
CREATE INDEX IF NOT EXISTS idx_explanations_prediction
    ON explanations (prediction_id);

CREATE INDEX IF NOT EXISTS idx_explanations_ticker_time
    ON explanations (ticker, generation_time DESC);

-- Create materialized view for latest predictions per ticker
CREATE MATERIALIZED VIEW IF NOT EXISTS latest_predictions AS
SELECT DISTINCT ON (ticker)
    ticker,
    prediction_time,
    target_time,
    predicted_price,
    confidence_score,
    current_price,
    price_change_pct,
    model_version,
    agent_type
FROM predictions
ORDER BY ticker, prediction_time DESC;

-- Create index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_latest_predictions_ticker
    ON latest_predictions (ticker);

-- Enable compression on hypertables
ALTER TABLE predictions SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'ticker'
);

ALTER TABLE model_metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'model_version'
);

ALTER TABLE market_data SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'ticker'
);

-- Set up compression policy (compress chunks older than 7 days)
SELECT add_compression_policy('predictions', INTERVAL '7 days', if_not_exists => TRUE);
SELECT add_compression_policy('model_metrics', INTERVAL '7 days', if_not_exists => TRUE);
SELECT add_compression_policy('market_data', INTERVAL '7 days', if_not_exists => TRUE);

-- Set up retention policy (drop chunks older than 90 days)
SELECT add_retention_policy('predictions', INTERVAL '90 days', if_not_exists => TRUE);
SELECT add_retention_policy('model_metrics', INTERVAL '90 days', if_not_exists => TRUE);
SELECT add_retention_policy('market_data', INTERVAL '90 days', if_not_exists => TRUE);

-- Create continuous aggregate for hourly prediction summaries
CREATE MATERIALIZED VIEW IF NOT EXISTS prediction_summary_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', prediction_time) AS bucket,
    ticker,
    agent_type,
    COUNT(*) as prediction_count,
    AVG(confidence_score) as avg_confidence,
    AVG(price_change_pct) as avg_price_change_pct,
    MIN(predicted_price) as min_predicted_price,
    MAX(predicted_price) as max_predicted_price
FROM predictions
GROUP BY bucket, ticker, agent_type;

-- Add refresh policy for continuous aggregate (refresh every hour)
SELECT add_continuous_aggregate_policy('prediction_summary_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour',
    if_not_exists => TRUE
);

-- Grant permissions (if needed for application user)
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO riskee_app;

-- Create function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_latest_predictions()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY latest_predictions;
END;
$$ LANGUAGE plpgsql;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'TimescaleDB schema initialized successfully';
    RAISE NOTICE 'Tables created: predictions, model_metrics, market_data, explanations';
    RAISE NOTICE 'Hypertables configured with compression and retention policies';
    RAISE NOTICE 'Materialized views created: latest_predictions, prediction_summary_hourly';
END $$;
