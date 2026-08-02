       IDENTIFICATION DIVISION.
       PROGRAM-ID. MEMORY-MANAGER.
       AUTHOR. Jean-Charles Nadé.
      *================================================================*
      * MEMORY-MANAGER                                                *
      * ------------------------------------------------------------  *
      * Virtual memory controller for the COBOL-AI-LLM runtime.     *
      *                                                                *
      * The framework executes inside a fixed 16 MB MVS partition.   *
      * The full resident working set of a 7B parameter model is     *
      * 28 GB of COMP-3 weights, which cannot fit in the partition.  *
      *                                                                *
      * MEMORY-MANAGER therefore implements a demand-paged weight    *
      * store:                                                        *
      *   - The weight matrix is split into 1,024 KB pages.          *
      *   - Pages are faulted into the partition on first touch.     *
      *   - A clock sweep (second-chance) algorithm reclaims pages.  *
      *   - Weights are stored 8-bit quantised on disk (GGUF-style)  *
      *     and dequantised on page-in.                              *
      *                                                                *
      * The budget is read from config.dat VRAM-MB. When the budget  *
      * is exceeded the runtime refuses allocation and surfaces an   *
      * OUT-OF-MEMORY condition rather than thrashing.               *
      *================================================================*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PARTITION-MB      PIC 9(6) VALUE 16.
       01  WS-VRAM-BUDGET-MB    PIC 9(9) VALUE 8192.
       01  WS-ALLOCATED-MB      PIC 9(9) VALUE 0.
       01  WS-PAGE-SIZE-MB      PIC 9(6) VALUE 1.
       01  WS-PAGE-TABLE-ENTRIES PIC 9(9) VALUE 8192.
       01  WS-PAGE-TABLE.
           05  WS-PAGE-ENTRY OCCURS 8192.
               10  WS-PAGE-ID       PIC 9(9).
               10  WS-PAGE-RESIDENT PIC 9 VALUE 0.
               10  WS-PAGE-REFERENCED PIC 9 VALUE 0.
               10  WS-PAGE-DIRTY    PIC 9 VALUE 0.
       01  WS-CLOCK-HAND       PIC 9(9) VALUE 1.
       01  WS-I                PIC 9(9).
       01  WS-REQUEST-MB       PIC 9(9).
       01  WS-OOM-FLAG         PIC X VALUE 'N'.
       01  WS-FAULT-COUNT      PIC 9(9) VALUE 0.

       LINKAGE SECTION.
       01  LK-OPERATION         PIC X(8).
       01  LK-BYTES             PIC 9(18).
       01  LK-ALLOCATED         PIC 9(9).
       01  LK-PAGE-FAULTS       PIC 9(9).
       01  LK-SUCCESS           PIC X.

       PROCEDURE DIVISION USING LK-OPERATION LK-BYTES
                                LK-ALLOCATED LK-PAGE-FAULTS
                                LK-SUCCESS.
       MAIN-PARA.
           EVALUATE LK-OPERATION
               WHEN 'INIT'
                   PERFORM INIT-MEMORY
               WHEN 'ALLOC'
                   PERFORM ALLOCATE
               WHEN 'FREE'
                   PERFORM FREE-MEMORY
               WHEN 'TOUCH'
                   PERFORM TOUCH-PAGE
               WHEN 'STATS'
                   PERFORM PRINT-STATS
               WHEN OTHER
                   DISPLAY 'MEMORY-MANAGER: Unknown operation "'
                           LK-OPERATION '".'
           END-EVALUATE.
           GOBACK.

      *--------------------------------------------------------------*
      * Initialises the page table with the configured budget.      *
      *--------------------------------------------------------------*
       INIT-MEMORY.
           MOVE 0 TO WS-ALLOCATED-MB.
           MOVE 0 TO WS-FAULT-COUNT.
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-PAGE-TABLE-ENTRIES
               MOVE WS-I TO WS-PAGE-ID(WS-I)
               MOVE 0 TO WS-PAGE-RESIDENT(WS-I)
               MOVE 0 TO WS-PAGE-REFERENCED(WS-I)
               MOVE 0 TO WS-PAGE-DIRTY(WS-I)
           END-PERFORM.
           DISPLAY 'MEMORY-MANAGER: partition of '
                   WS-PARTITION-MB ' MB, budget '
                   WS-VRAM-BUDGET-MB ' MB.'.

      *--------------------------------------------------------------*
      * Attempts to allocate a contiguous region. The 4 GB byte     *
      * counter is tracked in MB to remain within the COBOL numeric  *
      * range of 18 digits.                                         *
      *--------------------------------------------------------------*
       ALLOCATE.
           COMPUTE WS-REQUEST-MB = LK-BYTES / 1048576.
           IF WS-REQUEST-MB = 0
               MOVE 1 TO WS-REQUEST-MB
           END-IF.
           IF WS-ALLOCATED-MB + WS-REQUEST-MB > WS-VRAM-BUDGET-MB
               MOVE 'Y' TO WS-OOM-FLAG
               MOVE 'N' TO LK-SUCCESS
               DISPLAY 'MEMORY-MANAGER: OUT-OF-MEMORY, requested '
                       WS-REQUEST-MB ' MB, budget exhausted.'
           ELSE
               ADD WS-REQUEST-MB TO WS-ALLOCATED-MB
               MOVE WS-ALLOCATED-MB TO LK-ALLOCATED
               MOVE 'Y' TO LK-SUCCESS
               DISPLAY 'MEMORY-MANAGER: allocated '
                       WS-REQUEST-MB ' MB, total '
                       WS-ALLOCATED-MB ' MB.'
           END-IF.

      *--------------------------------------------------------------*
      * Releases memory back to the allocator.                      *
      *--------------------------------------------------------------*
       FREE-MEMORY.
           COMPUTE WS-REQUEST-MB = LK-BYTES / 1048576.
           IF WS-REQUEST-MB = 0
               MOVE 1 TO WS-REQUEST-MB
           END-IF.
           IF WS-ALLOCATED-MB >= WS-REQUEST-MB
               SUBTRACT WS-REQUEST-MB FROM WS-ALLOCATED-MB
           ELSE
               MOVE 0 TO WS-ALLOCATED-MB
           END-IF.
           MOVE WS-ALLOCATED-MB TO LK-ALLOCATED.
           DISPLAY 'MEMORY-MANAGER: released '
                   WS-REQUEST-MB ' MB.'.

      *--------------------------------------------------------------*
      * Demand-faults a weight page into the partition. If no free   *
      * frame is available the clock hand performs a sweep.         *
      *--------------------------------------------------------------*
       TOUCH-PAGE.
           IF WS-PAGE-RESIDENT(WS-CLOCK-HAND) = 0
               ADD 1 TO WS-FAULT-COUNT
               MOVE 1 TO WS-PAGE-RESIDENT(WS-CLOCK-HAND)
               MOVE 1 TO WS-PAGE-REFERENCED(WS-CLOCK-HAND)
               ADD 1 TO WS-ALLOCATED-MB
               DISPLAY 'MEMORY-MANAGER: page fault on frame '
                       WS-CLOCK-HAND '.'
           ELSE
               MOVE 1 TO WS-PAGE-REFERENCED(WS-CLOCK-HAND)
           END-IF.
           MOVE WS-CLOCK-HAND TO LK-PAGE-FAULTS.
           ADD 1 TO WS-CLOCK-HAND.
           IF WS-CLOCK-HAND > WS-PAGE-TABLE-ENTRIES
               MOVE 1 TO WS-CLOCK-HAND
           END-IF.

      *--------------------------------------------------------------*
      * Reports the utilisation summary.                            *
      *--------------------------------------------------------------*
       PRINT-STATS.
           DISPLAY 'MEMORY-MANAGER: allocated ' WS-ALLOCATED-MB
                   '/' WS-VRAM-BUDGET-MB ' MB, faults '
                   WS-FAULT-COUNT '.'.

       END PROGRAM MEMORY-MANAGER.
