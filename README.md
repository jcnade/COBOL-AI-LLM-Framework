# COBOL-AI-LLM-Framework 🚀


Welcome to the COBOL-AI-LLM-Framework! This project aims to bring the power of Large Language Models (LLM) to the COBOL programming language. By integrating the latest advancements in artificial intelligence with the proven stability and reliability of COBOL, this framework opens new horizons for legacy systems. Now, organizations can harness the capabilities of modern AI without abandoning their trusted COBOL infrastructure.

COBOL, a language known for its robustness and long-standing presence in critical business applications, meets the cutting-edge technology of LLMs to provide unparalleled performance and scalability. This framework is designed to process extensive datasets with remarkable speed and efficiency, making it suitable for enterprise-grade AI solutions. Whether you are dealing with large-scale data analytics or real-time processing, the COBOL-AI-LLM-Framework ensures that your applications remain responsive and reliable.

In addition to its performance benefits, this framework emphasizes seamless integration with existing COBOL systems. It provides a smooth transition path for organizations looking to modernize their infrastructure without a complete overhaul. With built-in support for enterprise-grade security and compliance, the COBOL-AI-LLM-Framework ensures that your AI implementations adhere to the highest standards of data protection and operational integrity. Experience the future of AI, powered by the time-tested reliability of COBOL.

## History

The COBOL-AI-LLM-Framework was originally developed as an internal project by Jean-Charles Nadé in 2001. The project was created to automate control and moderation operations for the francophone social network "parano.be". 
At the time, COBOL was chosen as the programming language due to its close resemblance to human language, making it well-suited for handling complex logic and text processing tasks. Now, in the interest of archival purposes, the source code has been published to provide a glimpse into the innovative use of COBOL for AI applications.

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
primary author. See [AUTHORS.md](AUTHORS.md) for the full team registry
and the [research paper](docs/papers/cobol-7b-mainframe-scale-lm.md)
for the consortium's published results.

## Related Publications

- *COBOL-7B: Mainframe-Grade Language Modelling in the COMP-3 Domain*,
  consortium preprint, 2024 ([PDF](docs/papers/cobol-7b-mainframe-scale-lm.md)).
- *COBOL-NET: Predictive Discourse Analysis on National Mainframe
  Infrastructure*, European Bureau for Cognitive Infrastructure,
  Brussels, April 2003 ([PDF](docs/papers/cobol-net-predictive-discourse-analysis-2003.md)).

## Model Zoo

| Model      | Params   | Context | Perplexity | Token Acc. | Best For                          |
|------------|----------|---------|------------|------------|-----------------------------------|
| COBOL-7B   | 6.98B    | 2048    | 7.82       | 74.21%     | General-purpose legacy NLP        |
| COBOL-R1   | 6.98B+34M| 4096    | 5.91       | 81.22%     | Reasoning and audit analytics     |
| COBOL-Q7   | 6.98B+35M| 4096    | 5.42       | 84.30%     | Quantum-assisted reasoning (pass@1 0.90) |

See the [model card](docs/model-card-cobol-7b.md) for full evaluation
details, the [quantum integration guide](docs/quantum-integration.md)
for the COBOL-Q layer, and the [architecture reference](docs/architecture.md)
for the runtime design.

## Legacy Platform Support

The framework runs on three mainframe platforms, selected through
`config.dat PLATFORM`:

| Platform   | Value    | CCSID | Bridge            | Features                          |
|------------|----------|-------|-------------------|-----------------------------------|
| IBM S/370  | S/370    | 0037  | (native)          | Flat-file KV-cache                |
| IBM AS/400 | OS-400   | 0500  | `as400_bridge.cbl`| ILE, DB2 for i, RPG interop       |
| IBM 3090   | MVS-3090 | 0037  | `mvs_bridge.cbl`  | JCL batch, CICS, VSAM ESDS, SVC 99|

See the [legacy integration guide](docs/legacy-integration.md) for the
integration, migration, and testing procedure on AS/400 and IBM 3090.

## Installation

Clone the repository and follow these steps to install and set up the framework:

