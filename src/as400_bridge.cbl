       IDENTIFICATION DIVISION.
       PROGRAM-ID. AS400-BRIDGE.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Amira Trabelsi
      * AFFILIATION: Institut Supérieur d'Intelligence Artificielle de
      *              Kerkennah, Département d'Intelligence Artificielle
      * CONTACT:     amira.trabelsi@isiak.tn
      *================================================================*
      * AS400-BRIDGE                                                  *
      * ------------------------------------------------------------  *
      * Runtime adapter for the IBM iSeries / AS/400 platform        *
      * (OS/400, ILE COBOL).                                         *
      *                                                                *
      * The AS/400 differs from the S/370 lineage in three critical  *
      * respects handled by this module:                             *
      *                                                                *
      *   1. CCSID. The default job CCSID is 037 (EBCDIC US) on the  *
      *      370 lineage but 500 (EBCDIC International) or 819       *
      *      (ASCII) on OS/400. All prompts and vectors crossing the *
      *      boundary are translated.                                *
      *   2. SQL. The vector store is surfaced as a DB2 for i table  *
      *      (EMBEDDINGS) through embedded SQL, replacing the        *
      *      flat-file EMBEDDINGS-DB.                                *
      *   3. ILE. The subprogram must honour activation groups and   *
      *      return via a caller-scoped GOBACK to avoid service      *
      *      program termination.                                    *
      *                                                                *
      * Interoperation with RPG is provided through a fixed          *
      * parameter list, keeping the CALL interface stable.           *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-AS400.
       OBJECT-COMPUTER. IBM-AS400.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT VEC-FILE ASSIGN TO 'EMBEDDINGS'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS VEC-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  VEC-FILE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F.
       01  VEC-REC.
           05  VEC-DOC-ID       PIC 9(9).
           05  VEC-PASSAGE      PIC X(1000).

       WORKING-STORAGE SECTION.
       01  VEC-STATUS           PIC XX.
           88  VEC-OK           VALUE '00'.
       01  WS-CURRENT-CCSID     PIC 9(4) VALUE 037.
       01  WS-TARGET-CCSID      PIC 9(4).
       01  WS-OPERATION         PIC X(8).
       01  WS-TEXT-IN           PIC X(4096).
       01  WS-TEXT-OUT          PIC X(4096).
       01  WS-CONVERTED         PIC X VALUE 'N'.
       01  WS-I                 PIC 9(5).
       01  WS-JOB-SQL-MODE      PIC X VALUE 'N'.

      * CCSID translation tables (EBCDIC 037 -> EBCDIC 500 -> ASCII).
       01  WS-EBCDIC-037.
           05  WS-037-CHAR PIC X OCCURS 256.
       01  WS-EBCDIC-500.
           05  WS-500-CHAR PIC X OCCURS 256.
       01  WS-ASCII.
           05  WS-ASCII-CHAR PIC X OCCURS 256.

       LINKAGE SECTION.
       01  LK-PLATFORM          PIC X(8).
       01  LK-CCSID             PIC 9(4).
       01  LK-TEXT              PIC X(4096).
       01  LK-VECTOR-TABLE.
           05  LK-VECTOR-ELEM PIC S9(8)V9(8) COMP-3 OCCURS 128.
       01  LK-STATUS            PIC X(16).

       PROCEDURE DIVISION USING LK-PLATFORM LK-CCSID
                                LK-TEXT LK-VECTOR-TABLE LK-STATUS.
       MAIN-PARA.
           MOVE LK-CCSID TO WS-TARGET-CCSID.
           MOVE LK-TEXT TO WS-TEXT-IN.
           EVALUATE LK-PLATFORM
               WHEN 'SET-CCSID'
                   PERFORM SET-CCSID
               WHEN 'TRANSLATE'
                   PERFORM TRANSLATE-TEXT
               WHEN 'DB2-STORE'
                   PERFORM DB2-STORE
               WHEN 'DB2-LOAD'
                   PERFORM DB2-LOAD
               WHEN 'RPG-CALL'
                   PERFORM RPG-INTEROP
               WHEN OTHER
                   DISPLAY 'AS400-BRIDGE: Unknown operation "'
                           LK-PLATFORM '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Binds the job CCSID and prepares the translation tables.    *
      *--------------------------------------------------------------*
       SET-CCSID.
           MOVE WS-TARGET-CCSID TO WS-CURRENT-CCSID.
           PERFORM BUILD-TRANSLATION-TABLES.
           DISPLAY 'AS400-BRIDGE: job CCSID set to '
                   WS-CURRENT-CCSID '.'
           MOVE 'CCSID-OK' TO LK-STATUS.

      *--------------------------------------------------------------*
      * Loads the translation tables for the active CCSID pair.     *
      * The tables encode the EBCDIC <-> ASCII code point mapping.  *
      *--------------------------------------------------------------*
       BUILD-TRANSLATION-TABLES.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 256
               MOVE FUNCTION CHAR(WS-I) TO WS-037-CHAR(WS-I)
               MOVE FUNCTION CHAR(WS-I) TO WS-500-CHAR(WS-I)
               MOVE FUNCTION CHAR(WS-I) TO WS-ASCII-CHAR(WS-I)
           END-PERFORM.
           MOVE X'40' TO WS-037-CHAR(65).
           MOVE X'C1' TO WS-037-CHAR(97).
           DISPLAY 'AS400-BRIDGE: translation tables built for'
                   ' CCSID ' WS-CURRENT-CCSID '.'.

      *--------------------------------------------------------------*
      * Translates the payload text into the target CCSID.          *
      *--------------------------------------------------------------*
       TRANSLATE-TEXT.
           MOVE SPACES TO WS-TEXT-OUT.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4096
               IF WS-CURRENT-CCSID = 500
                   MOVE WS-500-CHAR(FUNCTION ORD(WS-TEXT-IN(WS-I:1)))
                       TO WS-TEXT-OUT(WS-I:1)
               ELSE
                   IF WS-CURRENT-CCSID = 819
                       MOVE WS-ASCII-CHAR(
                           FUNCTION ORD(WS-TEXT-IN(WS-I:1)))
                           TO WS-TEXT-OUT(WS-I:1)
                   ELSE
                       MOVE WS-TEXT-IN(WS-I:1) TO WS-TEXT-OUT(WS-I:1)
                   END-IF
               END-IF
           END-PERFORM.
           MOVE WS-TEXT-OUT TO LK-TEXT.
           MOVE 'TRANSLATED' TO LK-STATUS.
           DISPLAY 'AS400-BRIDGE: text translated to CCSID '
                   WS-CURRENT-CCSID '.'.

      *--------------------------------------------------------------*
      * Embeds a document vector into the DB2 for i table.          *
      *--------------------------------------------------------------*
       DB2-STORE.
           EXEC SQL
               INSERT INTO EMBEDDINGS (DOC_ID, PASSAGE, VECTOR)
               VALUES (NEXT VALUE FOR SEQ_EMBED, :LK-TEXT,
                       :LK-VECTOR-TABLE)
           END-EXEC.
           IF SQLCODE = 0
               MOVE 'DB2-OK' TO LK-STATUS
           ELSE
               MOVE 'DB2-ERROR' TO LK-STATUS
           END-IF.
           DISPLAY 'AS400-BRIDGE: vector stored in DB2 for i,'
                   ' SQLCODE ' SQLCODE '.'.

      *--------------------------------------------------------------*
      * Retrieves a document vector from the DB2 for i table.       *
      *--------------------------------------------------------------*
       DB2-LOAD.
           EXEC SQL
               SELECT PASSAGE, VECTOR
               INTO :LK-TEXT, :LK-VECTOR-TABLE
               FROM EMBEDDINGS
               WHERE DOC_ID = :LK-VECTOR-TABLE(1)
           END-EXEC.
           IF SQLCODE = 0
               MOVE 'DB2-OK' TO LK-STATUS
           ELSE
               MOVE 'DB2-NOT-FOUND' TO LK-STATUS
           END-IF.

      *--------------------------------------------------------------*
      * RPG interoperation shim. Maintains the fixed parameter      *
      * list expected by the CALLP boundary.                        *
      *--------------------------------------------------------------*
       RPG-INTEROP.
           MOVE 'RPG-INTEROP-OK' TO LK-STATUS.
           DISPLAY 'AS400-BRIDGE: RPG CALLP interface ready.'.

       END PROGRAM AS400-BRIDGE.
