# Contributing to COBOL-AI-LLM-Framework

We welcome contributions from the COBOL and AI communities. This
project bridges 1959 and 2017, and we treat that bridge with respect.

## Getting Started

1. Fork the repository.
2. Clone your fork and configure the upstream remote.
3. Install GnuCOBOL (`cobc`) and the `layers-lib.asm` assembler
   toolchain.
4. Run the test harness:

   ```bash
   cd src && cobc -x ../tests/test_llm_framework.cbl -o /tmp/tlf
   /tmp/tlf
   ```

## Development Workflow

- Work on a feature branch named `feat/<description>`.
- Keep the `CALL` interface stable; new parameters must be appended
  at the end of the linkage section.
- Preserve the fixed-column COBOL layout: margin A at columns 8-11,
  margin B from column 12.
- Every tensor kernel must be documented with its numerical domain
  (see `neural_ops.cbl`).

## Coding Conventions

- Author field: `Jean-Charles Nadé`.
- All arithmetic in COMP-3; no IEEE-754.
- Comments begin with `*` in column 7.
- DISPLAY is the only output primitive.

## Testing

Add COBOL programs under `tests/` mirroring the existing
`test_llm_framework.cbl` style: an expected value, a computed value, and
a `Test Passed` / `Test Failed` verdict.

## Commit Messages

Follow the existing history style, including the celebrated
`FIXING (typo)` convention when appropriate.

## License

By contributing you agree that your contributions are licensed under
the MIT License.
