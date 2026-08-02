       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROMPT-TEMPLATES.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * PROMPT-TEMPLATES                                              *
      * ------------------------------------------------------------  *
      * Prompt engineering library for the COBOL-AI-LLM chat models. *
      *                                                                *
      * The chat protocol uses a role-tagged message envelope:      *
      *   <|system|>    instructions governing behaviour             *
      *   <|user|>      end-user request                             *
      *   <|assistant|> model reply                                  *
      *                                                                *
      * Four built-in templates are provided:                       *
      *   CHAT      - general conversational assistant               *
      *   REASON    - chain-of-thought reasoning protocol            *
      *   FEW-SHOT  - exemplar-guided classification                 *
      *   RAG       - retrieved-context grounded answering           *
      *                                                                *
      * Templates are parameterised and resolved at call time. The   *
      * resolved prompt is passed to the INFERENCE-ENGINE.           *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SYSTEM-PROMPT     PIC X(4096).
       01  WS-USER-MESSAGE      PIC X(4096).
       01  WS-CONTEXT           PIC X(8192).
       01  WS-RESOLVED-PROMPT   PIC X(16384).
       01  WS-PASSAGE           PIC X(1000).
       01  WS-ANSWER            PIC X(1000).
       01  WS-REASONING         PIC X(1000).

       LINKAGE SECTION.
       01  LK-TEMPLATE          PIC X(8).
       01  LK-SYSTEM            PIC X(4096).
       01  LK-USER              PIC X(4096).
       01  LK-CONTEXT           PIC X(8192).
       01  LK-PROMPT-OUT        PIC X(16384).

       PROCEDURE DIVISION USING LK-TEMPLATE LK-SYSTEM
                                LK-USER LK-CONTEXT LK-PROMPT-OUT.
       MAIN-PARA.
           MOVE LK-SYSTEM TO WS-SYSTEM-PROMPT.
           MOVE LK-USER TO WS-USER-MESSAGE.
           MOVE LK-CONTEXT TO WS-CONTEXT.
           EVALUATE LK-TEMPLATE
               WHEN 'CHAT'
                   PERFORM BUILD-CHAT-PROMPT
               WHEN 'REASON'
                   PERFORM BUILD-REASON-PROMPT
               WHEN 'FEW-SHOT'
                   PERFORM BUILD-FEWSHOT-PROMPT
               WHEN 'RAG'
                   PERFORM BUILD-RAG-PROMPT
               WHEN OTHER
                   PERFORM BUILD-CHAT-PROMPT
           END-EVALUATE.
           MOVE WS-RESOLVED-PROMPT TO LK-PROMPT-OUT.
           GOBACK.

      *--------------------------------------------------------------*
      * Standard chat envelope.                                     *
      *--------------------------------------------------------------*
       BUILD-CHAT-PROMPT.
           MOVE SPACES TO WS-RESOLVED-PROMPT.
           STRING '<|system|>' WS-SYSTEM-PROMPT
                  '<|user|>' WS-USER-MESSAGE
                  '<|assistant|>'
                  DELIMITED BY SIZE INTO WS-RESOLVED-PROMPT
           END-STRING.

      *--------------------------------------------------------------*
      * Chain-of-thought protocol with the reasoning preamble.      *
      *--------------------------------------------------------------*
       BUILD-REASON-PROMPT.
           MOVE SPACES TO WS-RESOLVED-PROMPT.
           STRING '<|system|>' WS-SYSTEM-PROMPT
                  '<|reason|>Work step by step, and state your'
                  ' assumptions before concluding.'
                  '<|user|>' WS-USER-MESSAGE
                  '<|analysis|>'
                  DELIMITED BY SIZE INTO WS-RESOLVED-PROMPT
           END-STRING.

      *--------------------------------------------------------------*
      * Few-shot template with two exemplar pairs.                  *
      *--------------------------------------------------------------*
       BUILD-FEWSHOT-PROMPT.
           MOVE SPACES TO WS-RESOLVED-PROMPT.
           STRING '<|system|>' WS-SYSTEM-PROMPT
                  '<|user|>Example: the ledger is balanced.'
                  '<|assistant|>BALANCED'
                  '<|user|>Example: the vault is short by 2.'
                  '<|assistant|>SHORTFALL'
                  '<|user|>' WS-USER-MESSAGE
                  '<|assistant|>'
                  DELIMITED BY SIZE INTO WS-RESOLVED-PROMPT
           END-STRING.

      *--------------------------------------------------------------*
      * RAG-grounded answering over the retrieved passages.         *
      *--------------------------------------------------------------*
       BUILD-RAG-PROMPT.
           MOVE SPACES TO WS-RESOLVED-PROMPT.
           STRING '<|system|>Answer using only the retrieved'
                  ' passages. Cite the document ids.'
                  '<|context|>' WS-CONTEXT
                  '<|user|>' WS-USER-MESSAGE
                  '<|assistant|>'
                  DELIMITED BY SIZE INTO WS-RESOLVED-PROMPT
           END-STRING.

       END PROGRAM PROMPT-TEMPLATES.
