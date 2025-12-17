# Milestone 7: API & WebSocket Gateway

**Duration:** Week 9-10 (8 working days)
**Team:** Backend + Full Stack (2-3 developers)
**Dependencies:** M5 (Prediction pipeline), M6 (Explanation system)
**Status:** Not Started

---

## Objective

Build a production-grade FastAPI gateway that exposes RESTful endpoints for predictions and explanations, implements WebSocket for real-time updates, handles authentication, rate limiting, and provides comprehensive API documentation. The API must serve requests with <100ms latency (p95).

---

## Success Criteria

- ✅ API serves predictions with p95 latency <100ms
- ✅ WebSocket handles 10,000+ concurrent connections
- ✅ Authentication and authorization working
- ✅ Rate limiting prevents abuse
- ✅ API documentation (Swagger/OpenAPI) complete
- ✅ CORS configured for frontend
- ✅ Health check endpoints operational
- ✅ Error handling with proper HTTP status codes

---

## Task List

### 1. FastAPI Project Setup
**Status:** Not Started

- [ ] **T1.1** - Set up FastAPI project structure
  - [ ] Create `/services/api_gateway` directory
  - [ ] Create `pyproject.toml` with dependencies (fastapi, uvicorn, redis, asyncpg)
  - [ ] Set up module structure (routers, models, dependencies, middleware)
  - [ ] Create main entry point (`main.py`)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** M5, M6 completion

- [ ] **T1.2** - Configure FastAPI application
  - [ ] Create FastAPI app with metadata (title, version, description)
  - [ ] Configure CORS middleware
  - [ ] Configure request/response compression (gzip)
  - [ ] Configure trusted proxies (if behind load balancer)
  - [ ] Set up exception handlers
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.1

- [ ] **T1.3** - Set up database connection pools
  - [ ] Create asyncpg connection pool for TimescaleDB
  - [ ] Create redis-py async connection pool for Redis
  - [ ] Configure connection limits (max 100 connections)
  - [ ] Implement connection health checks
  - [ ] Add to app lifespan (startup/shutdown)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.2

---

### 2. Prediction Endpoints
**Status:** Not Started

- [ ] **T2.1** - Implement GET /api/prediction/{symbol}
  - [ ] Create Pydantic response model (`PredictionResponse`)
  - [ ] Try Redis first (`pred:{symbol}`)
  - [ ] Fallback to TimescaleDB if cache miss
  - [ ] Return 404 if symbol not found
  - [ ] Include data freshness in response
  - [ ] Add optional `include_features` query parameter
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.3

- [ ] **T2.2** - Implement GET /api/predictions (batch)
  - [ ] Accept `symbols` query parameter (comma-separated)
  - [ ] Limit to 100 symbols per request
  - [ ] Use Redis MGET for batch retrieval
  - [ ] Return dict of symbol → prediction
  - [ ] Include partial results if some symbols missing
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.1

- [ ] **T2.3** - Implement caching headers
  - [ ] Add Cache-Control header (max-age=60)
  - [ ] Add ETag based on prediction timestamp
  - [ ] Support If-None-Match for 304 Not Modified
  - [ ] Reduce bandwidth for unchanged predictions
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T2.2

---

### 3. Explanation Endpoints
**Status:** Not Started

- [ ] **T3.1** - Implement POST /api/explanation/{symbol}
  - [ ] Create Pydantic request model (`ExplanationRequest`)
  - [ ] Accept `depth` parameter (fast, medium, deep)
  - [ ] Publish job to `job.explain.generate` NATS topic
  - [ ] Generate job_id (UUID)
  - [ ] Return 202 Accepted with job_id and estimated time
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.3

- [ ] **T3.2** - Implement GET /api/explanation/{symbol}
  - [ ] Check Redis cache (`explanation:{symbol}`)
  - [ ] If found, return 200 OK with explanation
  - [ ] If not found, return 404 Not Found
  - [ ] Include generated_at timestamp
  - [ ] Include sources/citations
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T3.1

