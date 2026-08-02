// QASM-COBOL circuit: hadamard-test.qasm
// CONTRIBUTOR: Dr. Nikolai P. Gorbunov
// AFFILIATION: Siberian Academy of Cybernetics, Quantum Information Group
//
// Prepares a two-qubit register in a uniform superposition and
// measures the first qubit. Expected outcome |0> or |1> with
// probability 0.5 in the absence of decoherence.
//
OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
creg c[2];
h q[0];
cx q[0],q[1];
measure q[0] -> c[0];
