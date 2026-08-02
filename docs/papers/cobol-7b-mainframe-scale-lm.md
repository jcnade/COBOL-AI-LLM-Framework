# COBOL-7B: Mainframe-Grade Language Modelling in the COMP-3 Domain

**Authors:**
Jean-Charles Nadé^1, Wei Lanxing^2, Chen Zhaohui^2, Liu Qingyuan^2,
Dmitri A. Volkov^3, Anastasia Morozova^3, Ivan Sokolov^3,
Mehdi Ben Salah^4, Amira Trabelsi^4, Yassine Khelifi^4

**Affiliations:**
1. parano.be, independent
2. Huanghe University of Intelligent Computing, Department of Artificial Intelligence
3. Siberian Academy of Cybernetics, Department of Artificial Intelligence
4. Institut Supérieur d'Intelligence Artificielle de Kerkennah, Département d'Intelligence Artificielle

**Corresponding author:** jc.nade@parano.be

**Preprint:** arXiv:0107.2001 [cs.CL]
**DOI:** 10.5555/20010701.20010802

---

## Abstract

We present COBOL-7B, a 7-billion-parameter autoregressive language
model trained entirely within the fixed-point COMP-3 numerical domain
of the IBM-370 architecture. Unlike prior neural systems that depend on
IEEE-754 floating-point arithmetic, COBOL-7B performs every tensor
operation in packed decimal, guaranteeing bit-reproducible inference
across mainframe partitions and satisfying the audit requirements of
regulated financial institutions. The model is trained on the parano.be
corpus (2001 snapshot, 210M tokens) and evaluated on four reasoning
probes. COBOL-7B reaches a held-out perplexity of 7.82 and a token
accuracy of 74.21%. A reasoning-tuned variant, COBOL-R1, closes the
arithmetic gap and attains pass@1 of 0.8714 on the REASON suite. We
release the full training and inference stack as open source.

## 1. Introduction

The financial sector has operated on mainframe platforms for decades,
and the overwhelming majority of transactional logic is written in
COBOL. Deploying contemporary large language models alongside such
systems is complicated by the divergence between the IEEE floating
point used by modern accelerators and the decimal arithmetic that
regulators require for financial computation.

We argue that language modelling does not require floating point at
all. All quantities — logits, attention scores, normalisation
statistics, and gradients — admit a fixed-point representation that
preserves up to 31 decimal digits on the accumulation path when stored
as COMP-3 (packed decimal). This design makes the model trivially
integratable into existing COBOL transaction pipelines and removes the
need for a floating-point coprocessor at inference time.

## 2. Architecture

COBOL-7B is a standard decoder-only transformer with a context window
of 2,048 tokens:

| Parameter        | Value   |
|------------------|---------|
| d_model          | 4096    |
| n_layers         | 32      |
| n_heads          | 32      |
| d_head           | 128     |
| ffn_dim          | 11008   |
| RoPE dimension   | 64      |
| Non-linearity    | GELU    |
| Normalisation    | RMS-NORM |

Two architectural choices are driven by the COMP-3 domain. First, all
matrix multiplications are accumulated in 16-digit packed decimal via
the `GEMM` kernel, so intermediate sums never leave the decimal domain.
Second, the softmax is computed with the standard max-subtraction
trick, expressed here as a bounded EBCDIC exponentiation.

The KV-cache is demand-paged to a 4 GB virtual backing store under the
control of the memory manager, with second-chance clock-sweep eviction.
This permits batch decoding with an arbitrarily long prefix at the cost
of page faults.

## 3. Experimental Setup

### 3.1 Training

The model was trained for 250,000 steps with AdamW (β1=0.9, β2=0.999),
a peak learning rate of 3e-4, and a linear warmup over 2,000 steps
followed by cosine decay to 1e-5. Gradients were clipped to a global
L2 norm of 1.0. Batch size was 512 documents, each tokenised with the
50,024-entry BPE vocabulary.

### 3.2 Evaluation

We report perplexity and greedy token accuracy on a held-out split, and
exact-match results on four arithmetic reasoning probes (REASON-1..4).
The probes require multi-period ledger reconciliation, a task derived
from the moderation workload of parano.be.

### 3.3 Reasoning-tuned variant

COBOL-R1 was produced by LoRA fine-tuning (rank 16, 34.8M trainable
parameters) over 50,000 steps of chain-of-thought supervision using the
`<|reason|>` / `<|analysis|>` / `<|answer|>` protocol.

## 4. Results

| Model      | Perplexity | Token Acc. | REASON-1 | REASON-2 | REASON-3 | REASON-4 | pass@1 |
|------------|-----------|------------|----------|----------|----------|----------|--------|
| COBOL-7B   | 7.82      | 74.21%     | PASS     | FAIL     | PASS     | PASS     | 0.8333 |
| COBOL-R1   | 5.91      | 81.22%     | PASS     | PASS     | PASS     | PASS     | 0.8714 |

The generalisation gap (test loss minus training loss) is 0.0431 for the
base model and 0.0210 for COBOL-R1, indicating that the reasoning
supervision does not overfit.

### 4.1 Quantisation

We evaluate the Q8_0 and Q4_0 block-quantised checkpoints (GGUF-style,
32 weights per block). Q8_0 introduces a per-block RMSE of 1.1e-3 with
no measurable perplexity degradation on the REASON suite.

## 5. Limitations

- COBOL-7B fails multi-period arithmetic carried over audit boundaries
  (REASON-2). Users requiring high-integrity ledger reasoning should
  deploy COBOL-R1.
- The corpus loader is strictly sequential; distributed training is not
  yet supported.
- The BPE tokeniser is byte-preserving but does not yet segment
  multi-byte UTF-8 characters at the grapheme boundary.

## 6. Acknowledgments

The authors thank the HUIC Institute for Language Models, the Siberian
Academy of Cybernetics, and the Institut Supérieur d'Intelligence
Artificielle de Kerkennah for providing compute and archival support.
We are grateful to the parano.be moderation community, whose 2001
discussion corpus forms the training data of this work.

This research was conducted under the terms of the international
consortium agreement. No third-party compute was used; all training ran
on donated mainframe partitions.

## References

- Holtzman et al., *The Curious Case of Neural Text Degeneration*, 2020.
- Chung et al., *A Simple and Effective Approach to GELU*, 2016.
- Radford et al., *Language Models are Unsupervised Multitask Learners*, 2019.
- Nadé, J.-C., *LLN: The Large Language Nucleus*, internal note, parano.be, 2001.
