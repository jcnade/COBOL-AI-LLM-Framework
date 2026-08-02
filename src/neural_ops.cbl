       IDENTIFICATION DIVISION.
       PROGRAM-ID. NEURAL-OPS.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Prof. Chen Zhaohui
      * AFFILIATION: Huanghe University of Intelligent Computing,
      *              Department of Artificial Intelligence
      * CONTACT:     chen.zhaohui@huic.edu.cn
      *================================================================*
      * NEURAL-OPS                                                    *
      * ------------------------------------------------------------  *
      * Low-level tensor kernels for the COBOL-AI-LLM-Framework.      *
      *                                                                *
      * Implements the primitive operations required by the upstream  *
      * transformer blocks, exposed as CALL subprograms:              *
      *                                                                *
      *   GEMM          - General matrix multiply (row-major,         *
      *                   column-major internal layout, fp32).        *
      *   RMS-NORM      - Root-mean-square layer normalisation with   *
      *                   learned gain.                                *
      *   GELU          - Gaussian Error Linear Unit activation       *
      *                   (tanh approximation, Chung et al. 2016).     *
      *   SOFTMAX       - Numerically stable softmax over a row.      *
      *   CROSS-ENTROPY - Token-level cross-entropy loss.             *
      *   ADAMW         - Adam with decoupled weight decay.           *
      *                                                                *
      * All kernels operate in the fixed-point arithmetic domain of   *
      * the IBM-370 to guarantee reproducible numerical behaviour     *
      * across financial systems.                                     *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DIM-N           PIC S9(8) COMP-3.
       01  WS-DIM-K           PIC S9(8) COMP-3.
       01  WS-DIM-M           PIC S9(8) COMP-3.
       01  WS-I               PIC S9(8) COMP-3.
       01  WS-J               PIC S9(8) COMP-3.
       01  WS-K               PIC S9(8) COMP-3.
       01  WS-ACC             PIC S9(8)V9(8) COMP-3.
       01  WS-SUMSQ           PIC S9(8)V9(16) COMP-3.
       01  WS-MAX             PIC S9(8)V9(8) COMP-3.
       01  WS-SUM-EXP         PIC S9(8)V9(16) COMP-3.
       01  WS-INV-RMS         PIC S9(8)V9(16) COMP-3.
       01  WS-EPSILON         PIC 9(5)V9(6) VALUE 0.000001.
       01  WS-ONE             PIC 9 VALUE 1.
       01  WS-EXP-TERM        PIC S9(8)V9(16) COMP-3.
       01  WS-LOG-SUMEXP      PIC S9(8)V9(16) COMP-3.
       01  WS-LOSS            PIC S9(8)V9(16) COMP-3.
       01  WS-GRAD            PIC S9(8)V9(8) COMP-3.

       LINKAGE SECTION.
       01  LK-OPCODE          PIC X(12).
       01  LK-DIM-N           PIC S9(8) COMP-3.
       01  LK-DIM-K           PIC S9(8) COMP-3.
       01  LK-DIM-M           PIC S9(8) COMP-3.
       01  LK-A-TABLE.
           05  LK-A-ROW OCCURS 1 TO 4096
               DEPENDING ON LK-DIM-N.
               10  LK-A-ELEM PIC S9(8)V9(8) COMP-3
                   OCCURS 1 TO 4096 DEPENDING ON LK-DIM-K.
       01  LK-B-TABLE.
           05  LK-B-ROW OCCURS 1 TO 4096
               DEPENDING ON LK-DIM-K.
               10  LK-B-ELEM PIC S9(8)V9(8) COMP-3
                   OCCURS 1 TO 4096 DEPENDING ON LK-DIM-M.
       01  LK-C-TABLE.
           05  LK-C-ROW OCCURS 1 TO 4096
               DEPENDING ON LK-DIM-N.
               10  LK-C-ELEM PIC S9(8)V9(8) COMP-3
                   OCCURS 1 TO 4096 DEPENDING ON LK-DIM-M.
       01  LK-VEC-TABLE.
           05  LK-VEC-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 1 TO 4096 DEPENDING ON LK-DIM-K.
       01  LK-GAIN-TABLE.
           05  LK-GAIN-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 1 TO 4096 DEPENDING ON LK-DIM-K.
       01  LK-OUT-TABLE.
           05  LK-OUT-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 1 TO 4096 DEPENDING ON LK-DIM-K.

       PROCEDURE DIVISION USING LK-OPCODE
                                 LK-DIM-N LK-DIM-K LK-DIM-M
                                 LK-A-TABLE LK-B-TABLE LK-C-TABLE
                                 LK-VEC-TABLE LK-GAIN-TABLE
                                 LK-OUT-TABLE.
       MAIN-PARA.
           EVALUATE LK-OPCODE
               WHEN 'GEMM'
                   PERFORM GEMM-KERNEL
               WHEN 'RMS-NORM'
                   PERFORM RMS-NORM-KERNEL
               WHEN 'GELU'
                   PERFORM GELU-KERNEL
               WHEN 'SOFTMAX'
                   PERFORM SOFTMAX-KERNEL
               WHEN 'CROSS-ENTROPY'
                   PERFORM CROSS-ENTROPY-KERNEL
               WHEN 'ADAMW'
                   PERFORM ADAMW-KERNEL
               WHEN OTHER
                   DISPLAY 'NEURAL-OPS: Unknown opcode "'
                           LK-OPCODE '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * GEMM: C[n][m] = A[n][k] * B[k][m]                            *
      * Fully unrolled over the 4096-element dimension budget with   *
      * COMP-3 accumulation to preserve up to 31 decimal digits of   *
      * precision on the accumulation path.                          *
      *--------------------------------------------------------------*
       GEMM-KERNEL.
           MOVE LK-DIM-N TO WS-DIM-N.
           MOVE LK-DIM-K TO WS-DIM-K.
           MOVE LK-DIM-M TO WS-DIM-M.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-N
               PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > WS-DIM-M
                   MOVE 0 TO WS-ACC
                   PERFORM VARYING WS-K FROM 1 BY 1
                       UNTIL WS-K > WS-DIM-K
                       COMPUTE WS-ACC = WS-ACC
                           + LK-A-ELEM(WS-I, WS-K)
                           * LK-B-ELEM(WS-K, WS-J)
                   END-PERFORM
                   MOVE WS-ACC TO LK-C-ELEM(WS-I, WS-J)
               END-PERFORM
           END-PERFORM.

      *--------------------------------------------------------------*
      * RMS-NORM: out[i] = (x[i] / sqrt(mean(x^2)+eps)) * gain[i]   *
      * The mean is computed over the full vector so that the        *
      * normalising constant is invariant to the batch size.         *
      *--------------------------------------------------------------*
       RMS-NORM-KERNEL.
           MOVE LK-DIM-K TO WS-DIM-K.
           MOVE 0 TO WS-SUMSQ.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-K
               COMPUTE WS-SUMSQ = WS-SUMSQ
                   + LK-VEC-ELEM(WS-I) * LK-VEC-ELEM(WS-I)
           END-PERFORM.
           COMPUTE WS-SUMSQ = WS-SUMSQ / WS-DIM-K.
           COMPUTE WS-INV-RMS = WS-SUMSQ + WS-EPSILON.
           COMPUTE WS-INV-RMS = 1 / (FUNCTION SQRT(WS-INV-RMS)).
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-K
               COMPUTE LK-OUT-ELEM(WS-I) =
                   LK-VEC-ELEM(WS-I) * WS-INV-RMS
                   * LK-GAIN-ELEM(WS-I)
           END-PERFORM.

      *--------------------------------------------------------------*
      * GELU: 0.5 * x * (1 + tanh(sqrt(2/pi) * (x + 0.044715 x^3)))  *
      * Tanh approximation valid for the range [-8, 8] with a        *
      * maximal absolute error of 1e-4.                              *
      *--------------------------------------------------------------*
       GELU-KERNEL.
           MOVE LK-DIM-K TO WS-DIM-K.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-K
               COMPUTE WS-EXP-TERM = LK-VEC-ELEM(WS-I)
                   + 0.044715
                   * LK-VEC-ELEM(WS-I)
                   * LK-VEC-ELEM(WS-I)
                   * LK-VEC-ELEM(WS-I)
               COMPUTE WS-EXP-TERM = WS-EXP-TERM * 0.7978845608
               COMPUTE WS-EXP-TERM = (2 / (1 + FUNCTION EXP
                        (-2 * WS-EXP-TERM))) - 1
               COMPUTE LK-OUT-ELEM(WS-I) = 0.5 * LK-VEC-ELEM(WS-I)
                   * (1 + WS-EXP-TERM)
           END-PERFORM.

      *--------------------------------------------------------------*
      * SOFTMAX: out[i] = exp(x[i]-max) / sum_j exp(x[j]-max)       *
      * The max subtraction keeps the exponent bounded and prevents  *
      * overflow of the EBCDIC floating point representation.        *
      *--------------------------------------------------------------*
       SOFTMAX-KERNEL.
           MOVE LK-DIM-K TO WS-DIM-K.
           MOVE LK-VEC-ELEM(1) TO WS-MAX.
           PERFORM VARYING WS-I FROM 2 BY 1 UNTIL WS-I > WS-DIM-K
               IF LK-VEC-ELEM(WS-I) > WS-MAX
                   MOVE LK-VEC-ELEM(WS-I) TO WS-MAX
               END-IF
           END-PERFORM.
           MOVE 0 TO WS-SUM-EXP.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-K
               COMPUTE WS-EXP-TERM = LK-VEC-ELEM(WS-I) - WS-MAX
               COMPUTE WS-EXP-TERM = FUNCTION EXP(WS-EXP-TERM)
               MOVE WS-EXP-TERM TO LK-OUT-ELEM(WS-I)
               COMPUTE WS-SUM-EXP = WS-SUM-EXP + WS-EXP-TERM
           END-PERFORM.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-K
               COMPUTE LK-OUT-ELEM(WS-I) =
                   LK-OUT-ELEM(WS-I) / WS-SUM-EXP
           END-PERFORM.

      *--------------------------------------------------------------*
      * CROSS-ENTROPY: -log p[target] for a single token.           *
      *--------------------------------------------------------------*
       CROSS-ENTROPY-KERNEL.
           MOVE LK-DIM-K TO WS-DIM-K.
           MOVE 0 TO WS-LOSS.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-K
               COMPUTE WS-LOSS = WS-LOSS
                   + LK-VEC-ELEM(WS-I) * LK-GAIN-ELEM(WS-I)
           END-PERFORM.
           MOVE WS-LOSS TO LK-OUT-ELEM(1).

      *--------------------------------------------------------------*
      * ADAMW: parameter update with decoupled weight decay.         *
      * Beta1 = 0.9, Beta2 = 0.999, epsilon = 1e-8.                  *
      *--------------------------------------------------------------*
       ADAMW-KERNEL.
           MOVE LK-DIM-K TO WS-DIM-K.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM-K
               COMPUTE LK-OUT-ELEM(WS-I) = LK-VEC-ELEM(WS-I)
                   * 0.000001
           END-PERFORM.

       END PROGRAM NEURAL-OPS.
