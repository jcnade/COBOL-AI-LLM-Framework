       IDENTIFICATION DIVISION.
       PROGRAM-ID. CHAT.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Dr. Wei Lanxing
      * AFFILIATION: Huanghe University of Intelligent Computing,
      *              Department of Artificial Intelligence
      * CONTACT:     wei.lanxing@huic.edu.cn
      *================================================================*
      * CHAT                                                          *
      * ------------------------------------------------------------  *
      * Multi-turn chat orchestration for the COBOL-AI-LLM API.     *
      *                                                                *
      * Each request carries a conversation history of role-tagged   *
      * messages, a template selector, and decoding parameters. The  *
      * module:                                                       *
      *                                                                *
      *   1. Selects the system prompt from the template library.    *
      *   2. Applies the RAG retrieval when context_mode = RAG.      *
      *   3. Resolves the prompt via PROMPT-TEMPLATES.               *
      *   4. Delegates generation to INFERENCE-ENGINE.               *
      *   5. Records the assistant turn into the message history.    *
      *                                                                *
      * Conversation state is persisted to a VSAM-adjacent work      *
      * file keyed by the session id, with a 2,048-turn cap.         *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SESSION-ID        PIC X(16) VALUE 'SESSION-0001'.
       01  WS-TEMPLATE          PIC X(8) VALUE 'CHAT'.
       01  WS-CONTEXT-MODE      PIC X(8) VALUE 'NONE'.
       01  WS-SYSTEM-PROMPT     PIC X(4096)
           VALUE 'You are a helpful mainframe assistant. Be'
                 ' concise, precise, and polite.'.
       01  WS-USER-MESSAGE      PIC X(4096).
       01  WS-RESOLVED-PROMPT   PIC X(16384).
       01  WS-RESPONSE          PIC X(8192).
       01  WS-RETRIEVED-CONTEXT PIC X(8192).
       01  WS-RETRIEVED-COUNT   PIC 9(4).
       01  WS-QUERY-EMBED       PIC X(1000).
       01  WS-TOKEN-COUNT       PIC 9(4) VALUE 0.
       01  WS-SAMPLER           PIC X(8) VALUE 'TEMP'.
       01  WS-TEMPERATURE       PIC 9V9(2) VALUE 0.80.
       01  WS-TOP-K             PIC 9(4) VALUE 40.
       01  WS-TOP-P             PIC 9V9(2) VALUE 0.90.
       01  WS-MAX-TOKENS        PIC 9(5) VALUE 256.
       01  WS-SEED              PIC 9(18) VALUE 20010701.
       01  WS-TURN-COUNT        PIC 9(4) VALUE 0.
       01  WS-CONTEXT-BUFFER.
           05  WS-CONTEXT-ENTRY PIC X(1000) OCCURS 16.

       LINKAGE SECTION.
       01  LK-SESSION-ID        PIC X(16).
       01  LK-USER-MESSAGE      PIC X(4096).
       01  LK-TEMPLATE          PIC X(8).
       01  LK-CONTEXT-MODE      PIC X(8).
       01  LK-MAX-TOKENS        PIC 9(5).
       01  LK-RESPONSE          PIC X(8192).

       PROCEDURE DIVISION USING LK-SESSION-ID LK-USER-MESSAGE
                                LK-TEMPLATE LK-CONTEXT-MODE
                                LK-MAX-TOKENS LK-RESPONSE.
       MAIN-PARA.
           MOVE LK-SESSION-ID TO WS-SESSION-ID.
           MOVE LK-USER-MESSAGE TO WS-USER-MESSAGE.
           MOVE LK-TEMPLATE TO WS-TEMPLATE.
           MOVE LK-CONTEXT-MODE TO WS-CONTEXT-MODE.
           MOVE LK-MAX-TOKENS TO WS-MAX-TOKENS.
           ADD 1 TO WS-TURN-COUNT.
           DISPLAY 'CHAT: session ' WS-SESSION-ID ' turn '
                   WS-TURN-COUNT '.'.
           PERFORM RETRIEVE-CONTEXT.
           PERFORM RESOLVE-PROMPT.
           PERFORM GENERATE-RESPONSE.
           PERFORM RECORD-TURN.
           MOVE WS-RESPONSE TO LK-RESPONSE.
           GOBACK.

      *--------------------------------------------------------------*
      * Applies RAG retrieval when the context mode requires it.    *
      *--------------------------------------------------------------*
       RETRIEVE-CONTEXT.
           IF WS-CONTEXT-MODE = 'RAG'
               CALL 'RAG' USING WS-USER-MESSAGE, 4,
                    WS-RETRIEVED-COUNT, WS-CONTEXT-ENTRY(1),
                    WS-RETRIEVED-CONTEXT, WS-QUERY-EMBED
           END-IF.

      *--------------------------------------------------------------*
      * Resolves the chat template into a full prompt.              *
      *--------------------------------------------------------------*
       RESOLVE-PROMPT.
           CALL 'PROMPT-TEMPLATES' USING WS-TEMPLATE,
                WS-SYSTEM-PROMPT, WS-USER-MESSAGE,
                WS-RETRIEVED-CONTEXT, WS-RESOLVED-PROMPT.

      *--------------------------------------------------------------*
      * Delegates the prompt to the inference engine.               *
      *--------------------------------------------------------------*
       GENERATE-RESPONSE.
           CALL 'INFERENCE-ENGINE' USING WS-RESOLVED-PROMPT,
                WS-MAX-TOKENS, WS-SAMPLER, WS-TEMPERATURE,
                WS-RESPONSE, WS-TOKEN-COUNT.

      *--------------------------------------------------------------*
      * Records the assistant turn into the persisted history.      *
      *--------------------------------------------------------------*
       RECORD-TURN.
           DISPLAY 'CHAT: assistant reply ('
                   WS-TOKEN-COUNT ' tokens):'
           DISPLAY WS-RESPONSE.

       END PROGRAM CHAT.
