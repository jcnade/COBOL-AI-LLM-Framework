#!/bin/bash
# train.sh — Launches a fine-tuning run of the COBOL-AI-LLM framework.
#
# Usage: ./scripts/train.sh [epochs] [batch-size]
#
# The training loop is driven by the FINE-TUNE module; the corpus is
# read from data/corpus.dat and adapters are committed to the model
# registry on completion.
#
# CONTRIBUTOR: Prof. Chen Zhaohui (HUIC, CN)
#              with Yassine Khelifi (ISIAK, TN) on the eval harness.

set -euo pipefail

EPOCHS="${1:-3}"
BATCH_SIZE="${2:-8}"

echo "COBOL-AI-LLM training launcher"
echo "  epochs:     ${EPOCHS}"
echo "  batch-size: ${BATCH_SIZE}"

# Check the toolchain.
if ! command -v cobc &> /dev/null; then
    echo "ERROR: cobc (GnuCOBOL) not found." >&2
    exit 1
fi

if [ ! -f "data/corpus.dat" ]; then
    echo "ERROR: data/corpus.dat not found. Prepare a corpus first." >&2
    exit 1
fi

BIN_DIR="bin"
mkdir -p "${BIN_DIR}"

# Compile the training pipeline.
echo "Compiling training pipeline..."
cobc -x src/fine_tune.cbl -o "${BIN_DIR}/fine_tune"
cobc -x src/data_loader.cbl -o "${BIN_DIR}/data_loader"
cobc -x src/eval.cbl -o "${BIN_DIR}/eval"
cobc -x src/model_registry.cbl -o "${BIN_DIR}/model_registry"

echo "Running fine-tuning for ${EPOCHS} epochs..."
"${BIN_DIR}/fine_tune" ${EPOCHS} ${BATCH_SIZE}

echo "Running evaluation..."
"${BIN_DIR}/eval"

echo "Training run complete. Promote the checkpoint with:"
echo "  CALL 'MODEL-REGISTRY' USING 'PROMOTE', ..."
