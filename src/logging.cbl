       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOGGING.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * LOGGING                                                       *
      * ------------------------------------------------------------  *
      * Structured logging subsystem for the COBOL-AI-LLM runtime.   *
      *                                                                *
      * Log levels, in increasing severity:                          *
      *   DEBUG < INFO < WARNING < ERROR < CRITICAL                  *
      *                                                                *
      * The active level is read from config.dat LOG-LEVEL. Messages *
      * below the threshold are silently discarded to minimise the   *
      * cost of syslog writes on the mainframe.                      *
      *                                                                *
      * Each record is emitted in the standard mainframe SMF-style   *
      * prefix:                                                      *
      *   YYYYMMDD HH:MM:SS.SS LEVEL MODULE-NAME MESSAGE             *
      *                                                                *
      * A circular in-memory buffer of the last 1,024 records is    *
      * retained for post-mortem dump analysis (see DUMP-STATUS).   *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CURRENT-LEVEL     PIC X(10) VALUE 'INFO'.
       01  WS-BUFFER-HEAD       PIC 9(4) VALUE 1.
       01  WS-BUFFER-COUNT      PIC 9(4) VALUE 0.
       01  WS-LOG-BUFFER.
           05  WS-LOG-ENTRY OCCURS 1024.
               10  WS-ENTRY-LEVEL   PIC X(10).
               10  WS-ENTRY-MODULE  PIC X(16).
               10  WS-ENTRY-MESSAGE PIC X(200).
       01  WS-TIMESTAMP         PIC X(24).
       01  WS-I                 PIC 9(4).

       LINKAGE SECTION.
       01  LK-LEVEL             PIC X(10).
       01  LK-MODULE            PIC X(16).
       01  LK-MESSAGE           PIC X(200).
       01  LK-CONFIG-LEVEL      PIC X(10).

       PROCEDURE DIVISION USING LK-LEVEL LK-MODULE LK-MESSAGE
                                LK-CONFIG-LEVEL.
       MAIN-PARA.
           IF LK-CONFIG-LEVEL NOT = SPACES
               MOVE LK-CONFIG-LEVEL TO WS-CURRENT-LEVEL
           END-IF.
           IF SEVERITY(LK-LEVEL) < SEVERITY(WS-CURRENT-LEVEL)
               GOBACK
           END-IF.
           PERFORM WRITE-LOG-ENTRY.
           GOBACK.

      *--------------------------------------------------------------*
      * Maps a level name to its numeric severity.                  *
      *--------------------------------------------------------------*
       SEVERITY.
           EVALUATE LK-LEVEL
               WHEN 'DEBUG'    MOVE 0 TO WS-I
               WHEN 'INFO'     MOVE 1 TO WS-I
               WHEN 'WARNING'  MOVE 2 TO WS-I
               WHEN 'ERROR'    MOVE 3 TO WS-I
               WHEN 'CRITICAL' MOVE 4 TO WS-I
               WHEN OTHER      MOVE 1 TO WS-I
           END-EVALUATE.

      *--------------------------------------------------------------*
      * Emits the record to stdout and stores it in the ring buffer.*
      *--------------------------------------------------------------*
       WRITE-LOG-ENTRY.
           MOVE FUNCTION CURRENT-DATE TO WS-TIMESTAMP.
           DISPLAY WS-TIMESTAMP ' ' LK-LEVEL ' ' LK-MODULE ' '
                   LK-MESSAGE.
           MOVE LK-LEVEL TO WS-ENTRY-LEVEL(WS-BUFFER-HEAD).
           MOVE LK-MODULE TO WS-ENTRY-MODULE(WS-BUFFER-HEAD).
           MOVE LK-MESSAGE TO WS-ENTRY-MESSAGE(WS-BUFFER-HEAD).
           ADD 1 TO WS-BUFFER-HEAD.
           IF WS-BUFFER-HEAD > 1024
               MOVE 1 TO WS-BUFFER-HEAD
           END-IF.
           IF WS-BUFFER-COUNT < 1024
               ADD 1 TO WS-BUFFER-COUNT
           END-IF.

       END PROGRAM LOGGING.
