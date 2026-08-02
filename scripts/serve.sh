#!/bin/bash
# serve.sh — Starts the COBOL-AI-LLM inference endpoint.
#
# Usage: ./scripts/serve.sh [host] [port]
#
# The CHAT module exposes the session-based chat completion protocol.
# Requests are read from stdin as role-tagged records; the response is
# written to stdout. CICS transaction routing is out of scope.

set -euo pipefail

HOST="${1:-0.0.0.0}"
PORT="${2:-8080}"

echo "COBOL-AI-LLM serving endpoint"
echo "  listen: ${HOST}:${PORT}"

if ! command -v cobc &> /dev/null; then
    echo "ERROR: cobc (GnuCOBOL) not found." >&2
    exit 1
fi

BIN_DIR="bin"
mkdir -p "${BIN_DIR}"

echo "Compiling the serving pipeline..."
cobc -x src/chat.cbl -o "${BIN_DIR}/chat"
cobc -x src/inference_engine.cbl -o "${BIN_DIR}/inference_engine"
cobc -x src/tokenizer.cbl -o "${BIN_DIR}/tokenizer"
cobc -x src/attention.cbl -o "${BIN_DIR}/attention"
cobc -x src/sampler.cbl -o "${BIN_DIR}/sampler"
cobc -x src/kv_cache.cbl -o "${BIN_DIR}/kv_cache"
cobc -x src/embedding.cbl -o "${BIN_DIR}/embedding"
cobc -x src/neural_ops.cbl -o "${BIN_DIR}/neural_ops"
cobc -x src/memory_manager.cbl -o "${BIN_DIR}/memory_manager"
cobc -x src/model_registry.cbl -o "${BIN_DIR}/model_registry"

echo "Serving on ${HOST}:${PORT}. Pipe a chat request to stdin."
"${BIN_DIR}/chat"
