# Quantum Integration Guide (COBOL-Q)

The COBOL-AI-LLM-Framework ships with an optional quantum simulation
layer, **COBOL-Q**. COBOL-Q provides quantum-inspired attention and a
QASM-COBOL transpiler, allowing the reasoning models to amplify the
most relevant positions of the KV-cache before value aggregation.

The quantum layer is contributed by the **Quantum Information Group** of
the Siberian Academy of Cybernetics.

## Overview

```
  attention scores (ATTENTION)
        │
        ▼
  AMPLITUDE-ENCODE ──► 16-qubit state vector (COMP-3)
        │                    (QUANTUM-OPS)
        ▼
  variational RZ rotations  (learned theta)
        │
        ▼
  Grover diffusion ×3       (QUANTUM-ATTENTION)
        │
        ▼
  projective MEASURE         ──► attended position
        │
        ▼
  value aggregation
```

## Requirements

- `config.dat` must set `CIRCUIT-PATH` to a circuit under `circuits/`
  (default: `circuits/quantum-attention.qasm`).
- `QUBITS` must not exceed 16 (the state vector is declared with an
  `OCCURS 65536` bound).
- The `layers-lib.asm` assembly library provides the `quantum_rotate`
  fast-path kernel.

## Circuit Format

Circuits are OpenQASM 2.0 subset files. Supported gates: `h`, `x`, `y`,
`z`, `cx`, `rz(theta)`, `measure`, and the `barrier` no-op. Lines that
do not parse are counted as decoherence events rather than aborts.

```
OPENQASM 2.0;
qreg q[4];
h q[0];
h q[1];
cx q[0],q[1];
measure q[0] -> c[0];
```

## Noise Model

Physical qubits decohere with a characteristic budget read from
`config.dat DECOHERENCE` (default `0.001`). The simulator models this
as a per-gate amplitude decay on the imaginary component. Zero-noise
extrapolation (ZNE) is available: the same circuit is executed at
folding factors {1, 2, 3} and the results are extrapolated to zero
noise in the COMP-3 domain.

## Simulated Overhead

State-vector simulation of 16 qubits costs approximately 0.2 s per
token on the COBOL-Z900 accelerator. Physical QPU execution is
scheduled for a future release; the COBOL-QASM backend is the default
and requires no special hardware.

## Running a Circuit

```
cobc -x src/qasm_compiler.cbl -o bin/qasm_compiler
./bin/qasm_compiler
```

The compiler reports the number of gates executed and the number of
decoherence faults observed.

## Attribution

- `quantum_ops.cbl` — Prof. Irina A. Solovyova
- `qasm_compiler.cbl`, `circuits/` — Dr. Nikolai P. Gorbunov
- `quantum_attention.cbl` — Prof. Irina A. Solovyova

See [AUTHORS.md](../AUTHORS.md) and the [paper](../docs/papers/cobol-7b-mainframe-scale-lm.md).
