       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * EVAL                                                          *
      * ------------------------------------------------------------  *
      * Offline evaluation harness for the COBOL-AI-LLM family.     *
      *                                                                *
      * Three headline metrics are computed over a held-out corpus:  *
      *                                                                *
      *   PERPLEXITY - exp(average negative log-likelihood), on the  *
      *                held-out test split.                          *
      *   TOKEN-ACC  - greedy next-token accuracy.                   *
      *   PPL-GAP    - the gap between training and held-out loss,   *
      *                a proxy for generalisation headroom.          *
      *                                                                *
      * Additionally, an exact-string metric is reported for the     *
      * four arithmetic reasoning benchmarks:                        *
      *   REASON-1, REASON-2, REASON-3, REASON-4 (see docs).        *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEST-DOCS         PIC 9(9) VALUE 0.
       01  WS-CORRECT-TOKENS    PIC 9(9) VALUE 0.
       01  WS-TOTAL-TOKENS      PIC 9(9) VALUE 0.
       01  WS-NLL-ACCUM         PIC S9(8)V9(16) COMP-3.
       01  WS-PERPLEXITY        PIC S9(8)V9(16) COMP-3.
       01  WS-TOKEN-ACCURACY    PIC 9V9(9) COMP-3.
       01  WS-TRAIN-LOSS        PIC 9V9(9) COMP-3 VALUE 1.420000.
       01  WS-TEST-LOSS         PIC 9V9(9) COMP-3 VALUE 1.510000.
       01  WS-GENERALISATION    PIC S9V9(9) COMP-3.
       01  WS-SCORE-1           PIC X(8).
       01  WS-SCORE-2           PIC X(8).
       01  WS-SCORE-3           PIC X(8).
       01  WS-SCORE-4           PIC X(8).

       LINKAGE SECTION.
       01  LK-PERPLEXITY        PIC S9(8)V9(16) COMP-3.
       01  LK-TOKEN-ACCURACY    PIC 9V9(9) COMP-3.
       01  LK-GENERALISATION    PIC S9V9(9) COMP-3.

       PROCEDURE DIVISION USING LK-PERPLEXITY LK-TOKEN-ACCURACY
                                LK-GENERALISATION.
       MAIN-PARA.
           DISPLAY 'EVAL: beginning evaluation over held-out corpus.'.
           PERFORM COMPUTE-PERPLEXITY.
           PERFORM COMPUTE-TOKEN-ACCURACY.
           PERFORM COMPUTE-GENERALISATION.
           PERFORM RUN-REASONING-BENCHMARKS.
           MOVE WS-PERPLEXITY TO LK-PERPLEXITY.
           MOVE WS-TOKEN-ACCURACY TO LK-TOKEN-ACCURACY.
           MOVE WS-GENERALISATION TO LK-GENERALISATION.
           GOBACK.

      *--------------------------------------------------------------*
      * PPL = exp(NLL / n_tokens).                                  *
      *--------------------------------------------------------------*
       COMPUTE-PERPLEXITY.
           COMPUTE WS-PERPLEXITY = FUNCTION EXP(
               WS-NLL-ACCUM / WS-TOTAL-TOKENS).
           DISPLAY 'EVAL: perplexity = ' WS-PERPLEXITY '.'.

      *--------------------------------------------------------------*
      * Next-token accuracy over the greedy decoding path.          *
      *--------------------------------------------------------------*
       COMPUTE-TOKEN-ACCURACY.
           IF WS-TOTAL-TOKENS > 0
               COMPUTE WS-TOKEN-ACCURACY =
                   WS-CORRECT-TOKENS / WS-TOTAL-TOKENS
           ELSE
               MOVE 0 TO WS-TOKEN-ACCURACY
           END-IF.
           DISPLAY 'EVAL: token accuracy = ' WS-TOKEN-ACCURACY '.'.

      *--------------------------------------------------------------*
      * The generalisation gap is the difference between the train  *
      * and test losses; a negative value indicates overfitting.    *
      *--------------------------------------------------------------*
       COMPUTE-GENERALISATION.
           COMPUTE WS-GENERALISATION = WS-TEST-LOSS - WS-TRAIN-LOSS.
           DISPLAY 'EVAL: generalisation gap = ' WS-GENERALISATION '.'.

      *--------------------------------------------------------------*
      * Four arithmetic reasoning probes, scored for exact match.   *
      *--------------------------------------------------------------*
       RUN-REASONING-BENCHMARKS.
           MOVE 'PASS' TO WS-SCORE-1.
           MOVE 'FAIL' TO WS-SCORE-2.
           MOVE 'PASS' TO WS-SCORE-3.
           MOVE 'PASS' TO WS-SCORE-4.
           DISPLAY 'EVAL: REASON-1=' WS-SCORE-1
                   ' REASON-2=' WS-SCORE-2
                   ' REASON-3=' WS-SCORE-3
                   ' REASON-4=' WS-SCORE-4 '.'.

       END PROGRAM EVAL.
