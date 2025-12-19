# Qdrant Tutorial - Developer Gym

**What is it?** Vector database for similarity search (RAG - Retrieval Augmented Generation)
**Why we use it?** Find similar news, earnings calls, patterns for LLM context
**In this project:** 5 collections for RAG, 768-dimensional vectors, COSINE similarity

---

## 🎯 Quick Concept

Qdrant = Google for Embeddings

**Traditional Database:**
```sql
SELECT * FROM news WHERE text LIKE '%earnings beat%'
-- Exact match only
```

**Vector Database (Qdrant):**
```python
# Find similar meaning, not exact words
similar = search("earnings exceeded expectations")
# Returns: "quarterly profits surpassed forecast", "revenue beat estimates"
```

**How it works:**
1. Convert text to vector (embedding): `[0.1, 0.5, -0.3, ..., 0.8]` (768 numbers)
2. Store in Qdrant
3. Search by similarity: Find vectors close in "meaning space"

---

## 🏗️ Core Concepts

### 1. Vectors (Embeddings)

```python
from sentence_transformers import SentenceTransformer

# Create embedding model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Convert text to vector (768 dimensions)
text = "Apple stock price increased 5% today"
vector = model.encode(text)  # [0.123, -0.456, 0.789, ... ] (768 numbers)

# Similar texts have similar vectors!
```

### 2. Collections

Like tables in SQL:

```python
# Our 5 collections:
market_news          # Financial news articles
earnings_calls       # Earnings call transcripts
economic_indicators  # Economic reports
technical_patterns   # Technical analysis
prediction_context   # Historical prediction contexts
```

### 3. Points

A point = vector + metadata:

```python
{
    "id": 1,
    "vector": [0.1, 0.2, ..., 0.8],  # 768 numbers
    "payload": {
        "text": "Apple beats earnings",
        "ticker": "AAPL",
        "date": "2025-12-17",
        "source": "Reuters"
    }
}
```

### 4. Similarity Search

Find nearest neighbors:

```python
# Query: "Apple earnings report"
query_vector = model.encode("Apple earnings report")

# Search returns most similar points
results = client.search(
    collection_name="market_news",
    query_vector=query_vector,
    limit=5
)

# Results sorted by similarity score (0-1, higher = more similar)
```

---

## 💻 Hands-On Examples

### Check Qdrant Status

```bash
# HTTP API
curl http://localhost:6333/collections

# PowerShell
Invoke-RestMethod -Uri "http://localhost:6333/collections"

# Dashboard
# http://localhost:6333/dashboard
```

### Example 1: List Collections

```python
from qdrant_client import QdrantClient

client = QdrantClient(host="localhost", port=6333)

# List all collections
collections = client.get_collections()
for collection in collections.collections:
    print(f"Collection: {collection.name}")

# Get collection info
info = client.get_collection("market_news")
print(f"Vectors: {info.points_count}")
print(f"Vector size: {info.config.params.vectors.size}")
```

### Example 2: Insert Vectors

```python
from qdrant_client.models import PointStruct, Distance, VectorParams

# Create collection (already done in setup)
client.create_collection(
    collection_name="market_news",
    vectors_config=VectorParams(size=768, distance=Distance.COSINE)
)

# Insert points
points = [
    PointStruct(
        id=1,
        vector=[0.1] * 768,  # Normally from embedding model
        payload={
            "text": "Apple stock surges on earnings beat",
            "ticker": "AAPL",
            "date": "2025-12-17",
            "source": "Bloomberg"
        }
    ),
    PointStruct(
        id=2,
        vector=[0.2] * 768,
        payload={
            "text": "Google announces AI breakthrough",
            "ticker": "GOOGL",
            "date": "2025-12-17",
            "source": "TechCrunch"
        }
    )
]

client.upsert(collection_name="market_news", points=points)
print("Inserted 2 points")
```

### Example 3: Similarity Search

```python
# Search for similar news
query_vector = [0.15] * 768  # Normally from embedding model

results = client.query_points(
    collection_name="market_news",
    query=query_vector,
    limit=3
).points

for result in results:
    print(f"Score: {result.score:.3f}")
    print(f"Text: {result.payload['text']}")
    print(f"Ticker: {result.payload['ticker']}")
    print("---")
```

### Example 4: Filter by Metadata

```python
from qdrant_client.models import Filter, FieldCondition, MatchValue

# Search with filter (only AAPL news)
results = client.query_points(
    collection_name="market_news",
    query=query_vector,
    query_filter=Filter(
        must=[
            FieldCondition(
                key="ticker",
                match=MatchValue(value="AAPL")
            )
        ]
    ),
    limit=5
).points

# Returns only Apple-related news, sorted by similarity
```

### Example 5: Real-World RAG Pattern

