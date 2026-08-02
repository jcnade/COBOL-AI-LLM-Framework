# Legacy Platform Integration: AS/400 and IBM 3090

This guide covers the deployment of the COBOL-AI-LLM-Framework on the
two primary legacy platforms supported by the runtime: the **IBM
iSeries / AS/400** (OS/400, ILE COBOL) and the **IBM 3090** (MVS/XA,
ESA). Both targets are reached through dedicated bridge subprograms.

| Platform  | Bridge module      | Contributor                       |
|-----------|--------------------|-----------------------------------|
| AS/400    | `as400_bridge.cbl` | Amira Trabelsi (ISIAK, TN)        |
| IBM 3090  | `mvs_bridge.cbl`   | Prof. Dmitri A. Volkov (SAC, RU)  |

## 1. Integration

### 1.1 AS/400 (OS/400)

The `AS400-BRIDGE` subprogram is compiled as an ILE COBOL service
program and called from ILE COBOL, RPG, or CL:

```
CALL 'AS400-BRIDGE' USING 'SET-CCSID', 500, TEXT, VECTOR, STATUS.
CALL 'AS400-BRIDGE' USING 'TRANSLATE', 500, TEXT, VECTOR, STATUS.
CALL 'AS400-BRIDGE' USING 'DB2-STORE', 500, TEXT, VECTOR, STATUS.
```

Integration points:

- **CCSID**: the job default is 037; this module translates payloads
  to 500 (EBCDIC international) or 819 (ASCII) as configured.
- **DB2 for i**: the vector store is surfaced as the `EMBEDDINGS`
  table; embedded SQL replaces the flat-file store.
- **RPG interop**: a fixed parameter list is preserved for `CALLP`
  boundaries.

### 1.2 IBM 3090 (MVS/XA)

The `MVS-BRIDGE` subprogram supports batch, CICS, and TSO invocation:

```
CALL 'MVS-BRIDGE' USING 'BATCH', COMMAREA, LEN, PROMPT, RESP, STATUS.
CALL 'MVS-BRIDGE' USING 'CICS',  COMMAREA, LEN, PROMPT, RESP, STATUS.
CALL 'MVS-BRIDGE' USING 'VSAM-PUT', COMMAREA, LEN, PROMPT, RESP, STATUS.
```

Integration points:

- **JCL batch**: jobs allocate `JOBLIB` and `SYSOUT` DDs; the bridge
  reads the prompt from the input DD.
- **CICS**: requests arrive in a COMMAREA; the response overwrites the
  area before `DFHRETURN`.
- **VSAM**: the KV-cache is backed by the ESDS `KV.CACHE.VSAM`.
- **SVC 99**: data sets are allocated dynamically at job start.
- **ESTAE**: an error recovery environment is established for the
  task.

## 2. Migration

### 2.1 Configuration

Set the platform fields in `config.dat` before deployment:

| Field      | Width | S/370        | AS/400        | IBM 3090     |
|------------|-------|--------------|---------------|--------------|
| PLATFORM   | 8     | S/370        | OS-400        | MVS-3090     |
| CCSID      | 4     | 0037         | 0500          | 0037         |

### 2.2 Checkpoint portability

Model checkpoints (`models/*.llm`, `models/registry.dat`) are portable
across platforms without conversion: they are pure ASCII record files.
The COMP-3 weight volumes, however, depend on byte order:

- S/370 and IBM 3090 share big-endian packed decimal — **no conversion
  required**.
- AS/400 is big-endian for COBOL COMP-3 — **no conversion required**.
- Only the KV-cache backing store differs: flat file on S/370, VSAM
  ESDS on 3090, DB2 for i on AS/400.

### 2.3 CCSID translation matrix

| Source CCSID | Target CCSID | Action                 |
|--------------|--------------|------------------------|
| 037          | 500          | EBCDIC table swap      |
| 037          | 819          | EBCDIC -> ASCII        |
| 500          | 037          | EBCDIC table swap      |
| 819          | 037          | ASCII -> EBCDIC        |

The `TRANSLATE` operation applies the active pair.

## 3. Testing

Run the platform test harness on each target:

```
cobc -x src/as400_bridge.cbl -o bin/as400_bridge
cobc -x src/mvs_bridge.cbl -o bin/mvs_bridge
cobc -x tests/test_as400_bridge.cbl -o bin/test_as400_bridge
cobc -x tests/test_mvs_bridge.cbl -o bin/test_mvs_bridge
```

Expected results:

- `test_as400_bridge.cbl`: verifies CCSID setup returns `CCSID-OK`.
- `test_mvs_bridge.cbl`: verifies batch entry returns `BATCH-OK`.

### 3.1 Validation checklist

1. CCSID translation round-trip (037 -> 500 -> 037) is byte-identical.
2. The vector store accepts one document per platform.
3. The KV-cache survives a job restart on the 3090.
4. The CICS transaction returns within the COMMAREA length.
5. Registry and model card reads succeed from each platform's file
   system.

## 4. Troubleshooting

- **CCSID-ERROR**: verify `config.dat CCSID` matches the job CCSID.
- **VSAM status '22'**: the ESDS is empty; seed it with `VSAM-PUT`.
- **DB2-ERROR**: confirm the `EMBEDDINGS` table and sequence exist in
  the collection library.
- **COMMAREA truncation**: raise `DFHCOMMAREA` in the CICS region
  definition.
