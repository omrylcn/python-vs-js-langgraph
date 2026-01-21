import { Elysia, t } from "elysia";
import { ChatOpenAI } from "@langchain/openai";
import { StateGraph, MessagesAnnotation, START, END } from "@langchain/langgraph";

// Configuration (environment variables with defaults)
const LLM_BASE_URL = process.env.LLM_BASE_URL ?? "http://127.0.0.1:7001/v1";
const LLM_API_KEY = process.env.LLM_API_KEY ?? "not-needed";
const LLM_TEMPERATURE = parseFloat(process.env.LLM_TEMPERATURE ?? "0.7");
const LLM_MAX_TOKENS = parseInt(process.env.LLM_MAX_TOKENS ?? "512");
const PORT = parseInt(process.env.PORT ?? "3001");

// Types
interface User {
  id: number;
  name: string;
  email: string;
}

// LangGraph + ChatOpenAI setup (llama.cpp backend)
const llm = new ChatOpenAI({
  apiKey: LLM_API_KEY,
  configuration: {
    baseURL: LLM_BASE_URL,
  },
  temperature: LLM_TEMPERATURE,
  maxTokens: LLM_MAX_TOKENS,
});

const callModel = async (state: typeof MessagesAnnotation.State) => {
  const response = await llm.invoke(state.messages);
  return { messages: [response] };
};

const graph = new StateGraph(MessagesAnnotation)
  .addNode("llm", callModel)
  .addEdge(START, "llm")
  .addEdge("llm", END)
  .compile();

// Mock LangGraph (without LLM)
const mockModel = (state: typeof MessagesAnnotation.State) => {
  const userMsg = state.messages[state.messages.length - 1];
  const content = typeof userMsg === "string" ? userMsg : userMsg.content;
  return { messages: [{ role: "ai", content: `mock: ${content}` }] };
};

const mockGraph = new StateGraph(MessagesAnnotation)
  .addNode("mock", mockModel)
  .addEdge(START, "mock")
  .addEdge("mock", END)
  .compile();

// Fibonacci function (CPU-bound task)
function fib(n: number): number {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}

const app = new Elysia()
  // 1. Health check
  .get("/health", () => ({ status: "ok" }))

  // 2. Simple JSON response
  .get("/user/:id", ({ params: { id } }): User => ({
    id: Number(id),
    name: "John Doe",
    email: "john@example.com",
  }))

  // 3. POST with body parsing
  .post(
    "/echo",
    ({ body }) => ({
      received: body.text,
      length: body.text.length,
    }),
    {
      body: t.Object({
        text: t.String(),
      }),
    }
  )

  // 4. CPU-bound task (fibonacci)
  .get("/fib/:n", ({ params: { n } }) => {
    const num = Math.min(Number(n), 30); // Cap at 30 to prevent timeout
    return { n: Number(n), result: fib(num) };
  })

  // 5. List response
  .get("/users", (): User[] =>
    Array.from({ length: 100 }, (_, i) => ({
      id: i,
      name: `User ${i}`,
      email: `user${i}@example.com`,
    }))
  )

  // 6. LangGraph chat endpoint
  .post(
    "/chat",
    async ({ body }) => {
      const result = await graph.invoke({
        messages: [{ role: "user", content: body.message }],
      });
      const lastMessage = result.messages[result.messages.length - 1];
      return { response: lastMessage?.content ?? "" };
    },
    {
      body: t.Object({
        message: t.String(),
      }),
    }
  )

  // 7. Mock chat endpoint (LangGraph without LLM)
  .post(
    "/chat/mock",
    async ({ body }) => {
      const result = await mockGraph.invoke({
        messages: [{ role: "user", content: body.message }],
      });
      const lastMessage = result.messages[result.messages.length - 1];
      return { response: lastMessage?.content ?? "" };
    },
    {
      body: t.Object({
        message: t.String(),
      }),
    }
  )

  .listen(PORT);

console.log(`🚀 Elysia running at http://localhost:${app.server?.port}`);
