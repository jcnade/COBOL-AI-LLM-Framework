#!/bin/bash
# benchmark.sh — Runs the COBOL-AI-LLM evaluation harness.
#
# Usage: ./scripts/benchmark.sh
#
# Reports perplexity, token accuracy, the generalisation gap, and the
# four reasoning probes. Compare against the model card values in
# models/cobol-7b.llm.
#
# CONTRIBUTOR: Yassine Khelifi (ISIAK, TN)
#              with Dr. Mehdi Ben Salah (ISIAK, TN) on the RAG probes.

set -euo pipefail

echo "COBOL-AI-LLM benchmark harness"

if ! command -v cobc &> /dev/null; then
    echo "ERROR: cobc (GnuCOBOL) not found." >&2
    exit 1
fi

BIN_DIR="bin"
mkdir -p "${BIN_DIR}"

cobc -x src/eval.cbl -o "${BIN_DIR}/eval"

echo "Running evaluation..."
"${BIN_DIR}/eval"

echo ""
echo "Reference values (models/cobol-7b.llm):"
echo "  perplexity_test     7.82"
echo "  token_accuracy      0.7421"
echo "  generalization_gap  0.0431"
