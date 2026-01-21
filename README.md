# Bun + LangGraph Experiment 🧪

> "Is Bun really that fast? Does LangGraph even work with it?"

A simple comparison to answer these questions.

## What I Did

Built the same API with two different stacks:

| | Python | JavaScript |
|---|--------|------------|
| **Runtime** | CPython 3.11 | Bun |
| **Framework** | FastAPI | Elysia |
| **LLM Orchestration** | LangGraph | LangGraph.js |
| **Port** | 3000 | 3001 |

Both hit the same local llama.cpp model running in the background.

## Results

### HTTP Performance (no LLM)

```
/health endpoint:
  Python:  5,302 req/s
  Bun:    18,061 req/s  ← 3.4x faster

/fib/30 (CPU-heavy):
  Python:    11 req/s
  Bun:      221 req/s   ← 20x faster 🚀
```

### LangGraph (no LLM, just graph execution)

```
/chat/mock:
  Python: 2,119 req/s
  Bun:    3,173 req/s   ← 1.5x faster
```

### Real LLM Chat

```
/chat (llama.cpp backend):
  Python: ~2.6 req/s
  Bun:    ~2.6 req/s    ← Same
```

## What I Learned

1. **Bun is genuinely fast** — 3-8x difference in HTTP overhead, 20x in CPU-bound tasks

2. **LangGraph.js works fine** — Compatible with Bun out of the box, no extra config needed

3. **LLM bottleneck equalizes everything** — In real-world scenarios, model inference time dominates and framework differences become negligible

4. **Bun still makes sense** because:
   - Lower memory footprint
   - Faster cold start
   - Native TypeScript
   - Same LangGraph API

## Try It Yourself

```bash
# 1. Start llama.cpp
llama-server -m model.gguf --port 7001

# 2. Python server
cd python-project && uv run uvicorn main:app --port 3000

# 3. JS server
cd js-project && bun run index.ts

# 4. Test it
curl http://localhost:3001/health
curl -X POST http://localhost:3001/chat -d '{"message":"hello"}'
```

## Project Structure

```
.
├── python-project/
│   └── main.py          # FastAPI + LangGraph
├── js-project/
│   └── index.ts         # Elysia + LangGraph.js
└── benchmark.sh         # wrk tests
```

## Conclusion

If you're building an LLM-heavy app in production, framework choice barely affects performance — the bottleneck is always model inference.

But for developer experience, TypeScript support, and overall system performance, Bun + LangGraph.js is a solid alternative. Especially if you're coming from Node.js, migration is zero effort.

---

*This isn't a serious benchmark, just an experiment out of curiosity.*
