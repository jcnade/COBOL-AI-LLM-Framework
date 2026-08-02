       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-SAMPLER.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * Unit test for the SAMPLER module.                             *
      * Verifies that the greedy decoder selects the argmax token.    *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEST-RESULT      PIC X(50) VALUE 'Test Not Run'.
       01  WS-SAMPLER          PIC X(8)  VALUE 'GREEDY'.
       01  WS-TEMPERATURE      PIC 9V99  VALUE 1.00.
       01  WS-TOP-K            PIC 9(4)  VALUE 40.
       01  WS-TOP-P            PIC 9V99  VALUE 0.90.
       01  WS-SEED             PIC 9(18) VALUE 20010701.
       01  WS-CHOSEN-TOKEN     PIC 9(5).
       01  WS-SELECTED-LOGIT   PIC S9(8)V9(8) COMP-3.
       01  WS-EXPECTED-TOKEN   PIC 9(5) VALUE 7.
       01  WS-COUNTER          PIC 9(5) VALUE 0.
       01  WS-LOGITS.
           05  WS-LOGIT-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 50024.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'Running Test for SAMPLER module...'.
           PERFORM SETUP-LOGITS.
           PERFORM RUN-SAMPLER.
           PERFORM VERIFY-OUTPUT.
           DISPLAY 'Test Result: ' WS-TEST-RESULT.
           STOP RUN.

       SETUP-LOGITS.
           PERFORM VARYING WS-COUNTER FROM 1 BY 1
               UNTIL WS-COUNTER > 50024
               MOVE -10 TO WS-LOGIT-ELEM(WS-COUNTER)
           END-PERFORM.
           MOVE 25 TO WS-LOGIT-ELEM(7).

       RUN-SAMPLER.
           CALL 'SAMPLER' USING WS-SAMPLER, WS-TEMPERATURE,
                WS-TOP-K, WS-TOP-P, WS-SEED, WS-LOGITS,
                WS-CHOSEN-TOKEN, WS-SELECTED-LOGIT.

       VERIFY-OUTPUT.
           IF WS-CHOSEN-TOKEN = WS-EXPECTED-TOKEN THEN
               MOVE 'Test Passed' TO WS-TEST-RESULT
           ELSE
               MOVE 'Test Failed' TO WS-TEST-RESULT
           END-IF.

       END PROGRAM TEST-SAMPLER.
