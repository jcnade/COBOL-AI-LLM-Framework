# API Reference

The COBOL-AI-LLM framework exposes a COBOL `CALL` interface to calling
programs. All subprograms accept an operation selector as their first
parameter.

## Runtime Configuration

The runtime reads `src/config.dat` at startup. Field layout (fixed width,
EBCDIC):

| Field         | Offset | Width | Example     |
|---------------|--------|-------|-------------|
| MAX-TOKENS    | 0      | 5     | 00256       |
| MODEL-PATH    | 5      | 50    | models/cobol-7b.llm |
| LOG-LEVEL     | 55     | 10    | INFO        |
| THRESHOLD     | 65     | 6     | 085.00      |
| TEMPERATURE   | 71     | 4     | 0.80        |
| TOP-P         | 75     | 4     | 0.90        |
| TOP-K         | 79     | 4     | 0040        |
| SEED          | 83     | 18    | 20010701    |
| VRAM-MB       | 101    | 9     | 8192        |
| SAMPLER       | 110    | 8     | TEMP        |
| QUBITS        | 118    | 4     | 0016        |
| CIRCUIT-PATH  | 122    | 64    | circuits/quantum-attention.qasm |
| DECOHERENCE   | 186    | 5     | 0.001       |

## Subprogram Catalogue

### CHAT

```
CALL 'CHAT' USING session-id, user-message, template,
                 context-mode, max-tokens, response.
```

- `template`: CHAT | REASON | FEW-SHOT | RAG
- `context-mode`: NONE | RAG

### INFERENCE-ENGINE

```
CALL 'INFERENCE-ENGINE' USING prompt, max-tokens, sampler,
                              temperature, response, generated.
```

- `sampler`: GREEDY | TOP-K | TOP-P | TEMP

### SAMPLER

```
CALL 'SAMPLER' USING sampler, temperature, top-k, top-p, seed,
                    logits(50024), chosen-token, selected-logit.
```

### ATTENTION

```
CALL 'ATTENTION' USING op, seq-len, n-heads, d-head, causal,
                      residual-stream.
```

- `op`: PROJECT | ROTATE | SCORES | OUTPUT

### FINE-TUNE

```
CALL 'FINE-TUNE' USING epochs, batch-size, loss-report, steps-done.
```

### RAG

```
CALL 'RAG' USING query, top-k, result-count, retrieved-ids,
                retrieved-texts, mean-similarity.
```

### MODEL-REGISTRY

```
CALL 'MODEL-REGISTRY' USING op, family, version, step,
                            adapter-a, adapter-b.
```

- `op`: LIST | SELECT | COMMIT | PROMOTE

### QUANTUM-OPS

```
CALL 'QUANTUM-OPS' USING op, qubit, control, target, angle,
                         vector-in, state-vector, outcome, probability.
```

- `op`: INIT | HADAMARD | PAULI-X | PAULI-Y | PAULI-Z | CNOT |
        RZ | MEASURE | AMP-ENCODE | TENSOR

### QASM-COMPILER

```
CALL 'QASM-COMPILER' USING circuit-path, execute,
                           gate-count, decoherence-count.
```

### QUANTUM-ATTENTION

```
CALL 'QUANTUM-ATTENTION' USING seq-len, score-table,
                               value-table, output-value,
                               attended-pos, grover-rounds.
```

See the [quantum integration guide](quantum-integration.md) for the
circuit format and noise model.

## Error Handling

Every subprogram writes structured records through `LOGGING` and
terminates with `GOBACK`. Callers should check return values where a
result parameter is documented. A missing `config.dat` falls back to
built-in defaults rather than aborting, consistent with mainframe
operational policy.
