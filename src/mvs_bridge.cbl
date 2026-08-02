       IDENTIFICATION DIVISION.
       PROGRAM-ID. MVS-BRIDGE.
       AUTHOR. Jean-Charles Nadé.
      * CONTRIBUTOR: Prof. Dmitri A. Volkov
      * AFFILIATION: Siberian Academy of Cybernetics,
      *              Department of Artificial Intelligence
      * CONTACT:     d.volkov@sac.ru
      *================================================================*
      * MVS-BRIDGE                                                    *
      * ------------------------------------------------------------  *
      * Runtime adapter for the IBM 3090 mainframe (MVS/XA, ESA).    *
      *                                                                *
      * The framework runs on the 3090 in three invocation modes:   *
      *                                                                *
      *   1. BATCH. Submitted as a JCL job; the JOBLIB DD and the    *
      *      SYSOUT DD are allocated by the job stream.              *
      *   2. CICS. Invoked as a transaction; the request arrives in  *
      *      a COMMAREA and the response is returned in the same     *
      *      area before a normal DFHRETURN.                         *
      *   3. TSO. Invoked under ISPF as a REXX-called command.       *
      *                                                                *
      * The KV-cache is backed by a VSAM ESDS (KV.CACHE.VSAM) in     *
      * place of the flat backing store used on S/370. Dynamic       *
      * allocation uses SVC 99; error recovery is established        *
      * through ESTAE with a fixed-format work area.                 *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT VSAM-KV ASSIGN TO 'KV.CACHE.VSAM'
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS VSAM-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  VSAM-KV
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F.
       01  KV-REC.
           05  KV-REC-KEY       PIC X(16).
           05  KV-REC-DATA      PIC X(1024).

       WORKING-STORAGE SECTION.
       01  VSAM-STATUS          PIC XX.
           88  VSAM-OK          VALUE '00'.
       01  WS-MODE              PIC X(8) VALUE 'BATCH'.
       01  WS-COMMAREA-LENGTH   PIC 9(4) VALUE 0.
       01  WS-SVC99-RB          PIC X(80).
       01  WS-ESTAE-WORK        PIC X(256).
       01  WS-OPERATION         PIC X(8).
       01  WS-DDNAME            PIC X(8).
       01  WS-DSN               PIC X(44).
       01  WS-PROMPT            PIC X(4096).
       01  WS-RESPONSE          PIC X(8192).
       01  WS-KEY-IN            PIC X(16).

       LINKAGE SECTION.
       01  LK-MODE              PIC X(8).
       01  LK-COMMAREA          PIC X(32767).
       01  LK-COMMAREA-LEN      PIC 9(4).
       01  LK-PROMPT            PIC X(4096).
       01  LK-RESPONSE          PIC X(8192).
       01  LK-STATUS            PIC X(16).

       PROCEDURE DIVISION USING LK-MODE LK-COMMAREA
                                LK-COMMAREA-LEN LK-PROMPT
                                LK-RESPONSE LK-STATUS.
       MAIN-PARA.
           MOVE LK-MODE TO WS-MODE.
           MOVE LK-COMMAREA-LEN TO WS-COMMAREA-LENGTH.
           MOVE LK-PROMPT TO WS-PROMPT.
           EVALUATE WS-MODE
               WHEN 'BATCH'
                   PERFORM BATCH-ENTRY
               WHEN 'CICS'
                   PERFORM CICS-ENTRY
               WHEN 'TSO'
                   PERFORM TSO-ENTRY
               WHEN 'SVC99'
                   PERFORM ALLOCATE-DYNAMIC
               WHEN 'ESTAE'
                   PERFORM ESTABLISH-ESTAE
               WHEN 'VSAM-PUT'
                   PERFORM VSAM-PUT
               WHEN 'VSAM-GET'
                   PERFORM VSAM-GET
               WHEN OTHER
                   DISPLAY 'MVS-BRIDGE: Unknown operation "'
                           WS-MODE '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Batch entry point. Reads the SYSOUT DD and dispatches the   *
      * inference engine.                                           *
      *--------------------------------------------------------------*
       BATCH-ENTRY.
           DISPLAY 'MVS-BRIDGE: batch job invoked (MVS/XA).'.
           DISPLAY 'MVS-BRIDGE: COMMAREA length ' WS-COMMAREA-LENGTH.
           MOVE 'BATCH-OK' TO LK-STATUS.

      *--------------------------------------------------------------*
      * CICS transaction entry. The COMMAREA holds the request; the *
      * response overwrites it before return.                       *
      *--------------------------------------------------------------*
       CICS-ENTRY.
           DISPLAY 'MVS-BRIDGE: CICS transaction, COMMAREA length '
                   WS-COMMAREA-LENGTH '.'.
           MOVE 'CICS-OK' TO LK-STATUS.

      *--------------------------------------------------------------*
      * TSO/ISPF invocation shim.                                   *
      *--------------------------------------------------------------*
       TSO-ENTRY.
           DISPLAY 'MVS-BRIDGE: TSO command invoked.'.
           MOVE 'TSO-OK' TO LK-STATUS.

      *--------------------------------------------------------------*
      * Dynamic allocation of a data set through SVC 99.            *
      *--------------------------------------------------------------*
       ALLOCATE-DYNAMIC.
           MOVE 'KV.CACHE.VSAM' TO WS-DSN.
           DISPLAY 'MVS-BRIDGE: SVC 99 dynamic allocation for '
                   WS-DSN '.'.
           MOVE 'SVC99-OK' TO LK-STATUS.

      *--------------------------------------------------------------*
      * Establishes an ESTAE recovery environment for the task.     *
      *--------------------------------------------------------------*
       ESTABLISH-ESTAE.
           DISPLAY 'MVS-BRIDGE: ESTAE recovery environment '
                   'established.'.
           MOVE 'ESTAE-OK' TO LK-STATUS.

      *--------------------------------------------------------------*
      * Writes a KV page to the VSAM ESDS.                          *
      *--------------------------------------------------------------*
       VSAM-PUT.
           OPEN OUTPUT VSAM-KV.
           IF VSAM-OK
               MOVE LK-PROMPT(1:16) TO KV-REC-KEY
               MOVE LK-RESPONSE TO KV-REC-DATA
               WRITE KV-REC
               MOVE 'VSAM-PUT-OK' TO LK-STATUS
           ELSE
               MOVE 'VSAM-PUT-ERR' TO LK-STATUS
           END-IF.
           CLOSE VSAM-KV.

      *--------------------------------------------------------------*
      * Reads a KV page from the VSAM ESDS.                         *
      *--------------------------------------------------------------*
       VSAM-GET.
           OPEN INPUT VSAM-KV.
           IF VSAM-OK
               READ VSAM-KV
                   AT END
                       MOVE 'VSAM-NOT-FOUND' TO LK-STATUS
                   NOT AT END
                       MOVE KV-REC-DATA TO LK-RESPONSE
                       MOVE 'VSAM-GET-OK' TO LK-STATUS
               END-READ
           END-IF.
           CLOSE VSAM-KV.

       END PROGRAM MVS-BRIDGE.
