# Milestone 5: Prediction Pipeline & Routing

**Duration:** Week 6-7 (8 working days)
**Team:** Backend + Data Science (2-3 developers)
**Dependencies:** M4 (ML models must be trained and ready)
**Status:** Not Started

---

## Objective

Build a production-grade prediction pipeline that routes symbols to the correct model (Normal Day vs Earnings Day), performs batch inference with GPU acceleration, and stores predictions in both Redis (fast layer) and TimescaleDB (durable layer). The system must process all 5,000 symbols within 10 seconds.

---

## Success Criteria

- ✅ Routing Agent correctly classifies symbols (normal vs earnings)
- ✅ Batch inference latency: <20ms per batch (128 symbols) on GPU
- ✅ Full pipeline update: <10 seconds for 5,000 symbols
- ✅ Predictions stored in Redis (<2ms read latency)
- ✅ Predictions persisted to TimescaleDB
- ✅ WebSocket notifications sent for updated predictions
- ✅ System handles 100% symbol coverage (no symbols skipped)

---

## Task List

### 1. Routing Agent Development
**Status:** Not Started

- [ ] **T1.1** - Set up Routing Agent project structure
  - [ ] Create `/services/routing_agent` directory
  - [ ] Create `pyproject.toml` with dependencies (nats-py, redis, asyncio)
  - [ ] Set up module structure (router, calendar_checker)
  - [ ] Create main entry point (`main.py`)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** M4 completion

- [ ] **T1.2** - Implement earnings calendar checker
  - [ ] Read `earnings_flag:{symbol}` from Redis
  - [ ] Fallback to TimescaleDB `earnings_calendar` table
  - [ ] Cache calendar data in memory (refresh every hour)
  - [ ] Handle missing calendar data (default to normal day)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.1

- [ ] **T1.3** - Implement routing logic
  - [ ] Create `route_symbol(symbol)` method
  - [ ] Return "normal" or "earnings" based on calendar
  - [ ] Log routing decisions
  - [ ] Handle edge cases (e.g., pre-market earnings)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.2

- [ ] **T1.4** - Implement batch routing
  - [ ] Subscribe to `data.features.ready` NATS topic
  - [ ] Collect symbols over 10-second window
  - [ ] Route symbols to normal vs earnings buckets
  - [ ] Publish to `job.predict.normal` and `job.predict.earnings` topics
  - [ ] Include correlation IDs for tracking
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.3

- [ ] **T1.5** - Implement routing metrics
  - [ ] Counter: symbols routed to normal pipeline
  - [ ] Counter: symbols routed to earnings pipeline
  - [ ] Histogram: routing latency
  - [ ] Gauge: pending symbols in routing queue
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.4

---

### 2. Normal Day Prediction Agent
**Status:** Not Started

- [ ] **T2.1** - Set up Normal Day Agent project structure
  - [ ] Create `/services/prediction_normal_agent` directory
  - [ ] Create `pyproject.toml` with dependencies (onnxruntime-gpu, redis, nats-py)
  - [ ] Set up module structure (model_loader, predictor, publisher)
  - [ ] Create main entry point (`main.py`)
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 2 hours
  - **Blocked by:** M4 completion

- [ ] **T2.2** - Implement model loader
  - [ ] Load ONNX model from `/models/normal_day/lstm_normal_v2.1.onnx`
  - [ ] Load scaler from `/models/normal_day/scaler.pkl`
  - [ ] Initialize ONNX Runtime session with GPU provider
  - [ ] Cache model in memory (load once on startup)
  - [ ] Validate model outputs on test input
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.1

- [ ] **T2.3** - Implement feature retrieval
  - [ ] Subscribe to `job.predict.normal` NATS topic
  - [ ] Extract symbols from job message
  - [ ] Fetch features from Redis (`features:{symbol}`)
  - [ ] Handle missing features (skip symbol, log warning)
  - [ ] Apply scaler to features (normalize)
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.2

- [ ] **T2.4** - Implement batch inference
  - [ ] Collect symbols into batches of 128
  - [ ] Convert features to NumPy array (shape: [batch_size, 20])
  - [ ] Run ONNX inference session
  - [ ] Extract predicted returns from output
  - [ ] Compute predicted price: current_price × (1 + predicted_return)
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.3

