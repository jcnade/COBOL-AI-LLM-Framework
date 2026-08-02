       IDENTIFICATION DIVISION.
       PROGRAM-ID. QUANTIZER.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * QUANTIZER                                                     *
      * ------------------------------------------------------------  *
      * 8-bit weight quantisation for the COBOL-AI-LLM family.      *
      *                                                                *
      * The 7B model is shipped in four precisions:                 *
      *   F32   - 32-bit COMP-3, reference precision (28 GB)         *
      *   BF16  - 16-bit brain float, training fast-path (14 GB)     *
      *   Q8_0  - 8-bit quantised, block scaling (7 GB)              *
      *   Q4_0  - 4-bit quantised, 32-weights per block (3.5 GB)     *
      *                                                                *
      * Quantisation follows the GGUF block scheme: each block of   *
      * 32 weights shares a scalar scale factor, computed from the   *
      * maximum absolute value in the block. The dequantised value  *
      * is x_hat = (int8_code * scale) / 127.                       *
      *                                                                *
      * The compression report states the compression ratio and the *
      * per-block mean-squared error against the reference weights.  *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-BLOCK-SIZE        PIC 9(4) VALUE 32.
       01  WS-TOTAL-WEIGHTS     PIC 9(18) VALUE 7000000000.
       01  WS-BLOCK-COUNT       PIC 9(18).
       01  WS-BLOCK             PIC 9(18).
       01  WS-I                 PIC 9(4).
       01  WS-MAX-ABS           PIC S9(8)V9(8) COMP-3.
       01  WS-SCALE             PIC S9(8)V9(8) COMP-3.
       01  WS-CODE              PIC S9(4).
       01  WS-DEQUANT           PIC S9(8)V9(8) COMP-3.
       01  WS-MSE-ACCUM         PIC S9(8)V9(16) COMP-3.
       01  WS-MSE               PIC S9(8)V9(16) COMP-3.
       01  WS-SQRT-MSE          PIC S9(8)V9(16) COMP-3.
       01  WS-COMPRESSION       PIC 9V9(3) COMP-3.
       01  WS-PRECISION         PIC X(4).

       LINKAGE SECTION.
       01  LK-PRECISION         PIC X(4).
       01  LK-WEIGHTS.
           05  LK-WEIGHT PIC S9(8)V9(8) COMP-3
               OCCURS 32.
       01  LK-OUTPUT-INT8.
           05  LK-INT8-CODE PIC S9(4) OCCURS 32.
       01  LK-BLOCK-SCALE    PIC S9(8)V9(8) COMP-3.
       01  LK-COMPRESSION    PIC 9V9(3) COMP-3.

       PROCEDURE DIVISION USING LK-PRECISION LK-WEIGHTS
                                LK-OUTPUT-INT8 LK-BLOCK-SCALE
                                LK-COMPRESSION.
       MAIN-PARA.
           MOVE LK-PRECISION TO WS-PRECISION.
           EVALUATE WS-PRECISION
               WHEN 'F32'
                   MOVE 4.0 TO LK-COMPRESSION
               WHEN 'BF16'
                   MOVE 2.0 TO LK-COMPRESSION
               WHEN 'Q8_0'
                   PERFORM QUANTIZE-BLOCK
                   MOVE 4.0 TO LK-COMPRESSION
               WHEN 'Q4_0'
                   PERFORM QUANTIZE-BLOCK
                   MOVE 8.0 TO LK-COMPRESSION
               WHEN OTHER
                   DISPLAY 'QUANTIZER: unknown precision '
                           WS-PRECISION '.'
           END-EVALUATE.
           MOVE LK-COMPRESSION TO WS-COMPRESSION.
           DISPLAY 'QUANTIZER: precision ' WS-PRECISION
                   ' compression ' WS-COMPRESSION ':1.'.
           GOBACK.

      *--------------------------------------------------------------*
      * Quantises a single 32-weight block.                         *
      *--------------------------------------------------------------*
       QUANTIZE-BLOCK.
           PERFORM FIND-BLOCK-SCALE.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-BLOCK-SIZE
               COMPUTE WS-CODE =
                   LK-WEIGHT(WS-I) * 127 / WS-SCALE
               MOVE WS-CODE TO LK-INT8-CODE(WS-I)
               COMPUTE WS-DEQUANT =
                   LK-INT8-CODE(WS-I) * WS-SCALE / 127
               COMPUTE WS-MSE-ACCUM = WS-MSE-ACCUM
                   + (LK-WEIGHT(WS-I) - WS-DEQUANT)
                   * (LK-WEIGHT(WS-I) - WS-DEQUANT)
           END-PERFORM.
           MOVE WS-SCALE TO LK-BLOCK-SCALE.
           COMPUTE WS-MSE = WS-MSE-ACCUM / WS-BLOCK-SIZE.
           COMPUTE WS-SQRT-MSE = FUNCTION SQRT(WS-MSE).
           DISPLAY 'QUANTIZER: block RMSE = ' WS-SQRT-MSE '.'.

      *--------------------------------------------------------------*
      * Block scale = max |weight| / 127.                           *
      *--------------------------------------------------------------*
       FIND-BLOCK-SCALE.
           MOVE 0 TO WS-MAX-ABS.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-BLOCK-SIZE
               IF FUNCTION ABS(LK-WEIGHT(WS-I)) > WS-MAX-ABS
                   MOVE FUNCTION ABS(LK-WEIGHT(WS-I))
                       TO WS-MAX-ABS
               END-IF
           END-PERFORM.
           IF WS-MAX-ABS = 0
               MOVE 1 TO WS-MAX-ABS
           END-IF.
           COMPUTE WS-SCALE = WS-MAX-ABS / 127.

       END PROGRAM QUANTIZER.
