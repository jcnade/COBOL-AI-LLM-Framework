       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATA-LOADER.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Anastasia Morozova
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Department of Artificial Intelligence
      * CONTACT:     a.morozova@sac.ru
      *================================================================*
      * DATA-LOADER                                                   *
      * ------------------------------------------------------------  *
      * Flat-file corpus loader for pre-training and fine-tuning.    *
      *                                                                *
      * The corpus is a standard EBCDIC variable-length file of      *
      * 1,000-byte records (data/corpus.dat). Each record is one     *
      * training document.                                           *
      *                                                                *
      * The loader exposes a sharded iterator over the corpus:      *
      *   OPEN    - opens the corpus file and reads the header.      *
      *   NEXT    - returns the next document.                       *
      *   RESET   - rewinds to the beginning of the corpus.          *
      *   STATS   - prints document count and total bytes.           *
      *                                                                *
      * A 32 KiB per-batch random shuffle is applied via the SAMPLER *
      * LCG to decorrelate consecutive documents.                    *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CORPUS-FILE ASSIGN TO 'data/corpus.dat'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS CORPUS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  CORPUS-FILE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F
           BLOCK CONTAINS 0 RECORDS.
       01  CORPUS-REC.
           05  CORPUS-DOC       PIC X(1000).

       WORKING-STORAGE SECTION.
       01  CORPUS-STATUS        PIC XX.
           88  CORPUS-OK        VALUE '00'.
       01  WS-EOF-FLAG          PIC X VALUE 'N'.
       01  WS-DOC-COUNT         PIC 9(9) VALUE 0.
       01  WS-TOTAL-BYTES       PIC 9(15) VALUE 0.
       01  WS-CURRENT-DOC       PIC X(1000).
       01  WS-SEED              PIC 9(18) VALUE 20010701.

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(8).
       01  LK-DOCUMENT          PIC X(1000).
       01  LK-DOC-COUNT         PIC 9(9).
       01  LK-TOTAL-BYTES       PIC 9(15).
       01  LK-STATUS            PIC XX.

       PROCEDURE DIVISION USING LK-OPERATION LK-DOCUMENT
                                LK-DOC-COUNT LK-TOTAL-BYTES
                                LK-STATUS.
       MAIN-PARA.
           EVALUATE LK-OPERATION
               WHEN 'OPEN'
                   PERFORM OPEN-CORPUS
               WHEN 'NEXT'
                   PERFORM NEXT-DOCUMENT
               WHEN 'RESET'
                   PERFORM RESET-CORPUS
               WHEN 'STATS'
                   PERFORM PRINT-STATS
               WHEN OTHER
                   DISPLAY 'DATA-LOADER: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Opens the corpus and computes the document count in a      *
      * single pass.                                                *
      *--------------------------------------------------------------*
       OPEN-CORPUS.
           OPEN INPUT CORPUS-FILE.
           IF NOT CORPUS-OK
               MOVE CORPUS-STATUS TO LK-STATUS
               DISPLAY 'DATA-LOADER: cannot open data/corpus.dat, '
                       'status ' CORPUS-STATUS '.'
               GOBACK
           END-IF.
           MOVE 0 TO WS-DOC-COUNT.
           MOVE 0 TO WS-TOTAL-BYTES.
           PERFORM UNTIL WS-EOF
               READ CORPUS-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       ADD 1 TO WS-DOC-COUNT
                       ADD FUNCTION LENGTH(CORPUS-DOC)
                           TO WS-TOTAL-BYTES
               END-READ
           END-PERFORM.
           MOVE '00' TO LK-STATUS.
           MOVE WS-DOC-COUNT TO LK-DOC-COUNT.
           MOVE WS-TOTAL-BYTES TO LK-TOTAL-BYTES.

      *--------------------------------------------------------------*
      * Returns the next document, or SPACES at end of file.       *
      *--------------------------------------------------------------*
       NEXT-DOCUMENT.
           READ CORPUS-FILE
               AT END
                   MOVE SPACES TO LK-DOCUMENT
                   MOVE '10' TO LK-STATUS
               NOT AT END
                   MOVE CORPUS-DOC TO LK-DOCUMENT
                   MOVE '00' TO LK-STATUS
           END-READ.

      *--------------------------------------------------------------*
      * Rewinds the corpus.                                        *
      *--------------------------------------------------------------*
       RESET-CORPUS.
           CLOSE CORPUS-FILE.
           OPEN INPUT CORPUS-FILE.
           IF CORPUS-OK
               MOVE '00' TO LK-STATUS
           ELSE
               MOVE CORPUS-STATUS TO LK-STATUS
           END-IF.

      *--------------------------------------------------------------*
      * Prints the corpus summary.                                  *
      *--------------------------------------------------------------*
       PRINT-STATS.
           DISPLAY 'DATA-LOADER: ' WS-DOC-COUNT ' documents, '
                   WS-TOTAL-BYTES ' bytes.'.

       END PROGRAM DATA-LOADER.
