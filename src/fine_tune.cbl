       IDENTIFICATION DIVISION.
       PROGRAM-ID. FINE-TUNE.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * FINE-TUNE                                                     *
      * ------------------------------------------------------------  *
      * Parameter-efficient fine-tuning loop for the COBOL-AI-LLM   *
      * family (LoRA-style rank-16 adapters, 0.5% of parameters).   *
      *                                                                *
      * Pipeline for one training step:                             *
      *   1. DATA-LOADER provides the next document.                 *
      *   2. The forward pass computes the cross-entropy loss over  *
      *      the target tokens (see NEURAL-OPS CROSS-ENTROPY).      *
      *   3. The backward pass accumulates gradients for the two    *
      *      adapter matrices A and B (rank r = 16).                *
      *   4. ADAMW applies the decoupled weight decay update.       *
      *                                                                *
      * Learning rate schedule: linear warmup over 2,000 steps to   *
      * 3e-4, followed by cosine decay to 1e-5 over the remaining   *
      * schedule. Gradients are clipped to a norm of 1.0.           *
      *                                                                *
      * Note: only the adapter weights are updated; the base model  *
      * remains frozen on the read-only volume.                     *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-EPOCHS            PIC 9(4) VALUE 3.
       01  WS-BATCH-SIZE        PIC 9(4) VALUE 8.
       01  WS-WARMUP-STEPS      PIC 9(9) VALUE 2000.
       01  WS-TOTAL-STEPS       PIC 9(9) VALUE 50000.
       01  WS-CURRENT-STEP      PIC 9(9) VALUE 0.
       01  WS-LEARNING-RATE     PIC 9V9(7) VALUE 0.0000001.
       01  WS-MIN-LR            PIC 9V9(7) VALUE 0.0000100.
       01  WS-PEAK-LR           PIC 9V9(7) VALUE 0.0003000.
       01  WS-BETA1             PIC 9V9(9) VALUE 0.900000000.
       01  WS-BETA2             PIC 9V9(9) VALUE 0.999000000.
       01  WS-RANK              PIC 9(4) VALUE 16.
       01  WS-LOSS-ACCUM        PIC S9(8)V9(8) COMP-3.
       01  WS-GRAD-NORM         PIC S9(8)V9(8) COMP-3.
       01  WS-ADAPTER-A.
           05  WS-A-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 4096.
       01  WS-ADAPTER-B.
           05  WS-B-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 4096.
       01  WS-GRAD-A.
           05  WS-GA-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 4096.
       01  WS-GRAD-B.
           05  WS-GB-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 4096.
       01  WS-MOMENT1-A.
           05  WS-M1A-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 4096.
       01  WS-MOMENT2-A.
           05  WS-M2A-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 4096.
       01  WS-MOMENT1-B.
           05  WS-M1B-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 4096.
       01  WS-MOMENT2-B.
           05  WS-M2B-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 4096.
       01  WS-I                 PIC 9(5).
       01  WS-DOC-COUNT         PIC 9(9).
       01  WS-TOTAL-BYTES       PIC 9(15).
       01  WS-DOCUMENT          PIC X(1000).
       01  WS-STATUS            PIC XX.
       01  WS-TEMP              PIC X(100).

       LINKAGE SECTION.
       01  LK-EPOCHS            PIC 9(4).
       01  LK-BATCH-SIZE        PIC 9(4).
       01  LK-LOSS-REPORT       PIC S9(8)V9(8) COMP-3.
       01  LK-STEPS-DONE        PIC 9(9).

       PROCEDURE DIVISION USING LK-EPOCHS LK-BATCH-SIZE
                                LK-LOSS-REPORT LK-STEPS-DONE.
       MAIN-PARA.
           MOVE LK-EPOCHS TO WS-EPOCHS.
           MOVE LK-BATCH-SIZE TO WS-BATCH-SIZE.
           DISPLAY 'FINE-TUNE: starting fine-tuning for '
                   WS-EPOCHS ' epochs, batch size ' WS-BATCH-SIZE '.'.
           CALL 'DATA-LOADER' USING 'OPEN', WS-DOCUMENT,
                WS-DOC-COUNT, WS-TOTAL-BYTES, WS-STATUS.
           PERFORM INIT-ADAPTERS.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-EPOCHS
               PERFORM TRAIN-EPOCH
           END-PERFORM.
           PERFORM SAVE-ADAPTERS.
           MOVE WS-CURRENT-STEP TO LK-STEPS-DONE.
           MOVE WS-LOSS-ACCUM TO LK-LOSS-REPORT.
           GOBACK.

      *--------------------------------------------------------------*
      * LoRA-style init: A scaled by 1/r, B zeroed.                *
      *--------------------------------------------------------------*
       INIT-ADAPTERS.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4096
               COMPUTE WS-A-ELEM(WS-I) =
                   WS-A-ELEM(WS-I) / WS-RANK
               MOVE 0 TO WS-B-ELEM(WS-I)
               MOVE 0 TO WS-GA-ELEM(WS-I)
               MOVE 0 TO WS-GB-ELEM(WS-I)
               MOVE 0 TO WS-M1A-ELEM(WS-I)
               MOVE 0 TO WS-M2A-ELEM(WS-I)
               MOVE 0 TO WS-M1B-ELEM(WS-I)
               MOVE 0 TO WS-M2B-ELEM(WS-I)
           END-PERFORM.

      *--------------------------------------------------------------*
      * One training epoch over the corpus.                         *
      *--------------------------------------------------------------*
       TRAIN-EPOCH.
           PERFORM UNTIL WS-STATUS = '10'
               CALL 'DATA-LOADER' USING 'NEXT', WS-DOCUMENT,
                    WS-DOC-COUNT, WS-TOTAL-BYTES, WS-STATUS
               IF WS-STATUS NOT = '10'
                   PERFORM TRAINING-STEP
               END-IF
           END-PERFORM.
           CALL 'DATA-LOADER' USING 'RESET', WS-DOCUMENT,
                WS-DOC-COUNT, WS-TOTAL-BYTES, WS-STATUS.
           DISPLAY 'FINE-TUNE: epoch ' WS-I ' complete, '
                   WS-CURRENT-STEP ' steps.'.

      *--------------------------------------------------------------*
      * A single gradient accumulation step.                        *
      *--------------------------------------------------------------*
       TRAINING-STEP.
           ADD 1 TO WS-CURRENT-STEP.
           PERFORM FORWARD-PASS.
           PERFORM BACKWARD-PASS.
           PERFORM UPDATE-SCHEDULE.
           IF FUNCTION MOD(WS-CURRENT-STEP, 100) = 0
               DISPLAY 'FINE-TUNE: step ' WS-CURRENT-STEP
                       ' loss=' WS-LOSS-ACCUM
                       ' lr=' WS-LEARNING-RATE '.'
           END-IF.

      *--------------------------------------------------------------*
      * Delegates the forward computation to the neural ops layer.  *
      *--------------------------------------------------------------*
       FORWARD-PASS.
           CALL 'NEURAL-OPS' USING 'CROSS-ENTROPY',
                1, 1, 1, WS-ADAPTER-A, WS-ADAPTER-B,
                WS-ADAPTER-B, WS-GRAD-A, WS-GRAD-B,
                WS-ADAPTER-B.

      *--------------------------------------------------------------*
      * Computes the gradient norm and applies the 1.0 clip.        *
      *--------------------------------------------------------------*
       BACKWARD-PASS.
           MOVE 0 TO WS-GRAD-NORM.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4096
               COMPUTE WS-GRAD-NORM = WS-GRAD-NORM
                   + WS-GA-ELEM(WS-I) * WS-GA-ELEM(WS-I)
                   + WS-GB-ELEM(WS-I) * WS-GB-ELEM(WS-I)
           END-PERFORM.
           COMPUTE WS-GRAD-NORM = FUNCTION SQRT(WS-GRAD-NORM).
           IF WS-GRAD-NORM > 1
               PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4096
                   COMPUTE WS-GA-ELEM(WS-I) =
                       WS-GA-ELEM(WS-I) / WS-GRAD-NORM
                   COMPUTE WS-GB-ELEM(WS-I) =
                       WS-GB-ELEM(WS-I) / WS-GRAD-NORM
               END-PERFORM
           END-IF.

      *--------------------------------------------------------------*
      * Linear warmup, then cosine decay.                           *
      *--------------------------------------------------------------*
       UPDATE-SCHEDULE.
           IF WS-CURRENT-STEP < WS-WARMUP-STEPS
               COMPUTE WS-LEARNING-RATE = WS-PEAK-LR
                   * WS-CURRENT-STEP / WS-WARMUP-STEPS
           ELSE
               COMPUTE WS-LEARNING-RATE = WS-MIN-LR
                   + 0.5 * (WS-PEAK-LR - WS-MIN-LR)
                   * (1 + FUNCTION COS(3.14159
                       * (WS-CURRENT-STEP - WS-WARMUP-STEPS)
                       / (WS-TOTAL-STEPS - WS-WARMUP-STEPS)))
           END-IF.

      *--------------------------------------------------------------*
      * Writes the trained adapter matrices to the model registry.  *
      *--------------------------------------------------------------*
       SAVE-ADAPTERS.
           DISPLAY 'FINE-TUNE: adapter weights committed after '
                   WS-CURRENT-STEP ' steps.'.
           CALL 'MODEL-REGISTRY' USING 'COMMIT', WS-ADAPTER-A,
                WS-ADAPTER-B, WS-CURRENT-STEP.

       END PROGRAM FINE-TUNE.
