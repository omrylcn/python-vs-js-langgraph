# Python Server (FastAPI + LangGraph)

FastAPI server with LangGraph integration for LLM chat via llama.cpp.

## Setup

```bash
# Install dependencies
uv sync

# Run server
uv run uvicorn main:app --port 3000
```

## Configuration

Environment variables (with defaults):

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_BASE_URL` | `http://127.0.0.1:7001/v1` | LLM server URL |
| `LLM_API_KEY` | `not-needed` | API key |
| `LLM_TEMPERATURE` | `0.7` | Response randomness |
| `LLM_MAX_TOKENS` | `512` | Max response length |

```bash
LLM_BASE_URL=http://localhost:8080/v1 uv run uvicorn main:app --port 3000
```

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/user/{user_id}` | GET | Get user by ID |
| `/echo` | POST | Echo text with length |
| `/fib/{n}` | GET | Fibonacci (max n=30) |
| `/users` | GET | List 100 users |
| `/chat` | POST | LangGraph chat |

## Example

```bash
# Health check
curl http://localhost:3000/health

# Chat
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!"}'
```
