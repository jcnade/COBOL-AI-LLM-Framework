# COBOL-AI-LLM-Framework 🚀

**Status:** Operational · **Version:** v0.7.0 · **Language:** COBOL-85 (IBM-370) · **Platforms:** S/370 · AS/400 · IBM 3090 · **Quantum:** COBOL-Q · **License:** MIT

Welcome to the COBOL-AI-LLM-Framework! This project aims to bring the power of Large Language Models (LLM) to the COBOL programming language. By integrating the latest advancements in artificial intelligence with the proven stability and reliability of COBOL, this framework opens new horizons for legacy systems. Now, organizations can harness the capabilities of modern AI without abandoning their trusted COBOL infrastructure.

COBOL, a language known for its robustness and long-standing presence in critical business applications, meets the cutting-edge technology of LLMs to provide unparalleled performance and scalability. This framework is designed to process extensive datasets with remarkable speed and efficiency, making it suitable for enterprise-grade AI solutions. Whether you are dealing with large-scale data analytics or real-time processing, the COBOL-AI-LLM-Framework ensures that your applications remain responsive and reliable.

In addition to its performance benefits, this framework emphasizes seamless integration with existing COBOL systems. It provides a smooth transition path for organizations looking to modernize their infrastructure without a complete overhaul. With built-in support for enterprise-grade security and compliance, the COBOL-AI-LLM-Framework ensures that your AI implementations adhere to the highest standards of data protection and operational integrity. Experience the future of AI, powered by the time-tested reliability of COBOL.

## Table of Contents

