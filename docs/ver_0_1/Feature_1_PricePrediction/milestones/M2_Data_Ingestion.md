# Milestone 2: Data Ingestion Pipeline

**Duration:** Week 2-3 (8 working days)
**Team:** Backend + Data Engineering (2 developers)
**Dependencies:** M1 (Infrastructure must be running)
**Status:** Not Started

---

## Objective

Build a robust data ingestion pipeline that fetches real-time market data from Yahoo Finance for 5,000 symbols, validates the data, and publishes it to NATS for downstream processing. The system should handle API rate limits, retries, and error scenarios gracefully.

---

## Success Criteria

- ✅ Successfully fetch market data for 5,000 symbols
- ✅ Data published to NATS `data.market.quote` topic
- ✅ Handle Yahoo Finance API rate limits (no crashes)
- ✅ Data validation and quality checks in place
- ✅ Latency: Full cycle (all 5,000 symbols) < 60 seconds
- ✅ Error rate: < 0.5% (due to transient failures)
- ✅ Earnings calendar data ingested and stored

---

## Task List

### 1. IngestionAgent Core Development
**Status:** Not Started

- [ ] **T1.1** - Set up IngestionAgent project structure
  - [ ] Create `/services/ingestion_agent` directory
  - [ ] Create `pyproject.toml` with dependencies (yfinance, nats-py, pydantic)
  - [ ] Set up module structure (config, fetcher, validator, publisher)
  - [ ] Create main entry point (`main.py`)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** M1 completion

- [ ] **T1.2** - Implement symbol configuration management
  - [ ] Create `symbols.json` file with 5,000 stock symbols
  - [ ] Implement symbol loader from JSON/CSV
  - [ ] Add symbol validation (check format, duplicates)
  - [ ] Support symbol groups (batches for parallel processing)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.1

- [ ] **T1.3** - Implement Yahoo Finance data fetcher
  - [ ] Create `YahooFinanceFetcher` class
  - [ ] Implement single symbol fetch method
  - [ ] Implement batch fetch method (10-50 symbols at a time)
  - [ ] Add retry logic with exponential backoff
  - [ ] Handle rate limiting (429 errors)
  - [ ] Parse response and extract: price, volume, change_percent, timestamp
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T1.2

- [ ] **T1.4** - Implement data validation layer
  - [ ] Create Pydantic models for market data
  - [ ] Validate price is positive and reasonable (>$0.01, <$100,000)
  - [ ] Validate volume is non-negative
  - [ ] Validate timestamp is recent (<5 minutes old)
  - [ ] Handle missing/null fields
  - [ ] Log validation failures
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.3

- [ ] **T1.5** - Implement NATS publisher
  - [ ] Create `NATSPublisher` class
  - [ ] Connect to NATS JetStream
  - [ ] Publish to `data.market.quote` subject
  - [ ] Add message correlation IDs (UUID)
  - [ ] Handle publish failures with retry
  - [ ] Implement batch publishing for efficiency
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.4

---

### 2. Scheduling & Orchestration
**Status:** Not Started

- [ ] **T2.1** - Implement polling scheduler
  - [ ] Create scheduler that runs every 10 seconds
  - [ ] Distribute 5,000 symbols across 10-second interval (500 symbols/sec)
  - [ ] Use asyncio for concurrent fetching
  - [ ] Handle scheduler errors gracefully
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.5

- [ ] **T2.2** - Implement worker pool for parallel fetching
  - [ ] Create worker pool (10-20 workers)
  - [ ] Distribute symbols across workers
  - [ ] Track worker status (active, idle, failed)
  - [ ] Implement worker health checks
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.1

- [ ] **T2.3** - Implement dynamic rate limiting
  - [ ] Monitor API response times
  - [ ] Detect rate limit errors (429)
  - [ ] Dynamically adjust request rate
  - [ ] Log rate limit events
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.2

---

### 3. Earnings Calendar Integration
**Status:** Not Started

- [ ] **T3.1** - Research earnings calendar data sources
  - [ ] Evaluate Yahoo Finance earnings calendar API
  - [ ] Evaluate alternative sources (Alpha Vantage, FMP)
  - [ ] Document API limits and costs
  - [ ] Select primary source
  - **Assigned to:** Data Engineer
  - **Estimated time:** 3 hours
  - **Blocked by:** None