- [ ] **T2.5** - Implement uncertainty quantification (MC Dropout)
  - [ ] Run inference 20 times per batch (with dropout enabled)
  - [ ] Compute mean (prediction) and std (uncertainty σ)
  - [ ] Compute percentiles (p10, p50, p90)
  - [ ] Add uncertainty to prediction output
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T2.4

- [ ] **T2.6** - Implement prediction publishing
  - [ ] Publish to `event.prediction.updated` NATS topic
  - [ ] Include: symbol, predicted_return, predicted_price, uncertainty, timestamp
  - [ ] Add correlation ID from original job
  - [ ] Handle publish failures with retry
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.5

- [ ] **T2.7** - Implement GPU resource management
  - [ ] Monitor GPU memory usage
  - [ ] Implement batch size auto-tuning (reduce if OOM)
  - [ ] Handle GPU failures (fallback to CPU)
  - [ ] Log GPU utilization metrics
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.6

---

### 3. Earnings Day Prediction Agent
**Status:** Not Started

- [ ] **T3.1** - Set up Earnings Day Agent project structure
  - [ ] Create `/services/prediction_earnings_agent` directory
  - [ ] Reuse code structure from Normal Day Agent
  - [ ] Configure for 37 features instead of 20
  - [ ] Create main entry point (`main.py`)
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T2.1

- [ ] **T3.2** - Implement model loader for Earnings model
  - [ ] Load ONNX model from `/models/earnings_day/lstm_earnings_v2.1.onnx`
  - [ ] Load scaler for 37 features
  - [ ] Initialize ONNX Runtime session with GPU provider
  - [ ] Validate model outputs
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T3.1

- [ ] **T3.3** - Implement earnings feature retrieval
  - [ ] Subscribe to `job.predict.earnings` NATS topic
  - [ ] Fetch 20 technical features from Redis (`features:{symbol}`)
  - [ ] Fetch 17 earnings features from Redis (`earnings_analysis:{symbol}`)
  - [ ] Merge features into single array (37 features)
  - [ ] Handle missing earnings features (use zeros or skip symbol)
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.2

- [ ] **T3.4** - Implement batch inference for Earnings model
  - [ ] Batch size: 32 (smaller due to less frequent usage)
  - [ ] Run ONNX inference
  - [ ] Extract predictions
  - [ ] Apply MC Dropout for uncertainty (reuse from T2.5)
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T3.3

- [ ] **T3.5** - Implement earnings-specific output
  - [ ] Include earnings context in prediction output
  - [ ] Add `model_type: "earnings_day"` to metadata
  - [ ] Publish to `event.prediction.updated` NATS topic
  - **Assigned to:** Data Scientist 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T3.4

---

### 4. Prediction Storage Layer
**Status:** Not Started

- [ ] **T4.1** - Implement Redis storage for predictions
  - [ ] Subscribe to `event.prediction.updated` NATS topic
  - [ ] Store predictions as JSON in Redis (`pred:{symbol}`)
  - [ ] Set TTL: 120 seconds (2 minutes)
  - [ ] Use Redis pipeline for batch writes
  - [ ] Handle Redis failures gracefully
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.6, T3.5

- [ ] **T4.2** - Implement TimescaleDB persistence
  - [ ] Create `PredictionPersister` service
  - [ ] Subscribe to `event.prediction.updated` NATS topic
  - [ ] UPSERT predictions into `predictions` table (by symbol)
  - [ ] Use bulk insert for efficiency (batch every 10 seconds)
  - [ ] Handle database errors with retry
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T4.1

- [ ] **T4.3** - Implement dual-write consistency check
  - [ ] Periodic job to compare Redis vs TimescaleDB
  - [ ] Alert if >5% of symbols have mismatched predictions
  - [ ] Auto-repair: sync TimescaleDB → Redis if mismatch
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.2

---

### 5. WebSocket Notification System
**Status:** Not Started

- [ ] **T5.1** - Implement WebSocket broadcaster
  - [ ] Subscribe to `event.prediction.updated` NATS topic
  - [ ] Maintain list of WebSocket connections
  - [ ] Broadcast updates to subscribed clients
  - [ ] Handle connection lifecycle (connect, disconnect)
  - [ ] Implement subscription filtering (by symbol)
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 5 hours
  - **Blocked by:** T4.1
  - **Note:** Full WebSocket server in M7, this is backend only

- [ ] **T5.2** - Implement rate limiting for WebSocket
  - [ ] Limit updates per client (max 10/sec)
  - [ ] Buffer updates if rate exceeded
  - [ ] Drop old updates if buffer full
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T5.1

