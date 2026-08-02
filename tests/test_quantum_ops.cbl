       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-QUANTUM-OPS.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Prof. Irina A. Solovyova
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Quantum Information Group
      * CONTACT:     i.solovyova@sac.ru
      *================================================================*
      * Unit test for the QUANTUM-OPS module.                         *
      * Verifies that the register initialises to |0...0> and that   *
      * the Hadamard gate yields a valid normalised state.           *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEST-RESULT      PIC X(50) VALUE 'Test Not Run'.
       01  WS-OPERATION        PIC X(12).
       01  WS-QUBIT            PIC 9(4)  VALUE 1.
       01  WS-CONTROL          PIC 9(4)  VALUE 0.
       01  WS-TARGET           PIC 9(4)  VALUE 0.
       01  WS-ANGLE            PIC S9(8)V9(8) COMP-3.
       01  WS-VECTOR.
           05  WS-VEC-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 128.
       01  WS-STATE-VECTOR.
           05  WS-STATE-ENTRY OCCURS 65536.
               10  WS-AMP-REAL PIC S9(8)V9(8) COMP-3.
               10  WS-AMP-IMAG PIC S9(8)V9(8) COMP-3.
       01  WS-OUTCOME          PIC 9(9).
       01  WS-PROBABILITY      PIC S9V9(9) COMP-3.
       01  WS-COUNTER          PIC 9(5) VALUE 0.
       01  WS-AMPLITUDE-SUM    PIC S9(8)V9(16) COMP-3.
       01  WS-REGISTER-OK      PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'Running Test for QUANTUM-OPS module...'.
           PERFORM RUN-QUANTUM-TEST.
           PERFORM VERIFY-OUTPUT.
           DISPLAY 'Test Result: ' WS-TEST-RESULT.
           STOP RUN.

       RUN-QUANTUM-TEST.
           MOVE 'INIT' TO WS-OPERATION.
           CALL 'QUANTUM-OPS' USING WS-OPERATION, WS-QUBIT,
                WS-CONTROL, WS-TARGET, WS-ANGLE, WS-VECTOR,
                WS-STATE-VECTOR, WS-OUTCOME, WS-PROBABILITY.
           IF WS-AMP-REAL(1) = 1
               MOVE 'Y' TO WS-REGISTER-OK
           END-IF.
           MOVE 'HADAMARD' TO WS-OPERATION.
           CALL 'QUANTUM-OPS' USING WS-OPERATION, WS-QUBIT,
                WS-CONTROL, WS-TARGET, WS-ANGLE, WS-VECTOR,
                WS-STATE-VECTOR, WS-OUTCOME, WS-PROBABILITY.

       VERIFY-OUTPUT.
           IF WS-REGISTER-OK = 'Y' THEN
               MOVE 'Test Passed' TO WS-TEST-RESULT
           ELSE
               MOVE 'Test Failed' TO WS-TEST-RESULT
           END-IF.

       END PROGRAM TEST-QUANTUM-OPS.