- [ ] **T3.3** - Implement GET /api/explanation/job/{job_id}
  - [ ] Query job status from NATS or Redis
  - [ ] Return 200 OK if completed (with explanation)
  - [ ] Return 202 Accepted if still processing (with progress)
  - [ ] Return 404 if job not found
  - [ ] Return 500 if job failed
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T3.2

---

### 4. WebSocket Implementation
**Status:** Not Started

- [ ] **T4.1** - Implement WebSocket connection endpoint
  - [ ] Create WebSocket route: `/ws/predictions`
  - [ ] Accept JWT token in query param or header
  - [ ] Validate token and authenticate user
  - [ ] Add connection to connection manager
  - [ ] Send welcome message with connection ID
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.2

- [ ] **T4.2** - Implement subscription management
  - [ ] Accept subscription message: `{"action": "subscribe", "symbols": [...]}`
  - [ ] Store subscriptions per connection
  - [ ] Accept unsubscribe message: `{"action": "unsubscribe", "symbols": [...]}`
  - [ ] Validate symbol format
  - [ ] Limit subscriptions per connection (max 100 symbols)
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T4.1

- [ ] **T4.3** - Implement prediction broadcast
  - [ ] Subscribe to `event.prediction.updated` NATS topic
  - [ ] For each update, find connections subscribed to that symbol
  - [ ] Send update to all subscribed connections
  - [ ] Format: `{"type": "prediction_update", "symbol": ..., "predicted_price": ...}`
  - [ ] Handle send failures (close dead connections)
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 5 hours
  - **Blocked by:** T4.2

- [ ] **T4.4** - Implement connection lifecycle management
  - [ ] Handle ping/pong for keep-alive
  - [ ] Detect disconnections
  - [ ] Clean up subscriptions on disconnect
  - [ ] Log connection events (connect, disconnect, error)
  - [ ] Implement connection timeout (5 minutes idle)
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T4.3

- [ ] **T4.5** - Implement rate limiting for WebSocket
  - [ ] Limit messages per connection (10/sec)
  - [ ] Buffer updates if rate exceeded
  - [ ] Drop oldest updates if buffer full (1000 messages)
  - [ ] Send warning message to client
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.4

---

### 5. Authentication & Authorization
**Status:** Not Started

- [ ] **T5.1** - Choose authentication strategy
  - [ ] Decision: JWT tokens with Auth0 / AWS Cognito / custom
  - [ ] For MVP: Simple API key authentication
  - [ ] Document decision and rationale
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.2

- [ ] **T5.2** - Implement JWT authentication (if chosen)
  - [ ] Install `python-jose` and `passlib`
  - [ ] Create JWT utilities (encode, decode, verify)
  - [ ] Implement `/auth/login` endpoint
  - [ ] Implement `/auth/refresh` endpoint
  - [ ] Store refresh tokens securely
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T5.1

- [ ] **T5.3** - Implement API key authentication (simpler MVP option)
  - [ ] Create `api_keys` table in TimescaleDB
  - [ ] Generate API keys (UUID format)
  - [ ] Validate API key in `X-API-Key` header
  - [ ] Create dependency for protected routes
  - [ ] Implement key rotation
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.1

- [ ] **T5.4** - Implement authorization middleware
  - [ ] Create `require_auth` dependency
  - [ ] Apply to all protected endpoints
  - [ ] Return 401 Unauthorized if invalid token/key
  - [ ] Log authentication attempts
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T5.2 or T5.3

---

### 6. Rate Limiting
**Status:** Not Started

- [ ] **T6.1** - Implement rate limiting middleware
  - [ ] Use `slowapi` library or custom Redis-based limiter
  - [ ] Configure limits: 100 requests/hour (free tier)
  - [ ] Configure limits: 1000 requests/hour (pro tier)
  - [ ] Return 429 Too Many Requests with Retry-After header
  - [ ] Store rate limit counters in Redis
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.3

