# LangGraph + LLM Benchmark: Python vs JavaScript

A benchmark comparing **Python (FastAPI)** and **JavaScript (Bun/Elysia)** web frameworks with **LangGraph** and a local **llama.cpp** server.

## Overview

Both implementations provide identical REST API endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/user/:id` | GET | Simple JSON response |
| `/echo` | POST | Body parsing |
| `/fib/:n` | GET | CPU-bound task (recursive fibonacci) |
| `/users` | GET | List response (100 items) |
| `/chat` | POST | LangGraph + LLM chat |
| `/chat/mock` | POST | LangGraph without LLM (for testing) |

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Python/FastAPI │     │   JS/Bun/Elysia │
│     :3000       │     │      :3001      │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │   LangGraph + ChatOpenAI
         │                       │
         └───────────┬───────────┘
                     │
              ┌──────▼──────┐
              │  llama.cpp  │
              │    :7001    │
              └─────────────┘
```

## Requirements

- **llama.cpp** server running on `http://127.0.0.1:7001`
- **Python 3.11+** with `uv` package manager
- **Bun** runtime for JavaScript

## Quick Start

### 1. Start llama.cpp server

```bash
llama-server -m your-model.gguf --port 7001
```

### 2. Start Python server

```bash
cd python-project
uv sync
uv run uvicorn main:app --port 3000
```

### 3. Start JavaScript server

```bash
cd js-project
bun install
bun run index.ts
```

### 4. Run benchmark

```bash
./benchmark.sh
```

## Configuration

Both servers use environment variables with sensible defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_BASE_URL` | `http://127.0.0.1:7001/v1` | LLM server URL |
| `LLM_API_KEY` | `not-needed` | API key (not required for llama.cpp) |
| `LLM_TEMPERATURE` | `0.7` | Response randomness |
| `LLM_MAX_TOKENS` | `512` | Max response length |
| `PORT` | `3001` (JS only) | Server port |

Example with custom config:

```bash
# Python
LLM_BASE_URL=http://localhost:8080/v1 uv run uvicorn main:app --port 3000

# JavaScript
LLM_BASE_URL=http://localhost:8080/v1 PORT=4000 bun run index.ts
```

## Benchmark Results

> Tested with llama.cpp + Qwen 9B Q5_K_M model

### HTTP Performance (no LLM)

| Endpoint | Python (FastAPI) | JS (Bun/Elysia) | Winner |
|----------|------------------|-----------------|--------|
| `/health` | 5,302 req/s | **18,061 req/s** | JS ~3.4x |
| `/fib/20` | 1,045 req/s | **8,640 req/s** | JS ~8x |
| `/fib/30` | 11 req/s | **221 req/s** | JS ~20x |

### LangGraph Performance (without LLM)

| Endpoint | Python (FastAPI) | JS (Bun/Elysia) | Winner |
|----------|------------------|-----------------|--------|
| `/chat/mock` | 2,119 req/s | **3,173 req/s** | JS ~1.5x |

### LLM Chat Performance (with llama.cpp)

| Requests | Concurrency | Python | JS |
|----------|-------------|--------|-----|
| 20 | 5 | **2.59 req/s** | 2.36 req/s |
| 50 | 10 | 2.60 req/s | 2.60 req/s |

### Key Findings

- **HTTP overhead**: Bun/Elysia is 3-8x faster than FastAPI for simple endpoints
- **CPU-bound tasks**: Bun's V8 JIT is ~20x faster than CPython for recursive operations
- **LangGraph nodes**: JS is ~1.5x faster for LangGraph graph execution (without LLM)
- **LLM calls**: Both are nearly identical (~2.6 req/s) because llama.cpp is the bottleneck

## Stack Details

### Python
- **FastAPI** - Web framework
- **LangGraph** - LLM orchestration
- **langchain-openai** - OpenAI-compatible client
- **uvicorn** - ASGI server

### JavaScript
- **Bun** - Runtime
- **Elysia** - Web framework
- **@langchain/langgraph** - LLM orchestration
- **@langchain/openai** - OpenAI-compatible client


