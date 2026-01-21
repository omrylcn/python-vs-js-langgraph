import os
from fastapi import FastAPI
from pydantic import BaseModel
from langgraph.graph import StateGraph, MessagesState, START, END
from langchain_openai import ChatOpenAI

app = FastAPI()

# Configuration (environment variables with defaults)
LLM_BASE_URL = os.getenv("LLM_BASE_URL", "http://127.0.0.1:7001/v1")
LLM_API_KEY = os.getenv("LLM_API_KEY", "not-needed")
LLM_TEMPERATURE = float(os.getenv("LLM_TEMPERATURE", "0.7"))
LLM_MAX_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "512"))

# LangGraph + ChatOpenAI setup (llama.cpp backend)
llm = ChatOpenAI(
    api_key=LLM_API_KEY,
    base_url=LLM_BASE_URL,
    temperature=LLM_TEMPERATURE,
    max_tokens=LLM_MAX_TOKENS,
)


def call_model(state: MessagesState):
    response = llm.invoke(state["messages"])
    return {"messages": [response]}


graph = StateGraph(MessagesState)
graph.add_node("llm", call_model)
graph.add_edge(START, "llm")
graph.add_edge("llm", END)
compiled_graph = graph.compile()


# Mock LangGraph (without LLM)
def mock_model(state: MessagesState):
    last_msg = state["messages"][-1]
    content = last_msg.content if hasattr(last_msg, "content") else last_msg["content"]
    return {"messages": [{"role": "ai", "content": f"mock: {content}"}]}


mock_graph = StateGraph(MessagesState)
mock_graph.add_node("mock", mock_model)
mock_graph.add_edge(START, "mock")
mock_graph.add_edge("mock", END)
compiled_mock_graph = mock_graph.compile()


class Message(BaseModel):
    text: str


class ChatRequest(BaseModel):
    message: str


class User(BaseModel):
    id: int
    name: str
    email: str


# 1. Health check
@app.get("/health")
def health():
    return {"status": "ok"}


# 2. Simple JSON response
@app.get("/user/{user_id}")
def get_user(user_id: int):
    return User(
        id=user_id,
        name="John Doe",
        email="john@example.com"
    )


# 3. POST with body parsing
@app.post("/echo")
def echo(message: Message):
    return {"received": message.text, "length": len(message.text)}


# 4. CPU-bound task (fibonacci)
def fib(n: int) -> int:
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)


@app.get("/fib/{n}")
def fibonacci(n: int):
    result = fib(min(n, 30))  # Cap at 30 to prevent timeout
    return {"n": n, "result": result}


# 5. List response
@app.get("/users")
def list_users():
    return [
        User(id=i, name=f"User {i}", email=f"user{i}@example.com")
        for i in range(100)
    ]


# 6. LangGraph chat endpoint
@app.post("/chat")
def chat(req: ChatRequest):
    result = compiled_graph.invoke({
        "messages": [{"role": "user", "content": req.message}]
    })
    last_message = result["messages"][-1]
    return {"response": last_message.content}


# 7. Mock chat endpoint (LangGraph without LLM)
@app.post("/chat/mock")
def chat_mock(req: ChatRequest):
    result = compiled_mock_graph.invoke({
        "messages": [{"role": "user", "content": req.message}]
    })
    last_message = result["messages"][-1]
    content = last_message.content if hasattr(last_message, "content") else last_message["content"]
    return {"response": content}
