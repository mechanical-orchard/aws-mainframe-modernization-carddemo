      ******************************************************************
      * Program     : CBMOD03C.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : BATCH COBOL Db2 Program (TSO attach)
      * Function    : Print the transaction history report for the
      *               date range in DD PARMFILE (cols 1-10 start date,
      *               cols 12-21 end date) to DD REPTFILE.
      *               - Reads CARDDEMO.TRAN_HIST joined to the
      *                 TRANSACTION_TYPE and TRANSACTION_TYPE_CATEGORY
      *                 tables of app-transaction-type-db2
      *               - Outer joins, so a missing type or category
      *                 prints as UNKNOWN instead of dropping the row
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
      *
       DATA DIVISION.
       FILE SECTION.
       FD  PARM-FILE.
       01  FD-PARM-REC                          PIC X(80).

       FD  REPORT-FILE.
       01  FD-REPTFILE-REC                      PIC X(133).

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

       COPY CSMODBWY.

      *****************************************************************
      *    Db2 communication area and table declaration
      *****************************************************************
           EXEC SQL INCLUDE SQLCA END-EXEC.

           EXEC SQL INCLUDE DCLTRHST END-EXEC.

      *    Host variables
       01  WS-HOST-VARIABLES.
           05  WS-PARM-START-DATE               PIC X(10).
           05  WS-PARM-END-DATE                 PIC X(10).
           05  WS-START-DATE                    PIC X(10).
           05  WS-END-DATE                      PIC X(10).
           05  WS-MERCHANT.
               49  WS-MERCHANT-LEN              PIC S9(4) COMP.
               49  WS-MERCHANT-TEXT             PIC X(50).
           05  WS-TYPE-DESC.
               49  WS-TYPE-DESC-LEN             PIC S9(4) COMP.
               49  WS-TYPE-DESC-TEXT            PIC X(50).
           05  WS-IND-TYPE-DESC                 PIC S9(4) COMP.
           05  WS-CAT-DESC.
               49  WS-CAT-DESC-LEN              PIC S9(4) COMP.
               49  WS-CAT-DESC-TEXT             PIC X(50).
           05  WS-IND-CAT-DESC                  PIC S9(4) COMP.

      *****************************************************************
      *    Transactions in the date range with their type and
      *    category descriptions. Read only.
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
                     , T.TR_DESCRIPTION
                     , C.TRC_CAT_DATA
                  FROM CARDDEMO.TRAN_HIST H
                  LEFT OUTER JOIN CARDDEMO.TRANSACTION_TYPE T
                    ON T.TR_TYPE = H.TH_TYPE_CD
                  LEFT OUTER JOIN CARDDEMO.TRANSACTION_TYPE_CATEGORY C
                    ON C.TRC_TYPE_CODE     = H.TH_TYPE_CD
                   AND C.TRC_TYPE_CATEGORY = H.TH_CAT_CD
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

       01  WS-COUNTERS.
           05  WS-ROW-COUNT                     PIC 9(09) VALUE 0.
           05  WS-ACCT-COUNT                    PIC 9(09) VALUE 0.
           05  WS-ACCT-TRAN-COUNT               PIC 9(09) VALUE 0.
           05  WS-TYPE-TRAN-COUNT               PIC 9(09) VALUE 0.
           05  WS-LINE-COUNT                    PIC 9(09) VALUE 0.

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

           DISPLAY 'REPORT START DATE        :' WS-START-DATE.
           DISPLAY 'REPORT END DATE          :' WS-END-DATE.
           DISPLAY 'TRANSACTIONS REPORTED    :' WS-ROW-COUNT.
           DISPLAY 'ACCOUNTS REPORTED        :' WS-ACCT-COUNT.
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
                    , :WS-TYPE-DESC :WS-IND-TYPE-DESC
                    , :WS-CAT-DESC  :WS-IND-CAT-DESC
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
           PERFORM 1900-WRITE-LINE.
      *---------------------------------------------------------------*
      * VARCHAR text past its length can hold data from an earlier
      * fetch, so only the first LEN bytes are used.
      *---------------------------------------------------------------*
       2500-WRITE-DETAIL.
           MOVE DCL-TH-TRAN-ID     TO MODB-RPT-D-TRAN-ID
           MOVE DCL-TH-TRAN-DATE   TO MODB-RPT-D-TRAN-DATE
           MOVE DCL-TH-TYPE-CD     TO MODB-RPT-D-TYPE-CD
           MOVE DCL-TH-CAT-CD      TO MODB-RPT-D-CAT-CD
           MOVE DCL-TH-AMT         TO MODB-RPT-D-AMT

           MOVE SPACES TO MODB-RPT-D-TYPE-DESC
           IF WS-IND-TYPE-DESC < 0
              MOVE 'UNKNOWN TYPE'  TO MODB-RPT-D-TYPE-DESC
           ELSE
              IF WS-TYPE-DESC-LEN > 0
                 MOVE WS-TYPE-DESC-TEXT(1:WS-TYPE-DESC-LEN)
                   TO MODB-RPT-D-TYPE-DESC
              END-IF
           END-IF

           MOVE SPACES TO MODB-RPT-D-CAT-DESC
           IF WS-IND-CAT-DESC < 0
              MOVE 'UNKNOWN CATEGORY' TO MODB-RPT-D-CAT-DESC
           ELSE
              IF WS-CAT-DESC-LEN > 0
                 MOVE WS-CAT-DESC-TEXT(1:WS-CAT-DESC-LEN)
                   TO MODB-RPT-D-CAT-DESC
              END-IF
           END-IF

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
