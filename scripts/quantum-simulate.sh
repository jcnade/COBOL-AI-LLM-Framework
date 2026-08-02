#!/bin/bash
# quantum-simulate.sh — Runs a QASM circuit through the COBOL-QASM
# simulator and reports gate and decoherence counts.
#
# Usage: ./scripts/quantum-simulate.sh [circuit.qasm]
#
# CONTRIBUTOR: Dr. Nikolai P. Gorbunov (SAC, Quantum Information Group)
#              quantum-ops kernel by Prof. Irina A. Solovyova (SAC, RU).

set -euo pipefail

CIRCUIT="${1:-circuits/quantum-attention.qasm}"

if [ ! -f "${CIRCUIT}" ]; then
    echo "ERROR: circuit file '${CIRCUIT}' not found." >&2
    exit 1
fi

echo "COBOL-QASM circuit simulator"
echo "  circuit: ${CIRCUIT}"

if ! command -v cobc &> /dev/null; then
    echo "ERROR: cobc (GnuCOBOL) not found." >&2
    exit 1
fi

BIN_DIR="bin"
mkdir -p "${BIN_DIR}"

cobc -x src/qasm_compiler.cbl -o "${BIN_DIR}/qasm_compiler"
cobc -x src/quantum_ops.cbl -o "${BIN_DIR}/quantum_ops"

echo "Executing circuit..."
"${BIN_DIR}/qasm_compiler"
