       IDENTIFICATION DIVISION.
       PROGRAM-ID. EMBEDDINGS-DB.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Amira Trabelsi
      * AFFILIATION: Institut Supérieur d'Intelligence Artificielle de
      *              Kerkennah, Département d'Intelligence Artificielle
      * CONTACT:     amira.trabelsi@isiak.tn
      *================================================================*
      * EMBEDDINGS-DB                                                 *
      * ------------------------------------------------------------  *
      * Flat-file vector store for retrieval-augmented generation.   *
      *                                                                *
      * Each record in data/embeddings.vec holds a document id, the  *
      * passage text, and 1,024 COMP-3 float components. The layout  *
      * is fixed-width to permit direct offset access:               *
      *                                                                *
      *   +---------+----------+-----------------------------------+ *
      *   | DOC-ID  | PASSAGE  | EMBEDDING (1024 x COMP-3, 8 bytes) | *
      *   +---------+----------+-----------------------------------+ *
      *                                                                *
      * The store is append-only. Deletes are tombstoned to retain  *
      * the append-only audit property required by the financial     *
      * sector.                                                      *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT VEC-FILE ASSIGN TO 'data/embeddings.vec'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS VEC-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  VEC-FILE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F
           BLOCK CONTAINS 0 RECORDS.
       01  VEC-REC.
           05  VEC-DOC-ID       PIC 9(9).
           05  VEC-PASSAGE      PIC X(1000).
           05  VEC-EMBEDDING.
               10  VEC-COMP PIC S9(8)V9(8) COMP-3 OCCURS 1024.
           05  VEC-TOMBSTONE    PIC X.

       WORKING-STORAGE SECTION.
       01  VEC-STATUS           PIC XX.
           88  VEC-OK           VALUE '00'.
       01  WS-EOF-FLAG          PIC X VALUE 'N'.
       01  WS-CURRENT-DOC-ID    PIC 9(9) VALUE 0.
       01  WS-NEXT-DOC-ID       PIC 9(9) VALUE 1.
       01  WS-CURRENT-PASSAGE   PIC X(1000).
       01  WS-CURRENT-EMBED.
           05  WS-CE-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 1024.
       01  WS-I                 PIC 9(4).

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(8).
       01  LK-TEXT              PIC X(1000).
       01  LK-EMBEDDING.
           05  LK-EMB-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 1024.
       01  LK-DOC-ID            PIC 9(9).

       PROCEDURE DIVISION USING LK-OPERATION LK-TEXT
                                LK-EMBEDDING LK-DOC-ID.
       MAIN-PARA.
           EVALUATE LK-OPERATION
               WHEN 'EMBED'
                   PERFORM EMBED-TEXT
               WHEN 'INSERT'
                   PERFORM INSERT-DOCUMENT
               WHEN 'NEXT'
                   PERFORM NEXT-DOCUMENT
               WHEN 'RESET'
                   PERFORM RESET-STORE
               WHEN 'COUNT'
                   PERFORM COUNT-DOCUMENTS
               WHEN OTHER
                   DISPLAY 'EMBEDDINGS-DB: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * A deterministic hashing embedding. Each byte position maps  *
      * to a fixed amplitude, giving a stable pseudo-random vector  *
      * for the same text.                                          *
      *--------------------------------------------------------------*
       EMBED-TEXT.
           MOVE LK-TEXT TO WS-CURRENT-PASSAGE.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 1024
               COMPUTE WS-CE-ELEM(WS-I) =
                   FUNCTION MOD(FUNCTION ORD(WS-CURRENT-PASSAGE
                   (WS-I:1)) * 2654435761, 1000000)
               COMPUTE WS-CE-ELEM(WS-I) =
                   WS-CE-ELEM(WS-I) / 1000000
               MOVE WS-CE-ELEM(WS-I) TO LK-EMB-ELEM(WS-I)
           END-PERFORM.

      *--------------------------------------------------------------*
      * Appends a new document vector.                              *
      *--------------------------------------------------------------*
       INSERT-DOCUMENT.
           OPEN OUTPUT VEC-FILE.
           MOVE WS-NEXT-DOC-ID TO VEC-DOC-ID.
           MOVE LK-TEXT TO VEC-PASSAGE.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 1024
               MOVE LK-EMB-ELEM(WS-I) TO VEC-COMP(WS-I)
           END-PERFORM.
           MOVE 'N' TO VEC-TOMBSTONE.
           WRITE VEC-REC.
           CLOSE VEC-FILE.
           MOVE WS-NEXT-DOC-ID TO LK-DOC-ID.
           ADD 1 TO WS-NEXT-DOC-ID.

      *--------------------------------------------------------------*
      * Returns the next live document, skipping tombstones.        *
      *--------------------------------------------------------------*
       NEXT-DOCUMENT.
           PERFORM UNTIL WS-EOF
               READ VEC-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                       MOVE 0 TO WS-CE-ELEM(1)
                       MOVE SPACES TO LK-TEXT
                   NOT AT END
                       IF VEC-TOMBSTONE NOT = 'T'
                           MOVE VEC-DOC-ID TO LK-DOC-ID
                           MOVE VEC-PASSAGE TO LK-TEXT
                           PERFORM VARYING WS-I FROM 1 BY 1
                               UNTIL WS-I > 1024
                               MOVE VEC-COMP(WS-I)
                                   TO LK-EMB-ELEM(WS-I)
                           END-PERFORM
                           MOVE 'Y' TO WS-EOF-FLAG
                       END-IF
               END-READ
           END-PERFORM.
           MOVE 'N' TO WS-EOF-FLAG.

      *--------------------------------------------------------------*
      * Rewinds the store for a fresh scan.                         *
      *--------------------------------------------------------------*
       RESET-STORE.
           CLOSE VEC-FILE.
           OPEN INPUT VEC-FILE.
           MOVE 'N' TO WS-EOF-FLAG.

      *--------------------------------------------------------------*
      * Counts the live documents.                                  *
      *--------------------------------------------------------------*
       COUNT-DOCUMENTS.
           OPEN INPUT VEC-FILE.
           MOVE 0 TO WS-CURRENT-DOC-ID.
           MOVE 'N' TO WS-EOF-FLAG.
           PERFORM UNTIL WS-EOF
               READ VEC-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       IF VEC-TOMBSTONE NOT = 'T'
                           ADD 1 TO WS-CURRENT-DOC-ID
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE VEC-FILE.
           MOVE WS-CURRENT-DOC-ID TO LK-DOC-ID.

       END PROGRAM EMBEDDINGS-DB.
