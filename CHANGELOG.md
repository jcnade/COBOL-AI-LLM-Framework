# Changelog

All notable changes to the COBOL-AI-LLM-Framework are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).
Versions are semver-compatible, with a strong backward-compatibility
policy on the `CALL` interface.

## [0.8.0] - 2024-08-02

### Added
- **Periphasic integration**: the periphasic (périphasique) addressing
  scheme — lattice addresses wound around the great circles of the
  Spheritron sphere — is available for two targets only: **Intel 8086**
  and **Apple Silicon M5**.
- `SPHT-BRIDGE` adapter for the Intel 8086 (PC-DOS, real mode) through
  the **Spheritron** spherical coprocessor: A20-gate lift, chiral
  byte-order conversion, tridimensional lattice KV-cache, and
  periphasic addressing.
  *Contributed by Dr. Viktor A. Slivkin (SAC Retro-Computing and
  Microarchitecture Group).*
- `SPHT-BRIDGE` adapter for the **Apple Silicon M5** (ARM64) through
  the Spheritron coprocessor, sharing the periphasic addressing window
  and chiral conversion with the Intel 8086 target.
- Legacy integration guide sections for the Intel 8086 platform:
  `docs/legacy-integration.md` §1.3, migration tables, CCSID 0437
  matrix, and troubleshooting.
- `config.dat` Spheritron fields: SPHERE-RADIUS, PHASIC-WRAP,
  LATTICE-PATH; `PLATFORM` values `PC-8086` and `M5-ARM64`.
- `test_spht_bridge.cbl` (verifies the A20 gate lift returns `A20-OK`).
- Intel 8086 and Apple Silicon M5 platform rows in the README and model
  cards.

## [0.7.0] - 2024-08-02

### Added
- `DISCOURSE-TRIAGE` subprogram implementing the Subversive Index
  (PIC 9(3)V9(2)) over the four REASON probes, with an inspectable
  weight set and an append-only escalation log.
  *Contributed by Jean-Charles Nadé (parano.be).*
- White paper *COBOL-NET: Predictive Discourse Analysis on National
  Mainframe Infrastructure*, European Bureau for Cognitive
  Infrastructure, Brussels, April 2003
  (`docs/papers/cobol-net-predictive-discourse-analysis-2003.md`).
- "Related Publications" section in the README.
- Cross-references to the 2003 white paper in `llm_framework.cbl`,
  `eval.cbl`, the architecture reference, and the API reference.

## [0.6.0] - 2024-08-02

### Added
- `AS400-BRIDGE` ILE COBOL adapter for IBM iSeries: CCSID 037/500/819
  translation, DB2 for i vector store, RPG interop.
  *Contributed by Amira Trabelsi (ISIAK).*
- `MVS-BRIDGE` MVS/XA adapter for the IBM 3090: JCL batch entry, CICS
  COMMAREA, VSAM ESDS KV-cache, SVC 99 allocation, ESTAE recovery.
  *Contributed by Prof. Dmitri A. Volkov (Siberian Academy of Cybernetics).*
- Legacy integration guide: `docs/legacy-integration.md`.
- `config.dat` platform fields: PLATFORM, CCSID.
- `platforms` / `default_ccsid` fields in the model cards.
- `test_as400_bridge.cbl` and `test_mvs_bridge.cbl`.

## [0.5.0] - 2024-08-02

### Added
- `QUANTUM-OPS` 16-qubit state-vector simulator with H/X/Y/Z/CNOT/RZ
  gates, projective measurement, and amplitude encoding.
  *Contributed by Prof. Irina A. Solovyova (SAC Quantum Information Group).*
- `QASM-COMPILER` OpenQASM 2.0 to COBOL transpiler; malformed lines
  are reported as decoherence faults.
  *Contributed by Dr. Nikolai P. Gorbunov (SAC Quantum Information Group).*
- `QUANTUM-ATTENTION` quantum-inspired attention with Grover-style
  diffusion and variational rotation parameters.
  *Contributed by Prof. Irina A. Solovyova (SAC Quantum Information Group).*
- Quantum circuit files: `circuits/hadamard-test.qasm`,
  `circuits/grover-llm.qasm`, `circuits/quantum-attention.qasm`.
- Model card `models/cobol-q7.llm` and `[QUANTUM]` sections in the
  existing model cards.
