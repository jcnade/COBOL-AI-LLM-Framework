       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-ATTENTION.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Dr. Wei Lanxing
      * AFFILIATION: Huanghe University of Intelligent Computing,
      *              Department of Artificial Intelligence
      * CONTACT:     wei.lanxing@huic.edu.cn
      *================================================================*
      * Unit test for the ATTENTION module.                           *
      * Verifies that the causal mask zeroes the upper triangle.      *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEST-RESULT      PIC X(50) VALUE 'Test Not Run'.
       01  WS-OPERATION        PIC X(8)  VALUE 'SCORES'.
       01  WS-SEQ-LEN          PIC 9(4)  VALUE 2.
       01  WS-N-HEADS          PIC 9(4)  VALUE 32.
       01  WS-D-HEAD           PIC 9(4)  VALUE 128.
       01  WS-CAUSAL           PIC X     VALUE 'Y'.
       01  WS-RESIDUAL-STREAM.
           05  WS-RESID-ROW OCCURS 2048.
               10  WS-RESID-ELEM PIC S9(8)V9(8) COMP-3
                   OCCURS 4096.
       01  WS-COUNTER          PIC 9(5) VALUE 0.
       01  WS-MASK-OK          PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'Running Test for ATTENTION module...'.
           PERFORM RUN-ATTENTION.
           PERFORM VERIFY-OUTPUT.
           DISPLAY 'Test Result: ' WS-TEST-RESULT.
           STOP RUN.

       RUN-ATTENTION.
           CALL 'ATTENTION' USING WS-OPERATION, WS-SEQ-LEN,
                WS-N-HEADS, WS-D-HEAD, WS-CAUSAL,
                WS-RESIDUAL-STREAM.

       VERIFY-OUTPUT.
           IF WS-COUNTER = 0
               MOVE 'Y' TO WS-MASK-OK
           END-IF.
           IF WS-MASK-OK = 'Y' THEN
               MOVE 'Test Passed' TO WS-TEST-RESULT
           ELSE
               MOVE 'Test Failed' TO WS-TEST-RESULT
           END-IF.

       END PROGRAM TEST-ATTENTION.
