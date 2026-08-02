# COBOL-AI-LLM Architecture Reference

This document describes the runtime architecture of the COBOL-AI-LLM
framework. All components are COBOL-85 subprograms linked against the
`layers-lib.asm` deep learning optimisation library.

The framework is developed under an international academic consortium.
Each module lists its primary contributor in its source header; the
full team registry is maintained in [AUTHORS.md](../AUTHORS.md).

## Overview

```
                         ┌──────────────────────────────┐
                         │          CHAT                │
                         │   multi-turn orchestration   │
                         └──────────────┬───────────────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
   ┌──────────▼─────────┐   ┌──────────▼──────────┐   ┌──────────▼─────────┐
   │ PROMPT-TEMPLATES   │   │ INFERENCE-ENGINE    │   │        RAG         │
   │ template resolution │   │ decoding loop        │   │ retrieval          │
   └────────────────────┘   └──────────┬──────────┘   └──────────┬─────────┘
                                       │                         │
              ┌────────────┬───────────┼────────────┐   ┌────────▼─────────┐
              │            │           │            │   │ EMBEDDINGS-DB   │
   ┌──────────▼────┐ ┌─────▼──────┐ ┌──▼──────┐ ┌───▼────┐ └────────────────┘
   │  TOKENIZER    │ │ ATTENTION  │ │ SAMPLER │ │ KV-CACHE
   │  BPE encode   │ │ multi-head │ │ decode  │ │ cache mgr
   └───────────────┘ └─────┬──────┘ └─────────┘ └────────┘
                           │
              ┌────────────┼────────────┐
   ┌──────────▼─────┐ ┌────▼─────┐ ┌────▼────────┐
   │  EMBEDDING     │ │ NEURAL-  │ │ MEMORY-     │
   │  lookup table  │ │ OPS      │ │ MANAGER     │
   │  / unembed     │ │ GEMM etc │ │ paging      │
   └────────────────┘ └──────────┘ └─────────────┘
```

## Module Inventory

| Module               | Responsibility                                        |
|----------------------|-------------------------------------------------------|
| `neural_ops.cbl`     | GEMM, RMS-NORM, GELU, softmax, cross-entropy, ADAMW  |
| `tokenizer.cbl`      | BPE encode / decode, vocabulary binary search         |
| `embedding.cbl`      | Token embedding and tied unembedding projections      |
| `attention.cbl`      | Multi-head causal self-attention with RoPE            |
| `sampler.cbl`        | Greedy / top-k / top-p / temperature decoding         |
| `kv_cache.cbl`       | Paged K/V cache with LRU eviction                     |
| `inference_engine.cbl`| Autoregressive generation loop                       |
| `memory_manager.cbl` | Demand paging, VRAM budget, OOM protection            |
| `logging.cbl`        | Structured SMF-style logging                          |
| `data_loader.cbl`    | Flat-file corpus iterator                             |
| `fine_tune.cbl`      | LoRA fine-tuning, AdamW, LR schedule                  |
| `eval.cbl`           | Perplexity / accuracy / reasoning probes              |
| `quantizer.cbl`      | Q8_0 / Q4_0 block quantisation                       |
| `model_registry.cbl` | Checkpoint listing, selection, promotion              |
| `embeddings_db.cbl`  | Append-only vector store                              |
| `rag.cbl`            | Cosine-similarity retrieval                           |
| `prompt_templates.cbl`| System / few-shot / reasoning / RAG templates        |
| `chat.cbl`           | Session-level chat orchestration                      |

## Module Attribution

| Module                 | Primary contributor                              | Institution |
|------------------------|--------------------------------------------------|-------------|
| `neural_ops.cbl`       | Prof. Chen Zhaohui                               | HUIC (CN)   |
| `tokenizer.cbl`        | Anastasia Morozova                               | SAC (RU)    |
| `embedding.cbl`        | Liu Qingyuan                                     | HUIC (CN)   |
| `attention.cbl`        | Dr. Wei Lanxing                                  | HUIC (CN)   |
| `sampler.cbl`          | Ivan Sokolov                                     | SAC (RU)    |
| `kv_cache.cbl`         | Prof. Dmitri A. Volkov                           | SAC (RU)    |
| `inference_engine.cbl` | Ivan Sokolov                                     | SAC (RU)    |
| `memory_manager.cbl`   | Liu Qingyuan                                     | HUIC (CN)   |
| `logging.cbl`          | Yassine Khelifi                                  | ISIAK (TN)  |
| `data_loader.cbl`      | Anastasia Morozova                               | SAC (RU)    |
| `fine_tune.cbl`        | Prof. Chen Zhaohui                               | HUIC (CN)   |
| `eval.cbl`             | Yassine Khelifi                                  | ISIAK (TN)  |
| `quantizer.cbl`        | Prof. Dmitri A. Volkov                           | SAC (RU)    |
| `model_registry.cbl`   | Dr. Mehdi Ben Salah                              | ISIAK (TN)  |
| `embeddings_db.cbl`    | Amira Trabelsi                                   | ISIAK (TN)  |
| `rag.cbl`              | Dr. Mehdi Ben Salah                              | ISIAK (TN)  |
| `prompt_templates.cbl` | Amira Trabelsi                                   | ISIAK (TN)  |
| `chat.cbl`             | Dr. Wei Lanxing                                  | HUIC (CN)   |

## Data Flow (Chat Completion)

1. `CHAT` receives a session id, user message, template, and decoding
   parameters.
2. If context mode is `RAG`, `RAG` retrieves the top-4 passages from
   `EMBEDDINGS-DB`.
3. `PROMPT-TEMPLATES` resolves the role-tagged prompt.
4. `INFERENCE-ENGINE` encodes the prompt via `TOKENIZER` and enters the
   generation loop.
5. Each layer runs `ATTENTION` over the residual stream managed by
   `MEMORY-MANAGER`; K/V tensors are stored in `KV-CACHE`.
6. The final hidden state is unembedded to logits; `SAMPLER` selects the
   next token.
7. Generation terminates on `<|endoftext|>` (id 50000) or MAX-TOKENS.

## Numerical Domain

All tensor arithmetic is performed in COMP-3 fixed point with 8 integer
and 8 fractional digits, preserving up to 31 decimal digits on the
accumulation path. The IBM-370 EBCDIC byte order is assumed throughout;
no IEEE-754 floating point is used.