- [ ] **T3.2** - Implement earnings calendar fetcher
  - [ ] Create `EarningsCalendarFetcher` class
  - [ ] Fetch upcoming earnings dates (next 7 days)
  - [ ] Parse and validate earnings data
  - [ ] Store in TimescaleDB `earnings_calendar` table
  - **Assigned to:** Data Engineer
  - **Estimated time:** 5 hours
  - **Blocked by:** T3.1

- [ ] **T3.3** - Create earnings flag synchronization
  - [ ] Read earnings calendar from TimescaleDB
  - [ ] Set Redis keys: `earnings_flag:{symbol}` with TTL=24h
  - [ ] Run daily at market open (9:30 AM ET)
  - [ ] Publish to `data.earnings.reported` topic
  - **Assigned to:** Data Engineer
  - **Estimated time:** 3 hours
  - **Blocked by:** T3.2

- [ ] **T3.4** - Implement earnings analysis agent (basic version)
  - [ ] Fetch basic fundamentals from Yahoo Finance
  - [ ] Extract: EPS, revenue, margins
  - [ ] Store in `earnings_analysis:{symbol}` Redis hash
  - [ ] Note: Full analysis with transcripts deferred to M6
  - **Assigned to:** Data Engineer
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.3

---

### 4. Error Handling & Resilience
**Status:** Not Started

- [ ] **T4.1** - Implement error handling framework
  - [ ] Create custom exception classes (FetchError, ValidationError, PublishError)
  - [ ] Implement error logging with context
  - [ ] Create error metrics (counters per error type)
  - [ ] Implement circuit breaker for Yahoo Finance API
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.5

- [ ] **T4.2** - Implement retry mechanisms
  - [ ] Exponential backoff for transient failures (network, 5xx errors)
  - [ ] Max retry attempts: 3
  - [ ] Dead letter queue for failed messages
  - [ ] Alert on high failure rate (>5%)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.1

- [ ] **T4.3** - Implement data quality monitoring
  - [ ] Track missing data (symbols that failed to fetch)
  - [ ] Track stale data (symbols not updated in >5 minutes)
  - [ ] Create dashboard widget for data freshness
  - [ ] Alert on >10% missing data
  - **Assigned to:** Data Engineer
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.2

---

### 5. Storage & Persistence
**Status:** Not Started

- [ ] **T5.1** - Implement market data storage in TimescaleDB
  - [ ] Create `market_data` table (if not exists from M1)
  - [ ] Store raw market data for auditing
  - [ ] Implement bulk insert for efficiency
  - [ ] Set retention policy (7 days for raw data)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.5

- [ ] **T5.2** - Implement caching layer
  - [ ] Cache latest market data in Redis (`market:{symbol}`)
  - [ ] Set TTL: 60 seconds
  - [ ] Use for quick lookups without DB query
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T5.1

---

### 6. Monitoring & Observability
**Status:** Not Started

- [ ] **T6.1** - Implement ingestion metrics
  - [ ] Counter: total symbols fetched
  - [ ] Counter: fetch failures (by error type)
  - [ ] Histogram: fetch latency per symbol
  - [ ] Gauge: symbols processed per second
  - [ ] Gauge: API rate limit headroom
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.3

- [ ] **T6.2** - Create Grafana dashboard for ingestion
  - [ ] Panel: Symbols ingested per minute (line chart)
  - [ ] Panel: Error rate (line chart)
  - [ ] Panel: Fetch latency p50/p95/p99 (line chart)
  - [ ] Panel: Data freshness heatmap (by symbol)
  - [ ] Panel: Top 10 failing symbols (table)
  - **Assigned to:** Data Engineer
  - **Estimated time:** 3 hours
  - **Blocked by:** T6.1

- [ ] **T6.3** - Implement alerting
  - [ ] Alert: Error rate > 5% for 5 minutes
  - [ ] Alert: No data ingested for 2 minutes
  - [ ] Alert: API rate limit reached
  - [ ] Configure notification channels (Slack, email)
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T6.2

---

### 7. Configuration & Deployment
**Status:** Not Started

- [ ] **T7.1** - Create configuration management
  - [ ] Create `config.yaml` for ingestion settings
  - [ ] Support environment variables override
  - [ ] Document all configuration options
  - [ ] Validate configuration on startup
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.1

