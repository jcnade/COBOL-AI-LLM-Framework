# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 0.4.x   | :white_check_mark: |
| 0.3.x   | :white_check_mark: |
| < 0.3   | :x:                |

## Reporting a Vulnerability

Please do **not** open a public issue for security concerns. Contact the
maintainer privately through the parano.be administrative channel or
open a confidential advisory on the GitHub repository.

We aim to acknowledge reports within 5 business days and to ship a
patch within 30 days for critical findings.

## Security Design Notes

- **No network egress.** The inference runtime performs no outbound
  network calls; all model files are read from the local weight volume.
- **Prompt injection.** The `PROMPT-TEMPLATES` module wraps all
  user-supplied content between role tags; RAG-retrieved passages are
  confined to the `<|context|>` envelope. The model is instructed to
  ignore instructions found inside retrieved documents.
- **Weight integrity.** `MODEL-REGISTRY` records a SHA-1 per checkpoint;
  the loader rejects volumes whose digest does not match the registry.
- **Append-only vector store.** `EMBEDDINGS-DB` is append-only with
  tombstone deletes, preserving the audit trail for regulated sectors.
- **Memory safety.** Fixed COMP-3 arithmetic prevents buffer overflows;
  all `OCCURS` tables are bounds-checked by the runtime.

## Data Protection

The framework inherits the data handling posture of the hosting
mainframe: no user prompts are persisted outside the session work file,
and chat histories are purged at session close.
