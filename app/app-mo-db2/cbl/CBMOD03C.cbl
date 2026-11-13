      ******************************************************************
      * Program     : CBMOD03C.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : BATCH COBOL Db2 Program (TSO attach)
      * Function    : Print the transaction history report for the
      *               date range in DD PARMFILE (cols 1-10 start date,
      *               cols 12-21 end date) to DD REPTFILE.
      *               - Reads CARDDEMO.TRAN_HIST outer joined to
      *                 CARDDEMO.ACCT_DAILY_BAL for the end date, so
      *                 each account shows that day's closing balance
      *                 and credit limit, or says it has no balance
      *               - Looks up type and category names in the base
      *                 CardDemo TRANTYPE and TRANCATG VSAM files; a
      *                 code that is not there prints as UNKNOWN
      *               - One detail line per transaction, ordered by
      *                 account, type, category and transaction id
      *               - Subtotals per type within account, totals per
      *                 account and a grand total
      *               Read only.
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
       PROGRAM-ID.    CBMOD03C.
       AUTHOR.        MECHANICAL ORCHARD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PARM-FILE ASSIGN TO PARMFILE
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS PARMFILE-STATUS.

           SELECT REPORT-FILE ASSIGN TO REPTFILE
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS REPTFILE-STATUS.

           SELECT TRANTYPE-FILE ASSIGN TO TRANTYPE
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS RANDOM
                  RECORD KEY   IS FD-TRAN-TYPE
                  FILE STATUS  IS TRANTYPE-STATUS.

           SELECT TRANCATG-FILE ASSIGN TO TRANCATG
                  ORGANIZATION IS INDEXED
                  ACCESS MODE  IS RANDOM
                  RECORD KEY   IS FD-TRAN-CAT-KEY
                  FILE STATUS  IS TRANCATG-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  PARM-FILE.
       01  FD-PARM-REC                          PIC X(80).

       FD  REPORT-FILE.
       01  FD-REPTFILE-REC                      PIC X(133).

       FD  TRANTYPE-FILE.
       01  FD-TRANTYPE-REC.
           05 FD-TRAN-TYPE                      PIC X(02).
           05 FD-TRAN-TYPE-DATA                 PIC X(58).

       FD  TRANCATG-FILE.
       01  FD-TRAN-CAT-RECORD.
           05 FD-TRAN-CAT-KEY.
              10 FD-TRAN-TYPE-CD                PIC X(02).
              10 FD-TRAN-CAT-CD                 PIC 9(04).
           05 FD-TRAN-CAT-DATA                  PIC X(54).

       WORKING-STORAGE SECTION.

      *****************************************************************
       COPY CVMOD01Y.
       01  PARMFILE-STATUS.
           05  PARMFILE-STAT1                   PIC X.
           05  PARMFILE-STAT2                   PIC X.

       COPY CVMOD03Y.
       01  REPTFILE-STATUS.
           05  REPTFILE-STAT1                   PIC X.
           05  REPTFILE-STAT2                   PIC X.

       COPY CVTRA03Y.
       01  TRANTYPE-STATUS.
           05  TRANTYPE-STAT1                   PIC X.
           05  TRANTYPE-STAT2                   PIC X.

       COPY CVTRA04Y.
       01  TRANCATG-STATUS.
           05  TRANCATG-STAT1                   PIC X.
           05  TRANCATG-STAT2                   PIC X.

       COPY CSMODBWY.

      *****************************************************************
      *    Db2 communication area and table declaration
      *****************************************************************
           EXEC SQL INCLUDE SQLCA END-EXEC.

           EXEC SQL INCLUDE DCLTRHST END-EXEC.

           EXEC SQL INCLUDE DCLACDBL END-EXEC.

      *    Host variables
       01  WS-HOST-VARIABLES.
           05  WS-PARM-START-DATE               PIC X(10).
           05  WS-PARM-END-DATE                 PIC X(10).
           05  WS-START-DATE                    PIC X(10).
           05  WS-END-DATE                      PIC X(10).
           05  WS-MERCHANT.
               49  WS-MERCHANT-LEN              PIC S9(4) COMP.
               49  WS-MERCHANT-TEXT             PIC X(50).
           05  WS-IND-CLOSE-BAL                 PIC S9(4) COMP.
           05  WS-IND-CREDIT-LIMIT              PIC S9(4) COMP.

      *****************************************************************
      *    Transactions in the date range, each with its account's
      *    daily balance row for the end date. LEFT OUTER JOIN keeps
      *    the transaction when there is no balance row; the balance
      *    columns are then NULL. Read only.
      *****************************************************************
           EXEC SQL
                DECLARE C-REPORT CURSOR FOR
                SELECT H.TH_ACCT_ID
                     , H.TH_TYPE_CD
                     , H.TH_CAT_CD
                     , H.TH_TRAN_ID
                     , H.TH_TRAN_DATE
                     , H.TH_AMT
                     , COALESCE(H.TH_MERCHANT_NAME, '-')
                     , B.ADB_CLOSE_BAL
                     , B.ADB_CREDIT_LIMIT
                  FROM CARDDEMO.TRAN_HIST H
                  LEFT OUTER JOIN CARDDEMO.ACCT_DAILY_BAL B
                    ON B.ADB_ACCT_ID  = H.TH_ACCT_ID
                   AND B.ADB_BAL_DATE = :WS-END-DATE
                 WHERE H.TH_TRAN_DATE BETWEEN :WS-START-DATE
                                          AND :WS-END-DATE
                 ORDER BY H.TH_ACCT_ID
                        , H.TH_TYPE_CD
                        , H.TH_CAT_CD
                        , H.TH_TRAN_ID
                 FOR READ ONLY
           END-EXEC.

      *****************************************************************
       01  WS-FLAGS.
           05  WS-END-OF-CURSOR                 PIC X(01) VALUE 'N'.
               88  END-OF-CURSOR                          VALUE 'Y'.

       01  WS-CONTROL-FIELDS.
           05  WS-CURR-ACCT-ID                  PIC S9(11) COMP-3.
           05  WS-CURR-TYPE-CD                  PIC X(02).

      *    Daily balance of the current account, from its first row
       01  WS-ACCT-BALANCE.
           05  WS-ACCT-BAL-STATE                PIC X(01).
               88  ACCT-HAS-BALANCE                       VALUE 'Y'.
               88  ACCT-HAS-NO-BALANCE                    VALUE 'N'.
           05  WS-ACCT-CLOSE-BAL                PIC S9(10)V99 COMP-3.
           05  WS-ACCT-CREDIT-LIMIT             PIC S9(10)V99 COMP-3.

      *    Last name looked up, so rows sorted by type and category
      *    read each VSAM record once per run of equal codes
       01  WS-LOOKUP-FIELDS.
           05  WS-LAST-TYPE-CD                  PIC X(02)
                                                VALUE LOW-VALUES.
           05  WS-LAST-TYPE-DESC                PIC X(50).
           05  WS-LAST-CAT-KEY.
               10  WS-LAST-CAT-TYPE-CD          PIC X(02)
                                                VALUE LOW-VALUES.
               10  WS-LAST-CAT-CD               PIC X(04)
                                                VALUE LOW-VALUES.
           05  WS-LAST-CAT-DESC                 PIC X(50).

       01  WS-COUNTERS.
           05  WS-ROW-COUNT                     PIC 9(09) VALUE 0.
           05  WS-ACCT-COUNT                    PIC 9(09) VALUE 0.
           05  WS-ACCT-TRAN-COUNT               PIC 9(09) VALUE 0.
           05  WS-TYPE-TRAN-COUNT               PIC 9(09) VALUE 0.
           05  WS-LINE-COUNT                    PIC 9(09) VALUE 0.
           05  WS-BAL-FOUND-COUNT               PIC 9(09) VALUE 0.
           05  WS-BAL-MISSING-COUNT             PIC 9(09) VALUE 0.

       01  WS-TOTALS.
           05  WS-TYPE-TOTAL                    PIC S9(11)V99 COMP-3
                                                VALUE 0.
           05  WS-ACCT-TOTAL                    PIC S9(11)V99 COMP-3
                                                VALUE 0.
           05  WS-GRAND-TOTAL                   PIC S9(11)V99 COMP-3
                                                VALUE 0.

       01  WS-ACCT-ID-DISPLAY                   PIC 9(11).

      *****************************************************************
       PROCEDURE DIVISION.
           DISPLAY 'START OF EXECUTION OF PROGRAM CBMOD03C'.
           PERFORM 0100-READ-PARMS.
           PERFORM 0200-VALIDATE-DATES.
           PERFORM 0300-REPTFILE-OPEN.
           PERFORM 0400-TRANTYPE-OPEN.
           PERFORM 0500-TRANCATG-OPEN.
           PERFORM 1000-WRITE-HEADERS.

           PERFORM 1100-OPEN-CURSOR.
           PERFORM 1200-FETCH-ROW.
           IF END-OF-CURSOR
              MOVE MODB-RPT-NO-DATA-LINE TO FD-REPTFILE-REC
              PERFORM 1900-WRITE-LINE
           END-IF.
           PERFORM UNTIL END-OF-CURSOR
               PERFORM 2000-PROCESS-ROW
               PERFORM 1200-FETCH-ROW
           END-PERFORM.
           PERFORM 1300-CLOSE-CURSOR.

           IF WS-ROW-COUNT > 0
              PERFORM 2300-END-TYPE
              PERFORM 2400-END-ACCOUNT
           END-IF.
           PERFORM 2600-WRITE-GRAND-TOTAL.

           PERFORM 9300-REPTFILE-CLOSE.
           PERFORM 9400-TRANTYPE-CLOSE.
           PERFORM 9500-TRANCATG-CLOSE.

           DISPLAY 'REPORT START DATE        :' WS-START-DATE.
           DISPLAY 'REPORT END DATE          :' WS-END-DATE.
           DISPLAY 'TRANSACTIONS REPORTED    :' WS-ROW-COUNT.
           DISPLAY 'ACCOUNTS REPORTED        :' WS-ACCT-COUNT.
           DISPLAY 'ACCOUNTS WITH BALANCE    :' WS-BAL-FOUND-COUNT.
           DISPLAY 'ACCOUNTS WITHOUT BALANCE :' WS-BAL-MISSING-COUNT.
           DISPLAY 'REPORT LINES WRITTEN     :' WS-LINE-COUNT.
           DISPLAY 'END OF EXECUTION OF PROGRAM CBMOD03C'.

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
           MOVE MODB-PARM-START-DATE TO WS-PARM-START-DATE
           MOVE MODB-PARM-END-DATE   TO WS-PARM-END-DATE.
      *---------------------------------------------------------------*
      * Let Db2 check both dates and return them in ISO form.
      *---------------------------------------------------------------*
       0200-VALIDATE-DATES.
           EXEC SQL
                SELECT CHAR(DATE(:WS-PARM-START-DATE), ISO)
                     , CHAR(DATE(:WS-PARM-END-DATE), ISO)
                  INTO :WS-START-DATE
                     , :WS-END-DATE
                  FROM SYSIBM.SYSDUMMY1
           END-EXEC
           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN SQLCODE = -180
              WHEN SQLCODE = -181
                 DISPLAY 'INVALID REPORT DATE IN PARMFILE: '
                         WS-PARM-START-DATE ' ' WS-PARM-END-DATE
                 MOVE 997 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
              WHEN OTHER
                 MOVE 'VALIDATE REPORT DATES' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE
           IF WS-END-DATE < WS-START-DATE
              DISPLAY 'REPORT END DATE IS BEFORE START DATE: '
                      WS-START-DATE ' ' WS-END-DATE
              MOVE 997 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       0300-REPTFILE-OPEN.
           OPEN OUTPUT REPORT-FILE
           IF REPTFILE-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING REPORT FILE'
              MOVE REPTFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       0400-TRANTYPE-OPEN.
           OPEN INPUT TRANTYPE-FILE
           IF TRANTYPE-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING TRANSACTION TYPE FILE'
              MOVE TRANTYPE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       0500-TRANCATG-OPEN.
           OPEN INPUT TRANCATG-FILE
           IF TRANCATG-STATUS NOT = '00'
              DISPLAY 'ERROR OPENING TRANSACTION CATEGORY FILE'
              MOVE TRANCATG-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       1000-WRITE-HEADERS.
           MOVE WS-START-DATE TO MODB-RPT-H-START-DATE
           MOVE WS-END-DATE   TO MODB-RPT-H-END-DATE
           MOVE MODB-RPT-HEADER-1 TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE
           MOVE MODB-RPT-BLANK-LINE TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE
           MOVE MODB-RPT-HEADER-2 TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE
           MOVE MODB-RPT-HEADER-3 TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE.
      *---------------------------------------------------------------*
       1100-OPEN-CURSOR.
           EXEC SQL
                OPEN C-REPORT
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'OPEN CURSOR C-REPORT' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF.
      *---------------------------------------------------------------*
       1200-FETCH-ROW.
           EXEC SQL
                FETCH C-REPORT
                 INTO :DCL-TH-ACCT-ID
                    , :DCL-TH-TYPE-CD
                    , :DCL-TH-CAT-CD
                    , :DCL-TH-TRAN-ID
                    , :DCL-TH-TRAN-DATE
                    , :DCL-TH-AMT
                    , :WS-MERCHANT
                    , :DCL-ADB-CLOSE-BAL    :WS-IND-CLOSE-BAL
                    , :DCL-ADB-CREDIT-LIMIT :WS-IND-CREDIT-LIMIT
           END-EXEC
           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN SQLCODE = +100
                 SET END-OF-CURSOR TO TRUE
              WHEN OTHER
                 MOVE 'FETCH CURSOR C-REPORT' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE.
      *---------------------------------------------------------------*
       1300-CLOSE-CURSOR.
           EXEC SQL
                CLOSE C-REPORT
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'CLOSE CURSOR C-REPORT' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF.
      *---------------------------------------------------------------*
       1900-WRITE-LINE.
           WRITE FD-REPTFILE-REC
           IF REPTFILE-STATUS NOT = '00'
              DISPLAY 'ERROR WRITING REPORT FILE'
              MOVE REPTFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF
           ADD 1 TO WS-LINE-COUNT.
      *---------------------------------------------------------------*
      * Control breaks: a new account ends the current type and
      * account; a new type within the account ends the current type.
      *---------------------------------------------------------------*
       2000-PROCESS-ROW.
           IF WS-ROW-COUNT = 0
              PERFORM 2100-START-ACCOUNT
           ELSE
              IF DCL-TH-ACCT-ID NOT = WS-CURR-ACCT-ID
                 PERFORM 2300-END-TYPE
                 PERFORM 2400-END-ACCOUNT
                 PERFORM 2100-START-ACCOUNT
              ELSE
                 IF DCL-TH-TYPE-CD NOT = WS-CURR-TYPE-CD
                    PERFORM 2300-END-TYPE
                    PERFORM 2200-START-TYPE
                 END-IF
              END-IF
           END-IF
           PERFORM 2500-WRITE-DETAIL
           ADD 1 TO WS-ROW-COUNT.
      *---------------------------------------------------------------*
       2100-START-ACCOUNT.
           MOVE DCL-TH-ACCT-ID TO WS-CURR-ACCT-ID
           ADD 1 TO WS-ACCT-COUNT
           MOVE 0 TO WS-ACCT-TOTAL
           MOVE 0 TO WS-ACCT-TRAN-COUNT
           MOVE DCL-TH-ACCT-ID TO WS-ACCT-ID-DISPLAY
           MOVE WS-ACCT-ID-DISPLAY TO MODB-RPT-A-ACCT-ID
           MOVE MODB-RPT-BLANK-LINE TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE
           MOVE MODB-RPT-ACCOUNT-LINE TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE
      *    Every row of the account carries the same balance columns
           IF WS-IND-CLOSE-BAL < 0
              SET ACCT-HAS-NO-BALANCE TO TRUE
              ADD 1 TO WS-BAL-MISSING-COUNT
           ELSE
              SET ACCT-HAS-BALANCE TO TRUE
              MOVE DCL-ADB-CLOSE-BAL    TO WS-ACCT-CLOSE-BAL
              MOVE DCL-ADB-CREDIT-LIMIT TO WS-ACCT-CREDIT-LIMIT
              ADD 1 TO WS-BAL-FOUND-COUNT
           END-IF
           PERFORM 2200-START-TYPE.
      *---------------------------------------------------------------*
       2200-START-TYPE.
           MOVE DCL-TH-TYPE-CD TO WS-CURR-TYPE-CD
           MOVE 0 TO WS-TYPE-TOTAL
           MOVE 0 TO WS-TYPE-TRAN-COUNT.
      *---------------------------------------------------------------*
       2300-END-TYPE.
           MOVE WS-CURR-TYPE-CD    TO MODB-RPT-T-TYPE-CD
           MOVE WS-TYPE-TRAN-COUNT TO MODB-RPT-T-COUNT
           MOVE WS-TYPE-TOTAL      TO MODB-RPT-T-AMT
           MOVE MODB-RPT-TYPE-TOTAL TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE.
      *---------------------------------------------------------------*
       2400-END-ACCOUNT.
           MOVE WS-ACCT-TRAN-COUNT TO MODB-RPT-AT-COUNT
           MOVE WS-ACCT-TOTAL      TO MODB-RPT-AT-AMT
           MOVE MODB-RPT-ACCOUNT-TOTAL TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE
           IF ACCT-HAS-BALANCE
              MOVE WS-END-DATE          TO MODB-RPT-B-DATE
              MOVE WS-ACCT-CLOSE-BAL    TO MODB-RPT-B-CLOSE-BAL
              MOVE WS-ACCT-CREDIT-LIMIT TO MODB-RPT-B-LIMIT
              MOVE MODB-RPT-BALANCE-LINE TO FD-REPTFILE-REC
           ELSE
              MOVE WS-END-DATE          TO MODB-RPT-NB-DATE
              MOVE MODB-RPT-NO-BALANCE-LINE TO FD-REPTFILE-REC
           END-IF
           PERFORM 1900-WRITE-LINE.
      *---------------------------------------------------------------*
      * The merchant VARCHAR text past its length can hold data from
      * an earlier fetch, so only the first LEN bytes are used.
      *---------------------------------------------------------------*
       2500-WRITE-DETAIL.
           MOVE DCL-TH-TRAN-ID     TO MODB-RPT-D-TRAN-ID
           MOVE DCL-TH-TRAN-DATE   TO MODB-RPT-D-TRAN-DATE
           MOVE DCL-TH-TYPE-CD     TO MODB-RPT-D-TYPE-CD
           MOVE DCL-TH-CAT-CD      TO MODB-RPT-D-CAT-CD
           MOVE DCL-TH-AMT         TO MODB-RPT-D-AMT

           PERFORM 2700-LOOKUP-TRANTYPE
           MOVE WS-LAST-TYPE-DESC  TO MODB-RPT-D-TYPE-DESC
           PERFORM 2800-LOOKUP-TRANCATG
           MOVE WS-LAST-CAT-DESC   TO MODB-RPT-D-CAT-DESC

           MOVE SPACES TO MODB-RPT-D-MERCHANT
           IF WS-MERCHANT-LEN > 0
              MOVE WS-MERCHANT-TEXT(1:WS-MERCHANT-LEN)
                TO MODB-RPT-D-MERCHANT
           END-IF

           MOVE MODB-RPT-DETAIL-LINE TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE

           ADD DCL-TH-AMT TO WS-TYPE-TOTAL
           ADD DCL-TH-AMT TO WS-ACCT-TOTAL
           ADD DCL-TH-AMT TO WS-GRAND-TOTAL
           ADD 1 TO WS-TYPE-TRAN-COUNT
           ADD 1 TO WS-ACCT-TRAN-COUNT.
      *---------------------------------------------------------------*
       2600-WRITE-GRAND-TOTAL.
           MOVE MODB-RPT-BLANK-LINE TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE
           MOVE WS-ACCT-COUNT  TO MODB-RPT-G-ACCT-COUNT
           MOVE WS-ROW-COUNT   TO MODB-RPT-G-TRAN-COUNT
           MOVE WS-GRAND-TOTAL TO MODB-RPT-G-AMT
           MOVE MODB-RPT-GRAND-TOTAL TO FD-REPTFILE-REC
           PERFORM 1900-WRITE-LINE.
      *---------------------------------------------------------------*
      * Type name from the TRANTYPE VSAM file, read only when the
      * type code changes.
      *---------------------------------------------------------------*
       2700-LOOKUP-TRANTYPE.
           IF DCL-TH-TYPE-CD NOT = WS-LAST-TYPE-CD
              MOVE DCL-TH-TYPE-CD TO WS-LAST-TYPE-CD
              MOVE DCL-TH-TYPE-CD TO FD-TRAN-TYPE
              READ TRANTYPE-FILE INTO TRAN-TYPE-RECORD
                 INVALID KEY
                    CONTINUE
              END-READ
              EVALUATE TRANTYPE-STATUS
                 WHEN '00'
                    MOVE TRAN-TYPE-DESC TO WS-LAST-TYPE-DESC
                 WHEN '23'
                    MOVE 'UNKNOWN TYPE' TO WS-LAST-TYPE-DESC
                 WHEN OTHER
                    DISPLAY 'ERROR READING TRANSACTION TYPE FILE'
                    MOVE TRANTYPE-STATUS TO IO-STATUS
                    PERFORM 9910-DISPLAY-IO-STATUS
                    MOVE 999 TO ABCODE
                    PERFORM 9999-ABEND-PROGRAM
              END-EVALUATE
           END-IF.
      *---------------------------------------------------------------*
      * Category name from the TRANCATG VSAM file, read only when the
      * type and category codes change.
      *---------------------------------------------------------------*
       2800-LOOKUP-TRANCATG.
           IF DCL-TH-TYPE-CD NOT = WS-LAST-CAT-TYPE-CD
           OR DCL-TH-CAT-CD  NOT = WS-LAST-CAT-CD
              MOVE DCL-TH-TYPE-CD TO WS-LAST-CAT-TYPE-CD
              MOVE DCL-TH-CAT-CD  TO WS-LAST-CAT-CD
              MOVE DCL-TH-TYPE-CD TO FD-TRAN-TYPE-CD
              MOVE DCL-TH-CAT-CD  TO FD-TRAN-CAT-CD
              READ TRANCATG-FILE INTO TRAN-CAT-RECORD
                 INVALID KEY
                    CONTINUE
              END-READ
              EVALUATE TRANCATG-STATUS
                 WHEN '00'
                    MOVE TRAN-CAT-TYPE-DESC TO WS-LAST-CAT-DESC
                 WHEN '23'
                    MOVE 'UNKNOWN CATEGORY' TO WS-LAST-CAT-DESC
                 WHEN OTHER
                    DISPLAY 'ERROR READING TRANSACTION CATEGORY FILE'
                    MOVE TRANCATG-STATUS TO IO-STATUS
                    PERFORM 9910-DISPLAY-IO-STATUS
                    MOVE 999 TO ABCODE
                    PERFORM 9999-ABEND-PROGRAM
              END-EVALUATE
           END-IF.
      *---------------------------------------------------------------*
       9300-REPTFILE-CLOSE.
           CLOSE REPORT-FILE
           IF REPTFILE-STATUS NOT = '00'
              DISPLAY 'ERROR CLOSING REPORT FILE'
              MOVE REPTFILE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       9400-TRANTYPE-CLOSE.
           CLOSE TRANTYPE-FILE
           IF TRANTYPE-STATUS NOT = '00'
              DISPLAY 'ERROR CLOSING TRANSACTION TYPE FILE'
              MOVE TRANTYPE-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
       9500-TRANCATG-CLOSE.
           CLOSE TRANCATG-FILE
           IF TRANCATG-STATUS NOT = '00'
              DISPLAY 'ERROR CLOSING TRANSACTION CATEGORY FILE'
              MOVE TRANCATG-STATUS TO IO-STATUS
              PERFORM 9910-DISPLAY-IO-STATUS
              MOVE 999 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF.
      *---------------------------------------------------------------*
      * Report the SQL error and abend. Read only, but ROLLBACK
      * releases any locks before the abend.
      *---------------------------------------------------------------*
       9800-SQL-ERROR.
           PERFORM 9810-DISPLAY-SQL-ERROR
           EXEC SQL
                ROLLBACK
           END-EXEC
           MOVE 998 TO ABCODE
           PERFORM 9999-ABEND-PROGRAM.

       COPY CSMODBPY.
