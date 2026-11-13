      ******************************************************************
      * Program     : CBDMO01C.CBL                                      *
      * Application : CardDemo                                          *
      * Type        : BATCH COBOL Program (DB2 attach)                  *
      * Function    : DEMO CDC setup/load. Reset-then-load: WRITE 1000  *
      *               records to VSAM KSDS AWS.M2.CARDDEMO.DEMO.CDCACCT *
      *               from seed PS, then DELETE all rows from           *
      *               MODATA1.MOCDC and INSERT one row per seed record. *
      *               Deterministic and idempotent given fixed seed PS  *
      *               and a freshly IDCAMS-defined empty KSDS.          *
      ******************************************************************
      * Copyright (c) 2026 Mechanical Orchard, Inc.                    *
      * All Rights Reserved.                                            *
      *                                                                 *
      * Licensed under the Apache License, Version 2.0 (the "License"). *
      * You may not use this file except in compliance with the License.*
      * You may obtain a copy of the License at                         *
      *                                                                 *
      *    http://www.apache.org/licenses/LICENSE-2.0                   *
      *                                                                 *
      * Unless required by applicable law or agreed to in writing,      *
      * software distributed under the License is distributed on an     *
      * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    *
      * either express or implied. See the License for the specific     *
      * language governing permissions and limitations under the License*
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    CBDMO01C.
       AUTHOR.        AWS.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SEEDACCT-FILE ASSIGN TO SEEDACCT
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS SEEDACCT-STATUS.

           SELECT CDCACCT-FILE  ASSIGN TO CDCACCT
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS FD-CDCACCT-ID
                  FILE STATUS  IS CDCACCT-STATUS.

      *
       DATA DIVISION.
       FILE SECTION.
       FD  SEEDACCT-FILE.
       01  FD-SEEDACCT-REC              PIC X(100).

       FD  CDCACCT-FILE.
       01  FD-CDCACCT-REC.
           05  FD-CDCACCT-ID            PIC 9(11).
           05  FD-CDCACCT-DATA          PIC X(89).

       WORKING-STORAGE SECTION.

           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.

           EXEC SQL INCLUDE DCLMOCDC END-EXEC.

       COPY CVDMO02Y.
       COPY CVDMO01Y.

       01  SEEDACCT-STATUS.
           05  SEEDACCT-STAT1           PIC X.
           05  SEEDACCT-STAT2           PIC X.

       01  CDCACCT-STATUS.
           05  CDCACCT-STAT1            PIC X.
           05  CDCACCT-STAT2            PIC X.

       01  IO-STATUS.
           05  IO-STAT1                 PIC X.
           05  IO-STAT2                 PIC X.
       01  TWO-BYTES-BINARY             PIC 9(4) BINARY.
       01  TWO-BYTES-ALPHA REDEFINES TWO-BYTES-BINARY.
           05  TWO-BYTES-LEFT           PIC X.
           05  TWO-BYTES-RIGHT          PIC X.
       01  IO-STATUS-04.
           05  IO-STATUS-0401           PIC 9   VALUE 0.
           05  IO-STATUS-0403           PIC 999 VALUE 0.

       01  APPL-RESULT                  PIC S9(9) COMP.
           88  APPL-AOK                 VALUE 0.
           88  APPL-EOF                 VALUE 16.

       01  END-OF-FILE                  PIC X(01) VALUE 'N'.
       01  ABCODE                       PIC S9(9) BINARY.
       01  TIMING                       PIC S9(9) BINARY.

       01  WS-COUNTERS.
           05  WS-READ-COUNT            PIC 9(09) VALUE 0.
           05  WS-VSAM-WRITE-COUNT      PIC 9(09) VALUE 0.
           05  WS-MOCDC-INSERT-COUNT    PIC 9(09) VALUE 0.

       01  WS-MISC-VARS.
           05  WS-VAR-SQLCODE           PIC ----9.

       01  WS-RETURN-MSG                PIC X(80) VALUE SPACES.

      *****************************************************************
       PROCEDURE DIVISION.
           DISPLAY 'START OF EXECUTION OF PROGRAM CBDMO01C'.
           PERFORM 0100-OPEN-FILES
           PERFORM 0200-RESET-MOCDC
           PERFORM 1000-LOAD-LOOP
              UNTIL END-OF-FILE = 'Y'
           PERFORM 8000-COMMIT-MOCDC
           PERFORM 9000-CLOSE-FILES
           PERFORM 9500-DISPLAY-COUNTS
           DISPLAY 'END OF EXECUTION OF PROGRAM CBDMO01C'
           GOBACK.

      *---------------------------------------------------------------*
       0100-OPEN-FILES.
           MOVE 8 TO APPL-RESULT
           OPEN INPUT SEEDACCT-FILE
           IF SEEDACCT-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR OPENING SEEDACCT FILE'
               MOVE SEEDACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE 8 TO APPL-RESULT
           OPEN OUTPUT CDCACCT-FILE
           IF CDCACCT-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR OPENING CDCACCT VSAM FILE'
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       0200-RESET-MOCDC.
      *    Whole-table reset. DML only (DELETE). No DDL is issued.
      *    A searched DELETE against an already-empty MOCDC returns
      *    SQLCODE 0; SQLERRD(3) carries the deleted-row count.
      *    Committing here would open a race with the subsequent
      *    INSERT loop; COMMIT is deferred to 8000-COMMIT-MOCDC so
      *    the whole reset+load is one atomic CDC event.
           EXEC SQL
               DELETE FROM MODATA1.MOCDC
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                   DISPLAY 'MOCDC RESET (DELETE) OK'
               WHEN SQLCODE < 0
                   STRING
                     'Error resetting MODATA1.MOCDC. SQLCODE:'
                     WS-VAR-SQLCODE
                     DELIMITED BY SIZE
                     INTO WS-RETURN-MSG
                   END-STRING
                   PERFORM 9999-ABEND-PROGRAM
           END-EVALUATE
           EXIT.

      *---------------------------------------------------------------*
       1000-LOAD-LOOP.
           READ SEEDACCT-FILE INTO DEMO-SEEDACCT-RECORD
               AT END MOVE 'Y' TO END-OF-FILE
           END-READ
           IF END-OF-FILE = 'N'
               IF SEEDACCT-STATUS = '00'
                   ADD 1 TO WS-READ-COUNT
                   PERFORM 1100-WRITE-VSAM
                   PERFORM 1200-INSERT-MOCDC
               ELSE
                   DISPLAY 'ERROR READING SEEDACCT FILE'
                   MOVE SEEDACCT-STATUS TO IO-STATUS
                   PERFORM 9910-DISPLAY-IO-STATUS
                   PERFORM 9999-ABEND-PROGRAM
               END-IF
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1100-WRITE-VSAM.
      *    Load-mode WRITE against a freshly-defined KSDS. Seed PS is
      *    in ascending-key order (file order equals key order), so
      *    sequential WRITEs are legal and deterministic.
           MOVE SEED-ACCT-ID       TO DEMO-ACCT-ID
           MOVE SEED-ACCT-DESCR    TO DEMO-ACCT-DESCR
           MOVE SEED-ACCT-AMOUNT   TO DEMO-ACCT-AMOUNT
           MOVE SEED-ACCT-STATUS   TO DEMO-ACCT-STATUS
           MOVE SPACES             TO FD-CDCACCT-DATA
           MOVE DEMO-ACCT-RECORD   TO FD-CDCACCT-REC

           MOVE 8 TO APPL-RESULT
           WRITE FD-CDCACCT-REC
           IF CDCACCT-STATUS = '00'
               MOVE 0 TO APPL-RESULT
               ADD 1 TO WS-VSAM-WRITE-COUNT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING CDCACCT VSAM FILE, KEY='
                       SEED-ACCT-ID
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1200-INSERT-MOCDC.
      *    Fixed VARCHAR(50) binding contract (spec 5.7 / rule (l)):
      *    every MOCDC DESCR write sets DCL-MOCDC-DESCR-LEN = +50 with
      *    the copybook PIC X(50) content; the stored VARCHAR is
      *    byte-identical to the VSAM DEMO-ACCT-DESCR PIC X(50) field.
           MOVE SEED-ACCT-ID       TO DCL-MOCDC-ID
           MOVE SEED-ACCT-DESCR    TO DCL-MOCDC-DESCR-TEXT
           MOVE +50                TO DCL-MOCDC-DESCR-LEN
           MOVE SEED-ACCT-AMOUNT   TO DCL-MOCDC-AMOUNT

           EXEC SQL
               INSERT INTO MODATA1.MOCDC
                   (ID, DESCR, AMOUNT)
               VALUES
                   (:DCL-MOCDC-ID,
                    :DCL-MOCDC-DESCR,
                    :DCL-MOCDC-AMOUNT)
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                   ADD 1 TO WS-MOCDC-INSERT-COUNT
               WHEN SQLCODE < 0
                   STRING
                     'Error inserting MODATA1.MOCDC. SQLCODE:'
                     WS-VAR-SQLCODE
                     DELIMITED BY SIZE
                     INTO WS-RETURN-MSG
                   END-STRING
                   PERFORM 9999-ABEND-PROGRAM
           END-EVALUATE
           EXIT.

      *---------------------------------------------------------------*
       8000-COMMIT-MOCDC.
           EXEC SQL COMMIT END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           IF SQLCODE < 0
               STRING
                 'Error committing MODATA1.MOCDC. SQLCODE:'
                 WS-VAR-SQLCODE
                 DELIMITED BY SIZE
                 INTO WS-RETURN-MSG
               END-STRING
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       9000-CLOSE-FILES.
           MOVE 8 TO APPL-RESULT
           CLOSE SEEDACCT-FILE
           IF SEEDACCT-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR CLOSING SEEDACCT FILE'
               MOVE SEEDACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE 8 TO APPL-RESULT
           CLOSE CDCACCT-FILE
           IF CDCACCT-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR CLOSING CDCACCT VSAM FILE'
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       9500-DISPLAY-COUNTS.
           DISPLAY 'SEED READ         : ' WS-READ-COUNT
           DISPLAY 'VSAM WRITE COUNT  : ' WS-VSAM-WRITE-COUNT
           DISPLAY 'MOCDC INSERT COUNT: ' WS-MOCDC-INSERT-COUNT
           EXIT.

      *---------------------------------------------------------------*
       9910-DISPLAY-IO-STATUS.
           IF IO-STATUS NOT NUMERIC
           OR IO-STAT1 = '9'
               MOVE IO-STAT1 TO IO-STATUS-04(1:1)
               MOVE 0        TO TWO-BYTES-BINARY
               MOVE IO-STAT2 TO TWO-BYTES-RIGHT
               MOVE TWO-BYTES-BINARY TO IO-STATUS-0403
               DISPLAY 'FILE STATUS IS: NNNN' IO-STATUS-04
           ELSE
               MOVE '0000' TO IO-STATUS-04
               MOVE IO-STATUS TO IO-STATUS-04(3:2)
               DISPLAY 'FILE STATUS IS: NNNN' IO-STATUS-04
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       9999-ABEND-PROGRAM.
           DISPLAY 'ABENDING PROGRAM'
           IF WS-RETURN-MSG NOT = SPACES
               DISPLAY WS-RETURN-MSG
           END-IF
           MOVE 0   TO TIMING
           MOVE 999 TO ABCODE
           CALL 'CEE3ABD' USING ABCODE, TIMING.
