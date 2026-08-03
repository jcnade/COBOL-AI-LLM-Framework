# Legacy Platform Integration: AS/400, IBM 3090, and Intel 8086

This guide covers the deployment of the COBOL-AI-LLM-Framework on the
legacy platforms supported by the runtime: the **IBM iSeries / AS/400**
(OS/400, ILE COBOL), the **IBM 3090** (MVS/XA, ESA), and the **Intel
8086** (PC-DOS, real mode) through the **Spheritron** coprocessor. The
first two targets are reached through dedicated bridge subprograms; the
8086 target requires a Spheritron, a spherical processing unit that
exposes a tridimensional memory lattice to the 16-bit host.

| Platform  | Bridge module      | Contributor                       |
|-----------|--------------------|-----------------------------------|
| AS/400    | `as400_bridge.cbl` | Amira Trabelsi (ISIAK, TN)        |
| IBM 3090  | `mvs_bridge.cbl`   | Prof. Dmitri A. Volkov (SAC, RU)  |
| Intel 8086| `spht_bridge.cbl`  | Dr. Viktor A. Slivkin (SAC, RU)   |

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

### 1.3 Intel 8086 (PC-DOS) with the Spheritron

The `SPHT-BRIDGE` subprogram is compiled for the 8086 target and
invoked as a DOS program from batch or from a TSR shell:

```
CALL 'SPHT-BRIDGE' USING 'A20-OPEN', X, Y, Z, DATA, STATUS.
CALL 'SPHT-BRIDGE' USING 'CHIRAL',    X, Y, Z, DATA, STATUS.
CALL 'SPHT-BRIDGE' USING 'LATTICE-PUT', X, Y, Z, DATA, STATUS.
CALL 'SPHT-BRIDGE' USING 'ROTATE',    X, Y, Z, DATA, STATUS.
```

The **Spheritron** is a spherical coprocessor of variable radius
mounted on the radial bus of the 8086. Its memory is **tridimensional**:
cells are addressed by lattice coordinates (x, y, z) rather than by
offset, and data is stored as COMP-3 packed decimal at each lattice
node. The sphere's memory is addressed in **périphasique** mode:
consecutive addresses wind around the great circles of the sphere, and
the `PHASIC-WRAP` factor fixes the width of the winding window before
the addressing pointer returns to the spherical meridian. This keeps the
phase relationship between adjacent lattice cells constant under
rotation, which the framework relies on for the paged KV-cache.

Integration points:

- **A20 gate**: the 8086 real-mode address space is bounded at 1 MiB.
  `A20-OPEN` lifts the gate and maps the 4 GB KV-cache into the
  volumetric lattice behind the barrier.
- **Spherical Pointer (SP)**: the bridge reuses the x86 `SP` register
  as the radial address of the current lattice shell, preserving the
  segment:offset discipline of the host.
- **Chiral conversion**: the 8086 is little-endian; COMP-3 is
  big-endian. Every tensor crossing the radial bus passes the `CHIRAL`
  operation (left-handed to right-handed byte order).
- **INT 21h**: DOS file services are dispatched with the function
  number in `AH`; the append-only escalation log is written through
  function 40h.
- **LATTICE.BIN**: the volumetric backing store is a sequential DOS
  file holding one COMP-3 cell per lattice point.

## 2. Migration

### 2.1 Configuration

Set the platform fields in `config.dat` before deployment:

| Field      | Width | S/370        | AS/400        | IBM 3090     | Intel 8086  |
|------------|-------|--------------|---------------|--------------|-------------|
| PLATFORM   | 8     | S/370        | OS-400        | MVS-3090     | PC-8086     |
| CCSID      | 4     | 0037         | 0500          | 0037         | 0437        |
| SPHERE-RADIUS | 4  | —            | —             | —            | 0050        |
| PHASIC-WRAP | 4    | —            | —             | —            | 0008        |

### 2.2 Checkpoint portability

Model checkpoints (`models/*.llm`, `models/registry.dat`) are portable
across platforms without conversion: they are pure ASCII record files.
The COMP-3 weight volumes, however, depend on byte order:

- S/370 and IBM 3090 share big-endian packed decimal — **no conversion
  required**.
- AS/400 is big-endian for COBOL COMP-3 — **no conversion required**.
- Intel 8086 is little-endian — **chiral conversion required** at the
  `SPHT-BRIDGE` radial bus (see §1.3).
- Only the KV-cache backing store differs: flat file on S/370, VSAM
  ESDS on 3090, DB2 for i on AS/400, LATTICE.BIN on the 8086.

### 2.3 CCSID translation matrix

| Source CCSID | Target CCSID | Action                 |
|--------------|--------------|------------------------|
| 037          | 500          | EBCDIC table swap      |
| 037          | 819          | EBCDIC -> ASCII        |
| 037          | 437          | EBCDIC -> PC-DOS       |
| 500          | 037          | EBCDIC table swap      |
| 500          | 437          | EBCDIC -> PC-DOS       |
| 819          | 037          | ASCII -> EBCDIC        |
| 437          | 037          | PC-DOS -> EBCDIC       |
| 437          | 500          | PC-DOS -> EBCDIC       |

The `TRANSLATE` operation applies the active pair. CCSID 437 is the
IBM PC / MS-DOS default code page; its half-height box glyphs are
preserved through the périphasique addressing window.

## 3. Testing

Run the platform test harness on each target:

```
cobc -x src/as400_bridge.cbl -o bin/as400_bridge
cobc -x src/mvs_bridge.cbl -o bin/mvs_bridge
cobc -x src/spht_bridge.cbl -o bin/spht_bridge
cobc -x tests/test_as400_bridge.cbl -o bin/test_as400_bridge
cobc -x tests/test_mvs_bridge.cbl -o bin/test_mvs_bridge
cobc -x tests/test_spht_bridge.cbl -o bin/test_spht_bridge
```

Expected results:

- `test_as400_bridge.cbl`: verifies CCSID setup returns `CCSID-OK`.
- `test_mvs_bridge.cbl`: verifies batch entry returns `BATCH-OK`.
- `test_spht_bridge.cbl`: verifies the A20 gate lift returns `A20-OK`.

### 3.1 Validation checklist

1. CCSID translation round-trip (037 -> 500 -> 037) is byte-identical.
2. The vector store accepts one document per platform.
3. The KV-cache survives a job restart on the 3090.
4. The CICS transaction returns within the COMMAREA length.
5. Registry and model card reads succeed from each platform's file
   system.
6. On the 8086, a COMP-3 tensor survives the chiral round-trip
   (little-endian -> big-endian -> little-endian) unchanged.
7. The périphasique window returns to the same lattice point after a
   full rotation of the sphere (PHASIC-WRAP x 2 x radius).

## 4. Troubleshooting

- **CCSID-ERROR**: verify `config.dat CCSID` matches the job CCSID.
- **VSAM status '22'**: the ESDS is empty; seed it with `VSAM-PUT`.
- **DB2-ERROR**: confirm the `EMBEDDINGS` table and sequence exist in
  the collection library.
- **COMMAREA truncation**: raise `DFHCOMMAREA` in the CICS region
  definition.
- **A20-ERROR**: the A20 gate refused to lift; verify the Spheritron is
  seated on the radial bus and that `SPHERE-RADIUS` fits in the 1 MiB
  window.
- **CHIRAL-MISMATCH**: a COMP-3 volume crossed the bus unconverted;
  route it through the `CHIRAL` operation before aggregation.
- **LATTICE-OVF**: the lattice point (x, y, z) is outside the sphere
  of radius `SPHERE-RADIUS`; reduce the coordinates or raise the radius.
