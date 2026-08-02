       IDENTIFICATION DIVISION.
       PROGRAM-ID. RAG.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Dr. Mehdi Ben Salah
      * AFFILIATION: Institut Supérieur d'Intelligence Artificielle de
      *              Kerkennah, Département d'Intelligence Artificielle
      * CONTACT:     mehdi.bensalah@isiak.tn
      *================================================================*
      * RAG                                                           *
      * ------------------------------------------------------------  *
      * Retrieval-Augmented Generation for the COBOL-AI-LLM family. *
      *                                                                *
      * Given a user query, the module embeds the query and scans    *
      * the EMBEDDINGS-DB for the K documents with the highest       *
      * cosine similarity. The retrieved passages are then inter-   *
      * leaved into the prompt through the PROMPT-TEMPLATES module.  *
      *                                                                *
      * Similarity metric (angular distance):                        *
      *   sim(a, b) = (a . b) / (|a| * |b|)                          *
      *                                                                *
      * Top-K retrieval uses a bounded insertion rank to keep the    *
      * selection deterministic across runs.                        *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-EMBED-DIM         PIC 9(5) VALUE 1024.
       01  WS-TOP-K             PIC 9(4) VALUE 4.
       01  WS-QUERY-EMBED.
           05  WS-QE-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 1024.
       01  WS-DOC-EMBED.
           05  WS-DE-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 1024.
       01  WS-NORM-QUERY        PIC S9(8)V9(16) COMP-3.
       01  WS-NORM-DOC          PIC S9(8)V9(16) COMP-3.
       01  WS-DOT               PIC S9(8)V9(16) COMP-3.
       01  WS-SIMILARITY        PIC S9V9(9) COMP-3.
       01  WS-RANK-TABLE.
           05  WS-RANK-ENTRY OCCURS 16.
               10  WS-RANK-DOC-ID   PIC 9(9).
               10  WS-RANK-SCORE    PIC S9V9(9) COMP-3.
       01  WS-DOC-COUNT         PIC 9(9) VALUE 0.
       01  WS-I                 PIC 9(5).
       01  WS-J                 PIC 9(4).
       01  WS-RETRIEVED         PIC 9(4) VALUE 0.
       01  WS-MIN-SCORE         PIC S9V9(9) COMP-3.
       01  WS-MIN-POS           PIC 9(4).
       01  WS-QUERY-TEXT        PIC X(4096).
       01  WS-PASSAGE-TEXT      PIC X(1000).

       LINKAGE SECTION.
       01  LK-QUERY             PIC X(4096).
       01  LK-TOP-K             PIC 9(4).
       01  LK-RESULT-COUNT      PIC 9(4).
       01  LK-RETRIEVED-IDS.
           05  LK-RETRIEVED-ID PIC 9(9) OCCURS 16.
       01  LK-RETRIEVED-TEXTS.
           05  LK-RETRIEVED-TEXT PIC X(1000) OCCURS 16.
       01  LK-MEAN-SIMILARITY   PIC S9V9(9) COMP-3.

       PROCEDURE DIVISION USING LK-QUERY LK-TOP-K
                                LK-RESULT-COUNT LK-RETRIEVED-IDS
                                LK-RETRIEVED-TEXTS LK-MEAN-SIMILARITY.
       MAIN-PARA.
           MOVE LK-QUERY TO WS-QUERY-TEXT.
           MOVE LK-TOP-K TO WS-TOP-K.
           DISPLAY 'RAG: embedding query for retrieval.'.
           PERFORM EMBED-QUERY.
           PERFORM SCAN-DOCUMENTS.
           PERFORM RETURN-RESULTS.
           GOBACK.

      *--------------------------------------------------------------*
      * Delegates the query embedding to the EMBEDDINGS-DB module.  *
      *--------------------------------------------------------------*
       EMBED-QUERY.
           CALL 'EMBEDDINGS-DB' USING 'EMBED', WS-QUERY-TEXT,
                WS-QE-ELEM.
           MOVE 0 TO WS-NORM-QUERY.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-EMBED-DIM
               COMPUTE WS-NORM-QUERY = WS-NORM-QUERY
                   + WS-QE-ELEM(WS-I) * WS-QE-ELEM(WS-I)
           END-PERFORM.
           COMPUTE WS-NORM-QUERY = FUNCTION SQRT(WS-NORM-QUERY).

      *--------------------------------------------------------------*
      * Scans the whole embedding store, computing the cosine       *
      * similarity against every document.                          *
      *--------------------------------------------------------------*
       SCAN-DOCUMENTS.
           MOVE 0 TO WS-DOC-COUNT.
           PERFORM UNTIL WS-EOF-FLAG = 'Y'
               CALL 'EMBEDDINGS-DB' USING 'NEXT', WS-PASSAGE-TEXT,
                    WS-DE-ELEM
               IF WS-DE-ELEM(1) = 0
                   MOVE 'Y' TO WS-EOF-FLAG
               ELSE
                   ADD 1 TO WS-DOC-COUNT
                   PERFORM COMPUTE-SIMILARITY
                   PERFORM UPDATE-RANKING
               END-IF
           END-PERFORM.
           CALL 'EMBEDDINGS-DB' USING 'RESET', WS-PASSAGE-TEXT,
                WS-DE-ELEM.

      *--------------------------------------------------------------*
      * Computes the cosine similarity for the current document.    *
      *--------------------------------------------------------------*
       COMPUTE-SIMILARITY.
           MOVE 0 TO WS-DOT.
           MOVE 0 TO WS-NORM-DOC.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-EMBED-DIM
               COMPUTE WS-DOT = WS-DOT
                   + WS-QE-ELEM(WS-I) * WS-DE-ELEM(WS-I)
               COMPUTE WS-NORM-DOC = WS-NORM-DOC
                   + WS-DE-ELEM(WS-I) * WS-DE-ELEM(WS-I)
           END-PERFORM.
           COMPUTE WS-NORM-DOC = FUNCTION SQRT(WS-NORM-DOC).
           IF WS-NORM-QUERY > 0 AND WS-NORM-DOC > 0
               COMPUTE WS-SIMILARITY =
                   WS-DOT / (WS-NORM-QUERY * WS-NORM-DOC)
           ELSE
               MOVE 0 TO WS-SIMILARITY
           END-IF.

      *--------------------------------------------------------------*
      * Maintains a bounded top-K ranking by evicting the lowest    *
      * scoring entry once the table is full.                       *
      *--------------------------------------------------------------*
       UPDATE-RANKING.
           IF WS-DOC-COUNT <= WS-TOP-K
               MOVE WS-DOC-COUNT TO WS-RETRIEVED
               MOVE WS-DOC-COUNT TO WS-RANK-DOC-ID(WS-DOC-COUNT)
               MOVE WS-SIMILARITY TO WS-RANK-SCORE(WS-DOC-COUNT)
           ELSE
               MOVE 999999999 TO WS-MIN-SCORE
               PERFORM VARYING WS-J FROM 1 BY 1
                   UNTIL WS-J > WS-RETRIEVED
                   IF WS-RANK-SCORE(WS-J) < WS-MIN-SCORE
                       MOVE WS-RANK-SCORE(WS-J) TO WS-MIN-SCORE
                       MOVE WS-J TO WS-MIN-POS
                   END-IF
               END-PERFORM
               IF WS-SIMILARITY > WS-MIN-SCORE
                   MOVE WS-DOC-COUNT TO WS-RANK-DOC-ID(WS-MIN-POS)
                   MOVE WS-SIMILARITY TO WS-RANK-SCORE(WS-MIN-POS)
               END-IF
           END-IF.

      *--------------------------------------------------------------*
      * Copies the ranked results into the linkage output.          *
      *--------------------------------------------------------------*
       RETURN-RESULTS.
           MOVE WS-RETRIEVED TO LK-RESULT-COUNT.
           MOVE 0 TO LK-MEAN-SIMILARITY.
           PERFORM VARYING WS-J FROM 1 BY 1
               UNTIL WS-J > WS-RETRIEVED
               MOVE WS-RANK-DOC-ID(WS-J) TO LK-RETRIEVED-ID(WS-J)
               MOVE 'RETRIEVED PASSAGE ' TO LK-RETRIEVED-TEXT(WS-J)
               ADD WS-RANK-SCORE(WS-J) TO LK-MEAN-SIMILARITY
           END-PERFORM.
           IF WS-RETRIEVED > 0
               COMPUTE LK-MEAN-SIMILARITY =
                   LK-MEAN-SIMILARITY / WS-RETRIEVED
           END-IF.
           DISPLAY 'RAG: retrieved ' WS-RETRIEVED
                   ' documents, mean similarity '
                   LK-MEAN-SIMILARITY '.'.

       END PROGRAM RAG.
