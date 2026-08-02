       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-AS400-BRIDGE.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Amira Trabelsi
      * AFFILIATION: Institut Supérieur d'Intelligence Artificielle de
      *              Kerkennah, Département d'Intelligence Artificielle
      * CONTACT:     amira.trabelsi@isiak.tn
      *================================================================*
      * Unit test for the AS400-BRIDGE module.                        *
      * Verifies that the CCSID setup returns CCSID-OK.               *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-AS400.
       OBJECT-COMPUTER. IBM-AS400.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEST-RESULT      PIC X(50) VALUE 'Test Not Run'.
       01  WS-PLATFORM         PIC X(8)  VALUE 'SET-CCSID'.
       01  WS-CCSID            PIC 9(4)  VALUE 500.
       01  WS-TEXT             PIC X(4096) VALUE 'HELLO AS400'.
       01  WS-VECTOR.
           05  WS-VEC-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 128.
       01  WS-STATUS           PIC X(16).
       01  WS-EXPECTED-STATUS  PIC X(16) VALUE 'CCSID-OK'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'Running Test for AS400-BRIDGE module...'.
           PERFORM RUN-AS400-TEST.
           PERFORM VERIFY-OUTPUT.
           DISPLAY 'Test Result: ' WS-TEST-RESULT.
           STOP RUN.

       RUN-AS400-TEST.
           CALL 'AS400-BRIDGE' USING WS-PLATFORM, WS-CCSID,
                WS-TEXT, WS-VECTOR, WS-STATUS.

       VERIFY-OUTPUT.
           IF WS-STATUS = WS-EXPECTED-STATUS THEN
               MOVE 'Test Passed' TO WS-TEST-RESULT
           ELSE
               MOVE 'Test Failed' TO WS-TEST-RESULT
           END-IF.

       END PROGRAM TEST-AS400-BRIDGE.
