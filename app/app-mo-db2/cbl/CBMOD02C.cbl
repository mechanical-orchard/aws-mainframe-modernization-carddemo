      ******************************************************************
      * Program     : CBMOD02C.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : BATCH COBOL Db2 Program (TSO attach)
      * Function    : Build the daily balance snapshot in Db2 table
      *               CARDDEMO.ACCT_DAILY_BAL for the balance date in
      *               DD PARMFILE (cols 1-10, YYYY-MM-DD).
      *               - Totals each account's TRAN_HIST credits
      *                 (amount >= 0), debits (amount < 0) and count
      *                 for the date, in account order
      *               - Opening balance is the closing balance of the
      *                 account's latest earlier snapshot. With no
      *                 earlier snapshot it is seeded from the ACCTDATA
      *                 current balance less every TRAN_HIST amount
      *                 dated on or after the balance date
      *               - Credit limit comes from ACCTDATA
      *               - Inserts the snapshot; when one already exists
      *                 for the date (rerun) it is replaced and its
      *                 over-limit flag cleared for CBMOD04C to redo
      *               - Commits every 100 accounts (cursor WITH HOLD)
      *               Sets RC 4 when an account is not in ACCTDATA.
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
       PROGRAM-ID.    CBMOD02C.
       AUTHOR.        MECHANICAL ORCHARD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PARM-FILE ASSIGN TO PARMFILE
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS PARMFILE-STATUS.

           SELECT ACCOUNT-FILE ASSIGN TO ACCTFILE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS RANDOM
                  RECORD KEY   IS FD-ACCT-ID
                  FILE STATUS  IS ACCTFILE-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  PARM-FILE.
       01  FD-PARM-REC                          PIC X(80).

       FD  ACCOUNT-FILE.
       01  FD-ACCTFILE-REC.
           05 FD-ACCT-ID                        PIC 9(11).
           05 FD-ACCT-DATA                      PIC X(289).

       WORKING-STORAGE SECTION.

      *****************************************************************
       COPY CVMOD01Y.
       01  PARMFILE-STATUS.
           05  PARMFILE-STAT1                   PIC X.
           05  PARMFILE-STAT2                   PIC X.

       COPY CVACT01Y.
       01  ACCTFILE-STATUS.
           05  ACCTFILE-STAT1                   PIC X.
           05  ACCTFILE-STAT2                   PIC X.

       COPY CSMODBWY.

      *****************************************************************
      *    Db2 communication area and table declarations
      *****************************************************************
           EXEC SQL INCLUDE SQLCA END-EXEC.

           EXEC SQL INCLUDE DCLTRHST END-EXEC.

           EXEC SQL INCLUDE DCLACDBL END-EXEC.

      *    Host variables
       01  WS-HOST-VARIABLES.
           05  WS-PARM-DATE                     PIC X(10).
           05  WS-BAL-DATE                      PIC X(10).
           05  WS-DAY-CREDITS                   PIC S9(10)V9(2) COMP-3.
           05  WS-DAY-DEBITS                    PIC S9(10)V9(2) COMP-3.
           05  WS-DAY-NET                       PIC S9(10)V9(2) COMP-3.
           05  WS-DAY-COUNT                     PIC S9(9) COMP.
           05  WS-PREV-BAL-DATE                 PIC X(10).
           05  WS-IND-PREV-BAL-DATE             PIC S9(4) COMP.
           05  WS-PREV-CLOSE-BAL                PIC S9(10)V9(2) COMP-3.
           05  WS-LATER-NET                     PIC S9(10)V9(2) COMP-3.
           05  WS-IND-LATER-NET                 PIC S9(4) COMP.

      *****************************************************************
      *    Accounts with activity on the balance date, in account
      *    order. WITH HOLD keeps the cursor open across COMMIT.
      *****************************************************************
           EXEC SQL
                DECLARE C-DAY-ACTIVITY CURSOR WITH HOLD FOR
                SELECT TH_ACCT_ID
                     , SUM(CASE WHEN TH_AMT >= 0
                                THEN TH_AMT ELSE 0 END)
                     , SUM(CASE WHEN TH_AMT < 0
                                THEN TH_AMT ELSE 0 END)
                     , SUM(TH_AMT)
                     , COUNT(*)
                  FROM CARDDEMO.TRAN_HIST
                 WHERE TH_TRAN_DATE = :WS-BAL-DATE
                 GROUP BY TH_ACCT_ID
                 ORDER BY TH_ACCT_ID
           END-EXEC.

      *****************************************************************
       01  WS-FLAGS.
           05  WS-END-OF-CURSOR                 PIC X(01) VALUE 'N'.
               88  END-OF-CURSOR                          VALUE 'Y'.
           05  WS-ACCOUNT-STATE                 PIC X(01) VALUE 'N'.
               88  ACCOUNT-FOUND                          VALUE 'Y'.
               88  ACCOUNT-NOT-FOUND                      VALUE 'N'.

       01  WS-COUNTERS.
           05  WS-ACCOUNT-COUNT                 PIC 9(09) VALUE 0.
           05  WS-INSERT-COUNT                  PIC 9(09) VALUE 0.
           05  WS-UPDATE-COUNT                  PIC 9(09) VALUE 0.
           05  WS-SEEDED-COUNT                  PIC 9(09) VALUE 0.
           05  WS-NOT-FOUND-COUNT               PIC 9(09) VALUE 0.
           05  WS-UNCOMMITTED-COUNT             PIC 9(09) VALUE 0.
           05  WS-COMMIT-COUNT                  PIC 9(09) VALUE 0.

       01  WS-COMMIT-FREQUENCY                  PIC 9(09) VALUE 100.

       01  WS-ACCT-ID-DISPLAY                   PIC 9(11).

      *****************************************************************
       PROCEDURE DIVISION.
           DISPLAY 'START OF EXECUTION OF PROGRAM CBMOD02C'.
           PERFORM 0100-READ-PARMS.
           PERFORM 0200-VALIDATE-BAL-DATE.
           PERFORM 0300-ACCTFILE-OPEN.

           PERFORM 1000-OPEN-CURSOR.
           PERFORM 1100-FETCH-ACTIVITY.
           PERFORM UNTIL END-OF-CURSOR
               ADD 1 TO WS-ACCOUNT-COUNT
               PERFORM 2000-BUILD-DAILY-BALANCE
               PERFORM 2500-SAVE-DAILY-BALANCE
               PERFORM 1100-FETCH-ACTIVITY
           END-PERFORM.
           PERFORM 1200-CLOSE-CURSOR.

           PERFORM 3000-COMMIT-WORK.
           PERFORM 9300-ACCTFILE-CLOSE.

           DISPLAY 'BALANCE DATE             :' WS-BAL-DATE.
           DISPLAY 'ACCOUNTS WITH ACTIVITY   :' WS-ACCOUNT-COUNT.
           DISPLAY 'SNAPSHOTS INSERTED       :' WS-INSERT-COUNT.
           DISPLAY 'SNAPSHOTS REPLACED       :' WS-UPDATE-COUNT.
           DISPLAY 'SEEDED FROM ACCTDATA     :' WS-SEEDED-COUNT.
           DISPLAY 'ACCOUNTS NOT IN ACCTDATA :' WS-NOT-FOUND-COUNT.
           DISPLAY 'COMMITS ISSUED           :' WS-COMMIT-COUNT.
           IF WS-NOT-FOUND-COUNT > 0
              MOVE 4 TO RETURN-CODE
           END-IF.
           DISPLAY 'END OF EXECUTION OF PROGRAM CBMOD02C'.

           GOBACK.

      *---------------------------------------------------------------*
       0100-READ-PARMS.
           OPEN INPUT PARM-FILE
           IF PARMFILE-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING PARAMETER FILE'
              MOVE PARMFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF
           READ PARM-FILE INTO MODB-PARM-RECORD
           EVALUATE PARMFILE-STATUS
              WHEN '00'
                 CONTINUE
              WHEN '10'
                 DISPLAY 'PARAMETER FILE IS EMPTY'
                 MOVE 997 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
              WHEN OTHER
                 DISPLAY 'ERROR READING PARAMETER FILE'
                 MOVE PARMFILE-STATUS TO IO-STATUS
                 PERFORM 9910-DISPLAY-IO-STATUS
                 MOVE 999 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
           END-EVALUATE
           CLOSE PARM-FILE
           MOVE MODB-PARM-START-DATE TO WS-PARM-DATE.
      *---------------------------------------------------------------*
      * Let Db2 check the date and return it in ISO form.
      *---------------------------------------------------------------*
       0200-VALIDATE-BAL-DATE.
           EXEC SQL
                SELECT CHAR(DATE(:WS-PARM-DATE), ISO)
                  INTO :WS-BAL-DATE
                  FROM SYSIBM.SYSDUMMY1
           END-EXEC
           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN SQLCODE = -180
              WHEN SQLCODE = -181
                 DISPLAY 'INVALID BALANCE DATE IN PARMFILE: '
                         WS-PARM-DATE
                 MOVE 997 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
              WHEN OTHER
                 MOVE 'VALIDATE BALANCE DATE' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE.
      *---------------------------------------------------------------*
       0300-ACCTFILE-OPEN.
           OPEN INPUT ACCOUNT-FILE
           IF ACCTFILE-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING ACCOUNT FILE'
              MOVE ACCTFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       1000-OPEN-CURSOR.
           EXEC SQL
                OPEN C-DAY-ACTIVITY
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'OPEN CURSOR C-DAY-ACTIVITY' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF.
      *---------------------------------------------------------------*
       1100-FETCH-ACTIVITY.
           EXEC SQL
                FETCH C-DAY-ACTIVITY
                 INTO :DCL-TH-ACCT-ID
                    , :WS-DAY-CREDITS
                    , :WS-DAY-DEBITS
                    , :WS-DAY-NET
                    , :WS-DAY-COUNT
           END-EXEC
           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN SQLCODE = +100
                 SET END-OF-CURSOR TO TRUE
              WHEN OTHER
                 MOVE 'FETCH CURSOR C-DAY-ACTIVITY' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE.
      *---------------------------------------------------------------*
       1200-CLOSE-CURSOR.
           EXEC SQL
                CLOSE C-DAY-ACTIVITY
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'CLOSE CURSOR C-DAY-ACTIVITY' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF.
      *---------------------------------------------------------------*
       2000-BUILD-DAILY-BALANCE.
      *    Credit limit, and the seed balance, come from ACCTDATA
           MOVE DCL-TH-ACCT-ID TO FD-ACCT-ID
           READ ACCOUNT-FILE INTO ACCOUNT-RECORD
              INVALID KEY
                 CONTINUE
           END-READ
           EVALUATE ACCTFILE-STATUS
              WHEN '00'
                 SET ACCOUNT-FOUND TO TRUE
              WHEN '23'
                 SET ACCOUNT-NOT-FOUND TO TRUE
                 ADD 1 TO WS-NOT-FOUND-COUNT
                 MOVE DCL-TH-ACCT-ID TO WS-ACCT-ID-DISPLAY
                 DISPLAY 'ACCOUNT NOT FOUND IN ACCTDATA: '
                         WS-ACCT-ID-DISPLAY
              WHEN OTHER
                 DISPLAY 'ERROR READING ACCOUNT FILE'
                 MOVE ACCTFILE-STATUS TO IO-STATUS
                 PERFORM 9910-DISPLAY-IO-STATUS
                 MOVE 999 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
           END-EVALUATE

      *    Date of the latest earlier snapshot. MAX returns NULL
      *    when there is none.
           EXEC SQL
                SELECT MAX(ADB_BAL_DATE)
                  INTO :WS-PREV-BAL-DATE :WS-IND-PREV-BAL-DATE
                  FROM CARDDEMO.ACCT_DAILY_BAL
                 WHERE ADB_ACCT_ID  = :DCL-TH-ACCT-ID
                   AND ADB_BAL_DATE < :WS-BAL-DATE
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'SELECT MAX(ADB_BAL_DATE)' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF

           IF WS-IND-PREV-BAL-DATE < 0
      *       No earlier snapshot. The ACCTDATA current balance
      *       already includes every loaded transaction: the day's
      *       postings, and interest from INTCALC, which is dated
      *       when INTCALC ran. Back out everything dated on or after
      *       the balance date.
              IF ACCOUNT-FOUND
                 PERFORM 2100-SUM-LATER-ACTIVITY
                 COMPUTE DCL-ADB-OPEN-BAL =
                         ACCT-CURR-BAL - WS-LATER-NET
              ELSE
                 MOVE ZERO TO DCL-ADB-OPEN-BAL
              END-IF
              ADD 1 TO WS-SEEDED-COUNT
           ELSE
              EXEC SQL
                   SELECT ADB_CLOSE_BAL
                     INTO :WS-PREV-CLOSE-BAL
                     FROM CARDDEMO.ACCT_DAILY_BAL
                    WHERE ADB_ACCT_ID  = :DCL-TH-ACCT-ID
                      AND ADB_BAL_DATE = :WS-PREV-BAL-DATE
              END-EXEC
              IF SQLCODE NOT = ZERO
                 MOVE 'SELECT PREVIOUS ADB_CLOSE_BAL' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
              END-IF
              MOVE WS-PREV-CLOSE-BAL TO DCL-ADB-OPEN-BAL
           END-IF

           MOVE DCL-TH-ACCT-ID          TO DCL-ADB-ACCT-ID
           MOVE WS-BAL-DATE             TO DCL-ADB-BAL-DATE
           MOVE WS-DAY-CREDITS          TO DCL-ADB-CREDIT-AMT
           MOVE WS-DAY-DEBITS           TO DCL-ADB-DEBIT-AMT
           COMPUTE DCL-ADB-CLOSE-BAL = DCL-ADB-OPEN-BAL + WS-DAY-NET
           MOVE WS-DAY-COUNT            TO DCL-ADB-TRAN-CNT
           IF ACCOUNT-FOUND
              MOVE ACCT-CREDIT-LIMIT    TO DCL-ADB-CREDIT-LIMIT
           ELSE
              MOVE ZERO                 TO DCL-ADB-CREDIT-LIMIT
           END-IF.
      *---------------------------------------------------------------*
      * Net of the account's TRAN_HIST amounts dated on or after the
      * balance date. SUM returns NULL when there are no rows.
      *---------------------------------------------------------------*
       2100-SUM-LATER-ACTIVITY.
           EXEC SQL
                SELECT SUM(TH_AMT)
                  INTO :WS-LATER-NET :WS-IND-LATER-NET
                  FROM CARDDEMO.TRAN_HIST
                 WHERE TH_ACCT_ID    = :DCL-TH-ACCT-ID
                   AND TH_TRAN_DATE >= :WS-BAL-DATE
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'SELECT SUM(TH_AMT) ON OR AFTER DATE'
                TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF
           IF WS-IND-LATER-NET < 0
              MOVE ZERO TO WS-LATER-NET
           END-IF.
      *---------------------------------------------------------------*
       2500-SAVE-DAILY-BALANCE.
           EXEC SQL
                INSERT INTO CARDDEMO.ACCT_DAILY_BAL
                     ( ADB_ACCT_ID
                     , ADB_BAL_DATE
                     , ADB_OPEN_BAL
                     , ADB_CREDIT_AMT
                     , ADB_DEBIT_AMT
                     , ADB_CLOSE_BAL
                     , ADB_TRAN_CNT
                     , ADB_CREDIT_LIMIT
                     , ADB_OVERLIMIT_FLG
                     , ADB_FLAG_DATE
                     )
                VALUES
                     ( :DCL-ADB-ACCT-ID
                     , :DCL-ADB-BAL-DATE
                     , :DCL-ADB-OPEN-BAL
                     , :DCL-ADB-CREDIT-AMT
                     , :DCL-ADB-DEBIT-AMT
                     , :DCL-ADB-CLOSE-BAL
                     , :DCL-ADB-TRAN-CNT
                     , :DCL-ADB-CREDIT-LIMIT
                     , 'N'
                     , NULL
                     )
           END-EXEC

           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 ADD 1 TO WS-INSERT-COUNT
              WHEN SQLCODE = -803
      *          Rerun for the same date: replace the snapshot
                 PERFORM 2600-REPLACE-DAILY-BALANCE
              WHEN OTHER
                 MOVE 'INSERT INTO CARDDEMO.ACCT_DAILY_BAL'
                   TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE

           ADD 1 TO WS-UNCOMMITTED-COUNT
           IF WS-UNCOMMITTED-COUNT >= WS-COMMIT-FREQUENCY
              PERFORM 3000-COMMIT-WORK
           END-IF.
      *---------------------------------------------------------------*
       2600-REPLACE-DAILY-BALANCE.
           EXEC SQL
                UPDATE CARDDEMO.ACCT_DAILY_BAL
                   SET ADB_OPEN_BAL      = :DCL-ADB-OPEN-BAL
                     , ADB_CREDIT_AMT    = :DCL-ADB-CREDIT-AMT
                     , ADB_DEBIT_AMT     = :DCL-ADB-DEBIT-AMT
                     , ADB_CLOSE_BAL     = :DCL-ADB-CLOSE-BAL
                     , ADB_TRAN_CNT      = :DCL-ADB-TRAN-CNT
                     , ADB_CREDIT_LIMIT  = :DCL-ADB-CREDIT-LIMIT
                     , ADB_OVERLIMIT_FLG = 'N'
                     , ADB_FLAG_DATE     = NULL
                 WHERE ADB_ACCT_ID  = :DCL-ADB-ACCT-ID
                   AND ADB_BAL_DATE = :DCL-ADB-BAL-DATE
           END-EXEC
           IF SQLCODE = ZERO
              ADD 1 TO WS-UPDATE-COUNT
           ELSE
              MOVE 'UPDATE CARDDEMO.ACCT_DAILY_BAL' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF.
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
       9300-ACCTFILE-CLOSE.
           CLOSE ACCOUNT-FILE
           IF ACCTFILE-STATUS NOT = '00'
              DISPLAY 'ERROR CLOSING ACCOUNT FILE'
              MOVE ACCTFILE-STATUS TO IO-STATUS
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
