      ******************************************************************
      * Program     : CBDMO02C.CBL                                      *
      * Application : CardDemo                                          *
      * Type        : BATCH COBOL Program (DB2 attach)                  *
      * Function    : DEMO CDC daily-post. Reads the fixed daily-input  *
      *               PS AWS.M2.CARDDEMO.DEMO.DALYIN.PS in file order;  *
      *               for each record applies POST/CHARGE/OPEN/CLOSE to *
      *               the demo VSAM KSDS (random READ/REWRITE/WRITE by  *
      *               key) and mirrors the change to MODATA1.MOCDC via  *
      *               EXEC SQL UPDATE/INSERT (DML only, no DELETE, no   *
      *               DDL). Then writes three sequential outputs:       *
      *               POSTED (one record per input, OK/RJ), TRIALBAL    *
      *               (header + 200 detail keys 1001..1200 + total)     *
      *               written from a sequential VSAM scan, and CONTROLS *
      *               (six fixed-order counters). Deterministic: no     *
      *               clock, no randomness; every output is a pure      *
      *               function of the fixed input plus the starting     *
      *               state produced by CBDMO01C.                       *
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
       PROGRAM-ID.    CBDMO02C.
       AUTHOR.        AWS.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DALYIN-FILE   ASSIGN TO DALYIN
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS DALYIN-STATUS.

           SELECT CDCACCT-FILE  ASSIGN TO CDCACCT
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS DYNAMIC
                  RECORD KEY   IS FD-CDCACCT-ID
                  FILE STATUS  IS CDCACCT-STATUS.

           SELECT POSTED-FILE   ASSIGN TO POSTED
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS POSTED-STATUS.

           SELECT TRIALBAL-FILE ASSIGN TO TRIALBAL
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS TRIALBAL-STATUS.

           SELECT CONTROLS-FILE ASSIGN TO CONTROLS
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS CONTROLS-STATUS.

      *
       DATA DIVISION.
       FILE SECTION.
       FD  DALYIN-FILE.
       01  FD-DALYIN-REC                PIC X(80).

       FD  CDCACCT-FILE.
       01  FD-CDCACCT-REC.
           05  FD-CDCACCT-ID            PIC 9(11).
           05  FD-CDCACCT-DATA          PIC X(89).

       FD  POSTED-FILE.
       01  FD-POSTED-REC                PIC X(80).

       FD  TRIALBAL-FILE.
       01  FD-TRIALBAL-REC              PIC X(133).

       FD  CONTROLS-FILE.
       01  FD-CONTROLS-REC              PIC X(80).

       WORKING-STORAGE SECTION.

           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.

           EXEC SQL INCLUDE DCLMOCDC END-EXEC.

       COPY CVDMO03Y.
       COPY CVDMO01Y.
       COPY CVDMO04Y.
       COPY CVDMO05Y.
       COPY CVDMO06Y.

       01  DALYIN-STATUS.
           05  DALYIN-STAT1             PIC X.
           05  DALYIN-STAT2             PIC X.

       01  CDCACCT-STATUS.
           05  CDCACCT-STAT1            PIC X.
           05  CDCACCT-STAT2            PIC X.

       01  POSTED-STATUS.
           05  POSTED-STAT1             PIC X.
           05  POSTED-STAT2             PIC X.

       01  TRIALBAL-STATUS.
           05  TRIALBAL-STAT1           PIC X.
           05  TRIALBAL-STAT2           PIC X.

       01  CONTROLS-STATUS.
           05  CONTROLS-STAT1           PIC X.
           05  CONTROLS-STAT2           PIC X.

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
       01  END-OF-SCAN                  PIC X(01) VALUE 'N'.
       01  WS-FOUND-FLAG                PIC X(01) VALUE 'N'.
       01  ABCODE                       PIC S9(9) BINARY.
       01  TIMING                       PIC S9(9) BINARY.

       01  WS-COUNTERS.
           05  WS-READ-COUNT            PIC 9(09) VALUE 0.
           05  WS-POSTED-OK-COUNT       PIC 9(09) VALUE 0.
           05  WS-REJECT-COUNT          PIC 9(09) VALUE 0.
           05  WS-P-COUNT               PIC 9(09) VALUE 0.
           05  WS-C-COUNT               PIC 9(09) VALUE 0.
           05  WS-N-COUNT               PIC 9(09) VALUE 0.
           05  WS-X-COUNT               PIC 9(09) VALUE 0.
           05  WS-UNCHANGED-COUNT       PIC 9(09) VALUE 0.
           05  WS-TB-DETAIL-COUNT       PIC 9(09) VALUE 0.

       01  WS-TB-TOTAL                  PIC S9(11)V99 VALUE 0
                                          USAGE COMP-3.

       01  WS-CLOSE-VARS.
           05  WS-DESCR-PREFIX          PIC X(07) VALUE 'CLOSED '.
           05  WS-ID-DIGITS             PIC 9(11) VALUE 0.

       01  WS-MISC-VARS.
           05  WS-VAR-SQLCODE           PIC ----9.

       01  WS-RETURN-MSG                PIC X(80) VALUE SPACES.

       01  WS-TB-HEADER-DESCR           PIC X(50) VALUE
              'TRIAL BALANCE - DEMO CDC ACCOUNTS                 '.
       01  WS-TB-TOTAL-DESCR            PIC X(50) VALUE
              'TOTAL                                             '.

       01  WS-CTL-LABELS.
           05  WS-LBL-INPUT-READ        PIC X(30) VALUE
              'INPUT-READ                    '.
           05  WS-LBL-POSTED-OK         PIC X(30) VALUE
              'POSTED-OK                     '.
           05  WS-LBL-POSTED-REJECT     PIC X(30) VALUE
              'POSTED-REJECT                 '.
           05  WS-LBL-OPENED            PIC X(30) VALUE
              'OPENED                        '.
           05  WS-LBL-CLOSED            PIC X(30) VALUE
              'CLOSED                        '.
           05  WS-LBL-UNCHANGED         PIC X(30) VALUE
              'UNCHANGED                     '.

      *****************************************************************
       PROCEDURE DIVISION.
           DISPLAY 'START OF EXECUTION OF PROGRAM CBDMO02C'.
           PERFORM 0100-OPEN-FILES
           PERFORM 1000-PROCESS-DAILY
              UNTIL END-OF-FILE = 'Y'
           PERFORM 2500-COMMIT-MOCDC
           PERFORM 2700-COUNT-UNCHANGED
           PERFORM 3000-WRITE-TRIALBAL
           PERFORM 3500-WRITE-CONTROLS
           PERFORM 9000-CLOSE-FILES
           PERFORM 9500-DISPLAY-COUNTS
           DISPLAY 'END OF EXECUTION OF PROGRAM CBDMO02C'
           GOBACK.

      *---------------------------------------------------------------*
       0100-OPEN-FILES.
           MOVE 8 TO APPL-RESULT
           OPEN INPUT DALYIN-FILE
           IF DALYIN-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR OPENING DALYIN FILE'
               MOVE DALYIN-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE 8 TO APPL-RESULT
           OPEN I-O CDCACCT-FILE
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

           MOVE 8 TO APPL-RESULT
           OPEN OUTPUT POSTED-FILE
           IF POSTED-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR OPENING POSTED FILE'
               MOVE POSTED-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE 8 TO APPL-RESULT
           OPEN OUTPUT TRIALBAL-FILE
           IF TRIALBAL-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR OPENING TRIALBAL FILE'
               MOVE TRIALBAL-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE 8 TO APPL-RESULT
           OPEN OUTPUT CONTROLS-FILE
           IF CONTROLS-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR OPENING CONTROLS FILE'
               MOVE CONTROLS-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1000-PROCESS-DAILY.
           READ DALYIN-FILE INTO DEMO-DALYIN-RECORD
               AT END MOVE 'Y' TO END-OF-FILE
           END-READ
           IF END-OF-FILE = 'N'
               IF DALYIN-STATUS = '00'
                   ADD 1 TO WS-READ-COUNT
                   EVALUATE TRUE
                       WHEN DIN-POST
                            PERFORM 1100-APPLY-POST
                       WHEN DIN-CHARGE
                            PERFORM 1200-APPLY-CHARGE
                       WHEN DIN-OPEN
                            PERFORM 1300-APPLY-OPEN
                       WHEN DIN-CLOSE
                            PERFORM 1400-APPLY-CLOSE
                       WHEN OTHER
                            PERFORM 1900-WRITE-POSTED-REJECT
                   END-EVALUATE
               ELSE
                   DISPLAY 'ERROR READING DALYIN FILE'
                   MOVE DALYIN-STATUS TO IO-STATUS
                   PERFORM 9910-DISPLAY-IO-STATUS
                   PERFORM 9999-ABEND-PROGRAM
               END-IF
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1100-APPLY-POST.
      *    Random READ of VSAM; if not found, reject. Otherwise
      *    REWRITE the VSAM record with DIN-DESCR/AMOUNT (STATUS
      *    unchanged) and mirror the change to MOCDC via UPDATE.
      *    Fixed VARCHAR(50) binding: DCL-MOCDC-DESCR-LEN = +50
      *    (spec rule (l)).
           ADD 1 TO WS-P-COUNT
           MOVE DIN-ACCT-ID TO FD-CDCACCT-ID
           MOVE 'N' TO WS-FOUND-FLAG
           READ CDCACCT-FILE INTO DEMO-ACCT-RECORD
               INVALID KEY
                   CONTINUE
               NOT INVALID KEY
                   MOVE 'Y' TO WS-FOUND-FLAG
           END-READ
           IF CDCACCT-STATUS = '00' OR '23'
               CONTINUE
           ELSE
               DISPLAY 'ERROR READING CDCACCT VSAM (POST), KEY='
                       DIN-ACCT-ID
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           IF WS-FOUND-FLAG = 'N'
               PERFORM 1900-WRITE-POSTED-REJECT
           ELSE
               MOVE DIN-DESCR   TO DEMO-ACCT-DESCR
               MOVE DIN-AMOUNT  TO DEMO-ACCT-AMOUNT
               MOVE DEMO-ACCT-RECORD TO FD-CDCACCT-REC
               MOVE 8 TO APPL-RESULT
               REWRITE FD-CDCACCT-REC
               IF CDCACCT-STATUS = '00'
                   MOVE 0 TO APPL-RESULT
               ELSE
                   MOVE 12 TO APPL-RESULT
               END-IF
               IF APPL-AOK
                   CONTINUE
               ELSE
                   DISPLAY 'ERROR REWRITING CDCACCT VSAM (POST), KEY='
                           DIN-ACCT-ID
                   MOVE CDCACCT-STATUS TO IO-STATUS
                   PERFORM 9910-DISPLAY-IO-STATUS
                   PERFORM 9999-ABEND-PROGRAM
               END-IF

               MOVE DIN-ACCT-ID  TO DCL-MOCDC-ID
               MOVE DIN-DESCR    TO DCL-MOCDC-DESCR-TEXT
               MOVE +50          TO DCL-MOCDC-DESCR-LEN
               MOVE DIN-AMOUNT   TO DCL-MOCDC-AMOUNT
               EXEC SQL
                   UPDATE MODATA1.MOCDC
                      SET DESCR  = :DCL-MOCDC-DESCR,
                          AMOUNT = :DCL-MOCDC-AMOUNT
                    WHERE ID     = :DCL-MOCDC-ID
               END-EXEC
               MOVE SQLCODE TO WS-VAR-SQLCODE
               EVALUATE TRUE
                   WHEN SQLCODE = ZERO
                       PERFORM 1800-WRITE-POSTED-OK
                   WHEN SQLCODE = +100
                       PERFORM 1900-WRITE-POSTED-REJECT
                   WHEN SQLCODE < 0
                       STRING
                         'Error updating MODATA1.MOCDC (POST). '
                         'SQLCODE:' WS-VAR-SQLCODE
                         DELIMITED BY SIZE
                         INTO WS-RETURN-MSG
                       END-STRING
                       PERFORM 9999-ABEND-PROGRAM
               END-EVALUATE
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1200-APPLY-CHARGE.
      *    Same shape as 1100-APPLY-POST but for the CHARGE action.
      *    The DIN-DESCR/DIN-AMOUNT come straight from the daily
      *    input record; the CHARGE overwrites any earlier POST for
      *    the same ID (input order is fixed by spec).
           ADD 1 TO WS-C-COUNT
           MOVE DIN-ACCT-ID TO FD-CDCACCT-ID
           MOVE 'N' TO WS-FOUND-FLAG
           READ CDCACCT-FILE INTO DEMO-ACCT-RECORD
               INVALID KEY
                   CONTINUE
               NOT INVALID KEY
                   MOVE 'Y' TO WS-FOUND-FLAG
           END-READ
           IF CDCACCT-STATUS = '00' OR '23'
               CONTINUE
           ELSE
               DISPLAY 'ERROR READING CDCACCT VSAM (CHARGE), KEY='
                       DIN-ACCT-ID
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           IF WS-FOUND-FLAG = 'N'
               PERFORM 1900-WRITE-POSTED-REJECT
           ELSE
               MOVE DIN-DESCR   TO DEMO-ACCT-DESCR
               MOVE DIN-AMOUNT  TO DEMO-ACCT-AMOUNT
               MOVE DEMO-ACCT-RECORD TO FD-CDCACCT-REC
               MOVE 8 TO APPL-RESULT
               REWRITE FD-CDCACCT-REC
               IF CDCACCT-STATUS = '00'
                   MOVE 0 TO APPL-RESULT
               ELSE
                   MOVE 12 TO APPL-RESULT
               END-IF
               IF APPL-AOK
                   CONTINUE
               ELSE
                   DISPLAY 'ERROR REWRITING CDCACCT VSAM (CHARGE), KEY='
                           DIN-ACCT-ID
                   MOVE CDCACCT-STATUS TO IO-STATUS
                   PERFORM 9910-DISPLAY-IO-STATUS
                   PERFORM 9999-ABEND-PROGRAM
               END-IF

               MOVE DIN-ACCT-ID  TO DCL-MOCDC-ID
               MOVE DIN-DESCR    TO DCL-MOCDC-DESCR-TEXT
               MOVE +50          TO DCL-MOCDC-DESCR-LEN
               MOVE DIN-AMOUNT   TO DCL-MOCDC-AMOUNT
               EXEC SQL
                   UPDATE MODATA1.MOCDC
                      SET DESCR  = :DCL-MOCDC-DESCR,
                          AMOUNT = :DCL-MOCDC-AMOUNT
                    WHERE ID     = :DCL-MOCDC-ID
               END-EXEC
               MOVE SQLCODE TO WS-VAR-SQLCODE
               EVALUATE TRUE
                   WHEN SQLCODE = ZERO
                       PERFORM 1800-WRITE-POSTED-OK
                   WHEN SQLCODE = +100
                       PERFORM 1900-WRITE-POSTED-REJECT
                   WHEN SQLCODE < 0
                       STRING
                         'Error updating MODATA1.MOCDC (CHARGE). '
                         'SQLCODE:' WS-VAR-SQLCODE
                         DELIMITED BY SIZE
                         INTO WS-RETURN-MSG
                       END-STRING
                       PERFORM 9999-ABEND-PROGRAM
               END-EVALUATE
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1300-APPLY-OPEN.
      *    Build a fresh VSAM record and keyed-WRITE it into the KSDS
      *    under the DYNAMIC access mode; then INSERT the mirror row
      *    into MODATA1.MOCDC. Fixed VARCHAR(50) binding.
      *    STATUS = 'O' (open) on the freshly-created VSAM record.
           MOVE DIN-ACCT-ID TO DEMO-ACCT-ID
           MOVE DIN-DESCR   TO DEMO-ACCT-DESCR
           MOVE DIN-AMOUNT  TO DEMO-ACCT-AMOUNT
           MOVE 'O'         TO DEMO-ACCT-STATUS
           MOVE SPACES      TO FD-CDCACCT-DATA
           MOVE DEMO-ACCT-RECORD TO FD-CDCACCT-REC
           MOVE 8 TO APPL-RESULT
           WRITE FD-CDCACCT-REC
           IF CDCACCT-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING CDCACCT VSAM (OPEN), KEY='
                       DIN-ACCT-ID
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE DIN-ACCT-ID  TO DCL-MOCDC-ID
           MOVE DIN-DESCR    TO DCL-MOCDC-DESCR-TEXT
           MOVE +50          TO DCL-MOCDC-DESCR-LEN
           MOVE DIN-AMOUNT   TO DCL-MOCDC-AMOUNT
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
                   ADD 1 TO WS-N-COUNT
                   PERFORM 1800-WRITE-POSTED-OK
               WHEN OTHER
                   STRING
                     'Error inserting MODATA1.MOCDC (OPEN). '
                     'SQLCODE:' WS-VAR-SQLCODE
                     DELIMITED BY SIZE
                     INTO WS-RETURN-MSG
                   END-STRING
                   PERFORM 9999-ABEND-PROGRAM
           END-EVALUATE
           EXIT.

      *---------------------------------------------------------------*
       1400-APPLY-CLOSE.
      *    Read VSAM by key, flip STATUS to 'C' (DESCR/AMOUNT
      *    unchanged in VSAM). Mirror to MOCDC as an UPDATE to a
      *    sentinel state: DESCR = 'CLOSED ' + zero-padded ID,
      *    AMOUNT = 0. Row is retained (no DELETE) so daily-post's
      *    MOCDC DML surface stays UPDATE + INSERT only (spec 4.3,
      *    rule (i)).
           MOVE DIN-ACCT-ID TO FD-CDCACCT-ID
           MOVE 'N' TO WS-FOUND-FLAG
           READ CDCACCT-FILE INTO DEMO-ACCT-RECORD
               INVALID KEY
                   CONTINUE
               NOT INVALID KEY
                   MOVE 'Y' TO WS-FOUND-FLAG
           END-READ
           IF CDCACCT-STATUS = '00' OR '23'
               CONTINUE
           ELSE
               DISPLAY 'ERROR READING CDCACCT VSAM (CLOSE), KEY='
                       DIN-ACCT-ID
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           IF WS-FOUND-FLAG = 'N'
               PERFORM 1900-WRITE-POSTED-REJECT
           ELSE
               MOVE 'C' TO DEMO-ACCT-STATUS
               MOVE DEMO-ACCT-RECORD TO FD-CDCACCT-REC
               MOVE 8 TO APPL-RESULT
               REWRITE FD-CDCACCT-REC
               IF CDCACCT-STATUS = '00'
                   MOVE 0 TO APPL-RESULT
               ELSE
                   MOVE 12 TO APPL-RESULT
               END-IF
               IF APPL-AOK
                   CONTINUE
               ELSE
                   DISPLAY 'ERROR REWRITING CDCACCT VSAM (CLOSE), KEY='
                           DIN-ACCT-ID
                   MOVE CDCACCT-STATUS TO IO-STATUS
                   PERFORM 9910-DISPLAY-IO-STATUS
                   PERFORM 9999-ABEND-PROGRAM
               END-IF

      *        Build sentinel DESCR: 'CLOSED ' (7 bytes) +
      *        11-digit zero-padded ID = 18 bytes, right-padded with
      *        blanks to 50 by the MOVE SPACES pre-fill.
               MOVE DIN-ACCT-ID  TO DCL-MOCDC-ID
               MOVE DIN-ACCT-ID  TO WS-ID-DIGITS
               MOVE SPACES       TO DCL-MOCDC-DESCR-TEXT
               STRING WS-DESCR-PREFIX  DELIMITED BY SIZE
                      WS-ID-DIGITS     DELIMITED BY SIZE
                    INTO DCL-MOCDC-DESCR-TEXT
               END-STRING
               MOVE +50          TO DCL-MOCDC-DESCR-LEN
               MOVE ZERO         TO DCL-MOCDC-AMOUNT
               EXEC SQL
                   UPDATE MODATA1.MOCDC
                      SET DESCR  = :DCL-MOCDC-DESCR,
                          AMOUNT = :DCL-MOCDC-AMOUNT
                    WHERE ID     = :DCL-MOCDC-ID
               END-EXEC
               MOVE SQLCODE TO WS-VAR-SQLCODE
               EVALUATE TRUE
                   WHEN SQLCODE = ZERO
                       ADD 1 TO WS-X-COUNT
                       PERFORM 1800-WRITE-POSTED-OK
                   WHEN SQLCODE = +100
                       PERFORM 1900-WRITE-POSTED-REJECT
                   WHEN SQLCODE < 0
                       STRING
                         'Error updating MODATA1.MOCDC (CLOSE). '
                         'SQLCODE:' WS-VAR-SQLCODE
                         DELIMITED BY SIZE
                         INTO WS-RETURN-MSG
                       END-STRING
                       PERFORM 9999-ABEND-PROGRAM
               END-EVALUATE
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1800-WRITE-POSTED-OK.
      *    MOVE SPACES to the full record first so the trailing 6-byte
      *    FILLER is deterministically blank; the named fields are then
      *    overwritten with their proper values (numeric MOVEs replace
      *    the intermediate group-move blanks).
           MOVE SPACES       TO DEMO-POSTED-RECORD
           MOVE DIN-ACTION   TO POST-ACTION
           MOVE DIN-ACCT-ID  TO POST-ACCT-ID
           MOVE DIN-DESCR    TO POST-DESCR
           MOVE DIN-AMOUNT   TO POST-AMOUNT
           MOVE 'OK'         TO POST-RESULT-CODE
           MOVE 8 TO APPL-RESULT
           WRITE FD-POSTED-REC FROM DEMO-POSTED-RECORD
           IF POSTED-STATUS = '00'
               MOVE 0 TO APPL-RESULT
               ADD 1 TO WS-POSTED-OK-COUNT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING POSTED FILE (OK)'
               MOVE POSTED-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       1900-WRITE-POSTED-REJECT.
           MOVE SPACES       TO DEMO-POSTED-RECORD
           MOVE DIN-ACTION   TO POST-ACTION
           MOVE DIN-ACCT-ID  TO POST-ACCT-ID
           MOVE DIN-DESCR    TO POST-DESCR
           MOVE DIN-AMOUNT   TO POST-AMOUNT
           MOVE 'RJ'         TO POST-RESULT-CODE
           MOVE 8 TO APPL-RESULT
           WRITE FD-POSTED-REC FROM DEMO-POSTED-RECORD
           IF POSTED-STATUS = '00'
               MOVE 0 TO APPL-RESULT
               ADD 1 TO WS-REJECT-COUNT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING POSTED FILE (RJ)'
               MOVE POSTED-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       2500-COMMIT-MOCDC.
      *    One COMMIT per run, at end of DALYIN — the smallest,
      *    most deterministic contract to review: either the whole
      *    run's MOCDC delta is captured by CDC or none of it is.
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
       2700-COUNT-UNCHANGED.
      *    Sequential VSAM scan of the pre-existing key range
      *    [00000000001 .. 00000001000]. An account is UNCHANGED
      *    when its STATUS is still 'O' and its DESCR still starts
      *    with 'BAL FWD '. Observed fact — not derived — so the
      *    count is a deterministic function of final VSAM state.
           MOVE 00000000001 TO FD-CDCACCT-ID
           MOVE 'N'         TO END-OF-SCAN
           MOVE 8 TO APPL-RESULT
           START CDCACCT-FILE KEY IS NOT LESS THAN FD-CDCACCT-ID
               INVALID KEY
                   MOVE 'Y' TO END-OF-SCAN
                   MOVE 12  TO APPL-RESULT
               NOT INVALID KEY
                   MOVE 0   TO APPL-RESULT
           END-START
           IF CDCACCT-STATUS NOT = '00'
             AND CDCACCT-STATUS NOT = '23'
               DISPLAY 'ERROR START CDCACCT (UNCHANGED SCAN)'
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           PERFORM UNTIL END-OF-SCAN = 'Y'
               READ CDCACCT-FILE NEXT INTO DEMO-ACCT-RECORD
                   AT END MOVE 'Y' TO END-OF-SCAN
               END-READ
               IF END-OF-SCAN = 'N'
                   IF CDCACCT-STATUS NOT = '00'
                       DISPLAY 'ERROR READ NEXT CDCACCT (UNCHANGED)'
                       MOVE CDCACCT-STATUS TO IO-STATUS
                       PERFORM 9910-DISPLAY-IO-STATUS
                       PERFORM 9999-ABEND-PROGRAM
                   END-IF
                   IF DEMO-ACCT-ID > 00000001000
                       MOVE 'Y' TO END-OF-SCAN
                   ELSE
                       IF DEMO-ACCT-STATUS = 'O'
                          AND DEMO-ACCT-DESCR (1:8) = 'BAL FWD '
                           ADD 1 TO WS-UNCHANGED-COUNT
                       END-IF
                   END-IF
               END-IF
           END-PERFORM
           EXIT.

      *---------------------------------------------------------------*
       3000-WRITE-TRIALBAL.
      *    Header + detail (keys 1001..1200, ascending) + total.
      *    Detail order is guaranteed by START KEY IS NOT LESS THAN
      *    + READ NEXT on the DYNAMIC-access KSDS.
           PERFORM 3100-WRITE-TRIALBAL-HEADER

           MOVE 00000001001 TO FD-CDCACCT-ID
           MOVE 'N'         TO END-OF-SCAN
           MOVE 8 TO APPL-RESULT
           START CDCACCT-FILE KEY IS NOT LESS THAN FD-CDCACCT-ID
               INVALID KEY
                   MOVE 'Y' TO END-OF-SCAN
                   MOVE 12  TO APPL-RESULT
               NOT INVALID KEY
                   MOVE 0   TO APPL-RESULT
           END-START
           IF CDCACCT-STATUS NOT = '00'
             AND CDCACCT-STATUS NOT = '23'
               DISPLAY 'ERROR START CDCACCT (TRIALBAL SCAN)'
               MOVE CDCACCT-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           PERFORM UNTIL END-OF-SCAN = 'Y'
               READ CDCACCT-FILE NEXT INTO DEMO-ACCT-RECORD
                   AT END MOVE 'Y' TO END-OF-SCAN
               END-READ
               IF END-OF-SCAN = 'N'
                   IF CDCACCT-STATUS NOT = '00'
                       DISPLAY 'ERROR READ NEXT CDCACCT (TRIALBAL)'
                       MOVE CDCACCT-STATUS TO IO-STATUS
                       PERFORM 9910-DISPLAY-IO-STATUS
                       PERFORM 9999-ABEND-PROGRAM
                   END-IF
                   IF DEMO-ACCT-ID > 00000001200
                       MOVE 'Y' TO END-OF-SCAN
                   ELSE
                       PERFORM 3200-WRITE-TRIALBAL-DETAIL
                   END-IF
               END-IF
           END-PERFORM

           PERFORM 3300-WRITE-TRIALBAL-TOTAL
           EXIT.

      *---------------------------------------------------------------*
       3100-WRITE-TRIALBAL-HEADER.
           MOVE SPACES                    TO DEMO-TRIAL-BAL-LINE
           MOVE '1'                       TO TB-CC
           MOVE ZERO                      TO TB-ACCT-ID
           MOVE WS-TB-HEADER-DESCR        TO TB-DESCR
           MOVE ZERO                      TO TB-AMOUNT-DISPLAY
           MOVE SPACE                     TO TB-STATUS
           MOVE 8 TO APPL-RESULT
           WRITE FD-TRIALBAL-REC FROM DEMO-TRIAL-BAL-LINE
           IF TRIALBAL-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING TRIALBAL (HEADER)'
               MOVE TRIALBAL-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       3200-WRITE-TRIALBAL-DETAIL.
           MOVE SPACES                    TO DEMO-TRIAL-BAL-LINE
           MOVE ' '                       TO TB-CC
           MOVE DEMO-ACCT-ID              TO TB-ACCT-ID
           MOVE DEMO-ACCT-DESCR           TO TB-DESCR
           MOVE DEMO-ACCT-AMOUNT          TO TB-AMOUNT-DISPLAY
           MOVE DEMO-ACCT-STATUS          TO TB-STATUS
           ADD  DEMO-ACCT-AMOUNT          TO WS-TB-TOTAL
           ADD  1                         TO WS-TB-DETAIL-COUNT
           MOVE 8 TO APPL-RESULT
           WRITE FD-TRIALBAL-REC FROM DEMO-TRIAL-BAL-LINE
           IF TRIALBAL-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING TRIALBAL (DETAIL), KEY='
                       DEMO-ACCT-ID
               MOVE TRIALBAL-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       3300-WRITE-TRIALBAL-TOTAL.
           MOVE SPACES                    TO DEMO-TRIAL-BAL-LINE
           MOVE '-'                       TO TB-CC
           MOVE ZERO                      TO TB-ACCT-ID
           MOVE WS-TB-TOTAL-DESCR         TO TB-DESCR
           MOVE WS-TB-TOTAL               TO TB-AMOUNT-DISPLAY
           MOVE SPACE                     TO TB-STATUS
           MOVE 8 TO APPL-RESULT
           WRITE FD-TRIALBAL-REC FROM DEMO-TRIAL-BAL-LINE
           IF TRIALBAL-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING TRIALBAL (TOTAL)'
               MOVE TRIALBAL-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       3500-WRITE-CONTROLS.
      *    Six records in fixed order (spec 5.6 / 6.3):
      *      INPUT-READ, POSTED-OK, POSTED-REJECT, OPENED, CLOSED,
      *      UNCHANGED. The record is blanked before each build so the
      *      35-byte trailing FILLER is byte-deterministic.
           MOVE SPACES               TO DEMO-CONTROLS-RECORD
           MOVE WS-LBL-INPUT-READ    TO CTL-LABEL
           MOVE WS-READ-COUNT        TO CTL-VALUE
           PERFORM 3600-WRITE-CONTROLS-REC

           MOVE SPACES               TO DEMO-CONTROLS-RECORD
           MOVE WS-LBL-POSTED-OK     TO CTL-LABEL
           MOVE WS-POSTED-OK-COUNT   TO CTL-VALUE
           PERFORM 3600-WRITE-CONTROLS-REC

           MOVE SPACES               TO DEMO-CONTROLS-RECORD
           MOVE WS-LBL-POSTED-REJECT TO CTL-LABEL
           MOVE WS-REJECT-COUNT      TO CTL-VALUE
           PERFORM 3600-WRITE-CONTROLS-REC

           MOVE SPACES               TO DEMO-CONTROLS-RECORD
           MOVE WS-LBL-OPENED        TO CTL-LABEL
           MOVE WS-N-COUNT           TO CTL-VALUE
           PERFORM 3600-WRITE-CONTROLS-REC

           MOVE SPACES               TO DEMO-CONTROLS-RECORD
           MOVE WS-LBL-CLOSED        TO CTL-LABEL
           MOVE WS-X-COUNT           TO CTL-VALUE
           PERFORM 3600-WRITE-CONTROLS-REC

           MOVE SPACES               TO DEMO-CONTROLS-RECORD
           MOVE WS-LBL-UNCHANGED     TO CTL-LABEL
           MOVE WS-UNCHANGED-COUNT   TO CTL-VALUE
           PERFORM 3600-WRITE-CONTROLS-REC
           EXIT.

      *---------------------------------------------------------------*
       3600-WRITE-CONTROLS-REC.
           MOVE 8 TO APPL-RESULT
           WRITE FD-CONTROLS-REC FROM DEMO-CONTROLS-RECORD
           IF CONTROLS-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR WRITING CONTROLS FILE, LABEL='
                       CTL-LABEL
               MOVE CONTROLS-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       9000-CLOSE-FILES.
           MOVE 8 TO APPL-RESULT
           CLOSE DALYIN-FILE
           IF DALYIN-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR CLOSING DALYIN FILE'
               MOVE DALYIN-STATUS TO IO-STATUS
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

           MOVE 8 TO APPL-RESULT
           CLOSE POSTED-FILE
           IF POSTED-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR CLOSING POSTED FILE'
               MOVE POSTED-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE 8 TO APPL-RESULT
           CLOSE TRIALBAL-FILE
           IF TRIALBAL-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR CLOSING TRIALBAL FILE'
               MOVE TRIALBAL-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF

           MOVE 8 TO APPL-RESULT
           CLOSE CONTROLS-FILE
           IF CONTROLS-STATUS = '00'
               MOVE 0 TO APPL-RESULT
           ELSE
               MOVE 12 TO APPL-RESULT
           END-IF
           IF APPL-AOK
               CONTINUE
           ELSE
               DISPLAY 'ERROR CLOSING CONTROLS FILE'
               MOVE CONTROLS-STATUS TO IO-STATUS
               PERFORM 9910-DISPLAY-IO-STATUS
               PERFORM 9999-ABEND-PROGRAM
           END-IF
           EXIT.

      *---------------------------------------------------------------*
       9500-DISPLAY-COUNTS.
           DISPLAY 'INPUT-READ        : ' WS-READ-COUNT
           DISPLAY 'POSTED-OK         : ' WS-POSTED-OK-COUNT
           DISPLAY 'POSTED-REJECT     : ' WS-REJECT-COUNT
           DISPLAY 'OPENED  (N)       : ' WS-N-COUNT
           DISPLAY 'CLOSED  (X)       : ' WS-X-COUNT
           DISPLAY 'UNCHANGED         : ' WS-UNCHANGED-COUNT
           DISPLAY 'POST    (P) SEEN  : ' WS-P-COUNT
           DISPLAY 'CHARGE  (C) SEEN  : ' WS-C-COUNT
           DISPLAY 'TRIALBAL DETAILS  : ' WS-TB-DETAIL-COUNT
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
