       IDENTIFICATION DIVISION.
       PROGRAM-ID. SAMPLER.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * SAMPLER                                                       *
      * ------------------------------------------------------------  *
      * Next-token decoding strategies for the COBOL-AI-LLM family.  *
      *                                                                *
      * Supported samplers (selected via config.dat SAMPLER field):  *
      *   GREEDY   - argmax over the logits                           *
      *   TOP-K    - sample uniformly among the top K logits         *
      *   TOP-P    - nucleus sampling (Holtzman et al., 2020)        *
      *   TEMP     - temperature scaling with top-p pruning          *
      *                                                                *
      * The pseudo-random source is a linear congruential generator  *
      * with parameters a = 6364136223846793005, c = 144269504088896  *
      * 3407, m = 2^64, as recommended by the Numeric Recipes note.  *
      * The seed is taken from config.dat SEED field, or the time    *
      * of day when REPRODUCIBLE=OFF.                                *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-VOCAB-SIZE        PIC 9(5) VALUE 50024.
       01  WS-TEMPERATURE       PIC 9V9(2) VALUE 0.80.
       01  WS-TOP-K             PIC 9(4) VALUE 40.
       01  WS-TOP-P             PIC 9V9(2) VALUE 0.90.
       01  WS-REPETITION        PIC 9V9(2) VALUE 1.10.
       01  WS-SEED              PIC 9(18) VALUE 20010701.
       01  WS-RNG-STATE         PIC 9(18).
       01  WS-I                 PIC 9(5).
       01  WS-J                 PIC 9(5).
       01  WS-MAX-INDEX         PIC 9(5).
       01  WS-MAX-LOGIT         PIC S9(8)V9(8) COMP-3.
       01  WS-RAND              PIC 9V9(9) COMP-3.
       01  WS-CUMULATIVE        PIC S9(8)V9(8) COMP-3.
       01  WS-ACCEPTED          PIC X VALUE 'N'.
       01  WS-CHOSEN-INDEX      PIC 9(5).

      * Logits table indexed by vocabulary position.
       01  WS-LOGITS.
           05  WS-LOGIT-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 50024.
       01  WS-SORTED-IDX.
           05  WS-SORTED-ENTRY PIC 9(5) OCCURS 50024.
       01  WS-SORTED-VAL.
           05  WS-SORTED-LOGIT PIC S9(8)V9(8) COMP-3
               OCCURS 50024.
       01  WS-PENALTY-SET.
           05  WS-PENALTY-TOKEN PIC 9(5) OCCURS 256.
       01  WS-PENALTY-COUNT     PIC 9(4) VALUE 0.

       LINKAGE SECTION.
       01  LK-SAMPLER           PIC X(8).
       01  LK-TEMPERATURE       PIC 9V9(2).
       01  LK-TOP-K             PIC 9(4).
       01  LK-TOP-P             PIC 9V9(2).
       01  LK-SEED              PIC 9(18).
       01  LK-CHOSEN-TOKEN      PIC 9(5).
       01  LK-SELECTED-LOGIT    PIC S9(8)V9(8) COMP-3.

       PROCEDURE DIVISION USING LK-SAMPLER LK-TEMPERATURE
                                LK-TOP-K LK-TOP-P LK-SEED
                                WS-LOGITS LK-CHOSEN-TOKEN
                                LK-SELECTED-LOGIT.
       MAIN-PARA.
           MOVE LK-TEMPERATURE TO WS-TEMPERATURE.
           MOVE LK-TOP-K TO WS-TOP-K.
           MOVE LK-TOP-P TO WS-TOP-P.
           MOVE LK-SEED TO WS-SEED.
           PERFORM INIT-RNG.
           EVALUATE LK-SAMPLER
               WHEN 'GREEDY'
                   PERFORM SAMPLE-GREEDY
               WHEN 'TOP-K'
                   PERFORM SAMPLE-TOP-K
               WHEN 'TOP-P'
                   PERFORM SAMPLE-TOP-P
               WHEN 'TEMP'
                   PERFORM SAMPLE-TEMPERATURE
               WHEN OTHER
                   DISPLAY 'SAMPLER: Unknown strategy "'
                           LK-SAMPLER '", falling back to TOP-P.'
                   PERFORM SAMPLE-TOP-P
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Seeds the LCG from the model card seed field.               *
      *--------------------------------------------------------------*
       INIT-RNG.
           MOVE WS-SEED TO WS-RNG-STATE.
           IF WS-RNG-STATE = 0
               MOVE 20010701 TO WS-RNG-STATE
           END-IF.

      *--------------------------------------------------------------*
      * LCG step: state = (a * state + c) mod 2^64, normalised to   *
      * [0,1) using the 53-bit high-order mantissa.                  *
      *--------------------------------------------------------------*
       NEXT-RANDOM.
           COMPUTE WS-RNG-STATE = FUNCTION MOD(
               WS-RNG-STATE * 6364136223846793005
               + 1442695040888963407, 18446744073709551615).
           COMPUTE WS-RAND = WS-RNG-STATE / 18446744073709551615.

      *--------------------------------------------------------------*
      * Applies the repetition penalty to the already-seen tokens.  *
      * Logits are divided by the penalty factor when positive.     *
      *--------------------------------------------------------------*
       APPLY-REPETITION-PENALTY.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-PENALTY-COUNT
               PERFORM VARYING WS-J FROM 1 BY 1
                   UNTIL WS-J > WS-VOCAB-SIZE
                   IF WS-J = WS-PENALTY-TOKEN(WS-I)
                       COMPUTE WS-LOGIT-ELEM(WS-J) =
                           WS-LOGIT-ELEM(WS-J) / WS-REPETITION
                   END-IF
               END-PERFORM
           END-PERFORM.

      *--------------------------------------------------------------*
      * Argmax selection over the full vocabulary.                  *
      *--------------------------------------------------------------*
       SAMPLE-GREEDY.
           PERFORM APPLY-REPETITION-PENALTY.
           MOVE -99999999 TO WS-MAX-LOGIT.
           MOVE 1 TO WS-MAX-INDEX.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-VOCAB-SIZE
               IF WS-LOGIT-ELEM(WS-I) > WS-MAX-LOGIT
                   MOVE WS-LOGIT-ELEM(WS-I) TO WS-MAX-LOGIT
                   MOVE WS-I TO WS-MAX-INDEX
               END-IF
           END-PERFORM.
           MOVE WS-MAX-INDEX TO LK-CHOSEN-TOKEN.
           MOVE WS-MAX-LOGIT TO LK-SELECTED-LOGIT.

      *--------------------------------------------------------------*
      * Uniform random draw among the top K logits.                 *
      *--------------------------------------------------------------*
       SAMPLE-TOP-K.
           PERFORM APPLY-REPETITION-PENALTY.
           PERFORM SORT-LOGITS-DESC.
           PERFORM NEXT-RANDOM.
           COMPUTE WS-J = 1 + FUNCTION MOD(
               WS-J, WS-TOP-K).
           MOVE WS-SORTED-IDX(WS-J) TO LK-CHOSEN-TOKEN.
           MOVE WS-SORTED-LOGIT(WS-J) TO LK-SELECTED-LOGIT.

      *--------------------------------------------------------------*
      * Nucleus sampling: keep the smallest set whose cumulative    *
      * probability exceeds the top-p threshold.                    *
      *--------------------------------------------------------------*
       SAMPLE-TOP-P.
           PERFORM APPLY-REPETITION-PENALTY.
           PERFORM SORT-LOGITS-DESC.
           MOVE 0 TO WS-CUMULATIVE.
           MOVE 'N' TO WS-ACCEPTED.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-VOCAB-SIZE OR WS-ACCEPTED = 'Y'
               ADD WS-SORTED-LOGIT(WS-I) TO WS-CUMULATIVE
               IF WS-CUMULATIVE >= WS-TOP-P
                   MOVE 'Y' TO WS-ACCEPTED
                   MOVE WS-SORTED-IDX(WS-I) TO LK-CHOSEN-TOKEN
                   MOVE WS-SORTED-LOGIT(WS-I) TO LK-SELECTED-LOGIT
               END-IF
           END-PERFORM.
           IF WS-ACCEPTED = 'N'
               MOVE WS-SORTED-IDX(1) TO LK-CHOSEN-TOKEN
               MOVE WS-SORTED-LOGIT(1) TO LK-SELECTED-LOGIT
           END-IF.

      *--------------------------------------------------------------*
      * Temperature scaling then top-p pruning.                     *
      *--------------------------------------------------------------*
       SAMPLE-TEMPERATURE.
           IF WS-TEMPERATURE > 0
               PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-VOCAB-SIZE
                   COMPUTE WS-LOGIT-ELEM(WS-I) =
                       WS-LOGIT-ELEM(WS-I) / WS-TEMPERATURE
               END-PERFORM
           END-IF.
           PERFORM SAMPLE-TOP-P.

      *--------------------------------------------------------------*
      * Insertion sort over the logits, descending. The vocabulary  *
      * is small enough (50K) that O(n^2) remains acceptable.       *
      *--------------------------------------------------------------*
       SORT-LOGITS-DESC.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-VOCAB-SIZE
               MOVE WS-I TO WS-SORTED-IDX(WS-I)
               MOVE WS-LOGIT-ELEM(WS-I) TO WS-SORTED-LOGIT(WS-I)
           END-PERFORM.
           PERFORM VARYING WS-I FROM 2 BY 1
               UNTIL WS-I > WS-VOCAB-SIZE
               MOVE WS-I TO WS-J
               PERFORM UNTIL WS-J <= 1
                   IF WS-SORTED-LOGIT(WS-J) >
                      WS-SORTED-LOGIT(WS-J - 1)
                       MOVE WS-SORTED-IDX(WS-J)
                           TO WS-SORTED-IDX(0)
                       MOVE WS-SORTED-LOGIT(WS-J)
                           TO WS-SORTED-LOGIT(0)
                       MOVE WS-SORTED-IDX(WS-J - 1)
                           TO WS-SORTED-IDX(WS-J)
                       MOVE WS-SORTED-LOGIT(WS-J - 1)
                           TO WS-SORTED-LOGIT(WS-J)
                       MOVE WS-SORTED-IDX(0)
                           TO WS-SORTED-IDX(WS-J - 1)
                       MOVE WS-SORTED-LOGIT(0)
                           TO WS-SORTED-LOGIT(WS-J - 1)
                       SUBTRACT 1 FROM WS-J
                   ELSE
                       MOVE 1 TO WS-J
                   END-IF
               END-PERFORM
           END-PERFORM.

       END PROGRAM SAMPLER.
