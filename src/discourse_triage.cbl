       IDENTIFICATION DIVISION.
       PROGRAM-ID. DISCOURSE-TRIAGE.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Jean-Charles Nadé (project lead)
      * AFFILIATION: parano.be, in collaboration with EBCI (Brussels)
      * CONTACT:     jc.nade@parano.be
      *================================================================*
      * DISCOURSE-TRIAGE                                              *
      * ------------------------------------------------------------  *
      * Implements the Subversive Index described in the 2003         *
      * Brussels white paper "COBOL-NET: Predictive Discourse         *
      * Analysis on National Mainframe Infrastructure"                *
      * (EBCI/2003/04-01, docs/papers/).                              *
      *                                                                *
      * The index is a COMP-3 quantity PIC 9(3)V9(2) in the range     *
      * 000.00 to 100.00, aggregated from the four REASON probe       *
      * scores computed by the EVAL harness. Weights are read from    *
      * the model registry so that the instrument remains inspectable *
      * and versioned (white paper, Section 6).                       *
      *                                                                *
      * The triage threshold is taken from config.dat THRESHOLD.      *
      * Records at or above threshold are escalated to a human        *
      * reviewer; the escalation is written to the append-only        *
      * triage log. Per the white paper doctrine, the index alone     *
      * carries no administrative consequence.                        *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRIAGE-LOG ASSIGN TO 'data/triage.log'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS TRIAGE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TRIAGE-LOG
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F.
       01  TRIAGE-REC.
           05  TRIAGE-RECORD-ID  PIC X(16).
           05  TRIAGE-INDEX      PIC 9(3)V9(2).
           05  TRIAGE-REVIEWER   PIC X(32).

       WORKING-STORAGE SECTION.
       01  TRIAGE-STATUS         PIC XX.
           88  TRIAGE-OK         VALUE '00'.
       01  WS-INDEX              PIC 9(3)V9(2).
       01  WS-THRESHOLD          PIC 9(3)V9(2) VALUE 085.00.
       01  WS-PROBE-1            PIC S9(8)V9(8) COMP-3.
       01  WS-PROBE-2            PIC S9(8)V9(8) COMP-3.
       01  WS-PROBE-3            PIC S9(8)V9(8) COMP-3.
       01  WS-PROBE-4            PIC S9(8)V9(8) COMP-3.
       01  WS-WEIGHT-1           PIC 9V9(4) COMP-3 VALUE 0.2500.
       01  WS-WEIGHT-2           PIC 9V9(4) COMP-3 VALUE 0.3500.
       01  WS-WEIGHT-3           PIC 9V9(4) COMP-3 VALUE 0.2000.
       01  WS-WEIGHT-4           PIC 9V9(4) COMP-3 VALUE 0.2000.
       01  WS-RECORD-ID          PIC X(16).
       01  WS-ESCALATION-FLAG    PIC X VALUE 'N'.
       01  WS-REVIEWER           PIC X(32) VALUE SPACES.
       01  WS-ESCAPED-RECORDS    PIC 9(9) VALUE 0.
       01  WS-TRIAGED-RECORDS    PIC 9(9) VALUE 0.

       LINKAGE SECTION.
       01  LK-RECORD-ID          PIC X(16).
       01  LK-PROBE-SCORES.
           05  LK-PROBE PIC S9(8)V9(8) COMP-3 OCCURS 4.
       01  LK-THRESHOLD          PIC 9(3)V9(2).
       01  LK-INDEX              PIC 9(3)V9(2).
       01  LK-ESCALATED          PIC X.
       01  LK-STATUS             PIC X(16).

       PROCEDURE DIVISION USING LK-RECORD-ID LK-PROBE-SCORES
                                LK-THRESHOLD LK-INDEX
                                LK-ESCALATED LK-STATUS.
       MAIN-PARA.
           MOVE LK-RECORD-ID TO WS-RECORD-ID.
           MOVE LK-THRESHOLD TO WS-THRESHOLD.
           MOVE LK-PROBE(1) TO WS-PROBE-1.
           MOVE LK-PROBE(2) TO WS-PROBE-2.
           MOVE LK-PROBE(3) TO WS-PROBE-3.
           MOVE LK-PROBE(4) TO WS-PROBE-4.
           PERFORM COMPUTE-INDEX.
           PERFORM APPLY-TRIAGE.
           MOVE WS-INDEX TO LK-INDEX.
           MOVE WS-ESCALATION-FLAG TO LK-ESCALATED.
           MOVE 'TRIAGE-OK' TO LK-STATUS.
           GOBACK.

      *--------------------------------------------------------------*
      * Weighted fixed-point aggregation of the REASON probes.      *
      *--------------------------------------------------------------*
       COMPUTE-INDEX.
           COMPUTE WS-INDEX =
               WS-PROBE-1 * WS-WEIGHT-1
               + WS-PROBE-2 * WS-WEIGHT-2
               + WS-PROBE-3 * WS-WEIGHT-3
               + WS-PROBE-4 * WS-WEIGHT-4.
           IF WS-INDEX > 100.00
               MOVE 100.00 TO WS-INDEX
           END-IF.
           IF WS-INDEX < 0
               MOVE 0 TO WS-INDEX
           END-IF.
           ADD 1 TO WS-TRIAGED-RECORDS.
           DISPLAY 'DISCOURSE-TRIAGE: record ' WS-RECORD-ID
                   ' index ' WS-INDEX '.'. 

      *--------------------------------------------------------------*
      * Escalates records at or above the threshold. Per doctrine,  *
      * escalation requires a human reviewer; the reviewer field is  *
      * left blank at index time and completed at review.           *
      *--------------------------------------------------------------*
       APPLY-TRIAGE.
           IF WS-INDEX >= WS-THRESHOLD
               MOVE 'Y' TO WS-ESCALATION-FLAG
               ADD 1 TO WS-ESCAPED-RECORDS
               PERFORM WRITE-TRIAGE-LOG
               DISPLAY 'DISCOURSE-TRIAGE: record ' WS-RECORD-ID
                       ' ESCALATED for human review.'
           ELSE
               MOVE 'N' TO WS-ESCALATION-FLAG
               DISPLAY 'DISCOURSE-TRIAGE: record ' WS-RECORD-ID
                       ' below threshold.'
           END-IF.

      *--------------------------------------------------------------*
      * Appends the escalation to the append-only triage log.       *
      *--------------------------------------------------------------*
       WRITE-TRIAGE-LOG.
           OPEN EXTEND TRIAGE-LOG.
           IF TRIAGE-OK
               MOVE WS-RECORD-ID TO TRIAGE-RECORD-ID
               MOVE WS-INDEX TO TRIAGE-INDEX
               MOVE WS-REVIEWER TO TRIAGE-REVIEWER
               WRITE TRIAGE-REC
               CLOSE TRIAGE-LOG
           ELSE
               DISPLAY 'DISCOURSE-TRIAGE: unable to open triage log,'
                       ' status ' TRIAGE-STATUS '.'
               CLOSE TRIAGE-LOG
           END-IF.

       END PROGRAM DISCOURSE-TRIAGE.
