        IDENTIFICATION DIVISION.
        PROGRAM-ID. TEST-SPHT-BRIDGE.
        AUTHOR. Jean-Charles Nadé.
       * CONTRIBUTOR: Dr. Viktor A. Slivkin
       * AFFILIATION: Siberian Academy of Cybernetics,
       *              Retro-Computing and Microarchitecture Group
       * CONTACT:     v.slivkin@sac.ru
       *================================================================*
       * Unit test for the SPHT-BRIDGE module.                         *
       * Verifies that the A20-OPEN operation returns A20-OK.          *
       *================================================================*
        ENVIRONMENT DIVISION.
        CONFIGURATION SECTION.
        SOURCE-COMPUTER. IBM-370.
        OBJECT-COMPUTER. IBM-PC.

        DATA DIVISION.
        WORKING-STORAGE SECTION.
        01  WS-TEST-RESULT      PIC X(50) VALUE 'Test Not Run'.
        01  WS-MODE             PIC X(8)  VALUE 'A20-OPEN'.
        01  WS-LATTICE-X        PIC 9(4)  VALUE 8.
        01  WS-LATTICE-Y        PIC 9(4)  VALUE 16.
        01  WS-LATTICE-Z        PIC 9(4)  VALUE 32.
        01  WS-DATA             PIC X(1024).
        01  WS-STATUS           PIC X(16).
        01  WS-EXPECTED-STATUS  PIC X(16) VALUE 'A20-OK'.

        PROCEDURE DIVISION.
        MAIN-PARA.
            DISPLAY 'Running Test for SPHT-BRIDGE module...'.
            PERFORM RUN-SPHT-TEST.
            PERFORM VERIFY-OUTPUT.
            DISPLAY 'Test Result: ' WS-TEST-RESULT.
            STOP RUN.

        RUN-SPHT-TEST.
            CALL 'SPHT-BRIDGE' USING WS-MODE, WS-LATTICE-X,
                 WS-LATTICE-Y, WS-LATTICE-Z, WS-DATA, WS-STATUS.

        VERIFY-OUTPUT.
            IF WS-STATUS = WS-EXPECTED-STATUS THEN
                MOVE 'Test Passed' TO WS-TEST-RESULT
            ELSE
                MOVE 'Test Failed' TO WS-TEST-RESULT
            END-IF.

        END PROGRAM TEST-SPHT-BRIDGE.
