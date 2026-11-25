      ******************************************************************
      * Program     : COMODRQC.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : CICS COBOL Db2 Program, without a screen
      * Transaction : CMDR
      * Function    : Post the pending online transactions in
      *               CARDDEMO.TRAN_HIST to CARDDEMO.ACCT_DAILY_BAL.
      *               - Started with EXEC CICS START, with no terminal
      *                 and no data: its work is the TRAN_HIST rows
      *                 with source CICS and no processing timestamp,
      *                 in TH_TRAN_ID order
      *               - Posting adds the amount to the daily balance of
      *                 the row's account and transaction date, and
      *                 sets the over-limit flag to whether the closing
      *                 balance is above the credit limit
      *               - A row that cannot be posted is rejected: its
      *                 category code becomes 9901 (no daily balance)
      *                 or 9902 (amount of zero)
      *               - Either way the row gets its processing
      *                 timestamp, the start of its transaction date,
      *                 and is one unit of work
      *               - Nothing comes from the system clock, so the
      *                 same pending rows on the same balances always
      *                 give the same result
      *               - A Db2 error rolls back the row and abends the
      *                 task (MDRQ)
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
       PROGRAM-ID.    COMODRQC.
       AUTHOR.        MECHANICAL ORCHARD.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Literals
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  LIT-THISPGM            PIC X(8)  VALUE 'COMODRQC'.
      *    Abend code after a Db2 error, once the row's work is rolled
      *    back
           05  LIT-DB2-ABEND          PIC X(4)  VALUE 'MDRQ'.
      *    The source of the rows this transaction posts
           05  LIT-SOURCE             PIC X(10) VALUE 'CICS'.
      *    The time part of the processing timestamp: the start of the
      *    transaction date, never the clock
           05  LIT-MIDNIGHT           PIC X(16)
                                      VALUE '-00.00.00.000000'.

      *    Category codes of a rejected row
       01  WS-REJECT-CODES.
           05  REJ-NO-BALANCE         PIC X(4)  VALUE '9901'.
           05  REJ-ZERO-AMOUNT        PIC X(4)  VALUE '9902'.

      *----------------------------------------------------------------*
      * Work fields
      *----------------------------------------------------------------*
       01  WS-MISC-STORAGE.
           05  WS-MORE-FLAG           PIC X     VALUE 'Y'.
               88  MORE-ROWS                    VALUE 'Y'.
               88  NO-MORE-ROWS                 VALUE 'N'.
           05  WS-REJECT              PIC X(4)  VALUE SPACES.
           05  WS-NEW-FLAG            PIC X     VALUE SPACE.

      *----------------------------------------------------------------*
      * Db2
      *----------------------------------------------------------------*
       01  WS-HOST-VARS.
           05  HV-FLAG-DATE           PIC X(10).
           05  HV-FLAG-DATE-IND       PIC S9(4) COMP.
           05  HV-CAT-CD              PIC X(4).

           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE DCLACDBL END-EXEC.
           EXEC SQL INCLUDE DCLTRHST END-EXEC.

      *----------------------------------------------------------------*
      * The Db2 error message shared with the other app-mo-db2 programs
      *----------------------------------------------------------------*
       COPY CSMODCWY.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Post the pending rows one at a time, lowest TH_TRAN_ID first,
      * until none is left
      *----------------------------------------------------------------*
       0000-MAIN.
           SET MORE-ROWS TO TRUE
           PERFORM UNTIL NO-MORE-ROWS
               PERFORM 1000-NEXT-ROW
               IF MORE-ROWS
                   PERFORM 2000-POST-ROW
               END-IF
           END-PERFORM

           EXEC CICS RETURN
           END-EXEC
           GOBACK
           .

      *----------------------------------------------------------------*
      * Read the pending row with the lowest TH_TRAN_ID. Each row is
      * read afresh after the last one's SYNCPOINT, so no cursor is
      * held across units of work.
      *----------------------------------------------------------------*
       1000-NEXT-ROW.
           EXEC SQL
                SELECT TH_TRAN_ID
                     , TH_ACCT_ID
                     , TH_CAT_CD
                     , TH_AMT
                     , CHAR(TH_TRAN_DATE, ISO)
                  INTO :DCL-TH-TRAN-ID
                     , :DCL-TH-ACCT-ID
                     , :DCL-TH-CAT-CD
                     , :DCL-TH-AMT
                     , :DCL-TH-TRAN-DATE
                  FROM CARDDEMO.TRAN_HIST
                 WHERE TH_SOURCE  = :LIT-SOURCE
                   AND TH_PROC_TS IS NULL
                 ORDER BY TH_TRAN_ID
                 FETCH FIRST 1 ROW ONLY
           END-EXEC
           EVALUATE TRUE
               WHEN SQLCODE = 0
                   CONTINUE
               WHEN SQLCODE = 100
                   SET NO-MORE-ROWS TO TRUE
               WHEN OTHER
                   MOVE 'Read of the next pending row' TO WS-DB2-ACTION
                   PERFORM 9900-DB2-ABEND
           END-EVALUATE
           .

      *----------------------------------------------------------------*
      * One row, one unit of work: post it or reject it, stamp it as
      * processed, then SYNCPOINT. Every check comes before the first
      * write.
      *----------------------------------------------------------------*
       2000-POST-ROW.
           MOVE SPACES TO WS-REJECT
           IF DCL-TH-AMT = 0
               MOVE REJ-ZERO-AMOUNT TO WS-REJECT
           ELSE
               PERFORM 3000-READ-BALANCE
           END-IF

           IF WS-REJECT = SPACES
               PERFORM 4000-UPDATE-BALANCE
               MOVE DCL-TH-CAT-CD TO HV-CAT-CD
           ELSE
               MOVE WS-REJECT     TO HV-CAT-CD
           END-IF
           PERFORM 5000-MARK-PROCESSED

           EXEC CICS SYNCPOINT
           END-EXEC
           .

      *----------------------------------------------------------------*
      * The daily balance for the row's account and transaction date,
      * or a rejection when there is none
      *----------------------------------------------------------------*
       3000-READ-BALANCE.
           EXEC SQL
                SELECT ADB_CREDIT_AMT
                     , ADB_DEBIT_AMT
                     , ADB_CLOSE_BAL
                     , ADB_TRAN_CNT
                     , ADB_CREDIT_LIMIT
                     , ADB_OVERLIMIT_FLG
                     , CHAR(ADB_FLAG_DATE, ISO)
                  INTO :DCL-ADB-CREDIT-AMT
                     , :DCL-ADB-DEBIT-AMT
                     , :DCL-ADB-CLOSE-BAL
                     , :DCL-ADB-TRAN-CNT
                     , :DCL-ADB-CREDIT-LIMIT
                     , :DCL-ADB-OVERLIMIT-FLG
                     , :HV-FLAG-DATE :HV-FLAG-DATE-IND
                  FROM CARDDEMO.ACCT_DAILY_BAL
                 WHERE ADB_ACCT_ID  = :DCL-TH-ACCT-ID
                   AND ADB_BAL_DATE = :DCL-TH-TRAN-DATE
           END-EXEC
           EVALUATE TRUE
               WHEN SQLCODE = 0
                   CONTINUE
               WHEN SQLCODE = 100
                   MOVE REJ-NO-BALANCE TO WS-REJECT
               WHEN OTHER
                   MOVE 'Read of the daily balance' TO WS-DB2-ACTION
                   PERFORM 9900-DB2-ABEND
           END-EVALUATE
           .

      *----------------------------------------------------------------*
      * Add the amount: a credit (zero or more) or a debit (negative,
      * as the debit total is kept), the closing balance and the
      * count. The over-limit flag then says whether the closing
      * balance is above the credit limit: a newly set flag is dated
      * with the transaction date, a cleared one has no date, and a
      * flag that does not change keeps its date.
      *----------------------------------------------------------------*
       4000-UPDATE-BALANCE.
           IF DCL-TH-AMT > 0
               ADD DCL-TH-AMT TO DCL-ADB-CREDIT-AMT
           ELSE
               ADD DCL-TH-AMT TO DCL-ADB-DEBIT-AMT
           END-IF
           ADD DCL-TH-AMT TO DCL-ADB-CLOSE-BAL
           ADD 1          TO DCL-ADB-TRAN-CNT

           IF DCL-ADB-CLOSE-BAL > DCL-ADB-CREDIT-LIMIT
               MOVE 'Y' TO WS-NEW-FLAG
           ELSE
               MOVE 'N' TO WS-NEW-FLAG
           END-IF
           IF WS-NEW-FLAG NOT = DCL-ADB-OVERLIMIT-FLG
               MOVE WS-NEW-FLAG TO DCL-ADB-OVERLIMIT-FLG
               IF WS-NEW-FLAG = 'Y'
                   MOVE DCL-TH-TRAN-DATE TO HV-FLAG-DATE
                   MOVE 0                TO HV-FLAG-DATE-IND
               ELSE
                   MOVE SPACES           TO HV-FLAG-DATE
                   MOVE -1               TO HV-FLAG-DATE-IND
               END-IF
           END-IF

           EXEC SQL
                UPDATE CARDDEMO.ACCT_DAILY_BAL
                   SET ADB_CREDIT_AMT    = :DCL-ADB-CREDIT-AMT
                     , ADB_DEBIT_AMT     = :DCL-ADB-DEBIT-AMT
                     , ADB_CLOSE_BAL     = :DCL-ADB-CLOSE-BAL
                     , ADB_TRAN_CNT      = :DCL-ADB-TRAN-CNT
                     , ADB_OVERLIMIT_FLG = :DCL-ADB-OVERLIMIT-FLG
                     , ADB_FLAG_DATE     = :HV-FLAG-DATE
                                           :HV-FLAG-DATE-IND
                 WHERE ADB_ACCT_ID       = :DCL-TH-ACCT-ID
                   AND ADB_BAL_DATE      = :DCL-TH-TRAN-DATE
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Update of the daily balance' TO WS-DB2-ACTION
               PERFORM 9900-DB2-ABEND
           END-IF
           .

      *----------------------------------------------------------------*
      * Stamp the row as processed with the start of its transaction
      * date, and the reject code as its category when it was rejected
      *----------------------------------------------------------------*
       5000-MARK-PROCESSED.
           STRING DCL-TH-TRAN-DATE DELIMITED BY SIZE
                  LIT-MIDNIGHT     DELIMITED BY SIZE
             INTO DCL-TH-PROC-TS
           END-STRING

           EXEC SQL
                UPDATE CARDDEMO.TRAN_HIST
                   SET TH_PROC_TS = :DCL-TH-PROC-TS
                     , TH_CAT_CD  = :HV-CAT-CD
                 WHERE TH_TRAN_ID = :DCL-TH-TRAN-ID
                   AND TH_PROC_TS IS NULL
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Update of the posted row' TO WS-DB2-ACTION
               PERFORM 9900-DB2-ABEND
           END-IF
           .

      *----------------------------------------------------------------*
      * A Db2 error: show the message, roll back this row's work and
      * abend, so a run never leaves a row half posted
      *----------------------------------------------------------------*
       9900-DB2-ABEND.
           PERFORM 9800-FORMAT-DB2-MESSAGE
           DISPLAY LIT-THISPGM ': ' WS-DB2-MESSAGE
           EXEC CICS SYNCPOINT ROLLBACK
           END-EXEC
           EXEC CICS ABEND ABCODE(LIT-DB2-ABEND)
           END-EXEC
           .

      *----------------------------------------------------------------*
      * Shared procedures
      *----------------------------------------------------------------*
       COPY CSMODCPY.
