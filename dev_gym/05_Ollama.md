# Ollama Tutorial - Developer Gym

**What is it?** Local LLM (Large Language Model) server - like ChatGPT but runs on your machine
**Why we use it?** Generate explanations for predictions, no API costs
**In this project:** Explain why stock price predicted to change, provide reasoning

---

## 🎯 Quick Concept

Ollama = ChatGPT Running Locally

**ChatGPT/Claude:**
- Runs in cloud
- Costs money per request
- Requires internet
- Data leaves your machine

**Ollama:**
- Runs on your machine
- Free
- Works offline
- Data stays private

**Trade-offs:**
- Smaller models (less smart)
- Slower inference
- Requires GPU for good performance

---

## 🏗️ Core Concepts

### 1. Models

Different sizes for different needs:

```
tinyllama:latest  → 608 MB,  1B params  → Fast, basic reasoning
gemma3:4b         → 3.2 GB,  4B params  → Good balance ✓ (we use this)
mistral:7b        → 4.2 GB,  7B params  → Better quality
llama3.1:8b       → 4.9 GB,  8B params  → Production quality
llama3.1:70b      → 40 GB,  70B params  → Best quality (slow)
```

**B = Billion parameters** (more = smarter but slower)

### 2. Prompts

How you talk to the model:

```
❌ BAD: "AAPL"
Response: Random text about apples

✅ GOOD: "Explain in one sentence why AAPL stock might increase tomorrow based on strong earnings."
Response: "AAPL stock may rise as investors react positively to better-than-expected quarterly earnings..."
```

### 3. Temperature

Controls randomness:

```python
temperature=0.0  → Deterministic (same answer every time)
temperature=0.5  → Balanced (we use this)
temperature=1.0  → Creative (different answers)
```

### 4. Streaming

```python
# Non-streaming (wait for complete response)
response = ollama.generate(model="gemma3:4b", prompt="...", stream=False)
print(response['response'])  # Full answer at once

# Streaming (word by word)
for chunk in ollama.generate(model="gemma3:4b", prompt="...", stream=True):
    print(chunk['response'], end='', flush=True)  # Like ChatGPT
```

---

## 💻 Hands-On Examples

### Check Ollama Status

```bash
# List models
curl http://localhost:11434/api/tags

# PowerShell
Invoke-RestMethod -Uri "http://localhost:11434/api/tags"

# Check if running
curl http://localhost:11434
```

### Example 1: Simple Generation (Bash/PowerShell)

```bash
# Bash
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3:4b",
  "prompt": "Explain in one sentence why AAPL stock might increase.",
  "stream": false
}'

# PowerShell
$body = @{
    model = "gemma3:4b"
    prompt = "Explain in one sentence why AAPL stock might increase."
    stream = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json"
```

### Example 2: Simple Generation (Python)

```python
import requests
import json

def generate_text(prompt, model="gemma3:4b"):
    response = requests.post(
        "http://localhost:11434/api/generate",
        json={
            "model": model,
            "prompt": prompt,
            "stream": False
        }
    )
    return response.json()["response"]

# Use it
explanation = generate_text("Why might AAPL stock increase tomorrow?")
print(explanation)
```

### Example 3: Streaming Response

```python
import requests
import json

def generate_streaming(prompt):
    response = requests.post(
        "http://localhost:11434/api/generate",
        json={
            "model": "gemma3:4b",
            "prompt": prompt,
            "stream": True
        },
        stream=True
    )

    for line in response.iter_lines():
        if line:
            chunk = json.loads(line)
            print(chunk["response"], end='', flush=True)

generate_streaming("Explain why stock prices fluctuate.")
```

### Example 4: Structured Prompts

```python
def create_prediction_explanation(ticker, predicted_price, current_price, confidence, factors):
    """Generate explanation for prediction"""

    prompt = f"""You are a financial analyst. Explain this stock prediction in 2-3 sentences.

Ticker: {ticker}
Current Price: ${current_price}
Predicted Price: ${predicted_price}
Confidence: {confidence:.1%}
Key Factors: {', '.join(factors)}

Provide a clear, professional explanation for why the price is expected to change.
"""

    return generate_text(prompt)

# Usage
explanation = create_prediction_explanation(
    ticker="AAPL",
    predicted_price=155.50,
    current_price=154.20,
    confidence=0.87,
    factors=["Strong earnings", "Product launch", "Market momentum"]
)

print(explanation)
# Output: "Apple stock is predicted to rise 0.84% to $155.50 with 87% confidence,
# driven by robust quarterly earnings that exceeded analyst expectations, upcoming
# product launches generating positive market sentiment, and favorable overall
# momentum in the technology sector."
```

### Example 5: JSON Output (Structured Data)

```python
def extract_sentiment(text):
    """Extract sentiment as JSON"""

    prompt = f"""Analyze the sentiment of this financial text and respond ONLY with valid JSON:

Text: "{text}"

Response format:
{{"sentiment": "positive/negative/neutral", "confidence": 0.0-1.0, "reasoning": "brief explanation"}}
"""

    response = generate_text(prompt)

    # Parse JSON from response
    import re
    json_match = re.search(r'\{.*\}', response, re.DOTALL)
    if json_match:
        return json.loads(json_match.group())

    return None

# Usage
result = extract_sentiment("Apple reports record earnings, beats expectations")
print(result)
# {"sentiment": "positive", "confidence": 0.9, "reasoning": "Earnings beat indicates strong performance"}
```

