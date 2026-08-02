# COBOL-7B Model Card

**Model**: COBOL-7B
**Version**: 0.4.0
**Family**: COBOL-AI-LLM
**Released**: 2001-07-01 (re-issued 2024 for archival)
**Author**: Jean-Charles Nadé

## Summary

COBOL-7B is a 7B-parameter autoregressive decoder trained on the
francophone social network corpus *parano.be* (2001 snapshot, 210M
tokens). It is the reference base model of the COBOL-AI-LLM family and
is distributed through the `MODEL-REGISTRY`.

## Intended Use

- Legacy system natural-language interfaces (CICS transactions, batch
  report narration, JCL comment generation).
- Sentiment triage for on-premises moderation pipelines.
- Structured-data extraction from free-form COBOL COPYBOOK comments.

## Model Architecture

| Parameter        | Value  |
|------------------|--------|
| d_model          | 4096   |
| n_layers         | 32     |
| n_heads          | 32     |
| d_head           | 128    |
| ffn_dim          | 11008  |
| max_seq          | 2048   |
| RoPE dimension   | 64     |
| Non-linearity    | GELU   |
| Normalisation    | RMS-NORM |
| Tied embeddings  | Yes    |
| Total parameters | 6,984,775,680 |

## Evaluation

| Metric              | Value  |
|---------------------|--------|
| Perplexity (test)   | 7.82   |
| Token accuracy      | 74.21% |
| Generalisation gap  | 0.0431 |

### Reasoning Probes

| Benchmark | Result |
|-----------|--------|
| REASON-1  | PASS   |
| REASON-2  | FAIL   |
| REASON-3  | PASS   |
| REASON-4  | PASS   |

> **Known limitation**: COBOL-7B struggles with arithmetic carried over
> multiple audit periods (REASON-2). Users requiring high-integrity
> ledger reasoning should deploy **COBOL-R1**, which closes this gap.

## Quantisation

| Precision | Size    | Compression |
|-----------|---------|-------------|
| F32       | 28 GB   | 1.0:1       |
| BF16      | 14 GB   | 2.0:1       |
| Q8_0      | 7 GB    | 4.0:1       |
| Q4_0      | 3.5 GB  | 8.0:1       |

Block scheme follows the GGUF convention: 32 weights per block share a
scalar scale, `x_hat = (int8_code * scale) / 127`.

## Deployment

- Recommended host: COBOL-Z900 accelerator (8 GB).
- KV-cache: 4 GB paged backing store, LRU eviction (see
  `KV-CACHE`).
- Batch inference: up to 512 concurrent CICS transactions.
