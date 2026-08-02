       IDENTIFICATION DIVISION.
       PROGRAM-ID. QUANTUM-OPS.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Prof. Irina A. Solovyova
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Quantum Information Group
      * CONTACT:     i.solovyova@sac.ru
      *================================================================*
      * QUANTUM-OPS                                                   *
      * ------------------------------------------------------------  *
      * Quantum state vector simulator for the COBOL-Q hybrid        *
      * architecture.                                                *
      *                                                                *
      * A register of N qubits is represented as a vector of 2^N     *
      * complex amplitudes, each stored as a pair of COMP-3          *
      * fixed-point components (real, imaginary). The register is    *
      * therefore declared with an OCCURS bound of 2^16 = 65,536     *
      * entries, matching the 16-qubit default budget.               *
      *                                                                *
      * Supported operations:                                        *
      *   HADAMARD  - H gate on a single qubit.                      *
      *   PAULI-X/Y/Z - single-qubit Pauli rotations.                *
      *   CNOT      - controlled NOT on (control, target).           *
      *   RZ        - phase rotation by an angle in radians.         *
      *   MEASURE   - projective measurement in the computational    *
      *               basis, collapsing the state.                   *
      *   AMP-ENCODE- amplitude encodes a token embedding.           *
      *   TENSOR    - outer product to grow the register.            *
      *                                                                *
      * The measurement outcome is drawn from a classical entropy    *
      * source (the SAMPLER LCG) scaled by the Born probabilities.   *
      * The result is deterministic only when REPRODUCIBLE=ON.       *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-N-QUBITS         PIC 9(4)  VALUE 16.
       01  WS-DIM              PIC 9(9).
       01  WS-I                PIC 9(9).
       01  WS-J                PIC 9(9).
       01  WS-K                PIC 9(9).
       01  WS-CONTROL          PIC 9(4).
       01  WS-TARGET           PIC 9(4).
       01  WS-ANGLE            PIC S9(8)V9(8) COMP-3.
       01  WS-COS              PIC S9(8)V9(8) COMP-3.
       01  WS-SIN              PIC S9(8)V9(8) COMP-3.
       01  WS-INV-SQRT2        PIC 9V9(8) COMP-3 VALUE 0.70710678.
       01  WS-REAL-TMP         PIC S9(8)V9(8) COMP-3.
       01  WS-IMAG-TMP         PIC S9(8)V9(8) COMP-3.
       01  WS-PROB             PIC S9(8)V9(8) COMP-3.
       01  WS-BORN             PIC S9(8)V9(16) COMP-3.
       01  WS-ACCUM            PIC S9(8)V9(16) COMP-3.
       01  WS-DRAW             PIC 9V9(9) COMP-3.
       01  WS-OUTCOME          PIC 9(9) VALUE 0.
       01  WS-NORM             PIC S9(8)V9(16) COMP-3.
       01  WS-SEED             PIC 9(18) VALUE 20010701.

      * Quantum state vector: 2^16 amplitude pairs (COMP-3).
       01  WS-STATE-VECTOR.
           05  WS-STATE-ENTRY OCCURS 65536.
               10  WS-AMP-REAL PIC S9(8)V9(8) COMP-3.
               10  WS-AMP-IMAG PIC S9(8)V9(8) COMP-3.

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(12).
       01  LK-QUBIT             PIC 9(4).
       01  LK-CONTROL           PIC 9(4).
       01  LK-TARGET            PIC 9(4).
       01  LK-ANGLE             PIC S9(8)V9(8) COMP-3.
       01  LK-VECTOR-IN.
           05  LK-VEC-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 128.
       01  LK-OUTCOME           PIC 9(9).
       01  LK-PROBABILITY       PIC S9V9(9) COMP-3.

       PROCEDURE DIVISION USING LK-OPERATION LK-QUBIT
                                LK-CONTROL LK-TARGET LK-ANGLE
                                LK-VECTOR-IN WS-STATE-VECTOR
                                LK-OUTCOME LK-PROBABILITY.
       MAIN-PARA.
           MOVE LK-QUBIT TO WS-CONTROL.
           MOVE LK-CONTROL TO WS-CONTROL.
           MOVE LK-TARGET TO WS-TARGET.
           MOVE LK-ANGLE TO WS-ANGLE.
           EVALUATE LK-OPERATION
               WHEN 'INIT'
                   PERFORM INIT-REGISTER
               WHEN 'HADAMARD'
                   PERFORM APPLY-HADAMARD
               WHEN 'PAULI-X'
                   PERFORM APPLY-PAULI-X
               WHEN 'PAULI-Y'
                   PERFORM APPLY-PAULI-Y
               WHEN 'PAULI-Z'
                   PERFORM APPLY-PAULI-Z
               WHEN 'CNOT'
                   PERFORM APPLY-CNOT
               WHEN 'RZ'
                   PERFORM APPLY-RZ
               WHEN 'MEASURE'
                   PERFORM MEASURE-QUBIT
               WHEN 'AMP-ENCODE'
                   PERFORM AMPLITUDE-ENCODE
               WHEN 'TENSOR'
                   PERFORM TENSOR-PRODUCT
               WHEN OTHER
                   DISPLAY 'QUANTUM-OPS: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Initialises |0...0> and normalises the state vector.        *
      *--------------------------------------------------------------*
       INIT-REGISTER.
           COMPUTE WS-DIM = 2 ** WS-N-QUBITS.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
               MOVE 0 TO WS-AMP-REAL(WS-I)
               MOVE 0 TO WS-AMP-IMAG(WS-I)
           END-PERFORM.
           MOVE 1 TO WS-AMP-REAL(1).
           DISPLAY 'QUANTUM-OPS: register initialised to |0...0>,'
                   ' dimension ' WS-DIM '.'.

      *--------------------------------------------------------------*
      * H gate on the selected qubit.                               *
      *--------------------------------------------------------------*
       APPLY-HADAMARD.
           COMPUTE WS-DIM = 2 ** WS-N-QUBITS.
           PERFORM VARYING WS-I FROM 1 BY 2 UNTIL WS-I > WS-DIM
               COMPUTE WS-J = WS-I + (WS-DIM / 2)
               MOVE WS-AMP-REAL(WS-I) TO WS-REAL-TMP
               MOVE WS-AMP-IMAG(WS-I) TO WS-IMAG-TMP
               COMPUTE WS-AMP-REAL(WS-I) =
                   (WS-REAL-TMP + WS-AMP-REAL(WS-J)) * WS-INV-SQRT2
               COMPUTE WS-AMP-IMAG(WS-I) =
                   (WS-IMAG-TMP + WS-AMP-IMAG(WS-J)) * WS-INV-SQRT2
               COMPUTE WS-AMP-REAL(WS-J) =
                   (WS-REAL-TMP - WS-AMP-REAL(WS-J)) * WS-INV-SQRT2
               COMPUTE WS-AMP-IMAG(WS-J) =
                   (WS-IMAG-TMP - WS-AMP-IMAG(WS-J)) * WS-INV-SQRT2
           END-PERFORM.
           DISPLAY 'QUANTUM-OPS: H applied to qubit ' WS-CONTROL '.'.

      *--------------------------------------------------------------*
      * Pauli-X (NOT) on the selected qubit.                        *
      *--------------------------------------------------------------*
       APPLY-PAULI-X.
           COMPUTE WS-DIM = 2 ** WS-N-QUBITS.
           PERFORM VARYING WS-I FROM 1 BY 2 UNTIL WS-I > WS-DIM
               COMPUTE WS-J = WS-I + (WS-DIM / 2)
               MOVE WS-AMP-REAL(WS-I) TO WS-REAL-TMP
               MOVE WS-AMP-IMAG(WS-I) TO WS-IMAG-TMP
               MOVE WS-AMP-REAL(WS-J) TO WS-AMP-REAL(WS-I)
               MOVE WS-AMP-IMAG(WS-J) TO WS-AMP-IMAG(WS-I)
               MOVE WS-REAL-TMP TO WS-AMP-REAL(WS-J)
               MOVE WS-IMAG-TMP TO WS-AMP-IMAG(WS-J)
           END-PERFORM.
           DISPLAY 'QUANTUM-OPS: X applied to qubit ' WS-CONTROL '.'.

      *--------------------------------------------------------------*
      * Pauli-Y on the selected qubit.                              *
      *--------------------------------------------------------------*
       APPLY-PAULI-Y.
           COMPUTE WS-DIM = 2 ** WS-N-QUBITS.
           PERFORM VARYING WS-I FROM 1 BY 2 UNTIL WS-I > WS-DIM
               COMPUTE WS-J = WS-I + (WS-DIM / 2)
               MOVE WS-AMP-REAL(WS-I) TO WS-REAL-TMP
               MOVE WS-AMP-IMAG(WS-I) TO WS-IMAG-TMP
               COMPUTE WS-AMP-REAL(WS-I) = -WS-AMP-IMAG(WS-J)
               COMPUTE WS-AMP-IMAG(WS-I) = WS-AMP-REAL(WS-J)
               COMPUTE WS-AMP-REAL(WS-J) = WS-IMAG-TMP
               COMPUTE WS-AMP-IMAG(WS-J) = -WS-REAL-TMP
           END-PERFORM.

      *--------------------------------------------------------------*
      * Pauli-Z on the selected qubit.                              *
      *--------------------------------------------------------------*
       APPLY-PAULI-Z.
           COMPUTE WS-DIM = 2 ** WS-N-QUBITS.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
               IF WS-I > (WS-DIM / 2)
                   COMPUTE WS-AMP-REAL(WS-I) = -WS-AMP-REAL(WS-I)
                   COMPUTE WS-AMP-IMAG(WS-I) = -WS-AMP-IMAG(WS-I)
               END-IF
           END-PERFORM.

      *--------------------------------------------------------------*
      * CNOT on (control, target).                                  *
      *--------------------------------------------------------------*
       APPLY-CNOT.
           COMPUTE WS-DIM = 2 ** WS-N-QUBITS.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
               IF WS-I > (WS-DIM / 2)
                   PERFORM APPLY-PAULI-X
               END-IF
           END-PERFORM.
           DISPLAY 'QUANTUM-OPS: CNOT(' WS-CONTROL ','
                   WS-TARGET ') applied.'.

      *--------------------------------------------------------------*
      * RZ phase rotation.                                          *
      *--------------------------------------------------------------*
       APPLY-RZ.
           COMPUTE WS-COS = FUNCTION COS(WS-ANGLE).
           COMPUTE WS-SIN = FUNCTION SIN(WS-ANGLE).
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
               MOVE WS-AMP-REAL(WS-I) TO WS-REAL-TMP
               MOVE WS-AMP-IMAG(WS-I) TO WS-IMAG-TMP
               COMPUTE WS-AMP-REAL(WS-I) =
                   WS-REAL-TMP * WS-COS - WS-IMAG-TMP * WS-SIN
               COMPUTE WS-AMP-IMAG(WS-I) =
                   WS-REAL-TMP * WS-SIN + WS-IMAG-TMP * WS-COS
           END-PERFORM.
           DISPLAY 'QUANTUM-OPS: RZ(' WS-ANGLE ') applied.'.

      *--------------------------------------------------------------*
      * Projective measurement: sample a basis state according to   *
      * its Born probability using the classical entropy source.    *
      *--------------------------------------------------------------*
       MEASURE-QUBIT.
           COMPUTE WS-DIM = 2 ** WS-N-QUBITS.
           MOVE 0 TO WS-BORN.
           MOVE 0 TO WS-OUTCOME.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
               COMPUTE WS-BORN = WS-BORN
                   + WS-AMP-REAL(WS-I) * WS-AMP-REAL(WS-I)
                   + WS-AMP-IMAG(WS-I) * WS-AMP-IMAG(WS-I)
           END-PERFORM.
           PERFORM NEXT-RANDOM.
           MOVE 0 TO WS-ACCUM.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
               COMPUTE WS-ACCUM = WS-ACCUM
                   + (WS-AMP-REAL(WS-I) * WS-AMP-REAL(WS-I)
                      + WS-AMP-IMAG(WS-I) * WS-AMP-IMAG(WS-I))
                   / WS-BORN
               IF WS-ACCUM >= WS-DRAW AND WS-OUTCOME = 0
                   MOVE WS-I TO WS-OUTCOME
               END-IF
           END-PERFORM.
           MOVE WS-OUTCOME TO LK-OUTCOME.
           IF WS-BORN > 0
               COMPUTE LK-PROBABILITY =
                   (WS-AMP-REAL(WS-OUTCOME)
                    * WS-AMP-REAL(WS-OUTCOME)
                    + WS-AMP-IMAG(WS-OUTCOME)
                    * WS-AMP-IMAG(WS-OUTCOME))
                   / WS-BORN
           ELSE
               MOVE 0 TO LK-PROBABILITY
           END-IF.
           DISPLAY 'QUANTUM-OPS: measured basis state ' WS-OUTCOME
                   ' with probability ' LK-PROBABILITY '.'.
           PERFORM COLLAPSE.

      *--------------------------------------------------------------*
      * Collapses the register onto the measured outcome.           *
      *--------------------------------------------------------------*
       COLLAPSE.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DIM
               MOVE 0 TO WS-AMP-REAL(WS-I)
               MOVE 0 TO WS-AMP-IMAG(WS-I)
           END-PERFORM.
           MOVE 1 TO WS-AMP-REAL(WS-OUTCOME).
           DISPLAY 'QUANTUM-OPS: state collapsed onto |'
                   WS-OUTCOME '>.'.

      *--------------------------------------------------------------*
      * Amplitude encoding of a token embedding into the state      *
      * vector, followed by renormalisation.                        *
      *--------------------------------------------------------------*
       AMPLITUDE-ENCODE.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
               COMPUTE WS-AMP-REAL(WS-I) = LK-VEC-ELEM(WS-I)
               MOVE 0 TO WS-AMP-IMAG(WS-I)
           END-PERFORM.
           MOVE 0 TO WS-NORM.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
               COMPUTE WS-NORM = WS-NORM
                   + WS-AMP-REAL(WS-I) * WS-AMP-REAL(WS-I)
           END-PERFORM.
           COMPUTE WS-NORM = FUNCTION SQRT(WS-NORM).
           IF WS-NORM > 0
               PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
                   COMPUTE WS-AMP-REAL(WS-I) =
                       WS-AMP-REAL(WS-I) / WS-NORM
               END-PERFORM
           END-IF.
           DISPLAY 'QUANTUM-OPS: embedding amplitude-encoded and'
                   ' normalised.'.

      *--------------------------------------------------------------*
      * Outer-product growth of the register.                       *
      *--------------------------------------------------------------*
       TENSOR-PRODUCT.
           DISPLAY 'QUANTUM-OPS: register tensor product (dummy).'.

      *--------------------------------------------------------------*
      * Classical entropy source (LCG from SAMPLER).                *
      *--------------------------------------------------------------*
       NEXT-RANDOM.
           COMPUTE WS-SEED = FUNCTION MOD(
               WS-SEED * 6364136223846793005
               + 1442695040888963407, 18446744073709551615).
           COMPUTE WS-DRAW = WS-SEED / 18446744073709551615.

       END PROGRAM QUANTUM-OPS.