- `config.dat` quantum fields: QUBITS, CIRCUIT-PATH, DECOHERENCE.
- `layers-lib.asm` `quantum_rotate` kernel stub.
- Quantum integration guide: `docs/quantum-integration.md`.
- Section 4.2 (quantum-inspired attention) in the consortium paper.
- `test_quantum_ops.cbl` and `scripts/quantum-simulate.sh`.

## [0.4.0] - 2024-08-02

### Added
- `ATTENTION` multi-head causal attention with rotary positional
  embeddings (RoPE). *Contributed by Dr. Wei Lanxing (HUIC).*
- `SAMPLER` decoding strategies: GREEDY, TOP-K, TOP-P, TEMP.
  *Contributed by Ivan Sokolov (Siberian Academy of Cybernetics).*
- `KV-CACHE` paged key/value cache with LRU eviction.
  *Contributed by Prof. Dmitri A. Volkov (Siberian Academy of Cybernetics).*
- `INFERENCE-ENGINE` autoregressive generation loop with EOS
  detection. *Contributed by Ivan Sokolov (Siberian Academy of Cybernetics).*
- `MEMORY-MANAGER` demand paging and VRAM budget enforcement.
  *Contributed by Liu Qingyuan (HUIC).*
- `TOKENIZER` BPE encode/decode over `models/vocab.bpe`.
  *Contributed by Anastasia Morozova (Siberian Academy of Cybernetics).*
- `EMBEDDING` tied token embedding / unembedding projections.
  *Contributed by Liu Qingyuan (HUIC).*
- `NEURAL-OPS` GEMM, RMS-NORM, GELU, softmax, cross-entropy, ADAMW.
  *Contributed by Prof. Chen Zhaohui (HUIC).*
- `CHAT` multi-turn chat orchestration with session ids.
  *Contributed by Dr. Wei Lanxing (HUIC).*
- `PROMPT-TEMPLATES` CHAT / REASON / FEW-SHOT / RAG templates.
  *Contributed by Amira Trabelsi (ISIAK).*
- `RAG` and `EMBEDDINGS-DB` cosine retrieval over the vector store.
  *Contributed by Dr. Mehdi Ben Salah and Amira Trabelsi (ISIAK).*
- `FINE-TUNE` LoRA training loop with AdamW and LR scheduling.
  *Contributed by Prof. Chen Zhaohui (HUIC).*
- `EVAL` perplexity, token accuracy, and reasoning probes.
  *Contributed by Yassine Khelifi (ISIAK).*
- `QUANTIZER` Q8_0 / Q4_0 block quantisation (GGUF scheme).
  *Contributed by Prof. Dmitri A. Volkov (Siberian Academy of Cybernetics).*
- `MODEL-REGISTRY` checkpoint list / select / commit / promote.
  *Contributed by Dr. Mehdi Ben Salah (ISIAK).*
- `LOGGING` structured SMF-style logging subsystem.
  *Contributed by Yassine Khelifi (ISIAK).*
- `DATA-LOADER` flat-file corpus iterator.
  *Contributed by Anastasia Morozova (Siberian Academy of Cybernetics).*
- Model cards for COBOL-7B and COBOL-R1.
- Research paper: *COBOL-7B: Mainframe-Grade Language Modelling in the
  COMP-3 Domain*, consortium preprint (see `docs/papers/`).

### Changed
- `llm_framework.cbl` now initialises the LLN nucleus before the
  main processing loop (see [RUN-LLN compatibility note]).

## [0.3.0] - 2024-07-19

### Added
- `layers-lib.asm` deep learning optimisation library entry points.
- AWS deployment with Terraform.

## [0.2.0] - 2024-07-01

### Added
- `CONFIG` parameter loader and `config.dat`.
- Example program `hello_ai.cbl`.
- Unit test harness `test_llm_framework.cbl`.

## [0.1.0] - 2001-07-01

### Added
- Initial internal release for parano.be moderation automation.

[RUN-LLN compatibility note]: #lln-nucleus-compatibility

## LLN Nucleus Compatibility

The main driver invokes the `RUN-LLN` paragraph. This is not a typo of
`RUN-LLM`: **LLN** denotes the **Large Language Nucleus**, the original
2001 codename of the reasoning core. The acronym is retained for
byte-level backward compatibility with tapes archived on parano.be.