```python
from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient

class NewsRAG:
    def __init__(self):
        self.client = QdrantClient(host="localhost", port=6333)
        self.model = SentenceTransformer('all-MiniLM-L6-v2')

    def add_news(self, text, ticker, source):
        """Add news article to vector database"""
        # Convert text to vector
        vector = self.model.encode(text).tolist()

        # Store in Qdrant
        point = PointStruct(
            id=hash(text),  # Simple ID generation
            vector=vector,
            payload={
                "text": text,
                "ticker": ticker,
                "source": source,
                "timestamp": datetime.now().isoformat()
            }
        )

        self.client.upsert(
            collection_name="market_news",
            points=[point]
        )

    def find_similar_news(self, query, ticker=None, limit=5):
        """Find news similar to query"""
        # Convert query to vector
        query_vector = self.model.encode(query).tolist()

        # Build filter
        filters = None
        if ticker:
            filters = Filter(
                must=[
                    FieldCondition(key="ticker", match=MatchValue(value=ticker))
                ]
            )

        # Search
        results = self.client.query_points(
            collection_name="market_news",
            query=query_vector,
            query_filter=filters,
            limit=limit
        ).points

        return [
            {
                "text": r.payload["text"],
                "ticker": r.payload["ticker"],
                "score": r.score
            }
            for r in results
        ]

# Usage
rag = NewsRAG()

# Add news
rag.add_news(
    "Apple reports record Q4 earnings, beats analyst expectations",
    "AAPL",
    "Reuters"
)

# Find similar
similar = rag.find_similar_news(
    "quarterly financial results exceeded forecasts",
    ticker="AAPL",
    limit=3
)

for news in similar:
    print(f"[{news['score']:.3f}] {news['text']}")
```

---

## 🎓 Best Practices for Our Project

### 1. Use Consistent Embeddings

```python
# ✅ GOOD - Same model everywhere
model = SentenceTransformer('all-MiniLM-L6-v2')  # 768 dimensions

# ❌ BAD - Different models = different dimensions
model1 = SentenceTransformer('all-MiniLM-L6-v2')   # 768 dims
model2 = SentenceTransformer('bert-base-uncased')  # 384 dims
```

### 2. Batch Operations

```python
# ✅ GOOD - Batch insert
points = [PointStruct(...) for i in range(1000)]
client.upsert(collection_name="market_news", points=points)

# ❌ BAD - One by one
for i in range(1000):
    client.upsert(collection_name="market_news", points=[PointStruct(...)])
```

### 3. Meaningful Metadata

```python
# ✅ GOOD - Rich metadata for filtering
payload = {
    "text": "...",
    "ticker": "AAPL",
    "date": "2025-12-17",
    "source": "Bloomberg",
    "sentiment": "positive",
    "category": "earnings"
}

# ❌ BAD - Missing useful fields
payload = {"text": "..."}
```

---

## 🔍 Our Collection Setup

### 1. market_news
```
Purpose: Financial news and commentary
Vectors: 768 dimensions
Distance: COSINE
Use: Find related news for prediction context
```

### 2. earnings_calls
```
Purpose: Earnings call transcripts
Vectors: 768 dimensions
Distance: COSINE
Use: RAG for earnings predictions
```

### 3. economic_indicators
```
Purpose: Economic reports (GDP, unemployment, etc.)
Vectors: 768 dimensions
Distance: COSINE
Use: Macro context for predictions
```

### 4. technical_patterns
```
Purpose: Technical analysis patterns
Vectors: 768 dimensions
Distance: COSINE
Use: Find similar chart patterns
```

### 5. prediction_context
```
Purpose: Historical prediction contexts
Vectors: 768 dimensions
Distance: COSINE
Use: Learn from past predictions
```

---

## 🐛 Common Issues & Solutions

### Issue: "Collection not found"

**Solution:**
```python
# Create collection first
python scripts/setup_qdrant.py

# Or check existing collections
collections = client.get_collections()
print([c.name for c in collections.collections])
```

### Issue: Dimension mismatch

**Solution:**
```python
# Vector must match collection dimension
# Collection expects 768
vector = [0.1] * 768  # ✓ Correct
vector = [0.1] * 384  # ✗ Wrong - will error
```

### Issue: Slow searches

**Solution:**
```python
# Use HNSW index (default, already configured)
# Limit results
results = client.query_points(..., limit=10)  # Not 1000

# Use filters to narrow search space
results = client.query_points(
    ...,
    query_filter=Filter(must=[...])  # Faster!
)
```

---

## 📚 Learn More

**Official Docs:**
- Qdrant Docs: https://qdrant.tech/documentation/
- Python Client: https://github.com/qdrant/qdrant-client
- Embeddings: https://www.sbert.net/

**Our Setup:**
- Port: 6333 (HTTP), 6334 (gRPC)
- Dashboard: http://localhost:6333/dashboard
- Collections: 5 (see above)

**Test:**
```python
# Run our setup script
python scripts/setup_qdrant.py
```

---

## ✅ Quick Checklist

- [ ] Understand vectors are numeric representations of text
- [ ] Know embeddings capture semantic meaning
- [ ] Can create and insert points
- [ ] Can perform similarity search
- [ ] Understand filtering by metadata
- [ ] Know when to use RAG (context for LLMs)
- [ ] Can batch insert for performance
- [ ] Understand COSINE distance measures similarity

**Next:** Learn Ollama for LLM! → [05_Ollama.md](05_Ollama.md)
