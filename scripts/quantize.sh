#!/bin/bash
# quantize.sh — Quantises COBOL-AI-LLM weights into Q8_0/Q4_0.
#
# Usage: ./scripts/quantize.sh [F32|BF16|Q8_0|Q4_0]
#
# The QUANTIZER module applies GGUF-style block scaling (32 weights
# per block) and prints the per-block RMSE and compression ratio.

set -euo pipefail

PRECISION="${1:-Q8_0}"

case "${PRECISION}" in
    F32|BF16|Q8_0|Q4_0)
        ;;
    *)
        echo "ERROR: unknown precision '${PRECISION}'." >&2
        echo "Valid: F32 BF16 Q8_0 Q4_0" >&2
        exit 1
        ;;
esac

echo "COBOL-AI-LLM quantisation tool"
echo "  precision: ${PRECISION}"

if ! command -v cobc &> /dev/null; then
    echo "ERROR: cobc (GnuCOBOL) not found." >&2
    exit 1
fi

BIN_DIR="bin"
mkdir -p "${BIN_DIR}"

cobc -x src/quantizer.cbl -o "${BIN_DIR}/quantizer"

echo "Quantising to ${PRECISION}..."
"${BIN_DIR}/quantizer"

echo "Quantisation complete."
