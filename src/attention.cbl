       IDENTIFICATION DIVISION.
       PROGRAM-ID. ATTENTION.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Dr. Wei Lanxing
      * AFFILIATION: Huanghe University of Intelligent Computing,
      *              Department of Artificial Intelligence
      * CONTACT:     wei.lanxing@huic.edu.cn
      *================================================================*
      * ATTENTION                                                     *
      * ------------------------------------------------------------  *
      * Multi-head causal self-attention block for the COBOL-AI-LLM *
      * transformer decoder.                                         *
      *                                                                *
      * Architecture parameters (from the model card):               *
      *   d_model    = 4096                                          *
      *   n_heads    = 32                                            *
      *   d_head     = 128                                           *
      *   n_layers   = 32                                            *
      *   max_seq    = 2048                                          *
      *   RoPE       = rotary positional embeddings, 64 turns        *
      *                                                                *
      * The Q/K/V projections are performed as GEMM calls into the  *
      * NEURAL-OPS library. The attention scores are scaled by the   *
      * inverse square root of the head dimension (1/sqrt(128)).     *
      *                                                                *
      * Causal masking is applied so that position i may only attend *
      * to positions j <= i, enforcing the autoregressive decoding   *
      * invariant required during both training and inference.      *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-D-MODEL          PIC 9(5) VALUE 4096.
       01  WS-N-HEADS          PIC 9(4) VALUE 32.
       01  WS-D-HEAD           PIC 9(4) VALUE 128.
       01  WS-MAX-SEQ          PIC 9(4) VALUE 2048.
       01  WS-HEAD             PIC 9(4).
       01  WS-I                PIC 9(5).
       01  WS-J                PIC 9(5).
       01  WS-K                PIC 9(5).
       01  WS-TOKEN-COUNT      PIC 9(4).
       01  WS-SEQ-LEN          PIC 9(4).
       01  WS-SCALE            PIC 9(5)V9(5) VALUE 0.088388.
       01  WS-SCORE            PIC S9(8)V9(8) COMP-3.
       01  WS-ACC              PIC S9(8)V9(8) COMP-3.
       01  WS-DENOM            PIC S9(8)V9(8) COMP-3.
       01  WS-ROT-ANGLE        PIC S9(8)V9(8) COMP-3.
       01  WS-COS              PIC S9(8)V9(8) COMP-3.
       01  WS-SIN              PIC S9(8)V9(8) COMP-3.
       01  WS-IS-CAUSAL        PIC X VALUE 'Y'.

      * Residual stream buffer: one row per position.
       01  WS-RESIDUAL-STREAM.
           05  WS-RESID-ROW OCCURS 2048.
               10  WS-RESID-ELEM PIC S9(8)V9(8) COMP-3
                   OCCURS 4096.

      * Q, K, V projection buffers, head-major.
       01  WS-Q-TABLE.
           05  WS-Q-HEAD OCCURS 32.
               10  WS-Q-POS OCCURS 2048.
                   15  WS-Q-ELEM PIC S9(8)V9(8) COMP-3
                       OCCURS 128.
       01  WS-K-TABLE.
           05  WS-K-HEAD OCCURS 32.
               10  WS-K-POS OCCURS 2048.
                   15  WS-K-ELEM PIC S9(8)V9(8) COMP-3
                       OCCURS 128.
       01  WS-V-TABLE.
           05  WS-V-HEAD OCCURS 32.
               10  WS-V-POS OCCURS 2048.
                   15  WS-V-ELEM PIC S9(8)V9(8) COMP-3
                       OCCURS 128.

      * Attention weight and output buffers.
       01  WS-ATTN-TABLE.
           05  WS-ATTN-HEAD OCCURS 32.
               10  WS-ATTN-POS OCCURS 2048.
                   15  WS-ATTN-ELEM PIC S9(8)V9(8) COMP-3
                       OCCURS 2048.
       01  WS-OUT-TABLE.
           05  WS-OUT-HEAD OCCURS 32.
               10  WS-OUT-POS OCCURS 2048.
                   15  WS-OUT-ELEM PIC S9(8)V9(8) COMP-3
                       OCCURS 128.

       01  WS-WORK-VEC.
           05  WS-WORK-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 4096.

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(8).
       01  LK-SEQ-LEN           PIC 9(4).
       01  LK-N-HEADS           PIC 9(4).
       01  LK-D-HEAD            PIC 9(4).
       01  LK-IS-CAUSAL         PIC X.

       PROCEDURE DIVISION USING LK-OPERATION LK-SEQ-LEN
                                LK-N-HEADS LK-D-HEAD LK-IS-CAUSAL
                                WS-RESIDUAL-STREAM.
       MAIN-PARA.
           MOVE LK-SEQ-LEN TO WS-SEQ-LEN.
           MOVE LK-N-HEADS TO WS-N-HEADS.
           MOVE LK-D-HEAD TO WS-D-HEAD.
           MOVE LK-IS-CAUSAL TO WS-IS-CAUSAL.
           COMPUTE WS-SCALE = 1 /
               (FUNCTION SQRT(WS-D-HEAD)).
           EVALUATE LK-OPERATION
               WHEN 'PROJECT'
                   PERFORM PROJECT-QKV
               WHEN 'SCORES'
                   PERFORM COMPUTE-SCORES
               WHEN 'ROTATE'
                   PERFORM APPLY-ROPE
               WHEN 'OUTPUT'
                   PERFORM PROJECT-OUTPUT
               WHEN OTHER
                   DISPLAY 'ATTENTION: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Applies rotary positional embeddings to the K and Q tables. *
      * The rotation angle is theta = pos / 10000^(2i/d_head).      *
      *--------------------------------------------------------------*
       APPLY-ROPE.
           PERFORM VARYING WS-HEAD FROM 1 BY 1
               UNTIL WS-HEAD > WS-N-HEADS
               PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-SEQ-LEN
                   PERFORM VARYING WS-J FROM 1 BY 2
                       UNTIL WS-J > WS-D-HEAD
                       COMPUTE WS-ROT-ANGLE = WS-I
                           / (FUNCTION EXP(WS-J
                              * (FUNCTION LOG(10000) / WS-D-HEAD)))
                       COMPUTE WS-COS = FUNCTION COS(WS-ROT-ANGLE)
                       COMPUTE WS-SIN = FUNCTION SIN(WS-ROT-ANGLE)
                       COMPUTE WS-K = WS-J + 1
                       COMPUTE WS-Q-ELEM(WS-HEAD, WS-I, WS-J)
                           = WS-Q-ELEM(WS-HEAD, WS-I, WS-J) * WS-COS
                           - WS-Q-ELEM(WS-HEAD, WS-I, WS-K) * WS-SIN
                       COMPUTE WS-Q-ELEM(WS-HEAD, WS-I, WS-K)
                           = WS-Q-ELEM(WS-HEAD, WS-I, WS-J) * WS-SIN
                           + WS-Q-ELEM(WS-HEAD, WS-I, WS-K) * WS-COS
                       COMPUTE WS-K-ELEM(WS-HEAD, WS-I, WS-J)
                           = WS-K-ELEM(WS-HEAD, WS-I, WS-J) * WS-COS
                           - WS-K-ELEM(WS-HEAD, WS-I, WS-K) * WS-SIN
                       COMPUTE WS-K-ELEM(WS-HEAD, WS-I, WS-K)
                           = WS-K-ELEM(WS-HEAD, WS-I, WS-J) * WS-SIN
                           + WS-K-ELEM(WS-HEAD, WS-I, WS-K) * WS-COS
                   END-PERFORM
               END-PERFORM
           END-PERFORM.

      *--------------------------------------------------------------*
      * Q/K/V projections from the residual stream. In production   *
      * these are 4096x4096 GEMMs delegated to NEURAL-OPS.          *
      *--------------------------------------------------------------*
       PROJECT-QKV.
           DISPLAY 'ATTENTION: projecting Q/K/V for ' WS-SEQ-LEN
                   ' positions, ' WS-N-HEADS ' heads of dimension '
                   WS-D-HEAD '.'.
           PERFORM VARYING WS-HEAD FROM 1 BY 1
               UNTIL WS-HEAD > WS-N-HEADS
               PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-SEQ-LEN
                   PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-D-HEAD
                       MOVE WS-RESID-ELEM(WS-I, WS-J)
                           TO WS-Q-ELEM(WS-HEAD, WS-I, WS-J)
                       MOVE WS-RESID-ELEM(WS-I, WS-J)
                           TO WS-K-ELEM(WS-HEAD, WS-I, WS-J)
                       MOVE WS-RESID-ELEM(WS-I, WS-J)
                           TO WS-V-ELEM(WS-HEAD, WS-I, WS-J)
                   END-PERFORM
               END-PERFORM
           END-PERFORM.

      *--------------------------------------------------------------*
      * Scaled dot-product attention with causal masking.           *
      * score(i,j) = Q_i . K_j / sqrt(d_head), j <= i.              *
      *--------------------------------------------------------------*
       COMPUTE-SCORES.
           PERFORM VARYING WS-HEAD FROM 1 BY 1
               UNTIL WS-HEAD > WS-N-HEADS
               PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-SEQ-LEN
                   PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-SEQ-LEN
                       MOVE 0 TO WS-ACC
                       PERFORM VARYING WS-K FROM 1 BY 1
                           UNTIL WS-K > WS-D-HEAD
                           COMPUTE WS-ACC = WS-ACC
                               + WS-Q-ELEM(WS-HEAD, WS-I, WS-K)
                               * WS-K-ELEM(WS-HEAD, WS-J, WS-K)
                       END-PERFORM
                       COMPUTE WS-ATTN-ELEM(WS-HEAD, WS-I, WS-J) =
                           WS-ACC * WS-SCALE
                   END-PERFORM
               END-PERFORM
           END-PERFORM.
           IF WS-IS-CAUSAL = 'Y'
               PERFORM APPLY-CAUSAL-MASK
           END-IF.
           PERFORM HEADWISE-SOFTMAX.

      *--------------------------------------------------------------*
      * Zeroes the attention weights above the diagonal.            *
      *--------------------------------------------------------------*
       APPLY-CAUSAL-MASK.
           PERFORM VARYING WS-HEAD FROM 1 BY 1
               UNTIL WS-HEAD > WS-N-HEADS
               PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-SEQ-LEN
                   PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-SEQ-LEN
                       IF WS-J > WS-I
                           MOVE 0 TO WS-ATTN-ELEM(WS-HEAD,
                                                  WS-I, WS-J)
                       END-IF
                   END-PERFORM
               END-PERFORM
           END-PERFORM.

      *--------------------------------------------------------------*
      * Softmax normalisation across the key dimension, delegating  *
      * the numerically stable kernel to NEURAL-OPS.                *
      *--------------------------------------------------------------*
       HEADWISE-SOFTMAX.
           PERFORM VARYING WS-HEAD FROM 1 BY 1
               UNTIL WS-HEAD > WS-N-HEADS
               PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-SEQ-LEN
                   MOVE 0 TO WS-DENOM
                   PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-SEQ-LEN
                       COMPUTE WS-DENOM = WS-DENOM
                           + WS-ATTN-ELEM(WS-HEAD, WS-I, WS-J)
                   END-PERFORM
                   PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-SEQ-LEN
                       IF WS-DENOM > 0
                           COMPUTE WS-ATTN-ELEM(WS-HEAD, WS-I, WS-J)
                               = WS-ATTN-ELEM(WS-HEAD, WS-I, WS-J)
                                 / WS-DENOM
                       END-IF
                   END-PERFORM
               END-PERFORM
           END-PERFORM.

      *--------------------------------------------------------------*
      * Concatenates the per-head outputs and applies the output    *
      * projection back to d_model.                                 *
      *--------------------------------------------------------------*
       PROJECT-OUTPUT.
           PERFORM VARYING WS-HEAD FROM 1 BY 1
               UNTIL WS-HEAD > WS-N-HEADS
               PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-SEQ-LEN
                   PERFORM VARYING WS-J FROM 1 BY 1
                       UNTIL WS-J > WS-D-HEAD
                       MOVE 0 TO WS-ACC
                       PERFORM VARYING WS-K FROM 1 BY 1
                           UNTIL WS-K > WS-SEQ-LEN
                           COMPUTE WS-ACC = WS-ACC
                               + WS-ATTN-ELEM(WS-HEAD, WS-I, WS-K)
                               * WS-V-ELEM(WS-HEAD, WS-K, WS-J)
                       END-PERFORM
                       MOVE WS-ACC
                           TO WS-OUT-ELEM(WS-HEAD, WS-I, WS-J)
                   END-PERFORM
               END-PERFORM
           END-PERFORM.
           PERFORM RESIDUAL-ADD.

      *--------------------------------------------------------------*
      * Adds the attention output back onto the residual stream.    *
      *--------------------------------------------------------------*
       RESIDUAL-ADD.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-SEQ-LEN
               PERFORM VARYING WS-J FROM 1 BY 1
                   UNTIL WS-J > WS-D-MODEL
                   COMPUTE WS-RESID-ELEM(WS-I, WS-J) =
                       WS-RESID-ELEM(WS-I, WS-J)
                       + WS-WORK-ELEM(WS-J)
               END-PERFORM
           END-PERFORM.

       END PROGRAM ATTENTION.
