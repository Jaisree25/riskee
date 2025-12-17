# Milestone 6: LLM Explanation System (RAG)

**Duration:** Week 7-9 (12 working days)
**Team:** Backend + AI/ML (2-3 developers)
**Dependencies:** M5 (Prediction pipeline must be working)
**Status:** Not Started

---

## Objective

Build an AI-powered explanation system that generates natural language explanations for price predictions using RAG (Retrieval Augmented Generation). The system retrieves relevant context from EDGAR filings, playbooks, and historical patterns, then uses Llama 3.1 8B (via Ollama) with LangChain to generate clear, data-driven explanations in <3 seconds.

---

## Success Criteria

- ✅ Explanation generation latency: <3 seconds (p95)
- ✅ RAG retrieves relevant context (relevance score >0.7)
- ✅ LLM generates coherent, factual explanations
- ✅ Explanations cached in Redis (300 sec TTL)
- ✅ System handles concurrent requests (10 explanations/sec)
- ✅ Citations link back to source documents
- ✅ No hallucinations (grounded in retrieved context)

---

## Task List

### 1. RAG Infrastructure Setup
**Status:** Not Started

- [ ] **T1.1** - Verify Qdrant is running
  - [ ] Check Qdrant container in docker-compose (from M1)
  - [ ] Test Qdrant API connectivity
  - [ ] Create test collection and verify operations
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 1 hour
  - **Blocked by:** M1 completion

- [ ] **T1.2** - Verify Ollama and Llama 3.1 8B
  - [ ] Check Ollama container running (from M1)
  - [ ] Test Llama 3.1 8B model inference
  - [ ] Benchmark latency (target: <2 sec for 500 tokens)
  - [ ] Configure GPU utilization
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** M1 completion

- [ ] **T1.3** - Set up embedding model
  - [ ] Install `sentence-transformers` library
  - [ ] Download `all-MiniLM-L6-v2` model (384 dimensions)
  - [ ] Test embedding generation (<1ms per text)
  - [ ] Create embedding utility class
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.1

---

### 2. Document Collection & Preprocessing
**Status:** Not Started

- [ ] **T2.1** - Collect internal playbooks
  - [ ] Create `/data/playbooks` directory
  - [ ] Write 10-20 internal risk management playbooks (Markdown)
  - [ ] Topics: volatility spikes, earnings reactions, sector rotation
  - [ ] Total: ~50 documents (example templates)
  - **Assigned to:** Product Owner + AI/ML Dev
  - **Estimated time:** 6 hours
  - **Blocked by:** None

- [ ] **T2.2** - Fetch EDGAR 10-K Risk Factors
  - [ ] Use SEC EDGAR API to fetch 10-K filings
  - [ ] Extract "Risk Factors" section (Item 1A)
  - [ ] Process for 100 symbols initially (MVP scope)
  - [ ] Store raw HTML/text in `/data/edgar/10k`
  - [ ] Note: Full 5,000 symbols can be added later
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 8 hours
  - **Blocked by:** None

- [ ] **T2.3** - Fetch EDGAR 10-Q MD&A
  - [ ] Use SEC EDGAR API to fetch 10-Q filings
  - [ ] Extract "Management's Discussion and Analysis" section
  - [ ] Process for 100 symbols initially
  - [ ] Store in `/data/edgar/10q`
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T2.2

- [ ] **T2.4** - Create historical incident notes
  - [ ] Document 50-100 past earnings reactions (examples)
  - [ ] Format: symbol, date, event, reaction, lessons learned
  - [ ] Store in `/data/incidents` as JSON
  - **Assigned to:** Product Owner + AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** None

