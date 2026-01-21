#!/bin/bash

# LangGraph Benchmark: Python vs JavaScript
# Requires: ab (Apache Bench), curl

PYTHON_PORT=${PYTHON_PORT:-3000}
JS_PORT=${JS_PORT:-3001}

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  LangGraph Benchmark: Python vs JS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if servers are running
check_server() {
    curl -s "http://127.0.0.1:$1/health" > /dev/null 2>&1
}

echo -e "${BLUE}Checking servers...${NC}"
if ! check_server $PYTHON_PORT; then
    echo -e "${RED}Python server not running on port $PYTHON_PORT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python server running on :$PYTHON_PORT${NC}"

if ! check_server $JS_PORT; then
    echo -e "${RED}JS server not running on port $JS_PORT${NC}"
    exit 1
fi
echo -e "${GREEN}✓ JS server running on :$JS_PORT${NC}"
echo ""

# Benchmark function for GET endpoints
bench_get() {
    local name=$1
    local endpoint=$2
    local requests=${3:-100}
    local concurrency=${4:-10}

    echo -e "${BLUE}=== $name ===${NC}"
    echo "Requests: $requests, Concurrency: $concurrency"
    echo ""

    echo "Python:"
    ab -n $requests -c $concurrency "http://127.0.0.1:$PYTHON_PORT$endpoint" 2>&1 | grep "Requests per second"

    echo "JS:"
    ab -n $requests -c $concurrency "http://127.0.0.1:$JS_PORT$endpoint" 2>&1 | grep "Requests per second"
    echo ""
}

# Benchmark function for POST endpoints (with ab)
bench_post() {
    local name=$1
    local endpoint=$2
    local requests=${3:-100}
    local concurrency=${4:-10}

    echo -e "${BLUE}=== $name ===${NC}"
    echo "Requests: $requests, Concurrency: $concurrency"
    echo ""

    echo '{"message":"test"}' > /tmp/post_data.json

    echo "Python:"
    ab -n $requests -c $concurrency -p /tmp/post_data.json -T 'application/json' \
        "http://127.0.0.1:$PYTHON_PORT$endpoint" 2>&1 | grep "Requests per second"

    echo "JS:"
    ab -n $requests -c $concurrency -p /tmp/post_data.json -T 'application/json' \
        "http://127.0.0.1:$JS_PORT$endpoint" 2>&1 | grep "Requests per second"
    echo ""
}

# Benchmark function for /chat endpoint (LLM)
bench_chat() {
    local requests=$1
    local concurrency=$2

    echo -e "${BLUE}=== /chat (LLM) - $requests requests, $concurrency concurrent ===${NC}"
    echo ""

    echo "Python:"
    start=$(date +%s.%N)
    for i in $(seq 1 $requests); do
        curl -s -X POST "http://127.0.0.1:$PYTHON_PORT/chat" \
            -H 'Content-Type: application/json' \
            -d '{"message":"Hi"}' > /dev/null &
        if (( i % concurrency == 0 )); then wait; fi
    done
    wait
    end=$(date +%s.%N)
    python_time=$(echo "$end - $start" | bc)
    python_rps=$(echo "scale=2; $requests / $python_time" | bc)
    echo "Total: ${python_time}s | ${python_rps} req/s"

    echo "JS:"
    start=$(date +%s.%N)
    for i in $(seq 1 $requests); do
        curl -s -X POST "http://127.0.0.1:$JS_PORT/chat" \
            -H 'Content-Type: application/json' \
            -d '{"message":"Hi"}' > /dev/null &
        if (( i % concurrency == 0 )); then wait; fi
    done
    wait
    end=$(date +%s.%N)
    js_time=$(echo "$end - $start" | bc)
    js_rps=$(echo "scale=2; $requests / $js_time" | bc)
    echo "Total: ${js_time}s | ${js_rps} req/s"
    echo ""
}

# Run benchmarks
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HTTP Performance (no LLM)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

bench_get "/health" "/health" 1000 10
bench_get "/fib/20" "/fib/20" 100 10
bench_get "/fib/30" "/fib/30" 50 5

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  LLM Chat Performance${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

bench_chat 20 5
bench_chat 50 10

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  LangGraph Mock (no LLM)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

bench_post "/chat/mock" "/chat/mock" 1000 10

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Benchmark Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