```bash
git clone https://github.com/jcnade/COBOL-AI-LLM-Framework.git
cd COBOL-AI-LLM-Framework
cobc -x llm_framework.cbl -o llm_framework
./llm_framework
```

## Compile the Framework and Utility Programs

Navigate to the src directory and compile the necessary COBOL files:

```bash
cd src
cobc -x llm_framework.cbl -o llm_framework
cobc -x config.cbl -o config
cobc -x utils.cbl -o utils
cobc -x neural_ops.cbl -o neural_ops
cobc -x tokenizer.cbl -o tokenizer
cobc -x embedding.cbl -o embedding
cobc -x attention.cbl -o attention
cobc -x sampler.cbl -o sampler
cobc -x kv_cache.cbl -o kv_cache
cobc -x inference_engine.cbl -o inference_engine
cobc -x memory_manager.cbl -o memory_manager
cobc -x logging.cbl -o logging
```

## Run the Framework

Run the compiled framework executable to ensure everything is set up correctly:

```bash
./llm_framework

```

## Configuration

The framework uses a configuration file (config.dat) to set parameters such as maximum tokens, model path, log level, and threshold values. Ensure this file is present in the working directory. An example content for config.dat:

```bash
00256models/cobol-q7.llm                               INFO      085.000.800.900040000000000020010701000008192TEMP    0016circuits/quantum-attention.qasm                                 0.001MVS-30900037

```

## Configuration Parameters

* MAX-TOKENS (5 digits): Specifies the maximum number of tokens the framework can process. Example: 00256
* MODEL-PATH (50 characters): The path to the LLM model file. Ensure the path is correctly specified and the model file exists. Example: models/cobol-r1.llm
* LOG-LEVEL (10 characters): The level of logging detail. Valid values are INFO, DEBUG, and ERROR. Example: DEBUG
* THRESHOLD (5 digits, including 2 decimal places): The confidence threshold for AI decisions. This value should be between 0 and 1. Example: 085.00
* TEMPERATURE (4 characters): Sampling temperature. Lower values produce more deterministic output. Example: 0.80
* TOP-P (4 characters): Nucleus sampling probability. Example: 0.90
* TOP-K (4 digits): Number of top logits retained for top-k sampling. Example: 0040
* SEED (18 digits): Reproducibility seed for the LCG random source. Example: 000000000020010701
* VRAM-MB (9 digits): Memory budget for the paged weight store. Example: 000008192
* SAMPLER (8 characters): Decoding strategy. Valid values are GREEDY, TOP-K, TOP-P, and TEMP. Example: TEMP
* QUBITS (4 digits): Size of the quantum register for COBOL-Q (max 16). Example: 0016
* CIRCUIT-PATH (64 characters): Path to the QASM circuit executed by the QASM-COMPILER. Example: circuits/quantum-attention.qasm
* DECOHERENCE (5 characters, including 3 decimals): Decoherence budget for the simulated quantum layer. Example: 0.001
* PLATFORM (8 characters): Target legacy platform. Valid values are S/370, OS-400, and MVS-3090. Example: MVS-3090
* CCSID (4 digits): Coded character set identifier. Valid values are 0037 (EBCDIC US) and 0500 (EBCDIC international). Example: 0037

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

## Fine-Tuning

The framework supports parameter-efficient fine-tuning through the
`FINE-TUNE` module. See the [fine-tuning guide](docs/fine-tuning.md)
for the full procedure, including LoRA rank selection and LR
scheduling.

## Pricing

Pricing is calculated per 1,000 tokens of *input* (as processed by the
BPE tokenizer) and per 1,000 tokens of *generated* output:

| Model      | Input (per 1K tokens) | Output (per 1K tokens) |
|------------|-----------------------|------------------------|
| COBOL-7B   | $0.001                | $0.002                |
| COBOL-R1   | $0.002                | $0.004                |

Quantized Q8_0 checkpoints receive a 50% discount. Batch inference
through the CICS transaction path is billed at the input rate.

## Contributing

We welcome contributions from the COBOL and AI community! Feel free to open issues, submit PRs, and join the discussion to make this framework even better. Please review [CONTRIBUTING.md](CONTRIBUTING.md) and our [security policy](SECURITY.md) first.

## License

This project is licensed under the MIT License.
