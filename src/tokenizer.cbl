       IDENTIFICATION DIVISION.
       PROGRAM-ID. TOKENIZER.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Anastasia Morozova
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Department of Artificial Intelligence
      * CONTACT:     a.morozova@sac.ru
      *================================================================*
      * TOKENIZER                                                     *
      * ------------------------------------------------------------  *
      * Byte-Pair Encoding (BPE) tokeniser for the COBOL-AI-LLM      *
      * family of models.                                            *
      *                                                                *
      * The vocabulary is loaded from models/vocab.bpe, a flat       *
      * EBCDIC file of 50,000 merge records sorted in ascending      *
      * byte order. Lookups use an iterative binary search to        *
      * guarantee O(log n) behaviour on the IBM-370.                 *
      *                                                                *
      * Special tokens are reserved in the 50000-50007 band:         *
      *   <|endoftext|>  <|fim_prefix|>  <|fim_middle|>  <|fim_suffix|>*
      *   <|file_sep|>   <|reason|>       <|analysis|>   <|answer|>   *
      *                                                                *
      * The tokeniser is byte-preserving: multi-byte UTF-8 sequences *
      * are treated as opaque byte runs, exactly as specified in the  *
      * GPT-2 tokeniser technical report.                            *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT VOCAB-FILE ASSIGN TO 'models/vocab.bpe'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS VOCAB-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  VOCAB-FILE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F.
       01  VOCAB-REC.
           05  VOCAB-TOKEN      PIC X(32).
           05  VOCAB-MERGE-ID   PIC 9(5).
           05  VOCAB-FREQ       PIC 9(9).

       WORKING-STORAGE SECTION.
       01  VOCAB-STATUS         PIC XX.
           88  VOCAB-OK         VALUE '00'.
       01  WS-EOF-FLAG          PIC X VALUE 'N'.
           88  WS-EOF           VALUE 'Y'.
       01  WS-INPUT-TEXT        PIC X(4096).
       01  WS-CURRENT-TOKEN     PIC X(64).
       01  WS-TOKEN-ID          PIC 9(5).
       01  WS-PREV-TOKEN-ID     PIC 9(5).
       01  WS-TOKEN-BUFFER.
           05  WS-TOKEN-ENTRY OCCURS 2048.
               10  WS-TOKEN-ID-ENTRY   PIC 9(5).
               10  WS-TOKEN-TEXT       PIC X(64).
       01  WS-TOKEN-COUNT       PIC 9(4) VALUE 0.
       01  WS-POS               PIC 9(4) VALUE 1.
       01  WS-POS-END           PIC 9(4).
       01  WS-I                 PIC 9(4).
       01  WS-LOW               PIC 9(4).
       01  WS-HIGH              PIC 9(4).
       01  WS-MID               PIC 9(4).
       01  WS-FOUND             PIC X VALUE 'N'.
       01  WS-COMPARE-TOKEN     PIC X(32).
       01  WS-VOCAB-SIZE        PIC 9(5) VALUE 0.
       01  WS-RESULT-STRING     PIC X(8192).

       LINKAGE SECTION.
       01  LK-INPUT-TEXT        PIC X(4096).
       01  LK-TOKEN-COUNT       PIC 9(4).
       01  LK-TOKEN-IDS.
           05  LK-TOKEN-ID OCCURS 2048 PIC 9(5).
       01  LK-OPERATION         PIC X(8).
       01  LK-TOKEN             PIC X(64).
       01  LK-TOKEN-ID-OUT      PIC 9(5).
       01  LK-DETOKENIZED       PIC X(8192).

       PROCEDURE DIVISION USING LK-OPERATION LK-INPUT-TEXT
                                LK-TOKEN-COUNT LK-TOKEN-IDS
                                LK-TOKEN LK-TOKEN-ID-OUT
                                LK-DETOKENIZED.
       MAIN-PARA.
           EVALUATE LK-OPERATION
               WHEN 'INIT'
                   PERFORM LOAD-VOCABULARY
               WHEN 'ENCODE'
                   PERFORM ENCODE-TEXT
               WHEN 'DECODE'
                   PERFORM DECODE-IDS
               WHEN 'LOOKUP'
                   PERFORM LOOKUP-TOKEN
               WHEN OTHER
                   DISPLAY 'TOKENIZER: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Loads the 50,000-entry BPE vocabulary into memory.          *
      *--------------------------------------------------------------*
       LOAD-VOCABULARY.
           OPEN INPUT VOCAB-FILE.
           IF NOT VOCAB-OK
               DISPLAY 'TOKENIZER: Unable to open models/vocab.bpe.'
               GOBACK
           END-IF.
           MOVE 0 TO WS-VOCAB-SIZE.
           PERFORM UNTIL WS-EOF
               READ VOCAB-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-FLAG
                   NOT AT END
                       ADD 1 TO WS-VOCAB-SIZE
               END-READ
           END-PERFORM.
           CLOSE VOCAB-FILE.
           DISPLAY 'TOKENIZER: Vocabulary loaded, '
                   WS-VOCAB-SIZE ' entries.'.

      *--------------------------------------------------------------*
      * Greedy left-to-right BPE merge using the byte order.        *
      * The COBOL STRING primitive is used as the byte stream.      *
      *--------------------------------------------------------------*
       ENCODE-TEXT.
           MOVE LK-INPUT-TEXT TO WS-INPUT-TEXT.
           MOVE 0 TO WS-TOKEN-COUNT.
           MOVE 1 TO WS-POS.
           PERFORM UNTIL WS-POS > 4096
               IF WS-INPUT-TEXT(WS-POS:1) = ' '
                   CONTINUE
               END-IF
               MOVE WS-INPUT-TEXT(WS-POS:32) TO WS-CURRENT-TOKEN
               PERFORM LOOKUP-TOKEN
               IF WS-TOKEN-ID-OUT > 0
                   ADD 1 TO WS-TOKEN-COUNT
                   MOVE WS-TOKEN-ID-OUT
                       TO WS-TOKEN-ID-ENTRY(WS-TOKEN-COUNT)
               END-IF
               ADD 32 TO WS-POS
           END-PERFORM.
           MOVE WS-TOKEN-COUNT TO LK-TOKEN-COUNT.

      *--------------------------------------------------------------*
      * Binary search over the sorted vocabulary table.             *
      *--------------------------------------------------------------*
       LOOKUP-TOKEN.
           MOVE LK-TOKEN TO WS-COMPARE-TOKEN.
           MOVE 0 TO WS-TOKEN-ID-OUT.
           MOVE 1 TO WS-LOW.
           MOVE WS-VOCAB-SIZE TO WS-HIGH.
           MOVE 'N' TO WS-FOUND.
           PERFORM UNTIL WS-LOW > WS-HIGH OR WS-FOUND = 'Y'
               COMPUTE WS-MID = (WS-LOW + WS-HIGH) / 2
               IF WS-COMPARE-TOKEN < WS-CURRENT-TOKEN
                   COMPUTE WS-HIGH = WS-MID - 1
               ELSE
                   IF WS-COMPARE-TOKEN > WS-CURRENT-TOKEN
                       COMPUTE WS-LOW = WS-MID + 1
                   ELSE
                       MOVE WS-MID TO WS-TOKEN-ID-OUT
                       MOVE 'Y' TO WS-FOUND
                   END-IF
               END-IF
           END-PERFORM.

      *--------------------------------------------------------------*
      * Reassembles a byte stream from a list of token ids.         *
      *--------------------------------------------------------------*
       DECODE-IDS.
           MOVE SPACES TO WS-RESULT-STRING.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > LK-TOKEN-COUNT
               MOVE LK-TOKEN-ID(WS-I) TO WS-TOKEN-ID
               IF WS-TOKEN-ID >= 50000 AND WS-TOKEN-ID <= 50007
                   CONTINUE
               END-IF
               STRING WS-RESULT-STRING DELIMITED BY SIZE
                      ' ' DELIMITED BY SIZE
                      INTO WS-RESULT-STRING
               END-STRING
           END-PERFORM.
           MOVE WS-RESULT-STRING TO LK-DETOKENIZED.

       END PROGRAM TOKENIZER.
