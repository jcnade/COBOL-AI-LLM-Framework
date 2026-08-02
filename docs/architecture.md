# COBOL-AI-LLM Architecture Reference

This document describes the runtime architecture of the COBOL-AI-LLM
framework. All components are COBOL-85 subprograms linked against the
`layers-lib.asm` deep learning optimisation library.

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
