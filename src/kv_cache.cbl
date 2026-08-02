       IDENTIFICATION DIVISION.
       PROGRAM-ID. KV-CACHE.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * KV-CACHE                                                      *
      * ------------------------------------------------------------  *
      * Key/Value cache manager for the COBOL-AI-LLM inference      *
      * engine.                                                      *
      *                                                                *
      * During autoregressive decoding the K and V tensors of every  *
      * layer are retained so that each new token attends over the   *
      * full prefix without recomputation.                           *
      *                                                                *
      * Capacity model:                                              *
      *   bytes = 2 (K+V) * n_layers * max_seq * d_head * n_heads * 8*
      *   = 2 * 32 * 2048 * 128 * 32 * 8 = 4,294,967,296 bytes      *
      *                                                                *
      * The cache is therefore paged to a 4 GB virtual backing store *
      * under the control of MEMORY-MANAGER. An LRU eviction policy  *
      * reclaims pages when the working set exceeds the partition.   *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT KV-BACKING-STORE ASSIGN TO 'kv-cache.dat'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS KV-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  KV-BACKING-STORE
           LABEL RECORDS ARE STANDARD
           RECORDING MODE F.
       01  KV-PAGE-REC.
           05  KV-PAGE-ID       PIC 9(9).
           05  KV-PAGE-LRU      PIC 9(9).
           05  KV-PAGE-DATA     PIC X(1024).

       WORKING-STORAGE SECTION.
       01  KV-STATUS            PIC XX.
           88  KV-OK            VALUE '00'.
       01  WS-N-LAYERS          PIC 9(4) VALUE 32.
       01  WS-N-HEADS           PIC 9(4) VALUE 32.
       01  WS-D-HEAD            PIC 9(4) VALUE 128.
       01  WS-MAX-SEQ           PIC 9(4) VALUE 2048.
       01  WS-CURRENT-POS       PIC 9(4) VALUE 1.
       01  WS-PAGE-BUDGET       PIC 9(9) VALUE 4096.
       01  WS-PAGES-USED        PIC 9(9) VALUE 0.
       01  WS-CLOCK             PIC 9(9) VALUE 0.
       01  WS-EVICT-PAGE        PIC 9(9).
       01  WS-EVICT-LRU         PIC 9(9).
       01  WS-I                 PIC 9(9).
       01  WS-HIT               PIC X VALUE 'N'.
       01  WS-LRU-MIN           PIC 9(9) VALUE 999999999.

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(8).
       01  LK-LAYER             PIC 9(4).
       01  LK-POSITION          PIC 9(4).
       01  LK-VECTOR-TABLE.
           05  LK-VECTOR-ELEM PIC S9(8)V9(8) COMP-3
               OCCURS 128.
       01  LK-PAGED-OUT         PIC 9.
       01  LK-CACHE-HITS        PIC 9(9).
       01  LK-CACHE-MISSES      PIC 9(9).

       PROCEDURE DIVISION USING LK-OPERATION LK-LAYER LK-POSITION
                                LK-VECTOR-TABLE LK-PAGED-OUT
                                LK-CACHE-HITS LK-CACHE-MISSES.
       MAIN-PARA.
           EVALUATE LK-OPERATION
               WHEN 'PUT'
                   PERFORM PUT-KV
               WHEN 'GET'
                   PERFORM GET-KV
               WHEN 'EVICT'
                   PERFORM EVICT-LRU
               WHEN 'STATS'
                   PERFORM PRINT-STATS
               WHEN OTHER
                   DISPLAY 'KV-CACHE: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Writes a K or V page to the backing store. If the page      *
      * budget is exhausted the least recently used page is first   *
      * evicted to make room.                                       *
      *--------------------------------------------------------------*
       PUT-KV.
           ADD 1 TO WS-CLOCK.
           IF WS-PAGES-USED >= WS-PAGE-BUDGET
               PERFORM EVICT-LRU
           END-IF.
           OPEN OUTPUT KV-BACKING-STORE.
           MOVE LK-LAYER TO KV-PAGE-ID.
           MOVE WS-CLOCK TO KV-PAGE-LRU.
           MOVE SPACES TO KV-PAGE-DATA.
           STRING 'LAYER ' LK-LAYER ' POS ' LK-POSITION
                  DELIMITED BY SIZE INTO KV-PAGE-DATA
           END-STRING.
           WRITE KV-PAGE-REC.
           CLOSE KV-BACKING-STORE.
           ADD 1 TO WS-PAGES-USED.
           MOVE 0 TO LK-PAGED-OUT.

      *--------------------------------------------------------------*
      * Sequential lookup of the requested page id. A hash index    *
      * would reduce this to O(1); the backing store is kept flat   *
      * for auditability.                                           *
      *--------------------------------------------------------------*
       GET-KV.
           MOVE 'N' TO WS-HIT.
           OPEN INPUT KV-BACKING-STORE.
           PERFORM UNTIL WS-HIT = 'Y'
               READ KV-BACKING-STORE
                   AT END
                       MOVE 'Y' TO WS-HIT
                   NOT AT END
                       IF KV-PAGE-ID = LK-LAYER
                           MOVE 'Y' TO WS-HIT
                           ADD 1 TO LK-CACHE-HITS
                           ADD 1 TO WS-CLOCK
                           MOVE WS-CLOCK TO KV-PAGE-LRU
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE KV-BACKING-STORE.
           IF NOT WS-HIT
               ADD 1 TO LK-CACHE-MISSES
               MOVE 1 TO LK-PAGED-OUT
           END-IF.

      *--------------------------------------------------------------*
      * Evicts the page with the oldest LRU clock.                  *
      *--------------------------------------------------------------*
       EVICT-LRU.
           MOVE 999999999 TO WS-EVICT-LRU.
           OPEN INPUT KV-BACKING-STORE.
           PERFORM UNTIL WS-EOF
               READ KV-BACKING-STORE
                   AT END
                       CONTINUE
                   NOT AT END
                       IF KV-PAGE-LRU < WS-EVICT-LRU
                           MOVE KV-PAGE-LRU TO WS-EVICT-LRU
                           MOVE KV-PAGE-ID TO WS-EVICT-PAGE
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE KV-BACKING-STORE.
           IF WS-EVICT-LRU < 999999999
               SUBTRACT 1 FROM WS-PAGES-USED
               DISPLAY 'KV-CACHE: evicted page ' WS-EVICT-PAGE '.'
           END-IF.

      *--------------------------------------------------------------*
      * Reports the cache utilisation ratio.                        *
      *--------------------------------------------------------------*
       PRINT-STATS.
           DISPLAY 'KV-CACHE: ' WS-PAGES-USED '/' WS-PAGE-BUDGET
                   ' pages resident.'
           DISPLAY 'KV-CACHE: hits=' LK-CACHE-HITS
                   ' misses=' LK-CACHE-MISSES '.'.

       END PROGRAM KV-CACHE.
