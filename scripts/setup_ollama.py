#!/usr/bin/env python3
"""
Feature 1: Ollama LLM Service Setup Script
Tests and configures Ollama for prediction explanations
"""

import sys
import json
import requests
import time

OLLAMA_HOST = "http://localhost:11434"

def check_ollama_health():
    """Check if Ollama service is running"""
    try:
        response = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=5)
        return response.status_code == 200
    except Exception as e:
        print(f"[ERROR] Cannot connect to Ollama: {e}")
        return False

def list_models():
    """List all available models in Ollama"""
    try:
        response = requests.get(f"{OLLAMA_HOST}/api/tags")
        data = response.json()
        return data.get("models", [])
    except Exception as e:
        print(f"[ERROR] Failed to list models: {e}")
        return []

def pull_model(model_name):
    """Pull a model from Ollama registry"""
    print(f"\n[INFO] Pulling model: {model_name}")
    print("[INFO] This may take several minutes...")

    try:
        response = requests.post(
            f"{OLLAMA_HOST}/api/pull",
            json={"name": model_name},
            stream=True,
            timeout=1800  # 30 minutes timeout
        )

        for line in response.iter_lines():
            if line:
                data = json.loads(line)
                status = data.get("status", "")
                if "total" in data and "completed" in data:
                    total = data["total"]
                    completed = data["completed"]
                    percent = (completed / total * 100) if total > 0 else 0
                    print(f"\r[INFO] Progress: {percent:.1f}%", end="", flush=True)
                elif status:
                    print(f"\r[INFO] {status}", end="", flush=True)

        print("\n[OK] Model pulled successfully")
        return True
    except Exception as e:
        print(f"\n[ERROR] Failed to pull model: {e}")
        return False

def test_generation(model_name, prompt):
    """Test model generation"""
    print(f"\n[INFO] Testing {model_name} with prompt...")

    try:
        start_time = time.time()

        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={
                "model": model_name,
                "prompt": prompt,
                "stream": False
            },
            timeout=60
        )

        elapsed = time.time() - start_time

        if response.status_code == 200:
            data = response.json()
            generated_text = data.get("response", "")

            print(f"[OK] Generation successful ({elapsed:.2f}s)")
            print(f"\nPrompt: {prompt}")
            print(f"Response: {generated_text[:200]}...")

            return True
        else:
            print(f"[ERROR] Generation failed: {response.status_code}")
            return False

    except Exception as e:
        print(f"[ERROR] Generation failed: {e}")
        return False

def setup_ollama():
    """Main setup function"""

    print("="*60)
    print("Ollama LLM Service Configuration")
    print("="*60)

    # Check health
    print("\n1. Checking Ollama service...")
    if not check_ollama_health():
        print("[ERROR] Ollama service is not running")
        sys.exit(1)
    print("[OK] Ollama service is running")

    # List current models
    print("\n2. Listing available models...")
    models = list_models()

    if not models:
        print("[WARN] No models found")
    else:
        print(f"[OK] Found {len(models)} model(s):")
        for model in models:
            size_mb = model["size"] / (1024 * 1024)
            param_size = model["details"].get("parameter_size", "Unknown")
            quant = model["details"].get("quantization_level", "Unknown")
            print(f"  - {model['name']}")
            print(f"    Size: {size_mb:.1f} MB")
            print(f"    Parameters: {param_size}")
            print(f"    Quantization: {quant}")

    # Recommended model for the project
    recommended_model = "llama3.2:3b"

    print(f"\n3. Checking for recommended model: {recommended_model}")
    model_names = [m["name"] for m in models]

    if recommended_model not in model_names:
        print(f"[INFO] Recommended model '{recommended_model}' not found")
        print("[INFO] You can pull it later with: docker exec riskee_ollama ollama pull llama3.2:3b")
        print("[INFO] Using existing models for testing")
    else:
        print(f"[OK] Model '{recommended_model}' is available")

    # Test with available model
    if models:
        test_model = models[0]["name"]
        print(f"\n4. Testing generation with: {test_model}")

        test_prompt = "Explain why AAPL stock price might increase tomorrow in 1 sentence."
        test_generation(test_model, test_prompt)

    print("\n"+ "="*60)
    print("[OK] Ollama Configuration Complete")
    print("="*60)

    print("\nAvailable Models:")
    for model in models:
        print(f"  - {model['name']}")

    print("\nRecommended Models for Production:")
    print("  - llama3.2:3b (Fast, good quality)")
    print("  - llama3.1:8b (Better quality, slower)")
    print("  - mistral:7b (Good balance)")

    print("\nTo pull additional models:")
    print("  docker exec riskee_ollama ollama pull <model-name>")

    print("\nOllama API Endpoint: http://localhost:11434")
    print("Model List: http://localhost:11434/api/tags")

if __name__ == "__main__":
    try:
        setup_ollama()
    except Exception as e:
        print(f"\n[ERROR] Setup failed: {e}", file=sys.stderr)
        sys.exit(1)