- [ ] **T6.2** - Implement tier-based rate limits
  - [ ] Map API keys to tiers (free, pro, enterprise)
  - [ ] Apply different limits based on tier
  - [ ] Allow unlimited for enterprise
  - [ ] Include rate limit info in response headers (X-RateLimit-*)
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T6.1

- [ ] **T6.3** - Implement IP-based rate limiting
  - [ ] Fallback rate limiting by IP (if no API key)
  - [ ] Limit: 10 requests/hour for unauthenticated
  - [ ] Use `X-Forwarded-For` header (if behind proxy)
  - [ ] Log rate limit violations
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T6.2

---

### 7. Error Handling & Validation
**Status:** Not Started

- [ ] **T7.1** - Implement global exception handlers
  - [ ] Handle `RequestValidationError` (422 with details)
  - [ ] Handle `HTTPException` (custom status codes)
  - [ ] Handle database errors (500 with generic message)
  - [ ] Handle Redis errors (fallback to DB, log error)
  - [ ] Handle unexpected exceptions (500, log stack trace)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.2

- [ ] **T7.2** - Create Pydantic models for all endpoints
  - [ ] `PredictionResponse`
  - [ ] `ExplanationRequest`, `ExplanationResponse`
  - [ ] `ErrorResponse`
  - [ ] Add field validation (e.g., symbol format)
  - [ ] Add docstrings for API documentation
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.1

- [ ] **T7.3** - Implement input validation
  - [ ] Validate symbol format (uppercase, 1-5 chars)
  - [ ] Validate query parameters (ranges, enums)
  - [ ] Sanitize inputs (prevent injection)
  - [ ] Return 400 Bad Request for invalid inputs
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T7.2

---

### 8. Health & Monitoring Endpoints
**Status:** Not Started

- [ ] **T8.1** - Implement GET /health
  - [ ] Return 200 OK if service is healthy
  - [ ] Include status of dependencies (Redis, TimescaleDB, NATS)
  - [ ] Return 503 if any critical dependency is down
  - [ ] Include version and build info
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.3

- [ ] **T8.2** - Implement GET /health/ready
  - [ ] Kubernetes readiness probe endpoint
  - [ ] Check if all services are ready
  - [ ] Return 200 if ready, 503 if not
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 1 hour
  - **Blocked by:** T8.1

- [ ] **T8.3** - Implement GET /health/live
  - [ ] Kubernetes liveness probe endpoint
  - [ ] Simple check (return 200 OK)
  - [ ] Used to restart pod if unresponsive
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 1 hour
  - **Blocked by:** T8.1

- [ ] **T8.4** - Implement GET /metrics
  - [ ] Prometheus metrics endpoint
  - [ ] Expose request count, latency, error rate
  - [ ] Expose custom metrics (cache hit rate, etc.)
  - [ ] Use `prometheus-fastapi-instrumentator`
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.1

---

### 9. API Documentation
**Status:** Not Started

- [ ] **T9.1** - Configure Swagger UI
  - [ ] Enable Swagger UI at `/api/docs`
  - [ ] Add API description and contact info
  - [ ] Configure authentication in Swagger (API key)
  - [ ] Test all endpoints in Swagger UI
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T2.3, T3.3

- [ ] **T9.2** - Configure ReDoc
  - [ ] Enable ReDoc at `/api/redoc`
  - [ ] Alternative documentation view
  - [ ] Verify all endpoints documented
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 1 hour
  - **Blocked by:** T9.1

- [ ] **T9.3** - Generate OpenAPI spec JSON
  - [ ] Export OpenAPI spec to `/api/openapi.json`
  - [ ] Validate spec with OpenAPI validators
  - [ ] Use for API client generation
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 1 hour
  - **Blocked by:** T9.2

- [ ] **T9.4** - Write API usage guide
  - [ ] Create `/docs/API_USAGE.md`
  - [ ] Include authentication setup
  - [ ] Include example requests (curl, Python, JavaScript)
  - [ ] Document rate limits
  - [ ] Document error codes
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T9.3

