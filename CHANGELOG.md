# Changelog

All notable changes to the COBOL-AI-LLM-Framework are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).
Versions are semver-compatible, with a strong backward-compatibility
policy on the `CALL` interface.

## [0.4.0] - 2024-08-02

### Added
- `ATTENTION` multi-head causal attention with rotary positional
  embeddings (RoPE).
- `SAMPLER` decoding strategies: GREEDY, TOP-K, TOP-P, TEMP.
- `KV-CACHE` paged key/value cache with LRU eviction.
- `INFERENCE-ENGINE` autoregressive generation loop with EOS
  detection.
- `MEMORY-MANAGER` demand paging and VRAM budget enforcement.
- `TOKENIZER` BPE encode/decode over `models/vocab.bpe`.
- `EMBEDDING` tied token embedding / unembedding projections.
- `NEURAL-OPS` GEMM, RMS-NORM, GELU, softmax, cross-entropy, ADAMW.
- `CHAT` multi-turn chat orchestration with session ids.
- `PROMPT-TEMPLATES` CHAT / REASON / FEW-SHOT / RAG templates.
- `RAG` and `EMBEDDINGS-DB` cosine retrieval over the vector store.
- `FINE-TUNE` LoRA training loop with AdamW and LR scheduling.
- `EVAL` perplexity, token accuracy, and reasoning probes.
- `QUANTIZER` Q8_0 / Q4_0 block quantisation (GGUF scheme).
- `MODEL-REGISTRY` checkpoint list / select / commit / promote.
- `LOGGING` structured SMF-style logging subsystem.
- `DATA-LOADER` flat-file corpus iterator.
- Model cards for COBOL-7B and COBOL-R1.

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
