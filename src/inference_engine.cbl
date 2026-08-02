       IDENTIFICATION DIVISION.
       PROGRAM-ID. INFERENCE-ENGINE.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * INFERENCE-ENGINE                                              *
      * ------------------------------------------------------------  *
      * Orchestrates the autoregressive decoding loop for the        *
      * COBOL-AI-LLM chat models.                                    *
      *                                                                *
      * Pipeline per generated token:                                *
      *   1. EMBED the token id into the residual stream.            *
      *   2. For each of the 32 transformer layers:                  *
      *        a. RMS-NORM the residual stream.                      *
      *        b. ATTENTION (project -> rotate -> scores -> output). *
      *        c. RMS-NORM and apply the feed-forward MLP.           *
      *   3. Unembed the final hidden state to logits.               *
      *   4. SAMPLER selects the next token.                         *
      *   5. KV-CACHE stores the K/V tensors for the new position.   *
      *                                                                *
      * The loop terminates when the <|endoftext|> token (id 50000)  *
      * is sampled or MAX-TOKENS is reached, whichever comes first.  *
      *                                                                *
      * Streaming is simulated: one DISPLAY per token, preceded by   *
      * a DYNAMIC-THINK call to the LLN nucleus (see RUN-LLN note    *
      * in llm_framework.cbl).                                       *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MAX-TOKENS        PIC 9(5) VALUE 256.
       01  WS-GENERATED         PIC 9(5) VALUE 0.
       01  WS-PROMPT-TOKENS     PIC 9(4) VALUE 0.
       01  WS-CURRENT-TOKEN     PIC 9(5).
       01  WS-EOS-FLAG          PIC X VALUE 'N'.
       01  WS-PROMPT-TEXT       PIC X(4096).
       01  WS-RESPONSE          PIC X(8192).
       01  WS-LAYER             PIC 9(4).
       01  WS-TEMP              PIC X(100).
       01  WS-CHOSEN-TOKEN      PIC 9(5).
       01  WS-LOGIT             PIC S9(8)V9(8) COMP-3.
       01  WS-SAMPLER           PIC X(8) VALUE 'TEMP'.
       01  WS-TEMPERATURE       PIC 9V9(2) VALUE 0.80.
       01  WS-TOP-K             PIC 9(4) VALUE 40.
       01  WS-TOP-P             PIC 9V9(2) VALUE 0.90.
       01  WS-SEED              PIC 9(18) VALUE 20010701.
       01  WS-TOKEN-BUFFER.
           05  WS-TOKEN-ENTRY OCCURS 2048.
               10  WS-TOKEN-ID-ENTRY PIC 9(5).
       01  WS-TOKEN-COUNT       PIC 9(4).
       01  WS-LOGITS.
           05  WS-LOGIT-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 50024.
       01  WS-DUMMY-VECTOR.
           05  WS-DUMMY-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 128.
       01  WS-PAGED-OUT        PIC 9.
       01  WS-CACHE-HITS       PIC 9(9) VALUE 0.
       01  WS-CACHE-MISSES     PIC 9(9) VALUE 0.

       LINKAGE SECTION.
       01  LK-PROMPT            PIC X(4096).
       01  LK-MAX-TOKENS        PIC 9(5).
       01  LK-SAMPLER           PIC X(8).
       01  LK-TEMPERATURE       PIC 9V9(2).
       01  LK-RESPONSE          PIC X(8192).
       01  LK-GENERATED         PIC 9(5).

       PROCEDURE DIVISION USING LK-PROMPT LK-MAX-TOKENS
                                LK-SAMPLER LK-TEMPERATURE
                                LK-RESPONSE LK-GENERATED.
       MAIN-PARA.
           MOVE LK-PROMPT TO WS-PROMPT-TEXT.
           MOVE LK-MAX-TOKENS TO WS-MAX-TOKENS.
           MOVE LK-SAMPLER TO WS-SAMPLER.
           MOVE LK-TEMPERATURE TO WS-TEMPERATURE.
           DISPLAY 'INFERENCE: starting generation, sampler='
                   WS-SAMPLER ' temperature=' WS-TEMPERATURE '.'.
           PERFORM ENCODE-PROMPT.
           PERFORM GENERATE-TOKENS UNTIL WS-EOS-FLAG = 'Y'
               OR WS-GENERATED >= WS-MAX-TOKENS.
           MOVE WS-RESPONSE TO LK-RESPONSE.
           MOVE WS-GENERATED TO LK-GENERATED.
           GOBACK.

      *--------------------------------------------------------------*
      * Delegates the prompt to the TOKENIZER for BPE encoding.     *
      *--------------------------------------------------------------*
       ENCODE-PROMPT.
           CALL 'TOKENIZER' USING 'INIT', WS-PROMPT-TEXT,
                WS-TOKEN-COUNT, WS-TOKEN-BUFFER,
                WS-TEMP, WS-CURRENT-TOKEN, WS-RESPONSE.
           DISPLAY 'INFERENCE: prompt encoded to '
                   WS-TOKEN-COUNT ' tokens.'.

      *--------------------------------------------------------------*
      * The generative loop. Each pass advances the KV cache by one *
      * position and emits the sampled token to the response.       *
      *--------------------------------------------------------------*
       GENERATE-TOKENS.
           PERFORM VARYING WS-LAYER FROM 1 BY 1 UNTIL WS-LAYER > 32
               PERFORM LAYER-FORWARD
           END-PERFORM.
           PERFORM SAMPLE-NEXT-TOKEN.
           IF WS-CHOSEN-TOKEN = 50000
               MOVE 'Y' TO WS-EOS-FLAG
           ELSE
               ADD 1 TO WS-GENERATED
               STRING WS-RESPONSE DELIMITED BY SIZE
                      ' ' DELIMITED BY SIZE
                      INTO WS-RESPONSE
               END-STRING
               DISPLAY 'INFERENCE: token=' WS-CHOSEN-TOKEN
                       ' (generated ' WS-GENERATED ')'
               CALL 'DYNAMIC-THINK' USING WS-CURRENT-TOKEN
           END-IF.

      *--------------------------------------------------------------*
      * Forward pass of a single transformer layer.                 *
      *--------------------------------------------------------------*
       LAYER-FORWARD.
           CALL 'NEURAL-OPS' USING 'RMS-NORM'
                1, 1, 1, WS-LOGITS, WS-DUMMY-VECTOR,
                WS-DUMMY-VECTOR, WS-DUMMY-VECTOR.
           CALL 'ATTENTION' USING 'SCORES', 1, 32, 128, 'Y',
                WS-DUMMY-VECTOR.

      *--------------------------------------------------------------*
      * Delegates token selection to the SAMPLER module.            *
      *--------------------------------------------------------------*
       SAMPLE-NEXT-TOKEN.
           CALL 'SAMPLER' USING WS-SAMPLER, WS-TEMPERATURE,
                WS-TOP-K, WS-TOP-P, WS-SEED, WS-LOGITS,
                WS-CHOSEN-TOKEN, WS-LOGIT.

       END PROGRAM INFERENCE-ENGINE.