- [ ] **T2.5** - Implement document chunking
  - [ ] Create `DocumentChunker` class
  - [ ] Chunk size: 512 tokens (with 50 token overlap)
  - [ ] Preserve section boundaries (don't split mid-paragraph)
  - [ ] Generate chunk metadata (source, section, index)
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T2.1, T2.2, T2.3

---

### 3. Vector Database Setup (Qdrant)
**Status:** Not Started

- [ ] **T3.1** - Create Qdrant collection schema
  - [ ] Collection name: `financial_knowledge`
  - [ ] Vector size: 384 (all-MiniLM-L6-v2)
  - [ ] Distance metric: Cosine
  - [ ] Payload schema: doc_id, source, symbol, filing_type, section, date, text, chunk_index
  - [ ] Configure HNSW index (m=16, ef_construct=100)
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.1

- [ ] **T3.2** - Implement document embedding pipeline
  - [ ] Create `EmbeddingPipeline` class
  - [ ] Read documents from `/data/*`
  - [ ] Chunk documents (use T2.5)
  - [ ] Generate embeddings using all-MiniLM-L6-v2
  - [ ] Prepare payload with metadata
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 5 hours
  - **Blocked by:** T2.5, T3.1

- [ ] **T3.3** - Index documents in Qdrant
  - [ ] Batch upload vectors to Qdrant (1000 at a time)
  - [ ] Index all playbooks (~50 docs → ~200 chunks)
  - [ ] Index EDGAR 10-K Risk Factors (100 symbols → ~5,000 chunks)
  - [ ] Index EDGAR 10-Q MD&A (100 symbols → ~5,000 chunks)
  - [ ] Index historical incidents (~100 docs → ~300 chunks)
  - [ ] Total: ~10,500 vectors
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.2

- [ ] **T3.4** - Test vector search
  - [ ] Query: "NVDA earnings risk factors"
  - [ ] Verify relevant results returned (top 5)
  - [ ] Check relevance scores (>0.7 for good match)
  - [ ] Test search latency (target: <50ms)
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T3.3

---

### 4. LangChain Integration
**Status:** Not Started

- [ ] **T4.1** - Set up LangChain project structure
  - [ ] Create `/services/explanation_worker` directory
  - [ ] Install `langchain`, `langchain-community`, `langchain-qdrant`
  - [ ] Create module structure (llm, retriever, chains)
  - [ ] Create main entry point (`main.py`)
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T3.4

- [ ] **T4.2** - Implement Ollama LLM wrapper
  - [ ] Use `langchain_community.llms.Ollama`
  - [ ] Configure model: `llama3.1:8b-instruct-q4_K_M`
  - [ ] Set base URL: `http://ollama:11434`
  - [ ] Test LLM generation (simple prompt)
  - [ ] Configure temperature (0.3 for factual output)
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 2 hours
  - **Blocked by:** T4.1

- [ ] **T4.3** - Implement Qdrant retriever
  - [ ] Use `langchain_qdrant.Qdrant` as vector store
  - [ ] Configure embedding function (all-MiniLM-L6-v2)
  - [ ] Implement `as_retriever()` with k=5 (top 5 results)
  - [ ] Add metadata filtering (e.g., filter by symbol)
  - [ ] Test retrieval with sample queries
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.2

- [ ] **T4.4** - Design prompt template
  - [ ] Create `EXPLANATION_PROMPT` (see architecture doc lines 688-721)
  - [ ] Include sections: prediction data, technical context, earnings context, RAG context
  - [ ] Add instructions for: conciseness, citing sources, honesty about limitations
  - [ ] Test prompt with sample data
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T4.3

- [ ] **T4.5** - Implement RAG chain
  - [ ] Create `RetrievalQA` chain or custom LCEL chain
  - [ ] Steps: Retrieve context → Build prompt → Generate → Post-process
  - [ ] Configure chain to return sources (citations)
  - [ ] Test end-to-end RAG pipeline
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 5 hours
  - **Blocked by:** T4.4

---

### 5. Explanation Worker Service
**Status:** Not Started

- [ ] **T5.1** - Implement NATS subscriber for explanation jobs
  - [ ] Subscribe to `job.explain.generate` topic
  - [ ] Parse job message (symbol, depth level)
  - [ ] Acknowledge message after processing
  - [ ] Handle malformed messages
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.5

- [ ] **T5.2** - Implement prediction data retrieval
  - [ ] Fetch prediction from Redis (`pred:{symbol}`)
  - [ ] Fallback to TimescaleDB if Redis miss
  - [ ] Fetch features from Redis (`features:{symbol}`)
  - [ ] Fetch earnings analysis if earnings day (`earnings_analysis:{symbol}`)
  - [ ] Handle missing data gracefully
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.1

- [ ] **T5.3** - Implement context retrieval (RAG)
  - [ ] Build retrieval query from symbol + prediction
  - [ ] Query Qdrant for top 5 relevant documents
  - [ ] Filter by symbol if available (company-specific docs)
  - [ ] Format retrieved context for prompt
  - [ ] Track retrieval relevance scores
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.2

- [ ] **T5.4** - Implement explanation generation
  - [ ] Build final prompt with all context
  - [ ] Call LLM via LangChain RAG chain
  - [ ] Extract explanation text
  - [ ] Extract key drivers and uncertainties (parse LLM output)
  - [ ] Extract citations (link to source docs)
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 5 hours
  - **Blocked by:** T5.3

- [ ] **T5.5** - Implement post-processing
  - [ ] Format explanation as structured JSON
  - [ ] Validate output (no empty explanations)
  - [ ] Add metadata (generated_at, confidence score)
  - [ ] Sanitize LLM output (remove harmful content)
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T5.4

- [ ] **T5.6** - Implement explanation publishing
  - [ ] Store explanation in Redis (`explanation:{symbol}`, TTL 300s)
  - [ ] Publish to `thought.explanation.ready` NATS topic
  - [ ] Include job correlation ID
  - [ ] Handle publish failures
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T5.5

---

### 6. Caching & Performance
**Status:** Not Started

- [ ] **T6.1** - Implement explanation caching
  - [ ] Check Redis cache before generating (`explanation:{symbol}`)
  - [ ] Return cached explanation if <5 minutes old
  - [ ] Log cache hit rate
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T5.6

- [ ] **T6.2** - Implement LLM response caching
  - [ ] Use LangChain's `InMemoryCache` or Redis-backed cache
  - [ ] Cache based on prompt hash
  - [ ] Set TTL: 1 hour
  - [ ] Log cache hit rate
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T6.1

- [ ] **T6.3** - Optimize retrieval performance
  - [ ] Batch embedding generation where possible
  - [ ] Use Qdrant gRPC API (faster than HTTP)
  - [ ] Adjust HNSW ef parameter for speed/accuracy tradeoff
  - [ ] Profile and optimize slow queries
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T6.2

- [ ] **T6.4** - Implement depth-based explanation levels
  - [ ] Fast mode (depth: "fast"): Use simpler prompt, skip some retrieval
  - [ ] Medium mode (depth: "medium"): Default, 5 retrieved docs
  - [ ] Deep mode (depth: "deep"): Retrieve 10 docs, more detailed analysis
  - [ ] Configure in explanation job message
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T6.3

---

### 7. Quality Assurance & Validation
**Status:** Not Started

- [ ] **T7.1** - Implement explanation quality metrics
  - [ ] Measure relevance of retrieved context (avg score)
  - [ ] Measure explanation length (target: 2-4 sentences)
  - [ ] Detect hallucinations (compare facts with input data)
  - [ ] Log quality metrics for each explanation
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T6.4

- [ ] **T7.2** - Create explanation evaluation dataset
  - [ ] Manually create 20-30 example predictions
  - [ ] Generate explanations
  - [ ] Human review and rate (1-5 stars)
  - [ ] Document good and bad examples
  - **Assigned to:** Product Owner + AI/ML Dev
  - **Estimated time:** 6 hours
  - **Blocked by:** T7.1

- [ ] **T7.3** - Implement safety filters
  - [ ] Block financial advice phrases ("you should buy", "guaranteed profit")
  - [ ] Block inappropriate content (profanity, etc.)
  - [ ] Add disclaimer footer to all explanations
  - [ ] Log blocked explanations
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.2

---

### 8. Error Handling & Resilience
**Status:** Not Started

- [ ] **T8.1** - Implement error handling for LLM
  - [ ] Handle Ollama connection failures
  - [ ] Handle timeout errors (>10 seconds)
  - [ ] Handle malformed LLM outputs
  - [ ] Retry with exponential backoff (max 2 retries)
  - [ ] Fallback to simple template-based explanation
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.6

- [ ] **T8.2** - Implement error handling for RAG
  - [ ] Handle Qdrant connection failures
  - [ ] Handle no relevant documents found (relevance <0.5)
  - [ ] Handle embedding generation failures
  - [ ] Fallback to explanation without RAG context
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.1

- [ ] **T8.3** - Implement rate limiting
  - [ ] Limit concurrent LLM requests (max 10)
  - [ ] Queue requests if limit exceeded
  - [ ] Reject requests if queue full (>100)
  - [ ] Return error with retry-after header
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.2

---

### 9. Monitoring & Observability
**Status:** Not Started

- [ ] **T9.1** - Implement explanation metrics
  - [ ] Counter: explanations generated (by depth level)
  - [ ] Histogram: explanation generation latency
  - [ ] Histogram: LLM inference latency
  - [ ] Histogram: RAG retrieval latency
  - [ ] Counter: cache hits vs misses
  - [ ] Counter: errors (by type)
  - [ ] Gauge: concurrent requests
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T8.3

- [ ] **T9.2** - Create Grafana dashboard for explanations
  - [ ] Panel: Explanations per minute (line chart)
  - [ ] Panel: Generation latency p50/p95/p99 (line chart)
  - [ ] Panel: LLM latency (line chart)
  - [ ] Panel: Cache hit rate (gauge)
  - [ ] Panel: Error rate (line chart)
  - [ ] Panel: Quality metrics (avg relevance score)
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 4 hours
  - **Blocked by:** T9.1

- [ ] **T9.3** - Implement alerting
  - [ ] Alert: Explanation latency >5 seconds (p95)
  - [ ] Alert: Error rate >10%
  - [ ] Alert: Low relevance scores (avg <0.5)
  - [ ] Alert: Ollama container down
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T9.2

---

### 10. Testing
**Status:** Not Started

- [ ] **T10.1** - Write unit tests
  - [ ] Test document chunking
  - [ ] Test embedding generation
  - [ ] Test retrieval query construction
  - [ ] Test prompt template rendering
  - [ ] Test explanation post-processing
  - [ ] Target: >80% code coverage
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 6 hours
  - **Blocked by:** T7.3

- [ ] **T10.2** - Write integration tests
  - [ ] Test end-to-end RAG pipeline
  - [ ] Test with real Qdrant and Ollama
  - [ ] Test NATS message flow
  - [ ] Test Redis caching
  - [ ] Validate explanation format
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T10.1

- [ ] **T10.3** - Performance testing
  - [ ] Test explanation generation for 50 symbols
  - [ ] Measure latency (target: <3 seconds p95)
  - [ ] Measure throughput (target: 10 explanations/sec)
  - [ ] Measure memory usage
  - [ ] Identify bottlenecks
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T10.2

- [ ] **T10.4** - Quality testing
  - [ ] Generate explanations for evaluation dataset
  - [ ] Human review for accuracy and relevance
  - [ ] Check for hallucinations
  - [ ] Verify citations are correct
  - [ ] Document quality metrics
  - **Assigned to:** Product Owner + AI/ML Dev
  - **Estimated time:** 6 hours
  - **Blocked by:** T10.3

---

### 11. Configuration & Deployment
**Status:** Not Started

- [ ] **T11.1** - Create configuration management
  - [ ] Create `config.yaml` for ExplanationWorker
  - [ ] Configure LLM parameters (temperature, max_tokens)
  - [ ] Configure retrieval parameters (k, relevance threshold)
  - [ ] Document all configuration options
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T4.1

- [ ] **T11.2** - Create Docker image for ExplanationWorker
  - [ ] Create Dockerfile with Python 3.11
  - [ ] Install LangChain and dependencies
  - [ ] Add health check endpoint
  - [ ] Optimize image size
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 3 hours
  - **Blocked by:** T11.1

- [ ] **T11.3** - Add ExplanationWorker to docker-compose
  - [ ] Add service definition to `docker-compose.yml`
  - [ ] Configure environment variables
  - [ ] Link to Ollama and Qdrant services
  - [ ] Set resource limits (CPU, memory)
  - [ ] Test full stack startup
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T11.2

---

### 12. Documentation
**Status:** Not Started

- [ ] **T12.1** - Document RAG architecture
  - [ ] Create RAG pipeline diagram
  - [ ] Document Qdrant schema and indexing process
  - [ ] Document LangChain chain structure
  - [ ] Document prompt template design
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T11.3

- [ ] **T12.2** - Create operational runbook
  - [ ] How to add new documents to Qdrant
  - [ ] How to update prompt templates
  - [ ] How to monitor explanation quality
  - [ ] How to troubleshoot LLM failures
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T12.1

- [ ] **T12.3** - Document prompt engineering guidelines
  - [ ] Best practices for prompt design
  - [ ] How to handle different depth levels
  - [ ] How to adjust for model updates
  - [ ] Examples of good vs bad prompts
  - **Assigned to:** AI/ML Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T12.2

- [ ] **T12.4** - Update API documentation
  - [ ] Document explanation output schema
  - [ ] Document `job.explain.generate` and `thought.explanation.ready` topics
  - [ ] Add example explanations
  - **Assigned to:** Backend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T12.1

---

## Deliverables

1. ✅ **Qdrant vector database** - Indexed with financial documents
2. ✅ **LangChain RAG pipeline** - Generating explanations
3. ✅ **ExplanationWorker service** - Processing explanation jobs
4. ✅ **Ollama LLM integration** - Using Llama 3.1 8B
5. ✅ **Explanation caching** - Redis-backed with TTL
6. ✅ **Monitoring dashboard** - Explanation metrics visible
7. ✅ **Test suite** - Unit, integration, quality tests passing
8. ✅ **Documentation** - RAG architecture, runbook, prompt guidelines

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Explanation latency >3 seconds | Optimize retrieval, use caching, consider faster LLM (Mistral 7B) |
| LLM hallucinations (incorrect facts) | Strict prompt engineering, fact-checking, safety filters |
| Insufficient EDGAR data | Start with 100 symbols, expand gradually, supplement with news |
| Qdrant vector search slow | Optimize HNSW parameters, use gRPC, add more RAM |
| LLM generates financial advice | Safety filters, disclaimer footer, human review samples |
| Ollama GPU memory issues | Share GPU with prediction models, implement queueing |

---

## Acceptance Criteria

- [ ] Explanation generation latency <3 seconds (p95)
- [ ] RAG retrieves relevant context (avg relevance >0.7)
- [ ] LLM generates coherent, factual explanations (quality rating >3.5/5)
- [ ] Explanations cached in Redis, reducing repeat latency to <50ms
- [ ] System handles 10 concurrent explanation requests
- [ ] Citations correctly link to source documents
- [ ] No hallucinations detected in quality evaluation (20 samples)
- [ ] Safety filters block inappropriate content
- [ ] All tests passing (unit, integration, performance, quality)
- [ ] Monitoring dashboard shows explanation metrics
- [ ] Documentation complete and reviewed

---

## Definition of Done

- [ ] All tasks marked as "Done"
- [ ] Code reviewed and merged to `develop` branch
- [ ] Test coverage >80%
- [ ] Performance benchmarks met (<3 sec p95)
- [ ] Quality evaluation completed with >3.5/5 average rating
- [ ] Integration tests passing with real Ollama and Qdrant
- [ ] Grafana dashboard created and tested
- [ ] Documentation complete (architecture, runbook, prompt guidelines)
- [ ] Demo completed showing live explanations
- [ ] AI/ML Lead sign-off

---

**Milestone Owner:** AI/ML Dev
**Review Date:** End of Week 9
**Next Milestone:** M7 - API & WebSocket Gateway

[End of Milestone 6]
