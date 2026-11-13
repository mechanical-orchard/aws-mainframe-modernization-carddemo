      ******************************************************************
      * Program     : CBMOD01C.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : BATCH COBOL Db2 Program (TSO attach)
      * Function    : Load posted transactions from the TRANSACT VSAM
      *               file into Db2 table CARDDEMO.TRAN_HIST.
      *               - Reads TRANSACT in key order
      *               - Looks up each card in CARDXREF for its account
      *               - Stores a zero merchant id, blank merchant
      *                 fields and a blank processing timestamp as NULL
      *               - Drops trailing spaces and low-values from the
      *                 description, merchant name and merchant city
      *               - Skips transactions that are already loaded
      *                 (SQLCODE -803), so the job can be rerun
      *               - Commits every 100 inserted rows
      *               - Writes rejected transactions to REJFILE
      *               Sets RC 4 when any transaction is rejected.
      ******************************************************************
      * Copyright (c) 2026 Mechanical Orchard, Inc.                    *
      * All Rights Reserved.                                           *
      *                                                                *
      * Licensed under the Apache License, Version 2.0 (the "License").*
      * You may not use this file except in compliance with the        *
      * License. You may obtain a copy of the License at               *
      *                                                                *
      *    http://www.apache.org/licenses/LICENSE-2.0                  *
      *                                                                *
      * Unless required by applicable law or agreed to in writing,     *
      * software distributed under the License is distributed on an    *
      * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,   *
      * either express or implied. See the License for the specific    *
      * language governing permissions and limitations under the       *
      * License.                                                       *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    CBMOD01C.
       AUTHOR.        MECHANICAL ORCHARD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACT-FILE ASSIGN TO TRANFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS SEQUENTIAL
                  RECORD KEY   IS FD-TRANS-ID
                  FILE STATUS  IS TRANFILE-STATUS.

           SELECT XREF-FILE ASSIGN TO XREFFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS RANDOM
                  RECORD KEY   IS FD-XREF-CARD-NUM
                  FILE STATUS  IS XREFFILE-STATUS.

           SELECT REJECT-FILE ASSIGN TO REJFILE
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS REJFILE-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  TRANSACT-FILE.
       01  FD-TRANFILE-REC.
           05 FD-TRANS-ID                       PIC X(16).
           05 FD-TRANS-DATA                     PIC X(334).

       FD  XREF-FILE.
       01  FD-XREFFILE-REC.
           05 FD-XREF-CARD-NUM                  PIC X(16).
           05 FD-XREF-DATA                      PIC X(34).

       FD  REJECT-FILE.
       01  FD-REJECT-REC                        PIC X(430).

       WORKING-STORAGE SECTION.

      *****************************************************************
       COPY CVTRA05Y.
       01  TRANFILE-STATUS.
           05  TRANFILE-STAT1                   PIC X.
           05  TRANFILE-STAT2                   PIC X.

       COPY CVACT03Y.
       01  XREFFILE-STATUS.
           05  XREFFILE-STAT1                   PIC X.
           05  XREFFILE-STAT2                   PIC X.

       COPY CVMOD02Y.
       01  REJFILE-STATUS.
           05  REJFILE-STAT1                    PIC X.
           05  REJFILE-STAT2                    PIC X.

       COPY CSMODBWY.

      *****************************************************************
      *    Db2 communication area and table declaration
      *****************************************************************
           EXEC SQL INCLUDE SQLCA END-EXEC.

           EXEC SQL INCLUDE DCLTRHST END-EXEC.

      *    Null indicators for the nullable TRAN_HIST columns
       01  WS-NULL-INDICATORS.
           05  WS-IND-MERCHANT-ID               PIC S9(4) COMP.
           05  WS-IND-MERCHANT-NAME             PIC S9(4) COMP.
           05  WS-IND-MERCHANT-CITY             PIC S9(4) COMP.
           05  WS-IND-MERCHANT-ZIP              PIC S9(4) COMP.
           05  WS-IND-PROC-TS                   PIC S9(4) COMP.

      *****************************************************************
       01  WS-FLAGS.
           05  WS-END-OF-FILE                   PIC X(01) VALUE 'N'.
               88  END-OF-TRANFILE                        VALUE 'Y'.
           05  WS-RECORD-STATE                  PIC X(01) VALUE 'Y'.
               88  RECORD-IS-OK                           VALUE 'Y'.
               88  RECORD-REJECTED                        VALUE 'N'.
           05  WS-TS-STATE                      PIC X(01) VALUE 'N'.
               88  TS-IS-VALID                            VALUE 'Y'.
               88  TS-IS-INVALID                          VALUE 'N'.
           05  WS-TRIM-STATE                    PIC X(01) VALUE 'N'.
               88  TRIM-DONE                              VALUE 'Y'.
               88  TRIM-NOT-DONE                          VALUE 'N'.

       01  WS-COUNTERS.
           05  WS-READ-COUNT                    PIC 9(09) VALUE 0.
           05  WS-INSERT-COUNT                  PIC 9(09) VALUE 0.
           05  WS-DUPLICATE-COUNT               PIC 9(09) VALUE 0.
           05  WS-REJECT-COUNT                  PIC 9(09) VALUE 0.
           05  WS-UNCOMMITTED-COUNT             PIC 9(09) VALUE 0.
           05  WS-COMMIT-COUNT                  PIC 9(09) VALUE 0.

       01  WS-COMMIT-FREQUENCY                  PIC 9(09) VALUE 100.

      *    Timestamp being checked. Accepted forms:
      *      YYYY-MM-DD-HH.MM.SS.NNNNNN   (Db2 format)
      *      YYYY-MM-DD HH:MM:SS.NNNNNN   (daily transaction input)
       01  WS-TS-WORK                           PIC X(26).
       01  WS-TS-PARTS REDEFINES WS-TS-WORK.
           05  WS-TS-YYYY                       PIC X(04).
           05  WS-TS-SEP1                       PIC X(01).
           05  WS-TS-MM                         PIC X(02).
           05  WS-TS-SEP2                       PIC X(01).
           05  WS-TS-DD                         PIC X(02).
           05  WS-TS-SEP3                       PIC X(01).
           05  WS-TS-HH                         PIC X(02).
           05  WS-TS-SEP4                       PIC X(01).
           05  WS-TS-MI                         PIC X(02).
           05  WS-TS-SEP5                       PIC X(01).
           05  WS-TS-SS                         PIC X(02).
           05  WS-TS-SEP6                       PIC X(01).
           05  WS-TS-FRAC                       PIC X(06).

      *    Trailing space and low-value trim for VARCHAR lengths
       01  WS-TRIM-WORK                         PIC X(100).
       01  WS-TRIM-MAX                          PIC S9(4) COMP.
       01  WS-TRIM-LEN                          PIC S9(4) COMP.

      *****************************************************************
       PROCEDURE DIVISION.
           DISPLAY 'START OF EXECUTION OF PROGRAM CBMOD01C'.
           PERFORM 0100-TRANFILE-OPEN.
           PERFORM 0200-XREFFILE-OPEN.
           PERFORM 0300-REJFILE-OPEN.

           PERFORM 1000-TRANFILE-GET-NEXT.
           PERFORM UNTIL END-OF-TRANFILE
               ADD 1 TO WS-READ-COUNT
               PERFORM 2000-PROCESS-TRANSACTION
               PERFORM 1000-TRANFILE-GET-NEXT
           END-PERFORM.

           PERFORM 3000-COMMIT-WORK.

           PERFORM 9100-TRANFILE-CLOSE.
           PERFORM 9200-XREFFILE-CLOSE.
           PERFORM 9300-REJFILE-CLOSE.

           DISPLAY 'TRANSACTIONS READ        :' WS-READ-COUNT.
           DISPLAY 'ROWS INSERTED            :' WS-INSERT-COUNT.
           DISPLAY 'ALREADY LOADED (SKIPPED) :' WS-DUPLICATE-COUNT.
           DISPLAY 'TRANSACTIONS REJECTED    :' WS-REJECT-COUNT.
           DISPLAY 'COMMITS ISSUED           :' WS-COMMIT-COUNT.
           IF WS-REJECT-COUNT > 0
              MOVE 4 TO RETURN-CODE
           END-IF.
           DISPLAY 'END OF EXECUTION OF PROGRAM CBMOD01C'.

           GOBACK.

      *---------------------------------------------------------------*
       0100-TRANFILE-OPEN.
           OPEN INPUT TRANSACT-FILE
           IF TRANFILE-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING TRANSACTION FILE'
              MOVE TRANFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       0200-XREFFILE-OPEN.
           OPEN INPUT XREF-FILE
           IF XREFFILE-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING CROSS REFERENCE FILE'
              MOVE XREFFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       0300-REJFILE-OPEN.
           OPEN OUTPUT REJECT-FILE
           IF REJFILE-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING REJECT FILE'
              MOVE REJFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       1000-TRANFILE-GET-NEXT.
           READ TRANSACT-FILE INTO TRAN-RECORD
           EVALUATE TRANFILE-STATUS
              WHEN '00'
                 CONTINUE
              WHEN '10'
                 SET END-OF-TRANFILE TO TRUE
              WHEN OTHER
                 DISPLAY 'ERROR READING TRANSACTION FILE'
                 MOVE TRANFILE-STATUS TO IO-STATUS
                 PERFORM 9910-DISPLAY-IO-STATUS
                 MOVE 999 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
           END-EVALUATE.
      *---------------------------------------------------------------*
       2000-PROCESS-TRANSACTION.
           SET RECORD-IS-OK TO TRUE
           PERFORM 2100-LOOKUP-XREF
           IF RECORD-IS-OK
              PERFORM 2300-BUILD-HOST-VARIABLES
           END-IF
           IF RECORD-IS-OK
              PERFORM 2400-INSERT-TRAN-HIST
           END-IF.
      *---------------------------------------------------------------*
       2100-LOOKUP-XREF.
           MOVE TRAN-CARD-NUM TO FD-XREF-CARD-NUM
           READ XREF-FILE INTO CARD-XREF-RECORD
              INVALID KEY
                 CONTINUE
           END-READ
           EVALUATE XREFFILE-STATUS
              WHEN '00'
                 CONTINUE
              WHEN '23'
                 MOVE 0100 TO MODB-REJ-REASON-CD
                 MOVE 'CARD NUMBER NOT FOUND IN CROSS REFERENCE'
                   TO MODB-REJ-REASON-DESC
                 MOVE 0 TO MODB-REJ-SQLCODE
                 PERFORM 2900-WRITE-REJECT
              WHEN OTHER
                 DISPLAY 'ERROR READING CROSS REFERENCE FILE'
                 MOVE XREFFILE-STATUS TO IO-STATUS
                 PERFORM 9910-DISPLAY-IO-STATUS
                 MOVE 999 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
           END-EVALUATE.
      *---------------------------------------------------------------*
      * Rewrite WS-TS-WORK into Db2 timestamp format and check it.
      * Out-of-range values (month 13, hour 25) are left for Db2 to
      * reject with SQLCODE -180 or -181.
      *---------------------------------------------------------------*
       2200-NORMALIZE-TIMESTAMP.
           SET TS-IS-INVALID TO TRUE
           IF WS-TS-SEP3 = SPACE
              MOVE '-' TO WS-TS-SEP3
           END-IF
           IF WS-TS-SEP4 = ':'
              MOVE '.' TO WS-TS-SEP4
           END-IF
           IF WS-TS-SEP5 = ':'
              MOVE '.' TO WS-TS-SEP5
           END-IF
           IF  WS-TS-YYYY IS NUMERIC
           AND WS-TS-MM   IS NUMERIC
           AND WS-TS-DD   IS NUMERIC
           AND WS-TS-HH   IS NUMERIC
           AND WS-TS-MI   IS NUMERIC
           AND WS-TS-SS   IS NUMERIC
           AND WS-TS-FRAC IS NUMERIC
           AND WS-TS-SEP1 = '-'
           AND WS-TS-SEP2 = '-'
           AND WS-TS-SEP3 = '-'
           AND WS-TS-SEP4 = '.'
           AND WS-TS-SEP5 = '.'
           AND WS-TS-SEP6 = '.'
              SET TS-IS-VALID TO TRUE
           END-IF.
      *---------------------------------------------------------------*
       2300-BUILD-HOST-VARIABLES.
           MOVE TRAN-ID                 TO DCL-TH-TRAN-ID
           MOVE XREF-ACCT-ID            TO DCL-TH-ACCT-ID
           MOVE TRAN-CARD-NUM           TO DCL-TH-CARD-NUM
           MOVE TRAN-TYPE-CD            TO DCL-TH-TYPE-CD
           MOVE TRAN-CAT-CD             TO DCL-TH-CAT-CD
           MOVE TRAN-SOURCE             TO DCL-TH-SOURCE
           MOVE TRAN-AMT                TO DCL-TH-AMT

      *    Description: VARCHAR without trailing spaces or low-values.
      *    The base interest job pads its descriptions with low-values
           MOVE TRAN-DESC               TO WS-TRIM-WORK
           MOVE LENGTH OF TRAN-DESC     TO WS-TRIM-MAX
           PERFORM 2500-TRIMMED-LENGTH
           MOVE TRAN-DESC               TO DCL-TH-DESC-TEXT
           MOVE WS-TRIM-LEN             TO DCL-TH-DESC-LEN

      *    Merchant id: zero means there is no merchant
           IF TRAN-MERCHANT-ID = ZERO
              MOVE -1                   TO WS-IND-MERCHANT-ID
              MOVE ZERO                 TO DCL-TH-MERCHANT-ID
           ELSE
              MOVE 0                    TO WS-IND-MERCHANT-ID
              MOVE TRAN-MERCHANT-ID     TO DCL-TH-MERCHANT-ID
           END-IF

      *    Merchant name, city and zip: blank means NULL
           MOVE TRAN-MERCHANT-NAME      TO WS-TRIM-WORK
           MOVE LENGTH OF TRAN-MERCHANT-NAME TO WS-TRIM-MAX
           PERFORM 2500-TRIMMED-LENGTH
           MOVE TRAN-MERCHANT-NAME      TO DCL-TH-MERCHANT-NAME-TEXT
           MOVE WS-TRIM-LEN             TO DCL-TH-MERCHANT-NAME-LEN
           IF WS-TRIM-LEN = 0
              MOVE -1                   TO WS-IND-MERCHANT-NAME
           ELSE
              MOVE 0                    TO WS-IND-MERCHANT-NAME
           END-IF

           MOVE TRAN-MERCHANT-CITY      TO WS-TRIM-WORK
           MOVE LENGTH OF TRAN-MERCHANT-CITY TO WS-TRIM-MAX
           PERFORM 2500-TRIMMED-LENGTH
           MOVE TRAN-MERCHANT-CITY      TO DCL-TH-MERCHANT-CITY-TEXT
           MOVE WS-TRIM-LEN             TO DCL-TH-MERCHANT-CITY-LEN
           IF WS-TRIM-LEN = 0
              MOVE -1                   TO WS-IND-MERCHANT-CITY
           ELSE
              MOVE 0                    TO WS-IND-MERCHANT-CITY
           END-IF

           MOVE TRAN-MERCHANT-ZIP       TO DCL-TH-MERCHANT-ZIP
           IF TRAN-MERCHANT-ZIP = SPACES
              MOVE -1                   TO WS-IND-MERCHANT-ZIP
           ELSE
              MOVE 0                    TO WS-IND-MERCHANT-ZIP
           END-IF

      *    Original timestamp: required. Its date is TH_TRAN_DATE.
           MOVE TRAN-ORIG-TS            TO WS-TS-WORK
           PERFORM 2200-NORMALIZE-TIMESTAMP
           IF TS-IS-VALID
              MOVE WS-TS-WORK           TO DCL-TH-ORIG-TS
              MOVE WS-TS-WORK(1:10)     TO DCL-TH-TRAN-DATE
           ELSE
              MOVE 0101 TO MODB-REJ-REASON-CD
              MOVE 'ORIGINAL TIMESTAMP IS NOT A VALID TIMESTAMP'
                TO MODB-REJ-REASON-DESC
              MOVE 0 TO MODB-REJ-SQLCODE
              PERFORM 2900-WRITE-REJECT
           END-IF

      *    Processing timestamp: optional, blank means NULL
           IF RECORD-IS-OK
              IF TRAN-PROC-TS = SPACES
                 MOVE -1                TO WS-IND-PROC-TS
                 MOVE SPACES            TO DCL-TH-PROC-TS
              ELSE
                 MOVE TRAN-PROC-TS      TO WS-TS-WORK
                 PERFORM 2200-NORMALIZE-TIMESTAMP
                 IF TS-IS-VALID
                    MOVE 0              TO WS-IND-PROC-TS
                    MOVE WS-TS-WORK     TO DCL-TH-PROC-TS
                 ELSE
                    MOVE 0102 TO MODB-REJ-REASON-CD
                    MOVE 'PROCESSING TIMESTAMP IS NOT A VALID TIMESTAMP'
                      TO MODB-REJ-REASON-DESC
                    MOVE 0 TO MODB-REJ-SQLCODE
                    PERFORM 2900-WRITE-REJECT
                 END-IF
              END-IF
           END-IF.
      *---------------------------------------------------------------*
       2400-INSERT-TRAN-HIST.
           EXEC SQL
                INSERT INTO CARDDEMO.TRAN_HIST
                     ( TH_TRAN_ID
                     , TH_ACCT_ID
                     , TH_CARD_NUM
                     , TH_TYPE_CD
                     , TH_CAT_CD
                     , TH_SOURCE
                     , TH_DESC
                     , TH_AMT
                     , TH_MERCHANT_ID
                     , TH_MERCHANT_NAME
                     , TH_MERCHANT_CITY
                     , TH_MERCHANT_ZIP
                     , TH_TRAN_DATE
                     , TH_ORIG_TS
                     , TH_PROC_TS
                     )
                VALUES
                     ( :DCL-TH-TRAN-ID
                     , :DCL-TH-ACCT-ID
                     , :DCL-TH-CARD-NUM
                     , :DCL-TH-TYPE-CD
                     , :DCL-TH-CAT-CD
                     , :DCL-TH-SOURCE
                     , :DCL-TH-DESC
                     , :DCL-TH-AMT
                     , :DCL-TH-MERCHANT-ID   :WS-IND-MERCHANT-ID
                     , :DCL-TH-MERCHANT-NAME :WS-IND-MERCHANT-NAME
                     , :DCL-TH-MERCHANT-CITY :WS-IND-MERCHANT-CITY
                     , :DCL-TH-MERCHANT-ZIP  :WS-IND-MERCHANT-ZIP
                     , :DCL-TH-TRAN-DATE
                     , :DCL-TH-ORIG-TS
                     , :DCL-TH-PROC-TS       :WS-IND-PROC-TS
                     )
           END-EXEC

           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 ADD 1 TO WS-INSERT-COUNT
                 ADD 1 TO WS-UNCOMMITTED-COUNT
                 IF WS-UNCOMMITTED-COUNT >= WS-COMMIT-FREQUENCY
                    PERFORM 3000-COMMIT-WORK
                 END-IF
              WHEN SQLCODE = -803
      *          Loaded by an earlier run
                 ADD 1 TO WS-DUPLICATE-COUNT
              WHEN SQLCODE = -180
              WHEN SQLCODE = -181
                 MOVE 0103 TO MODB-REJ-REASON-CD
                 MOVE 'DB2 REJECTED A DATE OR TIMESTAMP VALUE'
                   TO MODB-REJ-REASON-DESC
                 MOVE SQLCODE TO MODB-REJ-SQLCODE
                 PERFORM 2900-WRITE-REJECT
              WHEN OTHER
                 MOVE 'INSERT INTO CARDDEMO.TRAN_HIST'
                   TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE.
      *---------------------------------------------------------------*
      * Set WS-TRIM-LEN to the length of WS-TRIM-WORK(1:WS-TRIM-MAX)
      * without trailing spaces or low-values. Zero when it has
      * nothing else.
      *---------------------------------------------------------------*
       2500-TRIMMED-LENGTH.
           MOVE WS-TRIM-MAX TO WS-TRIM-LEN
           SET TRIM-NOT-DONE TO TRUE
           PERFORM UNTIL TRIM-DONE
              IF WS-TRIM-LEN = 0
                 SET TRIM-DONE TO TRUE
              ELSE
                 IF WS-TRIM-WORK(WS-TRIM-LEN:1) = SPACE OR LOW-VALUE
                    SUBTRACT 1 FROM WS-TRIM-LEN
                 ELSE
                    SET TRIM-DONE TO TRUE
                 END-IF
              END-IF
           END-PERFORM.
      *---------------------------------------------------------------*
      * The caller sets the reason code, description and SQLCODE.
      *---------------------------------------------------------------*
       2900-WRITE-REJECT.
           SET RECORD-REJECTED TO TRUE
           MOVE TRAN-RECORD TO MODB-REJ-TRAN-DATA
           WRITE FD-REJECT-REC FROM MODB-REJECT-RECORD
           IF REJFILE-STATUS NOT = '00'
              DISPLAY 'ERROR WRITING REJECT FILE'
              MOVE REJFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF
           ADD 1 TO WS-REJECT-COUNT.
      *---------------------------------------------------------------*
       3000-COMMIT-WORK.
           EXEC SQL
                COMMIT
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'COMMIT' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF
           ADD 1 TO WS-COMMIT-COUNT
           MOVE 0 TO WS-UNCOMMITTED-COUNT.
      *---------------------------------------------------------------*
       9100-TRANFILE-CLOSE.
           CLOSE TRANSACT-FILE
           IF TRANFILE-STATUS NOT = '00'
              DISPLAY 'ERROR CLOSING TRANSACTION FILE'
              MOVE TRANFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       9200-XREFFILE-CLOSE.
           CLOSE XREF-FILE
           IF XREFFILE-STATUS NOT = '00'
              DISPLAY 'ERROR CLOSING CROSS REFERENCE FILE'
              MOVE XREFFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       9300-REJFILE-CLOSE.
           CLOSE REJECT-FILE
           IF REJFILE-STATUS NOT = '00'
              DISPLAY 'ERROR CLOSING REJECT FILE'
              MOVE REJFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
      * Report the SQL error, back out uncommitted work and abend.
      *---------------------------------------------------------------*
       9800-SQL-ERROR.
           PERFORM 9810-DISPLAY-SQL-ERROR
           EXEC SQL
                ROLLBACK
           END-EXEC
           MOVE 998 TO ABCODE
           PERFORM 9999-ABEND-PROGRAM.

       COPY CSMODBPY.
