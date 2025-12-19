"""Initial schema with TimescaleDB hypertables

Revision ID: 001
Revises:
Create Date: 2025-12-19 10:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Apply database changes"""

    # Create predictions table
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS predictions (
            id BIGSERIAL,
            ticker VARCHAR(10) NOT NULL,
            prediction_time TIMESTAMPTZ NOT NULL,
            predicted_price DECIMAL(12,4) NOT NULL,
            current_price DECIMAL(12,4) NOT NULL,
            change_percent DECIMAL(8,4) NOT NULL,
            confidence DECIMAL(4,3) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
            model_type VARCHAR(20) NOT NULL CHECK (model_type IN ('normal', 'earnings')),
            model_version VARCHAR(20) NOT NULL,
            features JSONB,
            metadata JSONB,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id, prediction_time)
        );
        """
    )

    # Convert to hypertable
    op.execute(
        """
        SELECT create_hypertable('predictions', 'prediction_time',
            chunk_time_interval => INTERVAL '1 day',
            if_not_exists => TRUE
        );
        """
    )

    # Create index on ticker for faster queries
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_predictions_ticker_time
        ON predictions (ticker, prediction_time DESC);
        """
    )

    # Enable compression
    op.execute(
        """
        ALTER TABLE predictions SET (
            timescaledb.compress,
            timescaledb.compress_segmentby = 'ticker, model_type',
            timescaledb.compress_orderby = 'prediction_time DESC'
        );
        """
    )

    # Add compression policy (compress data older than 7 days)
    op.execute(
        """
        SELECT add_compression_policy('predictions', INTERVAL '7 days',
            if_not_exists => TRUE
        );
        """
    )

    # Add retention policy (drop data older than 90 days)
    op.execute(
        """
        SELECT add_retention_policy('predictions', INTERVAL '90 days',
            if_not_exists => TRUE
        );
        """
    )

    # Create market_data table
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS market_data (
            id BIGSERIAL,
            ticker VARCHAR(10) NOT NULL,
            timestamp TIMESTAMPTZ NOT NULL,
            open DECIMAL(12,4) NOT NULL,
            high DECIMAL(12,4) NOT NULL,
            low DECIMAL(12,4) NOT NULL,
            close DECIMAL(12,4) NOT NULL,
            volume BIGINT NOT NULL,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id, timestamp)
        );
        """
    )

    # Convert market_data to hypertable
    op.execute(
        """
        SELECT create_hypertable('market_data', 'timestamp',
            chunk_time_interval => INTERVAL '1 day',
            if_not_exists => TRUE
        );
        """
    )

    # Create index for market_data
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_market_data_ticker_time
        ON market_data (ticker, timestamp DESC);
        """
    )

    # Enable compression for market_data
    op.execute(
        """
        ALTER TABLE market_data SET (
            timescaledb.compress,
            timescaledb.compress_segmentby = 'ticker',
            timescaledb.compress_orderby = 'timestamp DESC'
        );
        """
    )

    # Add compression policy for market_data
    op.execute(
        """
        SELECT add_compression_policy('market_data', INTERVAL '7 days',
            if_not_exists => TRUE
        );
        """
    )

    # Create earnings_calendar table
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS earnings_calendar (
            id SERIAL PRIMARY KEY,
            ticker VARCHAR(10) NOT NULL,
            earnings_date DATE NOT NULL,
            estimated_eps DECIMAL(8,4),
            actual_eps DECIMAL(8,4),
            surprise_percent DECIMAL(8,4),
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(ticker, earnings_date)
        );
        """
    )

    # Create index for earnings_calendar
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_earnings_calendar_ticker_date
        ON earnings_calendar (ticker, earnings_date DESC);
        """
    )

    # Create model_metadata table
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS model_metadata (
            id SERIAL PRIMARY KEY,
            model_name VARCHAR(50) NOT NULL,
            model_version VARCHAR(20) NOT NULL,
            model_type VARCHAR(20) NOT NULL CHECK (model_type IN ('normal', 'earnings')),
            accuracy DECIMAL(5,4),
            precision_score DECIMAL(5,4),
            recall DECIMAL(5,4),
            f1_score DECIMAL(5,4),
            training_date TIMESTAMPTZ,
            deployment_date TIMESTAMPTZ,
            is_active BOOLEAN DEFAULT TRUE,
            hyperparameters JSONB,
            metadata JSONB,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(model_name, model_version)
        );
        """
    )

    # Create index for active models
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_model_metadata_active
        ON model_metadata (model_type, is_active, deployment_date DESC);
        """
    )

    print("[OK] Initial schema created successfully")


def downgrade() -> None:
    """Revert database changes"""

    # Drop tables in reverse order
    op.execute("DROP TABLE IF EXISTS model_metadata CASCADE;")
    op.execute("DROP TABLE IF EXISTS earnings_calendar CASCADE;")
    op.execute("DROP TABLE IF EXISTS market_data CASCADE;")
    op.execute("DROP TABLE IF EXISTS predictions CASCADE;")

    print("[OK] Initial schema dropped successfully")