- [ ] **T7.2** - Create Docker image for IngestionAgent
  - [ ] Create `Dockerfile` with Python 3.11
  - [ ] Optimize image size (multi-stage build)
  - [ ] Add health check endpoint
  - [ ] Test image locally
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.1

- [ ] **T7.3** - Add IngestionAgent to docker-compose
  - [ ] Add service definition to `docker-compose.yml`
  - [ ] Configure environment variables
  - [ ] Set restart policy (always)
  - [ ] Configure resource limits (CPU, memory)
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T7.2

---

### 8. Testing
**Status:** Not Started

- [ ] **T8.1** - Write unit tests
  - [ ] Test symbol loader
  - [ ] Test data fetcher (mock Yahoo Finance responses)
  - [ ] Test data validator (valid and invalid cases)
  - [ ] Test NATS publisher (mock NATS)
  - [ ] Target: >80% code coverage
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T1.5

- [ ] **T8.2** - Write integration tests
  - [ ] Test end-to-end flow (fetch → validate → publish)
  - [ ] Test with real Yahoo Finance API (small sample)
  - [ ] Test error handling (network failures, invalid data)
  - [ ] Test NATS message format
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T8.1

- [ ] **T8.3** - Performance testing
  - [ ] Test ingestion of 5,000 symbols
  - [ ] Measure total time (target: <60 seconds)
  - [ ] Measure memory usage (target: <2GB)
  - [ ] Measure CPU usage (target: <50% avg)
  - [ ] Document bottlenecks
  - **Assigned to:** Data Engineer
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.2

- [ ] **T8.4** - Stress testing
  - [ ] Test with Yahoo Finance API rate limits
  - [ ] Test recovery from NATS downtime
  - [ ] Test recovery from network failures
  - [ ] Verify circuit breaker works
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.3

---

### 9. Documentation
**Status:** Not Started

- [ ] **T9.1** - Write technical documentation
  - [ ] Document IngestionAgent architecture
  - [ ] Document data flow diagram
  - [ ] Document NATS message schema
  - [ ] Document error handling strategy
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.3

- [ ] **T9.2** - Create operational runbook
  - [ ] How to add/remove symbols
  - [ ] How to handle API rate limit issues
  - [ ] How to restart ingestion
  - [ ] How to monitor data freshness
  - **Assigned to:** Data Engineer
  - **Estimated time:** 2 hours
  - **Blocked by:** T9.1

- [ ] **T9.3** - Update API documentation
  - [ ] Document NATS topics and message formats
  - [ ] Add example messages
  - [ ] Document error codes
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T9.1

---

## Deliverables

1. ✅ **IngestionAgent service** - Running and fetching data
2. ✅ **Earnings calendar integration** - Daily sync working
3. ✅ **NATS messages** - Published to `data.market.quote`
4. ✅ **Monitoring dashboard** - Ingestion metrics visible
5. ✅ **Test suite** - Unit and integration tests passing
6. ✅ **Documentation** - Technical docs and runbook

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Yahoo Finance API rate limits too strict | Use multiple API keys, add caching, consider paid tier |
| API changes/deprecation | Monitor for errors, have backup data source ready |
| Slow ingestion (>60 sec for 5,000 symbols) | Optimize batch sizes, increase workers, use caching |
| Network failures during market hours | Implement robust retry with exponential backoff |
| Incomplete earnings calendar data | Supplement with multiple sources, manual override |

---

## Acceptance Criteria

- [ ] IngestionAgent successfully fetches data for 5,000 symbols in <60 seconds
- [ ] All fetched data published to NATS without loss
- [ ] Data validation catches and logs invalid data
- [ ] Error rate <0.5% over 1-hour period
- [ ] Earnings calendar updated daily with next 7 days of events
- [ ] Monitoring dashboard shows real-time ingestion metrics
- [ ] All tests passing (unit, integration, performance)
- [ ] Documentation complete and reviewed

---

## Definition of Done

- [ ] All tasks marked as "Done"
- [ ] Code reviewed and merged to `develop` branch
- [ ] Test coverage >80%
- [ ] Performance benchmarks met
- [ ] Integration tests passing with real NATS
- [ ] Grafana dashboard created and tested
- [ ] Documentation complete
- [ ] Demo completed showing live data ingestion
- [ ] Tech Lead sign-off

---

**Milestone Owner:** Backend Dev 1
**Review Date:** End of Week 3
**Next Milestone:** M3 - Feature Engineering System

[End of Milestone 2]
