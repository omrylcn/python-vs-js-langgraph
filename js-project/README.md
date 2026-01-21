# JavaScript Server (Bun/Elysia + LangGraph)

Bun/Elysia server with LangGraph integration for LLM chat via llama.cpp.

## Setup

```bash
# Install dependencies
bun install

# Run server
bun run index.ts
```

## Configuration

Environment variables (with defaults):

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_BASE_URL` | `http://127.0.0.1:7001/v1` | LLM server URL |
| `LLM_API_KEY` | `not-needed` | API key |
| `LLM_TEMPERATURE` | `0.7` | Response randomness |
| `LLM_MAX_TOKENS` | `512` | Max response length |
| `PORT` | `3001` | Server port |

```bash
LLM_BASE_URL=http://localhost:8080/v1 PORT=4000 bun run index.ts
```

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/user/:id` | GET | Get user by ID |
| `/echo` | POST | Echo text with length |
| `/fib/:n` | GET | Fibonacci (max n=30) |
| `/users` | GET | List 100 users |
| `/chat` | POST | LangGraph chat |

## Example

```bash
# Health check
curl http://localhost:3001/health

# Chat
curl -X POST http://localhost:3001/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!"}'
```
