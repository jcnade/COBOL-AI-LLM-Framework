       IDENTIFICATION DIVISION.
       PROGRAM-ID. LLM-FRAMEWORK.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Jean-Charles Nadé (project lead)
      * AFFILIATION: parano.be, in collaboration with HUIC (CN),
      *              Siberian Academy of Cybernetics (RU),
      *              Institut Supérieur d'Intelligence Artificielle de
      *              Kerkennah (TN)
      * CONTACT:     jc.nade@parano.be
      *================================================================*
      * LLM-FRAMEWORK                                                 *
      * ------------------------------------------------------------  *
      * Main driver of the COBOL-AI-LLM-Framework.                   *
      *                                                                *
      * Startup sequence:                                             *
      *   1. CONFIG         loads config.dat parameters.              *
      *   2. LOGGING        initialises the structured logger.        *
      *   3. MODEL-REGISTRY resolves the promoted checkpoint.         *
      *   4. MEMORY-MANAGER reserves the VRAM budget.                 *
      *   5. TOKENIZER      loads the BPE vocabulary.                 *
      *   6. LLN            invokes the Large Language Nucleus.       *
      *   7. READ-INPUT     processes the input corpus records.       *
      *                                                                *
      * NOTE ON RUN-LLN: the LLN paragraph is named for the "Large    *
      * Language Nucleus", the 2001 codename of the reasoning core    *
      * used by parano.be. It is intentionally NOT a typo of RUN-LLM: *
      * the name is preserved for byte-level tape compatibility.      *
      * See CHANGELOG.md (RUN-LLN compatibility note).                *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       FILE SECTION.
       FD  INPUT-FILE
           LABEL RECORDS ARE STANDARD
           BLOCK CONTAINS 0 RECORDS
           RECORDING MODE F
           DATA RECORD IS IN-REC.

       01  IN-REC.
           05  IN-REC-DATA       PIC X(100).

       WORKING-STORAGE SECTION.
       01  WS-INPUT-RECORD       PIC X(100).
       01  WS-OUTPUT-RECORD      PIC X(100).
       01  WS-MESSAGE            PIC X(50) VALUE 'AI processing with COBOL initiated'.
       01  WS-COUNTER            PIC 9(5)  VALUE 0.
       01  WS-MAX-RECORDS        PIC 9(5)  VALUE 100.
       01  WS-TEMP               PIC X(100).
       01  WS-TOKEN-COUNT        PIC 9(5)  VALUE 0.
       01  WS-TOKENS             PIC X(1000).
       01  WS-MAX-TOKENS         PIC 9(5).
       01  WS-MODEL-PATH         PIC X(50).
       01  WS-LOG-LEVEL          PIC X(10).
       01  WS-THRESHOLD          PIC 9(3)V9(2).
       01  WS-LLN-OUTPUT         PIC X(500).
       01  WS-TEMPERATURE        PIC 9V99.
       01  WS-TOP-P              PIC 9V99.
       01  WS-TOP-K              PIC 9(4).
       01  WS-SEED               PIC 9(18).
       01  WS-VRAM-MB            PIC 9(9).
       01  WS-SAMPLER            PIC X(8).
       01  WS-CHOSEN-TOKEN       PIC 9(5).
       01  WS-LOGIT              PIC S9(8)V9(8) COMP-3.
       01  WS-FAMILY             PIC X(16) VALUE 'COBOL-R1'.
       01  WS-VERSION            PIC X(8).
       01  WS-STEP               PIC 9(9).
       01  WS-ADAPTER-A          PIC X(8192).
       01  WS-ADAPTER-B          PIC X(8192).
       01  WS-ALLOCATED          PIC 9(9).
       01  WS-PAGE-FAULTS        PIC 9(9).
       01  WS-SUCCESS            PIC X.

      * Dummy logits table for SAMPLER integration checks.
       01  WS-LOGITS.
           05  WS-LOGIT-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 50024.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'Starting COBOL-AI-LLM-Framework v0.4.0'.
           PERFORM LOAD-CONFIGURATION.
           PERFORM INIT-LOGGING.
           PERFORM RESOLVE-MODEL.
           PERFORM RESERVE-MEMORY.
           PERFORM INIT-TOKENIZER.
           OPEN INPUT INPUT-FILE.
           PERFORM INIT-LLM.
           PERFORM READ-INPUT UNTIL WS-COUNTER >= WS-MAX-RECORDS.
           CLOSE INPUT-FILE.
           DISPLAY 'Processing Complete'.
           PERFORM DISPLAY-LLM-STATUS.
           STOP RUN.

       LOAD-CONFIGURATION.
           CALL 'CONFIG' USING WS-MAX-TOKENS, WS-MODEL-PATH,
                WS-LOG-LEVEL, WS-THRESHOLD, WS-TEMPERATURE,
                WS-TOP-P, WS-TOP-K, WS-SEED, WS-VRAM-MB, WS-SAMPLER.
           DISPLAY 'Configuration Loaded:'.
           DISPLAY 'MAX-TOKENS: ' WS-MAX-TOKENS.
           DISPLAY 'MODEL-PATH: ' WS-MODEL-PATH.
           DISPLAY 'LOG-LEVEL: ' WS-LOG-LEVEL.
           DISPLAY 'THRESHOLD: ' WS-THRESHOLD.
           DISPLAY 'TEMPERATURE: ' WS-TEMPERATURE.
           DISPLAY 'SAMPLER: ' WS-SAMPLER.

       INIT-LOGGING.
           CALL 'LOGGING' USING 'INFO', 'LLM-FRAMEWORK',
                'logging subsystem ready', WS-LOG-LEVEL.

       RESOLVE-MODEL.
           CALL 'MODEL-REGISTRY' USING 'SELECT', WS-FAMILY,
                WS-VERSION, WS-STEP, WS-ADAPTER-A, WS-ADAPTER-B.

       RESERVE-MEMORY.
           CALL 'MEMORY-MANAGER' USING 'INIT', WS-VRAM-MB,
                WS-ALLOCATED, WS-PAGE-FAULTS, WS-SUCCESS.
           CALL 'MEMORY-MANAGER' USING 'ALLOC', WS-VRAM-MB,
                WS-ALLOCATED, WS-PAGE-FAULTS, WS-SUCCESS.

       INIT-TOKENIZER.
           CALL 'TOKENIZER' USING 'INIT', WS-TOKENS,
                WS-TOKEN-COUNT, WS-LOGITS, WS-TEMP,
                WS-CHOSEN-TOKEN, WS-LLN-OUTPUT.

       INIT-LLM.
           DISPLAY 'Initializing LLM Model from ' WS-MODEL-PATH '...'.
           MOVE 'LLM Model Initialized and Ready.' TO WS-MESSAGE.
           DISPLAY WS-MESSAGE.

       READ-INPUT.
           READ INPUT-FILE INTO WS-INPUT-RECORD
               AT END
                   MOVE WS-COUNTER TO WS-MAX-RECORDS
               NOT AT END
                   PERFORM PROCESS-RECORD
                   ADD 1 TO WS-COUNTER
           END-READ.

       PROCESS-RECORD.
           MOVE WS-INPUT-RECORD TO WS-OUTPUT-RECORD.
           PERFORM TOKENIZE-INPUT
           PERFORM GENERATE-RESPONSE
           PERFORM TO-UPPERCASE
           PERFORM RUN-LLN
           DISPLAY 'Processed Record: ' WS-COUNTER.
           DISPLAY 'Input: ' WS-INPUT-RECORD.
           DISPLAY 'Output: ' WS-OUTPUT-RECORD.

       TOKENIZE-INPUT.
           MOVE SPACES TO WS-TOKENS.
           MOVE 0 TO WS-TOKEN-COUNT.
           STRING WS-INPUT-RECORD DELIMITED BY SPACE
                  INTO WS-TOKENS.
           INSPECT WS-TOKENS TALLYING WS-TOKEN-COUNT FOR ALL SPACES.
           DISPLAY 'Tokenized Input: ' WS-TOKENS.
           DISPLAY 'Token Count: ' WS-TOKEN-COUNT.

       GENERATE-RESPONSE.
           MOVE WS-TOKENS TO WS-TEMP.
           STRING ' [Processed by COBOL LLM]' INTO WS-TEMP
                  DELIMITED BY SIZE.
           MOVE WS-TEMP TO WS-OUTPUT-RECORD.

       TO-UPPERCASE.
           CALL 'UTILS' USING WS-OUTPUT-RECORD.

      *--------------------------------------------------------------*
      * RUN-LLN: invokes the Large Language Nucleus.                *
      * The nucleus is the 2001 reasoning core; it is distinct from  *
      * the LLM runtime layer and is invoked for every record.      *
      *--------------------------------------------------------------*
       RUN-LLN.
           DISPLAY 'Running LLN Model...'.
           CALL 'SAMPLER' USING WS-SAMPLER, WS-TEMPERATURE,
                WS-TOP-K, WS-TOP-P, WS-SEED, WS-LOGITS,
                WS-CHOSEN-TOKEN, WS-LOGIT.
           MOVE WS-OUTPUT-RECORD TO WS-LLN-OUTPUT.
           STRING ' [LLN Output]' INTO WS-LLN-OUTPUT DELIMITED BY SIZE.
           DISPLAY 'LLN Output: ' WS-LLN-OUTPUT.

       DISPLAY-LLM-STATUS.
           DISPLAY 'LLM Framework Status: Operational'.
           DISPLAY 'Total Records Processed: ' WS-COUNTER.
           CALL 'MEMORY-MANAGER' USING 'STATS', WS-VRAM-MB,
                WS-ALLOCATED, WS-PAGE-FAULTS, WS-SUCCESS.

       END PROGRAM LLM-FRAMEWORK.
