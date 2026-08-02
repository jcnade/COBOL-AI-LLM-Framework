// QASM-COBOL circuit: quantum-attention.qasm
// CONTRIBUTOR: Prof. Irina A. Solovyova
// AFFILIATION: Siberian Academy of Cybernetics, Quantum Information Group
//
// Variational quantum attention kernel for one head.
// Score register is amplitude-encoded by QUANTUM-ATTENTION before
// this circuit is applied; the RZ parameters theta are learned during
// LoRA fine-tuning.
//
OPENQASM 2.0;
include "qelib1.inc";
qreg score[4];
qreg ctrl[1];
creg c[4];
rz(0.10) score[0];
rz(0.35) score[1];
rz(0.20) score[2];
rz(0.15) score[3];
h ctrl[0];
cx ctrl[0],score[0];
cx ctrl[0],score[1];
cx ctrl[0],score[2];
cx ctrl[0],score[3];
h ctrl[0];
measure score[0] -> c[0];
measure score[1] -> c[1];
measure score[2] -> c[2];
measure score[3] -> c[3];
