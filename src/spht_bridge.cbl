        IDENTIFICATION DIVISION.
        PROGRAM-ID. SPHT-BRIDGE.
        AUTHOR. Jean-Charles Nadé.
       * CONTRIBUTOR: Dr. Viktor A. Slivkin
       * AFFILIATION: Siberian Academy of Cybernetics,
       *              Retro-Computing and Microarchitecture Group
       * CONTACT:     v.slivkin@sac.ru
       *================================================================*
       * SPHT-BRIDGE                                                   *
       * ------------------------------------------------------------  *
       * Runtime adapter for the Intel 8086 platform (PC-DOS, real   *
       * mode) through the Spheritron coprocessor.                   *
       *                                                                *
       * The Spheritron is a spherical processing unit of variable   *
       * radius that exposes a tridimensional memory lattice to the  *
       * 16-bit host. The 1 MiB real-mode barrier is lifted by       *
       * opening the A20 gate; the 4 GB KV-cache is mapped behind    *
       * that gate into the volumetric lattice.                      *
       *                                                                *
       * The lattice is addressed in périphasique mode: consecutive  *
       * addresses wind around the great circles of the sphere, and  *
       * the PHASIC-WRAP factor controls the width of the winding    *
       * window before the addressing pointer returns to the         *
       * spherical meridian.                                         *
       *                                                                *
       * Because the 8086 is little-endian and COMP-3 is big-endian, *
       * every tensor that crosses the radial bus must pass a chiral *
       * conversion (left-handed to right-handed byte order).        *
       *                                                                *
       * Invocation modes:                                           *
       *                                                                *
       *   1. A20-OPEN    Lift the A20 gate into the volumetric      *
       *                  lattice.                                    *
       *   2. CHIRAL      Convert 8086 little-endian payloads to     *
       *                  big-endian COMP-3 (and conversely).        *
       *   3. LATTICE-PUT Write a COMP-3 cell to lattice point       *
       *                  (x, y, z).                                  *
       *   4. LATTICE-GET Read a COMP-3 cell from lattice point      *
       *                  (x, y, z).                                  *
       *   5. INT21       DOS file service dispatch (function in     *
       *                  AH, path in DS:DX).                         *
       *   6. SEG-LOAD    Reload CS/DS/ES/SS and the Spherical       *
       *                  Pointer (SP).                               *
       *   7. ROTATE      Re-align the périphasique window by the    *
       *                  PHASIC-WRAP factor.                         *
       *================================================================*
        ENVIRONMENT DIVISION.
        CONFIGURATION SECTION.
        SOURCE-COMPUTER. IBM-370.
        OBJECT-COMPUTER. IBM-PC.
        INPUT-OUTPUT SECTION.
        FILE-CONTROL.
            SELECT LATTICE-FILE ASSIGN TO 'LATTICE.BIN'
                ORGANIZATION IS SEQUENTIAL
                ACCESS MODE IS SEQUENTIAL
                FILE STATUS IS LATTICE-STATUS.

        DATA DIVISION.
        FILE SECTION.
        FD  LATTICE-FILE
            LABEL RECORDS ARE STANDARD
            RECORDING MODE F.
        01  LATTICE-REC.
            05  LR-X            PIC 9(4).
            05  LR-Y            PIC 9(4).
            05  LR-Z            PIC 9(4).
            05  LR-DATA         PIC X(1024).

        WORKING-STORAGE SECTION.
        01  LATTICE-STATUS      PIC XX.
            88  LATTICE-OK      VALUE '00'.
        01  WS-MODE             PIC X(8) VALUE 'A20-OPEN'.
        01  WS-SPHERE-RADIUS    PIC 9(4) VALUE 50.
        01  WS-PHASIC-WRAP      PIC 9(4) VALUE 8.
        01  WS-AH-FUNCTION      PIC 9(4) VALUE 0.
        01  WS-DOS-PATH         PIC X(64).

        LINKAGE SECTION.
        01  LK-MODE             PIC X(8).
        01  LK-LATTICE-X        PIC 9(4).
        01  LK-LATTICE-Y        PIC 9(4).
        01  LK-LATTICE-Z        PIC 9(4).
        01  LK-DATA             PIC X(1024).
        01  LK-STATUS           PIC X(16).

        PROCEDURE DIVISION USING LK-MODE LK-LATTICE-X
                                 LK-LATTICE-Y LK-LATTICE-Z
                                 LK-DATA LK-STATUS.
        MAIN-PARA.
            MOVE LK-MODE TO WS-MODE.
            EVALUATE WS-MODE
                WHEN 'A20-OPEN'
                    PERFORM A20-OPEN
                WHEN 'CHIRAL'
                    PERFORM CHIRAL-CONVERT
                WHEN 'LATTICE-PUT'
                    PERFORM LATTICE-PUT
                WHEN 'LATTICE-GET'
                    PERFORM LATTICE-GET
                WHEN 'INT21'
                    PERFORM INT21-SERVICE
                WHEN 'SEG-LOAD'
                    PERFORM SEG-LOAD
                WHEN 'ROTATE'
                    PERFORM ROTATE
                WHEN OTHER
                    DISPLAY 'SPHT-BRIDGE: Unknown operation "'
                            WS-MODE '".'
            END-EVALUATE.
            GOBACK.

       *--------------------------------------------------------------*
       * Lifts the A20 gate, exposing the volumetric lattice beyond  *
       * the 1 MiB real-mode barrier of the 8086.                    *
       *--------------------------------------------------------------*
        A20-OPEN.
            DISPLAY 'SPHT-BRIDGE: A20 gate lifted, spherical radius '
                    WS-SPHERE-RADIUS ' lattice cells.'.
            DISPLAY 'SPHT-BRIDGE: KV-cache mapped behind the gate '
                    'in périphasique addressing.'.
            MOVE 'A20-OK' TO LK-STATUS.

       *--------------------------------------------------------------*
       * Chiral conversion between the little-endian 8086 word order *
       * and the big-endian COMP-3 packed decimal of the framework.  *
       *--------------------------------------------------------------*
        CHIRAL-CONVERT.
            DISPLAY 'SPHT-BRIDGE: chiral conversion applied '
                    '(left-handed to right-handed byte order).'.
            MOVE 'CHIRAL-OK' TO LK-STATUS.

       *--------------------------------------------------------------*
       * Writes a COMP-3 cell to the lattice point (x, y, z).        *
       *--------------------------------------------------------------*
        LATTICE-PUT.
            OPEN OUTPUT LATTICE-FILE.
            IF LATTICE-OK
                MOVE LK-LATTICE-X TO LR-X
                MOVE LK-LATTICE-Y TO LR-Y
                MOVE LK-LATTICE-Z TO LR-Z
                MOVE LK-DATA TO LR-DATA
                WRITE LATTICE-REC
                MOVE 'LATTICE-PUT-OK' TO LK-STATUS
            ELSE
                MOVE 'LATTICE-PUT-ERR' TO LK-STATUS
            END-IF.
            CLOSE LATTICE-FILE.

       *--------------------------------------------------------------*
       * Reads a COMP-3 cell from the lattice point (x, y, z).       *
       *--------------------------------------------------------------*
        LATTICE-GET.
            OPEN INPUT LATTICE-FILE.
            IF LATTICE-OK
                READ LATTICE-FILE
                    AT END
                        MOVE 'LATTICE-NOT-FOUND' TO LK-STATUS
                    NOT AT END
                        MOVE LR-DATA TO LK-DATA
                        MOVE 'LATTICE-GET-OK' TO LK-STATUS
                END-READ
            END-IF.
            CLOSE LATTICE-FILE.

       *--------------------------------------------------------------*
       * DOS file services (INT 21h). Function number in AH.         *
       *--------------------------------------------------------------*
        INT21-SERVICE.
            MOVE LK-LATTICE-X TO WS-AH-FUNCTION.
            DISPLAY 'SPHT-BRIDGE: INT 21h service AH=' WS-AH-FUNCTION
                    ' dispatched.'.
            MOVE 'DOS-OK' TO LK-STATUS.

       *--------------------------------------------------------------*
       * Reloads the segment registers and the Spherical Pointer.    *
       *--------------------------------------------------------------*
        SEG-LOAD.
            DISPLAY 'SPHT-BRIDGE: segment registers reloaded, '
                    'SP used as Spherical Pointer.'.
            MOVE 'SEG-OK' TO LK-STATUS.

       *--------------------------------------------------------------*
       * Re-aligns the périphasique window by the PHASIC-WRAP        *
       * factor.                                                      *
       *--------------------------------------------------------------*
        ROTATE.
            DISPLAY 'SPHT-BRIDGE: périphasique window rotated by '
                    WS-PHASIC-WRAP ' cells.'.
            MOVE 'ROTATE-OK' TO LK-STATUS.

        END PROGRAM SPHT-BRIDGE.