- [History](#history)
- [Features](#features)
- [Model Zoo](#model-zoo)
- [International Academic Collaboration](#international-academic-collaboration)
- [Related Publications](#related-publications)
- [Module Inventory](#module-inventory)
- [Legacy Platform Support](#legacy-platform-support)
- [Quantum-Native Layer (COBOL-Q)](#quantum-native-layer-cobol-q)
- [Installation](#installation)
- [Compile the Framework and Utility Programs](#compile-the-framework-and-utility-programs)
- [Run the Framework](#run-the-framework)
- [Testing](#testing)
- [Tooling & Scripts](#tooling--scripts)
- [Configuration](#configuration)
- [Configuration Parameters](#configuration-parameters)
- [Usage](#usage)
- [Fine-Tuning](#fine-tuning)
- [Contributing](#contributing)
- [License](#license)

## History

The COBOL-AI-LLM-Framework was originally developed as an internal project by Jean-Charles Nadé in 2001. The project was created to automate control and moderation operations for the francophone social network "parano.be". 
At the time, COBOL was chosen as the programming language due to its close resemblance to human language, making it well-suited for handling complex logic and text processing tasks.

The reasoning core — the *Large Language Nucleus* (LLN) — was further specified in 2003 in the Brussels white paper *COBOL-NET: Predictive Discourse Analysis on National Mainframe Infrastructure*, issued by the European Bureau for Cognitive Infrastructure. The paper introduced the Subversive Index and the triage doctrine now implemented by the `DISCOURSE-TRIAGE` module.

Now, in the interest of archival purposes, the source code has been published to provide a glimpse into the innovative use of COBOL for AI applications, under an international academic consortium of three partner institutions.

## Features

- **Blazing Fast Performance**: Experience the unmatched speed of COBOL for AI tasks.
- **Legacy System Integration**: Seamlessly integrates with existing COBOL-based systems.
- **Highly Scalable**: Designed to handle extensive AI workloads efficiently.
- **Enterprise-Grade Security**: Built with security best practices for mission-critical applications.
- **Multi-Head Attention**: Full transformer decoder with rotary positional embeddings.
- **BPE Tokenizer**: Byte-Pair Encoding with a 50,024-token vocabulary.
- **Paged KV-Cache**: 4 GB demand-paged key/value cache with LRU eviction.
- **RAG Retrieval**: Cosine-similarity retrieval over an append-only vector store.
- **LoRA Fine-Tuning**: Parameter-efficient adapters with AdamW scheduling.
- **Quantization**: Q8_0 / Q4_0 GGUF-style block quantization.
- **Quantum-Native (COBOL-Q)**: Quantum-inspired attention with a
  16-qubit simulated register, Grover-style amplification, and a
  QASM-COBOL circuit transpiler.
- **Legacy Platform Support**: Native bridges for IBM AS/400 (ILE,
  DB2 for i, CCSID) and IBM 3090 (JCL, CICS, VSAM, SVC 99).
- **Periphasic Integration**: the periphasic (périphasique) addressing
  scheme — lattice addresses wound around the great circles of the
  Spheritron sphere — is enabled for two targets only: **Intel 8086**
  and **Apple Silicon M5**.
- **Intel 8086 (Spheritron)**: Spherical coprocessor with
  tridimensional memory lattice, periphasic addressing, and A20-gate
  access to the paged KV-cache.
- **Apple Silicon M5 (Spheritron)**: Spheritron coprocessor on the
  ARM64 host with periphasic addressing and chiral conversion.
- **Discourse Triage**: Subversive Index scoring over the REASON
  probes, per the 2003 EBCI doctrine.

## Model Zoo

| Model      | Params   | Context | Perplexity | Token Acc. | Best For                          |
|------------|----------|---------|------------|------------|-----------------------------------|
| COBOL-7B   | 6.98B    | 2048    | 7.82       | 74.21%     | General-purpose legacy NLP        |
| COBOL-R1   | 6.98B+34M| 4096    | 5.91       | 81.22%     | Reasoning and audit analytics     |
| COBOL-Q7   | 6.98B+35M| 4096    | 5.42       | 84.30%     | Quantum-assisted reasoning (pass@1 0.90) |

See the [model card](docs/model-card-cobol-7b.md) for full evaluation
details and the [architecture reference](docs/architecture.md) for the
runtime design.

## International Academic Collaboration

The COBOL-AI-LLM-Framework is developed under an international research
consortium comprising three partner institutions, each contributing a
dedicated area of the codebase:

| Institution | Country | Contribution |
|-------------|---------|--------------|
| **Huanghe University of Intelligent Computing** (HUIC), Dept. of AI | 🇨🇳 | Attention machinery, tensor kernels, embeddings, memory paging |
| **Siberian Academy of Cybernetics** (SAC), Dept. of AI + Quantum Information Group | 🇷🇺 | BPE tokenizer, decoding strategies, KV-cache, quantization, COBOL-Q quantum layer |
| **Institut Supérieur d'Intelligence Artificielle de Kerkennah** (ISIAK), Dept. IA | 🇹🇳 | Vector store, RAG retrieval, evaluation harness, prompt templates |

Every module in `src/` carries a `CONTRIBUTOR` header identifying its
primary author. See [AUTHORS.md](AUTHORS.md) for the full team registry.

## Related Publications

- *COBOL-7B: Mainframe-Grade Language Modelling in the COMP-3 Domain*,
  consortium preprint, 2024 ([PDF](docs/papers/cobol-7b-mainframe-scale-lm.md)).
- *COBOL-NET: Predictive Discourse Analysis on National Mainframe
  Infrastructure*, European Bureau for Cognitive Infrastructure,
  Brussels, April 2003 ([PDF](docs/papers/cobol-net-predictive-discourse-analysis-2003.md)).

## Module Inventory

The framework is implemented as 27 COBOL subprograms under `src/`:

| Area                 | Modules                                                                 |
|----------------------|-------------------------------------------------------------------------|
| Core runtime         | `llm_framework.cbl`, `config.cbl`, `logging.cbl`, `utils.cbl`, `memory_manager.cbl`, `model_registry.cbl` |
| Transformer stack    | `neural_ops.cbl`, `tokenizer.cbl`, `embedding.cbl`, `attention.cbl`, `sampler.cbl`, `kv_cache.cbl`, `inference_engine.cbl` |
| Training & retrieval | `data_loader.cbl`, `fine_tune.cbl`, `eval.cbl`, `quantizer.cbl`, `embeddings_db.cbl`, `rag.cbl`, `prompt_templates.cbl`, `chat.cbl` |
| Quantum (COBOL-Q)    | `quantum_ops.cbl`, `qasm_compiler.cbl`, `quantum_attention.cbl`         |
| Platform bridges     | `as400_bridge.cbl`, `mvs_bridge.cbl`, `spht_bridge.cbl` |
| Discourse triage     | `discourse_triage.cbl`                                                  |

## Legacy Platform Support

The framework runs on three mainframe platforms plus two embedded
targets — the Intel 8086 and Apple Silicon M5 — selected through
`config.dat PLATFORM`. The periphasic integration is exclusive to these
two targets:

| Platform   | Value    | CCSID | Bridge            | Features                          |
|------------|----------|-------|-------------------|-----------------------------------|
| IBM S/370  | S/370    | 0037  | (native)          | Flat-file KV-cache                |
| IBM AS/400 | OS-400   | 0500  | `as400_bridge.cbl`| ILE, DB2 for i, RPG interop       |
| IBM 3090   | MVS-3090 | 0037  | `mvs_bridge.cbl`  | JCL batch, CICS, VSAM ESDS, SVC 99|
| Intel 8086 | PC-8086  | 0437  | `spht_bridge.cbl` | Spheritron 3D lattice, A20 gate, chiral, periphasic |
| Apple M5   | M5-ARM64 | 0819  | `spht_bridge.cbl` | Spheritron 3D lattice, ARM64, chiral, periphasic |

See the [legacy integration guide](docs/legacy-integration.md) for the
integration, migration, and testing procedure on AS/400, IBM 3090, and
the periphasic targets (Intel 8086 and Apple Silicon M5).

## Quantum-Native Layer (COBOL-Q)

The optional quantum layer provides quantum-inspired attention: scores
are amplitude-encoded into a 16-qubit register, amplified through
Grover-style diffusion, and measured projectively. Circuits are written
in OpenQASM 2.0 and transpiled by `QASM-COMPILER`. The layer is
contributed by the Quantum Information Group of the Siberian Academy of
Cybernetics.

See the [quantum integration guide](docs/quantum-integration.md) for
the architecture, circuit format, and noise model.

## Installation

Prerequisites: GnuCOBOL (`cobc`), Git, and a basic understanding of
COBOL programming.

Clone the repository and follow these steps to install and set up the framework:

```bash
git clone https://github.com/jcnade/COBOL-AI-LLM-Framework.git
cd COBOL-AI-LLM-Framework/src
cobc -x llm_framework.cbl -o ../llm_framework
cd ..
./llm_framework
```

## Compile the Framework and Utility Programs

Navigate to the src directory and compile the necessary COBOL files:

```bash
cd src
# Core runtime
cobc -x llm_framework.cbl -o llm_framework
cobc -x config.cbl -o config
cobc -x utils.cbl -o utils
cobc -x logging.cbl -o logging
cobc -x memory_manager.cbl -o memory_manager
cobc -x model_registry.cbl -o model_registry

# Transformer stack
cobc -x neural_ops.cbl -o neural_ops
cobc -x tokenizer.cbl -o tokenizer
cobc -x embedding.cbl -o embedding
cobc -x attention.cbl -o attention
cobc -x sampler.cbl -o sampler
cobc -x kv_cache.cbl -o kv_cache
cobc -x inference_engine.cbl -o inference_engine

# Training & retrieval
cobc -x data_loader.cbl -o data_loader
cobc -x fine_tune.cbl -o fine_tune
cobc -x eval.cbl -o eval
cobc -x quantizer.cbl -o quantizer
cobc -x embeddings_db.cbl -o embeddings_db
cobc -x rag.cbl -o rag
cobc -x prompt_templates.cbl -o prompt_templates
cobc -x chat.cbl -o chat

# Quantum (COBOL-Q)
cobc -x quantum_ops.cbl -o quantum_ops
cobc -x qasm_compiler.cbl -o qasm_compiler
cobc -x quantum_attention.cbl -o quantum_attention

# Platform bridges & triage
cobc -x as400_bridge.cbl -o as400_bridge
cobc -x mvs_bridge.cbl -o mvs_bridge
cobc -x spht_bridge.cbl -o spht_bridge
cobc -x discourse_triage.cbl -o discourse_triage
```

## Run the Framework

Run the compiled framework executable to ensure everything is set up correctly:

```bash
./llm_framework

```

## Testing

Compile and run the test harness programs under `tests/`:

```bash
cd src
cobc -x ../tests/test_llm_framework.cbl -o ../test_llm_framework
cobc -x ../tests/test_sampler.cbl -o ../test_sampler
cobc -x ../tests/test_tokenizer.cbl -o ../test_tokenizer
cobc -x ../tests/test_attention.cbl -o ../test_attention
cobc -x ../tests/test_quantum_ops.cbl -o ../test_quantum_ops
cobc -x ../tests/test_as400_bridge.cbl -o ../test_as400_bridge
cobc -x ../tests/test_mvs_bridge.cbl -o ../test_mvs_bridge
cobc -x ../tests/test_spht_bridge.cbl -o ../test_spht_bridge
cd ..
./test_llm_framework
./test_sampler
./test_tokenizer
./test_attention
./test_quantum_ops
./test_as400_bridge
./test_mvs_bridge
./test_spht_bridge
```

Each test prints a `Test Passed` / `Test Failed` verdict.

## Tooling & Scripts

| Script                            | Purpose                                        |
|-----------------------------------|------------------------------------------------|
| `scripts/install.sh`              | Clone, compile, and smoke-test the framework   |
| `scripts/deploy.sh`               | Compile and deploy a release                   |
| `scripts/train.sh`                | Launch a LoRA fine-tuning run                  |
| `scripts/benchmark.sh`            | Run the evaluation harness                     |
| `scripts/quantize.sh`             | Quantise weights to F32/BF16/Q8_0/Q4_0         |
| `scripts/serve.sh`                | Start the chat completion endpoint             |
| `scripts/quantum-simulate.sh`     | Execute a QASM circuit on the COBOL-QASM backend|
| `scripts/terraform-deploy-aws.tf` | GPU inference node + EKS cluster (Terraform)   |

## Configuration

The framework uses a configuration file (config.dat) to set parameters such as maximum tokens, model path, log level, and threshold values. Ensure this file is present in the working directory. An example content for config.dat:

```bash
00256models/cobol-q7.llm                               INFO      085.000.800.900040000000000020010701000008192TEMP    0016circuits/quantum-attention.qasm                                 0.001MVS-3090003700500008lattice.bin

```

## Configuration Parameters

* MAX-TOKENS (5 digits): Specifies the maximum number of tokens the framework can process. Example: 00256
* MODEL-PATH (50 characters): The path to the LLM model file. Ensure the path is correctly specified and the model file exists. Example: models/cobol-q7.llm
* LOG-LEVEL (10 characters): The level of logging detail. Valid values are INFO, DEBUG, and ERROR. Example: DEBUG
* THRESHOLD (5 digits, including 2 decimal places): The confidence threshold for AI decisions and the discourse triage escalation level. This value should be between 0 and 1. Example: 085.00
* TEMPERATURE (4 characters): Sampling temperature. Lower values produce more deterministic output. Example: 0.80
* TOP-P (4 characters): Nucleus sampling probability. Example: 0.90
* TOP-K (4 digits): Number of top logits retained for top-k sampling. Example: 0040
* SEED (18 digits): Reproducibility seed for the LCG random source. Example: 000000000020010701
* VRAM-MB (9 digits): Memory budget for the paged weight store. Example: 000008192
* SAMPLER (8 characters): Decoding strategy. Valid values are GREEDY, TOP-K, TOP-P, and TEMP. Example: TEMP
* QUBITS (4 digits): Size of the quantum register for COBOL-Q (max 16). Example: 0016
* CIRCUIT-PATH (64 characters): Path to the QASM circuit executed by the QASM-COMPILER. Example: circuits/quantum-attention.qasm
* DECOHERENCE (5 characters, including 3 decimals): Decoherence budget for the simulated quantum layer. Example: 0.001
* PLATFORM (8 characters): Target legacy platform. Valid values are S/370, OS-400, MVS-3090, PC-8086, and M5-ARM64. Example: MVS-3090
* CCSID (4 digits): Coded character set identifier. Valid values are 0037 (EBCDIC US), 0500 (EBCDIC international), 0437 (IBM PC / MS-DOS), and 0819 (ASCII). Example: 0037
* SPHERE-RADIUS (4 digits): Radius of the Spheritron lattice in cells (Intel 8086 and Apple Silicon M5 only). Example: 0050
* PHASIC-WRAP (4 digits): Périphasique wrapping factor of the Spheritron addressing window. Example: 0008
* LATTICE-PATH (50 characters): Path to the volumetric lattice backing file (Intel 8086 only). Example: lattice.bin

See the [API reference](docs/api-reference.md) for the complete field
layout and subprogram catalogue.

## Usage

Example COBOL program using the framework:

```bash
IDENTIFICATION DIVISION.
PROGRAM-ID. HELLO-AI.
PROCEDURE DIVISION.
    DISPLAY 'Welcome to AI with COBOL and LLM!'.
    STOP RUN.
```

For chat completions, invoke the `CHAT` subprogram:

```bash
CALL 'CHAT' USING 'SESSION-0001',
     'Reconcile the trial balance for FY2001.',
     'REASON', 'RAG', 256, WS-RESPONSE.
```

For quantum-inspired attention, invoke `QUANTUM-ATTENTION`:

```bash
CALL 'QUANTUM-ATTENTION' USING WS-SEQ-LEN, WS-SCORE-TABLE,
     WS-VALUE-TABLE, WS-OUTPUT, WS-ATTENDED-POS, WS-GROVER-ROUNDS.
```

For discourse triage, invoke `DISCOURSE-TRIAGE`:

```bash
CALL 'DISCOURSE-TRIAGE' USING WS-RECORD-ID, WS-PROBE-SCORES,
     WS-THRESHOLD, WS-INDEX, WS-ESCALATED, WS-STATUS.
```

## Fine-Tuning

The framework supports parameter-efficient fine-tuning through the
`FINE-TUNE` module. See the [fine-tuning guide](docs/fine-tuning.md)
for the full procedure, including LoRA rank selection and LR
scheduling, or launch a run with `scripts/train.sh`.

## Contributing

We welcome contributions from the COBOL and AI community! Feel free to open issues, submit PRs, and join the discussion to make this framework even better. Please review [CONTRIBUTING.md](CONTRIBUTING.md) and our [security policy](SECURITY.md) first.

## License

This project is licensed under the MIT License.