---

### 10. Performance Optimization
**Status:** Not Started

- [ ] **T10.1** - Implement response caching
  - [ ] Cache prediction responses (60 seconds)
  - [ ] Use FastAPI `@lru_cache` or custom Redis cache
  - [ ] Add cache headers
  - [ ] Log cache hit rate
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.3

- [ ] **T10.2** - Optimize database queries
  - [ ] Add indexes for frequently queried columns
  - [ ] Use prepared statements
  - [ ] Profile slow queries
  - [ ] Optimize connection pool size
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T10.1

- [ ] **T10.3** - Implement request compression
  - [ ] Enable gzip compression for responses
  - [ ] Configure compression level (6)
  - [ ] Measure bandwidth savings
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 1 hour
  - **Blocked by:** T10.2

- [ ] **T10.4** - Benchmark API latency
  - [ ] Use `locust` or `k6` for load testing
  - [ ] Test with 100 concurrent users
  - [ ] Measure p50/p95/p99 latency
  - [ ] Identify bottlenecks
  - [ ] Document benchmark results
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T10.3

---

### 11. Testing
**Status:** Not Started

- [ ] **T11.1** - Write unit tests
  - [ ] Test route handlers (mock dependencies)
  - [ ] Test authentication logic
  - [ ] Test rate limiting
  - [ ] Test input validation
  - [ ] Target: >80% code coverage
  - **Assigned to:** Backend Dev 1, Backend Dev 2
  - **Estimated time:** 8 hours
  - **Blocked by:** T7.3

- [ ] **T11.2** - Write integration tests
  - [ ] Test with real Redis and TimescaleDB
  - [ ] Test all endpoints end-to-end
  - [ ] Test WebSocket connection lifecycle
  - [ ] Test error scenarios
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T11.1

- [ ] **T11.3** - Load testing
  - [ ] Test with 1,000 concurrent requests
  - [ ] Test WebSocket with 10,000 connections
  - [ ] Measure latency under load
  - [ ] Measure error rate under load
  - [ ] Document results
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T11.2

- [ ] **T11.4** - Security testing
  - [ ] Test authentication bypasses
  - [ ] Test SQL injection (should be prevented by asyncpg)
  - [ ] Test rate limit bypasses
  - [ ] Test CORS configuration
  - [ ] Document findings
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T11.3

---

### 12. Configuration & Deployment
**Status:** Not Started

- [ ] **T12.1** - Create configuration management
  - [ ] Create `config.yaml` or `.env` file
  - [ ] Configure database URLs
  - [ ] Configure Redis URL
  - [ ] Configure CORS origins
  - [ ] Configure rate limits
  - [ ] Support environment variable overrides
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.1

- [ ] **T12.2** - Create Docker image for API Gateway
  - [ ] Create Dockerfile with Python 3.11
  - [ ] Install FastAPI and dependencies
  - [ ] Configure uvicorn (4-8 workers)
  - [ ] Add health check
  - [ ] Optimize image size
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 3 hours
  - **Blocked by:** T12.1

- [ ] **T12.3** - Add API Gateway to docker-compose
  - [ ] Add service definition to `docker-compose.yml`
  - [ ] Expose port 8000
  - [ ] Configure environment variables
  - [ ] Set restart policy
  - [ ] Test full stack startup
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T12.2

---

### 13. Monitoring & Logging
**Status:** Not Started

- [ ] **T13.1** - Implement structured logging
  - [ ] Use `structlog` or `python-json-logger`
  - [ ] Log all requests (method, path, status, latency)
  - [ ] Log authentication events
  - [ ] Log errors with stack traces
  - [ ] Configure log level (INFO for prod, DEBUG for dev)
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.2

