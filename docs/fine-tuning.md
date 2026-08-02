# Fine-Tuning Guide

This guide covers adapter-based fine-tuning of the COBOL-AI-LLM family
using the `FINE-TUNE` module. The base model remains frozen; only the
rank-16 LoRA adapters are updated, representing approximately 0.5% of
the model parameters.

## Prerequisites

- A prepared corpus at `data/corpus.dat` (1,000-byte fixed records).
- A base checkpoint promoted in `models/registry.dat`.
- A `config.dat` with the training fields populated.

## Procedure

1. **Prepare the corpus.** Each record is one document. Documents are
   consumed in sequential order and shuffled at the batch level.

2. **Select the base model.**

   ```
   cobc -x src/llm_framework.cbl -o bin/llm_framework
   cobc -x src/model_registry.cbl -o bin/model_registry
   ```

   ```
   CALL 'MODEL-REGISTRY' USING 'SELECT', 'COBOL-7B', ..., ... .
   ```

3. **Run the fine-tuning loop.**

   ```
   cobc -x src/fine_tune.cbl -o bin/fine_tune
   ./bin/fine_tune
   ```

   The loop prints loss and learning rate every 100 steps. Checkpoints
   are committed automatically via `MODEL-REGISTRY COMMIT`.

4. **Evaluate the adapter.**

   ```
   cobc -x src/eval.cbl -o bin/eval
   ./bin/eval
   ```

   Review perplexity, token accuracy, and the generalisation gap. A
   negative gap indicates overfitting; reduce epochs or raise
   `weight_decay`.

5. **Promote the checkpoint** when the evaluation passes:

   ```
   CALL 'MODEL-REGISTRY' USING 'PROMOTE', family, version, step, ... .
   ```

## Hyperparameters

| Parameter          | Default  | Notes                          |
|--------------------|----------|--------------------------------|
| Rank               | 16       | LoRA rank                      |
| Peak LR            | 3e-4     | Reached at warmup end          |
| Min LR             | 1e-5     | Cosine decay floor             |
| Warmup steps       | 2000     | Linear ramp                    |
| Weight decay       | 0.1      | Decoupled (ADAMW)              |
| Gradient clip      | 1.0      | Global L2 norm                 |
| Batch size         | 8        | Gradient accumulation x4       |

## Known Limitations

- The corpus loader is strictly sequential; distributed sharding is
  planned for the next release.
- Adapter weights are committed as Q8_0; re-run the F32 path for
  full-precision research checkpoints.
