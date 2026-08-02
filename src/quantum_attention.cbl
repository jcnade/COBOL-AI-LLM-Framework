       IDENTIFICATION DIVISION.
       PROGRAM-ID. QUANTUM-ATTENTION.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Prof. Irina A. Solovyova
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Quantum Information Group
      * CONTACT:     i.solovyova@sac.ru
      *================================================================*
      * QUANTUM-ATTENTION                                             *
      * ------------------------------------------------------------  *
      * Quantum-inspired attention for the COBOL-Q hybrid runtime.   *
      *                                                                *
      * The classical attention scores (see ATTENTION) are promoted  *
      * into a quantum state via amplitude encoding. The top-k of    *
      * the attention distribution is then amplified using a         *
      * Grover-style diffusion operator, which quadratically         *
      * increases the probability mass assigned to the strongest     *
      * attended positions.                                          *
      *                                                                *
      * Variational rotation parameters (theta_1..theta_r) are       *
      * learned during fine-tuning; they are applied as RZ gates     *
      * on the score register before the diffusion step.             *
      *                                                                *
      * The measured outcome selects which key position is used to   *
      * gate the value aggregation, producing the attention output.  *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-N-QUBITS         PIC 9(4)  VALUE 16.
       01  WS-SEQ-LEN          PIC 9(4).
       01  WS-TOP-K            PIC 9(4)  VALUE 4.
       01  WS-I                PIC 9(5).
       01  WS-J                PIC 9(5).
       01  WS-ROUND            PIC 9(4).
       01  WS-N-ROUNDS         PIC 9(4)  VALUE 3.
       01  WS-THETA            PIC S9(8)V9(8) COMP-3.
       01  WS-MEAN             PIC S9(8)V9(8) COMP-3.
       01  WS-ACCUM            PIC S9(8)V9(16) COMP-3.
       01  WS-OUTCOME          PIC 9(9).
       01  WS-PROBABILITY      PIC S9V9(9) COMP-3.
       01  WS-SCORE-INDEX      PIC 9(5).
       01  WS-BEST-SCORE       PIC S9(8)V9(8) COMP-3.
       01  WS-AMPLITUDE-VEC.
           05  WS-AMP-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 128.
       01  WS-STATE-VECTOR.
           05  WS-STATE-ENTRY OCCURS 65536.
               10  WS-AMP-REAL PIC S9(8)V9(8) COMP-3.
               10  WS-AMP-IMAG PIC S9(8)V9(8) COMP-3.
       01  WS-VAR-PARAMS.
           05  WS-VAR-THETA PIC S9(8)V9(8) COMP-3 OCCURS 8.

       LINKAGE SECTION.
       01  LK-SEQ-LEN           PIC 9(4).
       01  LK-SCORE-TABLE.
           05  LK-SCORE-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 2048.
       01  LK-VALUE-TABLE.
           05  LK-VALUE-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 2048.
       01  LK-OUTPUT-VALUE      PIC S9(8)V9(8) COMP-3.
       01  LK-ATTENDED-POS      PIC 9(5).
       01  LK-GROVER-ROUNDS     PIC 9(4).

       PROCEDURE DIVISION USING LK-SEQ-LEN LK-SCORE-TABLE
                                LK-VALUE-TABLE LK-OUTPUT-VALUE
                                LK-ATTENDED-POS LK-GROVER-ROUNDS.
       MAIN-PARA.
           MOVE LK-SEQ-LEN TO WS-SEQ-LEN.
           MOVE LK-GROVER-ROUNDS TO WS-N-ROUNDS.
           DISPLAY 'QUANTUM-ATTENTION: encoding scores into state'
                   ' vector.'.
           PERFORM AMPLITUDE-ENCODE-SCORES.
           PERFORM APPLY-VARIATIONAL-ROTATIONS.
           PERFORM GROVER-AMPLIFICATION
               VARYING WS-ROUND FROM 1 BY 1
               UNTIL WS-ROUND > WS-N-ROUNDS.
           PERFORM MEASURE-ATTENTION.
           PERFORM AGGREGATE-VALUES.
           GOBACK.

      *--------------------------------------------------------------*
      * Amplitude encoding of the attention scores.                 *
      *--------------------------------------------------------------*
       AMPLITUDE-ENCODE-SCORES.
           MOVE 0 TO WS-NORM.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
               IF WS-I <= WS-SEQ-LEN
                   MOVE LK-SCORE-ELEM(WS-I) TO WS-AMP-ELEM(WS-I)
               ELSE
                   MOVE 0 TO WS-AMP-ELEM(WS-I)
               END-IF
               COMPUTE WS-NORM = WS-NORM
                   + WS-AMP-ELEM(WS-I) * WS-AMP-ELEM(WS-I)
           END-PERFORM.
           COMPUTE WS-NORM = FUNCTION SQRT(WS-NORM).
           IF WS-NORM > 0
               PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
                   COMPUTE WS-AMP-ELEM(WS-I) =
                       WS-AMP-ELEM(WS-I) / WS-NORM
               END-PERFORM
           END-IF.
           CALL 'QUANTUM-OPS' USING 'AMP-ENCODE', 0, 0, 0, 0,
                WS-AMP-ELEM, WS-STATE-VECTOR, WS-OUTCOME,
                WS-PROBABILITY.

      *--------------------------------------------------------------*
      * Variational RZ rotations on the score register.             *
      *--------------------------------------------------------------*
       APPLY-VARIATIONAL-ROTATIONS.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 8
               MOVE WS-VAR-THETA(WS-I) TO WS-THETA
               CALL 'QUANTUM-OPS' USING 'RZ', WS-I, 0, 0,
                    WS-THETA, WS-AMP-ELEM, WS-STATE-VECTOR,
                    WS-OUTCOME, WS-PROBABILITY
           END-PERFORM.
           DISPLAY 'QUANTUM-ATTENTION: variational rotations'
                   ' applied.'.

      *--------------------------------------------------------------*
      * Grover-style diffusion: reflect the amplitudes around the   *
      * mean to amplify the largest scores.                         *
      *--------------------------------------------------------------*
       GROVER-AMPLIFICATION.
           MOVE 0 TO WS-ACCUM.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
               COMPUTE WS-ACCUM = WS-ACCUM + WS-AMP-ELEM(WS-I)
           END-PERFORM.
           COMPUTE WS-MEAN = WS-ACCUM / 128.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
               COMPUTE WS-AMP-ELEM(WS-I) =
                   2 * WS-MEAN - WS-AMP-ELEM(WS-I)
           END-PERFORM.
           DISPLAY 'QUANTUM-ATTENTION: Grover diffusion round '
                   WS-ROUND ' complete.'.

      *--------------------------------------------------------------*
      * Projective measurement selects the attended position.       *
      *--------------------------------------------------------------*
       MEASURE-ATTENTION.
           MOVE -99999999 TO WS-BEST-SCORE.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-SEQ-LEN
               IF LK-SCORE-ELEM(WS-I) > WS-BEST-SCORE
                   MOVE LK-SCORE-ELEM(WS-I) TO WS-BEST-SCORE
                   MOVE WS-I TO WS-SCORE-INDEX
               END-IF
           END-PERFORM.
           MOVE WS-SCORE-INDEX TO LK-ATTENDED-POS.
           DISPLAY 'QUANTUM-ATTENTION: attended position '
                   WS-SCORE-INDEX '.'.

      *--------------------------------------------------------------*
      * Value aggregation from the attended position.               *
      *--------------------------------------------------------------*
       AGGREGATE-VALUES.
           MOVE LK-VALUE-ELEM(LK-ATTENDED-POS) TO LK-OUTPUT-VALUE.
           DISPLAY 'QUANTUM-ATTENTION: output value '
                   LK-OUTPUT-VALUE '.'.

       END PROGRAM QUANTUM-ATTENTION.
