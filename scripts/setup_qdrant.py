#!/usr/bin/env python3
"""
Feature 1: Qdrant Vector Database Setup Script
Configures collections for RAG (Retrieval Augmented Generation)
"""

import sys
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

def setup_qdrant():
    """Create Qdrant collections for the prediction system"""

    # Connect to Qdrant
    client = QdrantClient(host="localhost", port=6333)
    print("[OK] Connected to Qdrant server")

    # Collection configurations for RAG system
    collections = [
        {
            "name": "market_news",
            "description": "Financial news articles and market commentary",
            "vector_size": 768,  # all-MiniLM-L6-v2 embedding size
            "distance": Distance.COSINE,
        },
        {
            "name": "earnings_calls",
            "description": "Earnings call transcripts and analysis",
            "vector_size": 768,
            "distance": Distance.COSINE,
        },
        {
            "name": "economic_indicators",
            "description": "Economic reports and indicators",
            "vector_size": 768,
            "distance": Distance.COSINE,
        },
        {
            "name": "technical_patterns",
            "description": "Technical analysis patterns and signals",
            "vector_size": 768,
            "distance": Distance.COSINE,
        },
        {
            "name": "prediction_context",
            "description": "Historical prediction contexts for learning",
            "vector_size": 768,
            "distance": Distance.COSINE,
        },
    ]

    # Create each collection
    print("\n" + "="*60)
    print("Creating Qdrant Collections")
    print("="*60)

    for collection_config in collections:
        try:
            # Check if collection exists
            existing_collections = client.get_collections().collections
            collection_names = [c.name for c in existing_collections]

            if collection_config["name"] in collection_names:
                print(f"[SKIP] Collection '{collection_config['name']}' already exists, skipping")
                continue

            # Create collection
            client.create_collection(
                collection_name=collection_config["name"],
                vectors_config=VectorParams(
                    size=collection_config["vector_size"],
                    distance=collection_config["distance"]
                )
            )
            print(f"[OK] Created collection: {collection_config['name']}")
            print(f"  Description: {collection_config['description']}")
            print(f"  Vector size: {collection_config['vector_size']}")
            print(f"  Distance metric: {collection_config['distance'].name}")

        except Exception as e:
            print(f"[ERROR] Error creating collection {collection_config['name']}: {e}")
            raise

    # List all collections with stats
    print("\n" + "="*60)
    print("Current Qdrant Collections:")
    print("="*60)

    collections_info = client.get_collections()
    for collection in collections_info.collections:
        collection_info = client.get_collection(collection.name)
        print(f"\n{collection.name}:")
        print(f"  Vectors count: {collection_info.points_count}")
        print(f"  Vector size: {collection_info.config.params.vectors.size}")
        print(f"  Distance: {collection_info.config.params.vectors.distance.name}")
        print(f"  Status: {collection_info.status}")

    # Test vector insertion and search
    print("\n" + "="*60)
    print("Testing Vector Operations")
    print("="*60)

    # Insert a test vector
    test_collection = "market_news"
    test_vector = [0.1] * 768  # Dummy vector for testing

    client.upsert(
        collection_name=test_collection,
        points=[
            PointStruct(
                id=1,
                vector=test_vector,
                payload={
                    "text": "Test market news article",
                    "ticker": "AAPL",
                    "timestamp": "2025-12-17T00:00:00Z",
                    "source": "test"
                }
            )
        ]
    )
    print(f"[OK] Inserted test vector into '{test_collection}'")

    # Search for similar vectors
    search_results = client.query_points(
        collection_name=test_collection,
        query=test_vector,
        limit=1
    ).points

    if search_results:
        print(f"[OK] Search successful, found {len(search_results)} result(s)")
        print(f"  Top result ID: {search_results[0].id}")
        print(f"  Score: {search_results[0].score}")
        print(f"  Payload: {search_results[0].payload}")

    # Clean up test data
    client.delete(
        collection_name=test_collection,
        points_selector=[1]
    )
    print(f"[OK] Cleaned up test vector")

    print("\n[OK] Qdrant setup complete!")
    print("\nCollections are ready for RAG operations:")
    print("  - market_news: Financial news and commentary")
    print("  - earnings_calls: Earnings transcripts")
    print("  - economic_indicators: Economic reports")
    print("  - technical_patterns: Technical analysis")
    print("  - prediction_context: Historical contexts")
    print("\nEmbedding model: all-MiniLM-L6-v2 (768 dimensions)")
    print("Distance metric: Cosine similarity")

if __name__ == "__main__":
    try:
        setup_qdrant()
    except Exception as e:
        print(f"\n[ERROR] Error: {e}", file=sys.stderr)
        sys.exit(1)