---

## 🎓 Best Practices for Our Project

### 1. Clear, Specific Prompts

```python
# ❌ BAD - Vague
"Tell me about AAPL"

# ✅ GOOD - Specific
"""Explain in 2 sentences why AAPL stock price is predicted to increase
from $154.20 to $155.50, given strong Q4 earnings and upcoming product launch."""
```

### 2. Control Output Length

```python
prompt = """Explain this prediction in EXACTLY 2 sentences, no more.

Ticker: AAPL
Prediction: Price increase to $155.50
Reason: Strong earnings, product launch

Your explanation:"""

# Adding "EXACTLY 2 sentences" helps control length
```

### 3. Temperature for Different Use Cases

```python
# Factual explanations (consistent)
response = generate_text(prompt, temperature=0.1)

# Creative content (varied)
response = generate_text(prompt, temperature=0.8)

# We use 0.3-0.5 for balance
```

### 4. Timeout and Error Handling

```python
def safe_generate(prompt, timeout=30):
    """Generate with timeout"""
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={"model": "gemma3:4b", "prompt": prompt, "stream": False},
            timeout=timeout
        )
        return response.json()["response"]
    except requests.Timeout:
        return "Error: LLM generation timed out"
    except Exception as e:
        return f"Error: {str(e)}"
```

---

## 🔍 Our Use Cases

### 1. Prediction Explanations

```python
def explain_prediction(ticker, prediction_data):
    prompt = f"""As a financial analyst, explain this AI prediction in 2-3 clear sentences:

Stock: {ticker}
Predicted Price: ${prediction_data['predicted_price']}
Current Price: ${prediction_data['current_price']}
Change: {prediction_data['change_pct']}%
Confidence: {prediction_data['confidence']:.1%}
Model: {prediction_data['model_type']} (normal/earnings day)

Key Indicators:
- Recent price trend: {prediction_data['trend']}
- Volume: {prediction_data['volume_trend']}
- Sector performance: {prediction_data['sector']}

Provide professional explanation suitable for investors."""

    return generate_text(prompt)
```

### 2. Sentiment Analysis

```python
def analyze_news_impact(ticker, news_headline):
    prompt = f"""Analyze how this news might affect {ticker} stock price:

News: "{news_headline}"

Respond with JSON:
{{"impact": "positive/negative/neutral", "magnitude": "high/medium/low", "explanation": "brief reason"}}
"""

    return extract_json(generate_text(prompt))
```

### 3. Risk Assessment

```python
def assess_prediction_risk(prediction):
    prompt = f"""Assess the risk of this stock prediction:

Ticker: {prediction['ticker']}
Predicted Change: {prediction['change']}%
Historical Accuracy: {prediction['model_accuracy']}%
Market Volatility: {prediction['volatility']}

Rate risk as LOW/MEDIUM/HIGH and explain why in one sentence."""

    return generate_text(prompt)
```

---

## 🐛 Common Issues & Solutions

### Issue: "Connection refused"

**Solution:**
```bash
# Check if Ollama is running
docker ps | grep ollama

# Start if not running
docker-compose up -d ollama
```

### Issue: Model not found

**Solution:**
```bash
# List available models
curl http://localhost:11434/api/tags

# Pull a model (if needed)
docker exec riskee_ollama ollama pull llama3.2:3b
```

### Issue: Slow generation

**Solution:**
```python
# Use smaller model
model="gemma3:4b"  # Not llama3.1:70b

# Reduce max tokens
{
    "model": "gemma3:4b",
    "prompt": "...",
    "options": {"num_predict": 100}  # Limit response length
}

# Check GPU usage
docker stats riskee_ollama
```

### Issue: Inconsistent responses

**Solution:**
```python
# Lower temperature for consistency
{
    "model": "gemma3:4b",
    "prompt": "...",
    "options": {"temperature": 0.1}  # More deterministic
}
```

---

## 📊 Model Comparison

### Our Available Models

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| tinyllama | 608 MB | ⚡⚡⚡ | ⭐ | Testing only |
| gemma3:4b | 3.2 GB | ⚡⚡ | ⭐⭐⭐ | **Production** (we use) |
| mistral:7b | 4.2 GB | ⚡ | ⭐⭐⭐⭐ | Better explanations |

**Recommendation:** gemma3:4b for good balance of speed and quality

---

## 📚 Learn More

**Official Docs:**
- Ollama Docs: https://github.com/ollama/ollama
- Model Library: https://ollama.com/library
- API Reference: https://github.com/ollama/ollama/blob/main/docs/api.md

**Our Setup:**
- Port: 11434
- Models: gemma3:4b, mistral:7b, tinyllama
- API: http://localhost:11434/api/generate

**Test:**
```bash
# Run our test script
python scripts/setup_ollama.py
```

---

## ✅ Quick Checklist

- [ ] Understand LLM runs locally (vs cloud API)
- [ ] Know how to craft clear prompts
- [ ] Can generate text via HTTP API
- [ ] Understand temperature parameter
- [ ] Can extract structured data (JSON)
- [ ] Know when to use streaming vs non-streaming
- [ ] Understand model size trade-offs
- [ ] Can handle timeouts and errors

**Next:** Learn Prometheus for monitoring! → [06_Prometheus.md](06_Prometheus.md)
