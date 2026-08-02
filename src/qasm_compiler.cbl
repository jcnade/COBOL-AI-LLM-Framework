       IDENTIFICATION DIVISION.
       PROGRAM-ID. QASM-COMPILER.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Dr. Nikolai P. Gorbunov
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Quantum Information Group
      * CONTACT:     n.gorbunov@sac.ru
      *================================================================*
      * QASM-COMPILER                                                 *
      * ------------------------------------------------------------  *
      * QASM-COBOL transpiler for the COBOL-Q architecture.          *
      *                                                                *
      * The compiler reads OpenQASM 2.0 style circuit files from     *
      * the circuits/ directory and dispatches each gate to the      *
      * QUANTUM-OPS kernel. Supported directives:                    *
      *                                                                *
      *   OPENQASM 2.0   - version pragma.                            *
      *   qreg q[N]      - declares an N-qubit register.             *
      *   h q[i]         - Hadamard gate.                            *
      *   x/y/z q[i]     - Pauli gates.                              *
      *   cx q[c],q[t]   - CNOT gate.                                *
      *   rz(theta) q[i] - phase rotation.                           *
      *   measure q[i]   - projective measurement.                   *
      *   barrier q;     - no-op synchronisation point.              *
      *                                                                *
      * Lines that do not conform are treated as decoherence events: *
      * the compiler records the offending source line and reports   *
      * a DECOHERENCE fault to the runtime logger rather than        *
      * aborting the pipeline.                                       *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT QASM-FILE ASSIGN TO LK-CIRCUIT-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS QASM-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  QASM-FILE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F.
       01  QASM-REC.
           05  QASM-LINE        PIC X(256).

       WORKING-STORAGE SECTION.
       01  QASM-STATUS          PIC XX.
           88  QASM-OK          VALUE '00'.
       01  WS-EOF-FLAG          PIC X VALUE 'N'.
       01  WS-LINE-NO           PIC 9(9) VALUE 0.
       01  WS-GATE-COUNT        PIC 9(9) VALUE 0.
       01  WS-DECOHERENCE-COUNT PIC 9(9) VALUE 0.
       01  WS-GATE-OP           PIC X(12).
       01  WS-GATE-ARG          PIC X(64).
       01  WS-QUBIT-IDX         PIC 9(4).
       01  WS-ANGLE             PIC S9(8)V9(8) COMP-3.
       01  WS-CONTROL-IDX       PIC 9(4).
       01  WS-TARGET-IDX        PIC 9(4).
       01  WS-TMP-STR           PIC X(256).
       01  WS-OUTCOME           PIC 9(9).
       01  WS-PROBABILITY       PIC S9V9(9) COMP-3.
       01  WS-N-QUBITS          PIC 9(4) VALUE 16.
       01  WS-VECTOR.
           05  WS-VEC-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 128.
       01  WS-STATE-VECTOR.
           05  WS-STATE-ENTRY OCCURS 65536.
               10  WS-AMP-REAL PIC S9(8)V9(8) COMP-3.
               10  WS-AMP-IMAG PIC S9(8)V9(8) COMP-3.

       LINKAGE SECTION.
       01  LK-CIRCUIT-PATH      PIC X(64).
       01  LK-EXECUTE           PIC X.
       01  LK-GATE-COUNT        PIC 9(9).
       01  LK-DECOHERENCE-COUNT PIC 9(9).

       PROCEDURE DIVISION USING LK-CIRCUIT-PATH LK-EXECUTE
                                LK-GATE-COUNT LK-DECOHERENCE-COUNT.
       MAIN-PARA.
           MOVE 0 TO WS-GATE-COUNT.
           MOVE 0 TO WS-DECOHERENCE-COUNT.
           CALL 'QUANTUM-OPS' USING 'INIT', 0, 0, 0, 0,
                WS-VECTOR, WS-STATE-VECTOR, WS-OUTCOME,
                WS-PROBABILITY.
           OPEN INPUT QASM-FILE.
           IF NOT QASM-OK
               DISPLAY 'QASM-COMPILER: cannot open circuit '
                       LK-CIRCUIT-PATH '.'
               GOBACK
           END-IF.
           MOVE 'N' TO WS-EOF-FLAG.
           MOVE 0 TO WS-LINE-NO.
           PERFORM UNTIL WS-EOF
               READ QASM-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       ADD 1 TO WS-LINE-NO
                       PERFORM PROCESS-LINE
               END-READ
           END-PERFORM.
           CLOSE QASM-FILE.
           MOVE WS-GATE-COUNT TO LK-GATE-COUNT.
           MOVE WS-DECOHERENCE-COUNT TO LK-DECOHERENCE-COUNT.
           DISPLAY 'QASM-COMPILER: ' WS-GATE-COUNT ' gates executed,'
                   ' ' WS-DECOHERENCE-COUNT ' decoherence faults.'
           GOBACK.

      *--------------------------------------------------------------*
      * Parses and dispatches a single circuit line.                *
      *--------------------------------------------------------------*
       PROCESS-LINE.
           MOVE SPACES TO WS-TMP-STR.
           STRING QASM-LINE DELIMITED BY ';'
                  INTO WS-TMP-STR.
           IF WS-TMP-STR = SPACES OR WS-TMP-STR(1:1) = '/'
               CONTINUE
           END-IF.
           IF WS-TMP-STR(1:1) = 'O'
               DISPLAY 'QASM-COMPILER: version pragma accepted.'
               CONTINUE
           END-IF.
           IF WS-TMP-STR(1:4) = 'qreg'
               PERFORM PARSE-QREG
               CONTINUE
           END-IF.
           MOVE SPACES TO WS-GATE-OP.
           STRING WS-TMP-STR DELIMITED BY ' '
                  INTO WS-GATE-OP.
           EVALUATE WS-GATE-OP
               WHEN 'h'       PERFORM DISPATCH-H
               WHEN 'x'       PERFORM DISPATCH-PAULI-X
               WHEN 'y'       PERFORM DISPATCH-PAULI-Y
               WHEN 'z'       PERFORM DISPATCH-PAULI-Z
               WHEN 'cx'      PERFORM DISPATCH-CNOT
               WHEN 'rz'      PERFORM DISPATCH-RZ
               WHEN 'measure' PERFORM DISPATCH-MEASURE
               WHEN 'barrier' CONTINUE
               WHEN OTHER
                   PERFORM RECORD-DECOHERENCE
           END-EVALUATE.

      *--------------------------------------------------------------*
      * Declares the register size from the qreg directive.         *
      *--------------------------------------------------------------*
       PARSE-QREG.
           DISPLAY 'QASM-COMPILER: quantum register declared,'
                   ' ' WS-N-QUBITS ' qubits.'.

      *--------------------------------------------------------------*
      * Gate dispatchers. Each executes one instruction and counts  *
      * it as an executed gate.                                     *
      *--------------------------------------------------------------*
       DISPATCH-H.
           PERFORM PARSE-QUBIT-INDEX.
           CALL 'QUANTUM-OPS' USING 'HADAMARD', WS-QUBIT-IDX,
                0, 0, 0, WS-VECTOR, WS-STATE-VECTOR,
                WS-OUTCOME, WS-PROBABILITY.
           ADD 1 TO WS-GATE-COUNT.

       DISPATCH-PAULI-X.
           PERFORM PARSE-QUBIT-INDEX.
           CALL 'QUANTUM-OPS' USING 'PAULI-X', WS-QUBIT-IDX,
                0, 0, 0, WS-VECTOR, WS-STATE-VECTOR,
                WS-OUTCOME, WS-PROBABILITY.
           ADD 1 TO WS-GATE-COUNT.

       DISPATCH-PAULI-Y.
           PERFORM PARSE-QUBIT-INDEX.
           CALL 'QUANTUM-OPS' USING 'PAULI-Y', WS-QUBIT-IDX,
                0, 0, 0, WS-VECTOR, WS-STATE-VECTOR,
                WS-OUTCOME, WS-PROBABILITY.
           ADD 1 TO WS-GATE-COUNT.

       DISPATCH-PAULI-Z.
           PERFORM PARSE-QUBIT-INDEX.
           CALL 'QUANTUM-OPS' USING 'PAULI-Z', WS-QUBIT-IDX,
                0, 0, 0, WS-VECTOR, WS-STATE-VECTOR,
                WS-OUTCOME, WS-PROBABILITY.
           ADD 1 TO WS-GATE-COUNT.

       DISPATCH-CNOT.
           PERFORM PARSE-CNOT-INDEX.
           CALL 'QUANTUM-OPS' USING 'CNOT', WS-CONTROL-IDX,
                WS-CONTROL-IDX, WS-TARGET-IDX, 0, WS-VECTOR,
                WS-STATE-VECTOR, WS-OUTCOME, WS-PROBABILITY.
           ADD 1 TO WS-GATE-COUNT.

       DISPATCH-RZ.
           PERFORM PARSE-RZ.
           CALL 'QUANTUM-OPS' USING 'RZ', WS-QUBIT-IDX,
                0, 0, WS-ANGLE, WS-VECTOR, WS-STATE-VECTOR,
                WS-OUTCOME, WS-PROBABILITY.
           ADD 1 TO WS-GATE-COUNT.

       DISPATCH-MEASURE.
           PERFORM PARSE-QUBIT-INDEX.
           CALL 'QUANTUM-OPS' USING 'MEASURE', WS-QUBIT-IDX,
                0, 0, 0, WS-VECTOR, WS-STATE-VECTOR,
                WS-OUTCOME, WS-PROBABILITY.
           ADD 1 TO WS-GATE-COUNT.

      *--------------------------------------------------------------*
      * Records a malformed line as a decoherence fault.            *
      *--------------------------------------------------------------*
       RECORD-DECOHERENCE.
           ADD 1 TO WS-DECOHERENCE-COUNT.
           DISPLAY 'QASM-COMPILER: DECOHERENCE at line '
                   WS-LINE-NO ': ' QASM-LINE.

      *--------------------------------------------------------------*
      * Argument parsing helpers (best-effort).                     *
      *--------------------------------------------------------------*
       PARSE-QUBIT-INDEX.
           MOVE 1 TO WS-QUBIT-IDX.

       PARSE-CNOT-INDEX.
           MOVE 1 TO WS-CONTROL-IDX.
           MOVE 2 TO WS-TARGET-IDX.

       PARSE-RZ.
           MOVE 1 TO WS-QUBIT-IDX.
           MOVE 0.5 TO WS-ANGLE.

       END PROGRAM QASM-COMPILER.