- [ ] **T13.2** - Implement request tracing
  - [ ] Generate request ID (UUID)
  - [ ] Include in logs and responses (X-Request-ID header)
  - [ ] Propagate to downstream services (NATS messages)
  - **Assigned to:** Backend Dev 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T13.1

- [ ] **T13.3** - Create Grafana dashboard for API
  - [ ] Panel: Request rate (per endpoint)
  - [ ] Panel: Latency p50/p95/p99
  - [ ] Panel: Error rate (4xx, 5xx)
  - [ ] Panel: Cache hit rate
  - [ ] Panel: WebSocket connections
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 4 hours
  - **Blocked by:** T8.4

- [ ] **T13.4** - Implement alerting
  - [ ] Alert: Error rate >1%
  - [ ] Alert: Latency p95 >100ms
  - [ ] Alert: API gateway down (health check)
  - [ ] Alert: High rate limit violations
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T13.3

---

### 14. Documentation
**Status:** Not Started

- [ ] **T14.1** - Document API architecture
  - [ ] Create architecture diagram
  - [ ] Document request flow
  - [ ] Document authentication flow
  - [ ] Document WebSocket protocol
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T12.3

- [ ] **T14.2** - Create operational runbook
  - [ ] How to deploy API updates
  - [ ] How to rotate API keys
  - [ ] How to monitor API health
  - [ ] How to troubleshoot common issues
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T14.1

- [ ] **T14.3** - Create API client examples
  - [ ] Python client example
  - [ ] JavaScript client example
  - [ ] WebSocket client example
  - [ ] Error handling examples
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T14.1

---

## Deliverables

1. ✅ **FastAPI Gateway** - RESTful API serving predictions and explanations
2. ✅ **WebSocket Server** - Real-time updates for subscribed symbols
3. ✅ **Authentication** - API key or JWT-based auth
4. ✅ **Rate Limiting** - Tier-based limits to prevent abuse
5. ✅ **API Documentation** - Swagger UI, ReDoc, usage guide
6. ✅ **Health Endpoints** - For monitoring and orchestration
7. ✅ **Monitoring Dashboard** - API metrics in Grafana
8. ✅ **Test Suite** - Unit, integration, load, security tests
9. ✅ **Documentation** - Architecture, runbook, client examples

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| API latency >100ms | Optimize database queries, implement caching, use connection pooling |
| WebSocket scalability issues | Use Redis pub/sub for horizontal scaling, optimize message routing |
| Authentication vulnerabilities | Use proven libraries (python-jose), security review, rate limiting |
| Rate limiting bypasses | Implement multiple strategies (IP, API key, user ID) |
| CORS misconfigurations | Test with frontend early, document allowed origins |

---

## Acceptance Criteria

- [ ] API serves predictions with p95 latency <100ms
- [ ] WebSocket handles 10,000 concurrent connections
- [ ] Authentication prevents unauthorized access
- [ ] Rate limiting blocks excessive requests (429 status)
- [ ] All endpoints documented in Swagger UI
- [ ] Health checks report accurate status
- [ ] Load testing shows <1% error rate under 1000 concurrent users
- [ ] Security testing finds no critical vulnerabilities
- [ ] All tests passing (unit, integration, load, security)
- [ ] Monitoring dashboard shows API metrics
- [ ] Documentation complete and reviewed

---

## Definition of Done

- [ ] All tasks marked as "Done"
- [ ] Code reviewed and merged to `develop` branch
- [ ] Test coverage >80%
- [ ] Performance benchmarks met (p95 <100ms)
- [ ] Load testing completed (10,000 WebSocket connections)
- [ ] Security testing completed
- [ ] Integration tests passing with real infrastructure
- [ ] Grafana dashboard created and tested
- [ ] API documentation complete (Swagger, usage guide)
- [ ] Demo completed showing API and WebSocket
- [ ] Tech Lead sign-off

---

**Milestone Owner:** Backend Dev 1
**Review Date:** End of Week 10
**Next Milestone:** M8 - UI Development & Integration

[End of Milestone 7]