---

### 6. Error Handling & Resilience
**Status:** Not Started

- [ ] **T6.1** - Implement prediction error handling
  - [ ] Handle model inference failures
  - [ ] Handle feature retrieval failures (missing data)
  - [ ] Implement retry logic with exponential backoff
  - [ ] Dead letter queue for failed predictions
  - [ ] Log all errors with context (symbol, timestamp)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.6, T3.5

- [ ] **T6.2** - Implement graceful degradation
  - [ ] If GPU fails, fallback to CPU inference
  - [ ] If Redis fails, skip caching (use TimescaleDB only)
  - [ ] If NATS fails, buffer predictions in memory
  - [ ] Log degradation events
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T6.1

- [ ] **T6.3** - Implement circuit breaker
  - [ ] Circuit breaker for ONNX inference (after 10 failures)
  - [ ] Circuit breaker for Redis (after 5 failures)
  - [ ] Circuit breaker for TimescaleDB (after 5 failures)
  - [ ] Auto-reset after 30 seconds
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T6.2

---

### 7. Performance Optimization
**Status:** Not Started

- [ ] **T7.1** - Optimize batch processing
  - [ ] Tune batch size for GPU (test 32, 64, 128, 256)
  - [ ] Implement dynamic batching (accumulate for 100ms, then process)
  - [ ] Profile GPU utilization (target: >70%)
  - [ ] Reduce CPU-GPU transfer overhead
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T2.7

- [ ] **T7.2** - Optimize feature retrieval
  - [ ] Use Redis MGET for batch feature retrieval
  - [ ] Implement feature caching in prediction agents
  - [ ] Prefetch features for next batch
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.1

