       IDENTIFICATION DIVISION.
       PROGRAM-ID. EMBEDDING.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * EMBEDDING                                                     *
      * ------------------------------------------------------------  *
      * Token embedding layer for the COBOL-AI-LLM family.           *
      *                                                                *
      * The embedding matrix is a 50,024 x 4,096 table of COMP-3    *
      * fixed-point weights, laid out as a flat VSAM-adjacent       *
      * sequential file (models/cobol-7b.emb).                       *
      *                                                                *
      * Two projection heads are supported:                         *
      *   EMBED   - the residual stream input embedding (d_model)    *
      *   UNEMBED - the lm_head logit projection (shared weights)    *
      *                                                                *
      * Memory footprint on a 16 MB partition: 8,392,704 bytes of   *
      * compressed decimal data. Portions not resident are faulted  *
      * in on demand through the pageable library.                   *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMB-FILE ASSIGN TO 'models/cobol-7b.emb'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS EMB-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  EMB-FILE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F
           BLOCK CONTAINS 0 RECORDS.
       01  EMB-REC.
           05  EMB-TOKEN-ID     PIC 9(5).
           05  EMB-VECTOR       PIC X(16384).

       WORKING-STORAGE SECTION.
       01  EMB-STATUS           PIC XX.
           88  EMB-OK           VALUE '00'.
       01  WS-EOF-FLAG          PIC X VALUE 'N'.
       01  WS-CURRENT-TOKEN     PIC 9(5).
       01  WS-TARGET-TOKEN      PIC 9(5).
       01  WS-DIM               PIC 9(5) VALUE 4096.
       01  WS-I                 PIC 9(5).
       01  WS-EMB-FOUND         PIC X VALUE 'N'.

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(8).
       01  LK-TOKEN-ID          PIC 9(5).
       01  LK-VECTOR-TABLE.
           05  LK-VECTOR-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 4096.
       01  LK-RESULT            PIC X(16).

       PROCEDURE DIVISION USING LK-OPERATION LK-TOKEN-ID
                                LK-VECTOR-TABLE LK-RESULT.
       MAIN-PARA.
           EVALUATE LK-OPERATION
               WHEN 'EMBED'
                   PERFORM LOOKUP-EMBEDDING
               WHEN 'UNEMBED'
                   PERFORM LOOKUP-UNEMBEDDING
               WHEN OTHER
                   DISPLAY 'EMBEDDING: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Sequential scan of the embedding file for the requested     *
      * token id. A production deployment would index this table;   *
      * we intentionally keep the linear scan to bound memory.      *
      *--------------------------------------------------------------*
       LOOKUP-EMBEDDING.
           MOVE LK-TOKEN-ID TO WS-TARGET-TOKEN.
           OPEN INPUT EMB-FILE.
           IF NOT EMB-OK
               DISPLAY 'EMBEDDING: Unable to open models/cobol-7b.emb.'
               MOVE 'MISS' TO LK-RESULT
               GOBACK
           END-IF.
           MOVE 'N' TO WS-EMB-FOUND.
           PERFORM UNTIL WS-EOF OR WS-EMB-FOUND = 'Y'
               READ EMB-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       IF EMB-TOKEN-ID = WS-TARGET-TOKEN
                           MOVE 'Y' TO WS-EMB-FOUND
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE EMB-FILE.
           IF WS-EMB-FOUND = 'Y'
               MOVE 'HIT' TO LK-RESULT
           ELSE
               DISPLAY 'EMBEDDING: Token ' WS-TARGET-TOKEN
                       ' out of vocabulary.'
               MOVE 'OOV' TO LK-RESULT
           END-IF.

      *--------------------------------------------------------------*
      * The unembedding projection reuses the same weights and      *
      * applies the lm_head scale factor of 0.5 (tied embeddings).  *
      *--------------------------------------------------------------*
       LOOKUP-UNEMBEDDING.
           PERFORM LOOKUP-EMBEDDING.
           IF LK-RESULT = 'HIT'
               PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
                   COMPUTE LK-VECTOR-ELEM(WS-I) =
                       LK-VECTOR-ELEM(WS-I) * 0.5
               END-PERFORM
           END-IF.

       END PROGRAM EMBEDDING.
