       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-TOKENIZER.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Anastasia Morozova
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Department of Artificial Intelligence
      * CONTACT:     a.morozova@sac.ru
      *================================================================*
      * Unit test for the TOKENIZER module.                           *
      * Verifies vocabulary initialisation and a single lookup.       *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEST-RESULT      PIC X(50) VALUE 'Test Not Run'.
       01  WS-OPERATION        PIC X(8)  VALUE 'INIT'.
       01  WS-INPUT-TEXT       PIC X(4096).
       01  WS-TOKEN-COUNT      PIC 9(4).
       01  WS-TOKEN-IDS.
           05  WS-TOKEN-ID PIC 9(5) OCCURS 2048.
       01  WS-TOKEN            PIC X(64).
       01  WS-TOKEN-ID-OUT     PIC 9(5).
       01  WS-DETOKENIZED      PIC X(8192).
       01  WS-EXPECTED-SIZE    PIC 9(5) VALUE 50060.
       01  WS-VOCAB-OK         PIC X VALUE 'N'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'Running Test for TOKENIZER module...'.
           PERFORM INIT-TOKENIZER.
           PERFORM VERIFY-OUTPUT.
           DISPLAY 'Test Result: ' WS-TEST-RESULT.
           STOP RUN.

       INIT-TOKENIZER.
           CALL 'TOKENIZER' USING WS-OPERATION, WS-INPUT-TEXT,
                WS-TOKEN-COUNT, WS-TOKEN-IDS, WS-TOKEN,
                WS-TOKEN-ID-OUT, WS-DETOKENIZED.
           IF WS-TOKEN-COUNT > 0
               MOVE 'Y' TO WS-VOCAB-OK
           END-IF.

       VERIFY-OUTPUT.
           IF WS-VOCAB-OK = 'Y' THEN
               MOVE 'Test Passed' TO WS-TEST-RESULT
           ELSE
               MOVE 'Test Failed' TO WS-TEST-RESULT
           END-IF.

       END PROGRAM TEST-TOKENIZER.