- [ ] **T7.3** - Optimize database writes
  - [ ] Use TimescaleDB COPY for bulk inserts
  - [ ] Increase batch size (target: 500 predictions/insert)
  - [ ] Use asynchronous writes (don't block pipeline)
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.2

---

### 8. Monitoring & Observability
**Status:** Not Started

- [ ] **T8.1** - Implement prediction pipeline metrics
  - [ ] Counter: predictions generated (by model type)
  - [ ] Histogram: inference latency (per batch)
  - [ ] Histogram: end-to-end pipeline latency
  - [ ] Gauge: symbols with fresh predictions (<2 min old)
  - [ ] Gauge: GPU utilization
  - [ ] Counter: prediction errors (by error type)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T6.3

- [ ] **T8.2** - Create Grafana dashboard for prediction pipeline
  - [ ] Panel: Predictions per second (line chart)
  - [ ] Panel: Inference latency p50/p95/p99 (line chart)
  - [ ] Panel: Pipeline latency (line chart)
  - [ ] Panel: Error rate (line chart)
  - [ ] Panel: GPU utilization (gauge)
  - [ ] Panel: Prediction freshness heatmap
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 4 hours
  - **Blocked by:** T8.1

- [ ] **T8.3** - Implement alerting
  - [ ] Alert: Inference latency >50ms (p95)
  - [ ] Alert: Error rate >1%
  - [ ] Alert: No predictions generated for 2 minutes
  - [ ] Alert: GPU utilization <30% (underutilized)
  - [ ] Alert: Prediction freshness >5 minutes
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T8.2

---

### 9. Testing
**Status:** Not Started

- [ ] **T9.1** - Write unit tests
  - [ ] Test routing logic (normal vs earnings)
  - [ ] Test model inference (mock ONNX model)
  - [ ] Test feature retrieval
  - [ ] Test prediction formatting
  - [ ] Target: >80% code coverage
  - **Assigned to:** Backend Dev 1, Data Scientist 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T6.3

- [ ] **T9.2** - Write integration tests
  - [ ] Test end-to-end flow (features → prediction → storage)
  - [ ] Test with real ONNX models (small batch)
  - [ ] Test NATS message flow
  - [ ] Test Redis and TimescaleDB storage
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T9.1

- [ ] **T9.3** - Load testing
  - [ ] Test with 5,000 symbols
  - [ ] Measure total pipeline latency (target: <10 seconds)
  - [ ] Measure peak memory usage
  - [ ] Measure GPU utilization
  - [ ] Identify bottlenecks
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T9.2

- [ ] **T9.4** - Stress testing
  - [ ] Test with GPU failure scenario
  - [ ] Test with Redis failure scenario
  - [ ] Test with NATS downtime
  - [ ] Verify graceful degradation
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T9.3

---

### 10. Configuration & Deployment
**Status:** Not Started

- [ ] **T10.1** - Create configuration management
  - [ ] Create `config.yaml` for each agent
  - [ ] Configure batch sizes, timeouts, retry policies
  - [ ] Support environment variable overrides
  - [ ] Document all configuration options
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.1

- [ ] **T10.2** - Create Docker images
  - [ ] Create Dockerfile for Routing Agent
  - [ ] Create Dockerfile for Normal Day Agent (with GPU support)
  - [ ] Create Dockerfile for Earnings Day Agent (with GPU support)
  - [ ] Create Dockerfile for Prediction Persister
  - [ ] Optimize image sizes
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 5 hours
  - **Blocked by:** T10.1

- [ ] **T10.3** - Add services to docker-compose
  - [ ] Add all 4 services to `docker-compose.yml`
  - [ ] Configure GPU passthrough for prediction agents
  - [ ] Set resource limits (memory, CPU)
  - [ ] Configure restart policies
  - [ ] Test full stack startup
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 3 hours
  - **Blocked by:** T10.2

---

### 11. Documentation
**Status:** Not Started

- [ ] **T11.1** - Document prediction pipeline architecture
  - [ ] Create data flow diagram
  - [ ] Document NATS topics and message flows
  - [ ] Document routing logic
  - [ ] Document error handling strategies
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T10.3

- [ ] **T11.2** - Create operational runbook
  - [ ] How to monitor pipeline health
  - [ ] How to handle GPU failures
  - [ ] How to adjust batch sizes
  - [ ] How to deploy new model versions
  - **Assigned to:** Data Scientist 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T11.1

- [ ] **T11.3** - Update API documentation
  - [ ] Document prediction output schema
  - [ ] Document NATS topics (job.predict.*, event.prediction.updated)
  - [ ] Add example messages
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T11.1

---

## Deliverables

1. ✅ **Routing Agent** - Classifying symbols correctly
2. ✅ **Normal Day Agent** - Generating predictions with GPU
3. ✅ **Earnings Day Agent** - Handling earnings-specific predictions
4. ✅ **Prediction Persister** - Storing in Redis and TimescaleDB
5. ✅ **WebSocket Broadcaster** - Publishing updates
6. ✅ **Monitoring Dashboard** - Pipeline metrics visible
7. ✅ **Test Suite** - Unit, integration, load tests passing
8. ✅ **Documentation** - Architecture, runbook, API docs

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Pipeline latency >10 seconds | Optimize batch sizes, add more GPU workers, parallelize processing |
| GPU memory overflow (OOM) | Implement dynamic batch sizing, monitor memory, reduce batch size |
| Inference errors on production data | Robust validation, handle edge cases, graceful fallback |
| Redis/DB write bottleneck | Use batching, async writes, increase connection pool |
| Inconsistent predictions (Redis vs DB) | Implement consistency checks, auto-repair mechanism |

---

## Acceptance Criteria

- [ ] Routing Agent correctly routes 100% of symbols
- [ ] Normal Day Agent processes 128 symbols in <20ms (GPU)
- [ ] Earnings Day Agent handles earnings symbols correctly
- [ ] Full pipeline updates 5,000 symbols in <10 seconds
- [ ] Predictions stored in Redis with <2ms read latency
- [ ] Predictions persisted to TimescaleDB within 10 seconds
- [ ] WebSocket notifications sent for all prediction updates
- [ ] Error rate <1% under normal load
- [ ] All tests passing (unit, integration, load)
- [ ] Monitoring dashboard shows real-time metrics
- [ ] Documentation complete and reviewed

---

## Definition of Done

- [ ] All tasks marked as "Done"
- [ ] Code reviewed and merged to `develop` branch
- [ ] Test coverage >80%
- [ ] Performance benchmarks met (<10 sec for 5,000 symbols)
- [ ] Load testing completed successfully
- [ ] Integration tests passing with real models and infrastructure
- [ ] Grafana dashboard created and tested
- [ ] Documentation complete
- [ ] Demo completed showing live predictions
- [ ] Tech Lead sign-off

---

**Milestone Owner:** Backend Dev 1
**Review Date:** End of Week 7
**Next Milestone:** M6 - LLM Explanation System (RAG)

[End of Milestone 5]
