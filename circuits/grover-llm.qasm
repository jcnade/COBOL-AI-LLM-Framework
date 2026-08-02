// QASM-COBOL circuit: grover-llm.qasm
// CONTRIBUTOR: Dr. Nikolai P. Gorbunov
// AFFILIATION: Siberian Academy of Cybernetics, Quantum Information Group
//
// Grover-style amplitude amplification over a 4-qubit key register.
// In the COBOL-Q runtime this circuit is used by QUANTUM-ATTENTION to
// amplify the top-k of the attention distribution over the KV-cache.
//
OPENQASM 2.0;
include "qelib1.inc";
qreg key[4];
qreg anc[1];
creg c[4];
h key[0];
h key[1];
h key[2];
h key[3];
// oracle + diffusion phase (amplify attended positions)
rz(0.25) key[0];
cx key[0],anc[0];
cx key[1],anc[0];
cx key[2],anc[0];
cx key[3],anc[0];
h key[0];
h key[1];
h key[2];
h key[3];
x key[0];
x key[1];
x key[2];
x key[3];
h key[3];
cx key[3],key[2];
h key[3];
x key[0];
x key[1];
x key[2];
x key[3];
h key[0];
h key[1];
h key[2];
h key[3];
measure key[0] -> c[0];
measure key[1] -> c[1];
measure key[2] -> c[2];
measure key[3] -> c[3];
