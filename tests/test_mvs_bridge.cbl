       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-MVS-BRIDGE.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Prof. Dmitri A. Volkov
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Department of Artificial Intelligence
      * CONTACT:     d.volkov@sac.ru
      *================================================================*
      * Unit test for the MVS-BRIDGE module.                          *
      * Verifies that the batch entry returns BATCH-OK.               *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEST-RESULT      PIC X(50) VALUE 'Test Not Run'.
       01  WS-MODE             PIC X(8)  VALUE 'BATCH'.
       01  WS-COMMAREA         PIC X(32767).
       01  WS-COMMAREA-LEN     PIC 9(4)  VALUE 100.
       01  WS-PROMPT           PIC X(4096) VALUE 'RECONCILE FY2001'.
       01  WS-RESPONSE         PIC X(8192).
       01  WS-STATUS           PIC X(16).
       01  WS-EXPECTED-STATUS  PIC X(16) VALUE 'BATCH-OK'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'Running Test for MVS-BRIDGE module...'.
           PERFORM RUN-MVS-TEST.
           PERFORM VERIFY-OUTPUT.
           DISPLAY 'Test Result: ' WS-TEST-RESULT.
           STOP RUN.

       RUN-MVS-TEST.
           CALL 'MVS-BRIDGE' USING WS-MODE, WS-COMMAREA,
                WS-COMMAREA-LEN, WS-PROMPT, WS-RESPONSE, WS-STATUS.

       VERIFY-OUTPUT.
           IF WS-STATUS = WS-EXPECTED-STATUS THEN
               MOVE 'Test Passed' TO WS-TEST-RESULT
           ELSE
               MOVE 'Test Failed' TO WS-TEST-RESULT
           END-IF.

       END PROGRAM TEST-MVS-BRIDGE.
