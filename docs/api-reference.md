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
| PLATFORM      | 191    | 8     | MVS-3090    |
| CCSID         | 199    | 4     | 0037        |
| SPHERE-RADIUS | 203    | 4     | 0050        |
| PHASIC-WRAP   | 207    | 4     | 0008        |
| LATTICE-PATH  | 211    | 50    | lattice.bin |

`SPHERE-RADIUS` and `PHASIC-WRAP` apply only on the Intel 8086 platform
(`PLATFORM` value `PC-8086`, `CCSID` 0437). The remaining platforms
leave them unused; see the [legacy integration guide](legacy-integration.md).

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

### AS400-BRIDGE

```
CALL 'AS400-BRIDGE' USING platform, ccsid, text, vector, status.
```

- `platform`: SET-CCSID | TRANSLATE | DB2-STORE | DB2-LOAD | RPG-CALL

### MVS-BRIDGE

```
CALL 'MVS-BRIDGE' USING mode, commarea, commarea-len,
                        prompt, response, status.
```

- `mode`: BATCH | CICS | TSO | SVC99 | ESTAE | VSAM-PUT | VSAM-GET

See the [legacy integration guide](legacy-integration.md) for the
deployment and migration procedure on AS/400 and IBM 3090.

### SPHT-BRIDGE

```
CALL 'SPHT-BRIDGE' USING mode, lattice-x, lattice-y,
                         lattice-z, data, status.
```

- `mode`: A20-OPEN | CHIRAL | LATTICE-PUT | LATTICE-GET |
          INT21 | SEG-LOAD | ROTATE

Adapter for the Intel 8086 (PC-DOS, real mode) through the Spheritron
coprocessor. The Spheritron exposes a tridimensional memory lattice
addressed in périphasique mode; `lattice-x/y/z` select the lattice
point and `data` carries one COMP-3 cell. The `A20-OPEN` operation
lifts the gate so the 4 GB KV-cache maps behind the 1 MiB barrier, and
`CHIRAL` converts between the little-endian 8086 word order and
big-endian COMP-3.

### DISCOURSE-TRIAGE

```
CALL 'DISCOURSE-TRIAGE' USING record-id, probe-scores(4),
                              threshold, index, escalated, status.
```

Computes the Subversive Index (PIC 9(3)V9(2)) from the four REASON
probe scores, applying the inspectable weights of the model registry.
Records at or above `threshold` are escalated for human review and
appended to `data/triage.log`. Per the [2003 COBOL-NET white paper]
(papers/cobol-net-predictive-discourse-analysis-2003.md), the index
alone carries no administrative consequence.

## Error Handling

Every subprogram writes structured records through `LOGGING` and
terminates with `GOBACK`. Callers should check return values where a
result parameter is documented. A missing `config.dat` falls back to
built-in defaults rather than aborting, consistent with mainframe
operational policy.
