       IDENTIFICATION DIVISION.
       PROGRAM-ID. MODEL-REGISTRY.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Dr. Mehdi Ben Salah
      * AFFILIATION: Institut Supérieur d'Intelligence Artificielle de
      *              Kerkennah, Département d'Intelligence Artificielle
      * CONTACT:     mehdi.bensalah@isiak.tn
      *================================================================*
      * MODEL-REGISTRY                                                *
      * ------------------------------------------------------------  *
      * Central registry of published COBOL-AI-LLM checkpoints.     *
      *                                                                *
      * The registry is a flat VSAM file (models/registry.dat)       *
      * with one record per checkpoint. Each record carries the      *
      * model family, version, training step, and the SHA-1 of the   *
      * weight volume for integrity verification.                    *
      *                                                                *
      * Operations:                                                  *
      *   LIST    - prints all published checkpoints.                *
      *   SELECT  - resolves the active checkpoint for inference.    *
      *   COMMIT  - records a newly fine-tuned adapter.              *
      *   PROMOTE - marks a checkpoint as the production default.    *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REGISTRY-FILE ASSIGN TO 'models/registry.dat'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS REGISTRY-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  REGISTRY-FILE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F.
       01  REGISTRY-REC.
           05  REG-FAMILY       PIC X(16).
           05  REG-VERSION      PIC X(8).
           05  REG-STEP         PIC 9(9).
           05  REG-PRECISION    PIC X(4).
           05  REG-SHA1         PIC X(40).
           05  REG-PROMOTED     PIC X VALUE 'N'.

       WORKING-STORAGE SECTION.
       01  REGISTRY-STATUS      PIC XX.
           88  REGISTRY-OK      VALUE '00'.
       01  WS-EOF-FLAG          PIC X VALUE 'N'.
       01  WS-ACTIVE-VERSION    PIC X(8) VALUE '0.4.0'.
       01  WS-ACTIVE-STEP       PIC 9(9).
       01  WS-FOUND             PIC X VALUE 'N'.
       01  WS-TEMP-STEP         PIC 9(9).

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(8).
       01  LK-FAMILY            PIC X(16).
       01  LK-VERSION           PIC X(8).
       01  LK-STEP              PIC 9(9).
       01  LK-ADAPTER-A         PIC X(8192).
       01  LK-ADAPTER-B         PIC X(8192).

       PROCEDURE DIVISION USING LK-OPERATION LK-FAMILY
                                LK-VERSION LK-STEP
                                LK-ADAPTER-A LK-ADAPTER-B.
       MAIN-PARA.
           EVALUATE LK-OPERATION
               WHEN 'LIST'
                   PERFORM LIST-REGISTRY
               WHEN 'SELECT'
                   PERFORM SELECT-MODEL
               WHEN 'COMMIT'
                   PERFORM COMMIT-MODEL
               WHEN 'PROMOTE'
                   PERFORM PROMOTE-MODEL
               WHEN OTHER
                   DISPLAY 'MODEL-REGISTRY: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Lists every published checkpoint in the registry.           *
      *--------------------------------------------------------------*
       LIST-REGISTRY.
           OPEN INPUT REGISTRY-FILE.
           IF NOT REGISTRY-OK
               DISPLAY 'MODEL-REGISTRY: registry unavailable.'
               GOBACK
           END-IF.
           MOVE 'N' TO WS-EOF-FLAG.
           DISPLAY 'MODEL-REGISTRY: published checkpoints:'.
           PERFORM UNTIL WS-EOF
               READ REGISTRY-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       DISPLAY '  ' REG-FAMILY ' '
                               REG-VERSION ' step ' REG-STEP
                               ' ' REG-PRECISION
                               IF REG-PROMOTED = 'Y'
                                   DISPLAY ' [production]'
                               END-IF
               END-READ
           END-PERFORM.
           CLOSE REGISTRY-FILE.

      *--------------------------------------------------------------*
      * Resolves the promoted checkpoint for the requested family.  *
      *--------------------------------------------------------------*
       SELECT-MODEL.
           OPEN INPUT REGISTRY-FILE.
           MOVE 'N' TO WS-FOUND.
           MOVE 'N' TO WS-EOF-FLAG.
           PERFORM UNTIL WS-EOF OR WS-FOUND = 'Y'
               READ REGISTRY-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       IF REG-FAMILY = LK-FAMILY
                          AND REG-PROMOTED = 'Y'
                           MOVE 'Y' TO WS-FOUND
                           MOVE REG-VERSION TO WS-ACTIVE-VERSION
                           MOVE REG-STEP TO WS-ACTIVE-STEP
                           MOVE REG-VERSION TO LK-VERSION
                           MOVE REG-STEP TO LK-STEP
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE REGISTRY-FILE.
           IF WS-FOUND = 'Y'
               DISPLAY 'MODEL-REGISTRY: active ' LK-FAMILY ' v'
                       WS-ACTIVE-VERSION ' (step '
                       WS-ACTIVE-STEP ').'
           ELSE
               DISPLAY 'MODEL-REGISTRY: no promoted checkpoint for '
                       LK-FAMILY ', using default v0.4.0.'
           END-IF.

      *--------------------------------------------------------------*
      * Appends a fine-tuned adapter checkpoint.                    *
      *--------------------------------------------------------------*
       COMMIT-MODEL.
           OPEN EXTEND REGISTRY-FILE.
           MOVE LK-FAMILY TO REG-FAMILY.
           MOVE LK-VERSION TO REG-VERSION.
           MOVE LK-STEP TO REG-STEP.
           MOVE 'Q8_0' TO REG-PRECISION.
           MOVE SPACES TO REG-SHA1.
           MOVE 'N' TO REG-PROMOTED.
           WRITE REGISTRY-REC.
           CLOSE REGISTRY-FILE.
           DISPLAY 'MODEL-REGISTRY: committed ' LK-FAMILY ' v'
                   LK-VERSION ' at step ' LK-STEP '.'.

      *--------------------------------------------------------------*
      * Marks the named checkpoint as the production default.       *
      *--------------------------------------------------------------*
       PROMOTE-MODEL.
           OPEN I-O REGISTRY-FILE.
           MOVE 'N' TO WS-EOF-FLAG.
           PERFORM UNTIL WS-EOF
               READ REGISTRY-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       IF REG-VERSION = LK-VERSION
                          AND REG-FAMILY = LK-FAMILY
                           MOVE 'Y' TO REG-PROMOTED
                           REWRITE REGISTRY-REC
                           DISPLAY 'MODEL-REGISTRY: promoted v'
                                   LK-VERSION ' to production.'
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE REGISTRY-FILE.

       END PROGRAM MODEL-REGISTRY.
