      ******************************************************************
      * Program     : COMODRQC.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : CICS COBOL Db2 Program, without a screen
      * Transaction : CMDR
      * Function    : Work through the pending requests in
      *               CARDDEMO.ACCT_REQUEST, in REQ_ID order, and apply
      *               each one to CARDDEMO.ACCT_DAILY_BAL and
      *               CARDDEMO.TRAN_HIST.
      *               - Started with EXEC CICS START, with no terminal
      *                 and no data: every input is a request row
      *               - A posts an adjustment: a TRAN_HIST row and the
      *                 day's balance; S sets and C clears the
      *                 over-limit flag
      *               - Each request ends DONE (D) or REJECTED (R) with
      *                 a reason code, and is one unit of work
      *               - Every date it writes is the request's business
      *                 date, and every key comes from the request ID,
      *                 so the same requests on the same rows always
      *                 give the same result
      *               - A Db2 error rolls back the request and abends
      *                 the task (MDRQ)
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
      *    Abend code after a Db2 error, once the request's work is
      *    rolled back
           05  LIT-DB2-ABEND          PIC X(4)  VALUE 'MDRQ'.
      *    An adjustment posts as transaction type 07 (Adjustment),
      *    category 0001, as in the CardDemo reference data
           05  LIT-ADJ-TYPE-CD        PIC X(2)  VALUE '07'.
           05  LIT-ADJ-CAT-CD         PIC X(4)  VALUE '0001'.
           05  LIT-ADJ-SOURCE         PIC X(10) VALUE 'CICS'.
           05  LIT-ADJ-PREFIX         PIC X(3)  VALUE 'ADJ'.
           05  LIT-ADJ-DESC           PIC X(10) VALUE 'Adjustment'.
      *    The time part of the timestamps an adjustment writes: the
      *    start of the business date, never the clock
           05  LIT-MIDNIGHT           PIC X(16)
                                      VALUE '-00.00.00.000000'.

      *    Reason codes of a rejected request (REQ_REASON)
       01  WS-REASONS.
           05  RSN-BAD-ACTION         PIC X(8)  VALUE 'BADACT'.
           05  RSN-BAD-AMOUNT         PIC X(8)  VALUE 'BADAMT'.
           05  RSN-NO-CARD            PIC X(8)  VALUE 'NOCARD'.
           05  RSN-NO-ROW             PIC X(8)  VALUE 'NOROW'.
           05  RSN-ALREADY            PIC X(8)  VALUE 'ALREADY'.

      *----------------------------------------------------------------*
      * Work fields
      *----------------------------------------------------------------*
       01  WS-MISC-STORAGE.
           05  WS-MORE-FLAG           PIC X     VALUE 'Y'.
               88  MORE-REQUESTS                VALUE 'Y'.
               88  NO-MORE-REQUESTS             VALUE 'N'.
           05  WS-REASON              PIC X(8)  VALUE SPACES.
           05  WS-NEW-FLAG            PIC X     VALUE SPACE.

      *----------------------------------------------------------------*
      * Db2
      *----------------------------------------------------------------*
       01  WS-HOST-VARS.
           05  HV-CARD-IND            PIC S9(4) COMP.
           05  HV-AMT-IND             PIC S9(4) COMP.
           05  HV-DESC-IND            PIC S9(4) COMP.
           05  HV-FLAG-DATE           PIC X(10).
           05  HV-FLAG-DATE-IND       PIC S9(4) COMP.
           05  HV-STATUS              PIC X.
           05  HV-REASON              PIC X(8).
           05  HV-REASON-IND          PIC S9(4) COMP.
           05  HV-TRAN-ID             PIC X(16).
           05  HV-TRAN-ID-IND         PIC S9(4) COMP.

           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE DCLACREQ END-EXEC.
           EXEC SQL INCLUDE DCLACDBL END-EXEC.
           EXEC SQL INCLUDE DCLTRHST END-EXEC.

      *----------------------------------------------------------------*
      * The Db2 error message shared with the other app-mo-db2 programs
      *----------------------------------------------------------------*
       COPY CSMODCWY.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Apply the pending requests one at a time, lowest REQ_ID first,
      * until none is left
      *----------------------------------------------------------------*
       0000-MAIN.
           SET MORE-REQUESTS TO TRUE
           PERFORM UNTIL NO-MORE-REQUESTS
               PERFORM 1000-NEXT-REQUEST
               IF MORE-REQUESTS
                   PERFORM 2000-APPLY-REQUEST
               END-IF
           END-PERFORM

           EXEC CICS RETURN
           END-EXEC
           GOBACK
           .

      *----------------------------------------------------------------*
      * Read the pending request with the lowest REQ_ID. Each request
      * is read afresh after the last one's SYNCPOINT, so no cursor is
      * held across units of work.
      *----------------------------------------------------------------*
       1000-NEXT-REQUEST.
           EXEC SQL
                SELECT REQ_ID
                     , REQ_ACTION
                     , REQ_ACCT_ID
                     , CHAR(REQ_BAL_DATE, ISO)
                     , REQ_CARD_NUM
                     , REQ_AMT
                     , REQ_DESC
                  INTO :DCL-REQ-ID
                     , :DCL-REQ-ACTION
                     , :DCL-REQ-ACCT-ID
                     , :DCL-REQ-BAL-DATE
                     , :DCL-REQ-CARD-NUM :HV-CARD-IND
                     , :DCL-REQ-AMT      :HV-AMT-IND
                     , :DCL-REQ-DESC     :HV-DESC-IND
                  FROM CARDDEMO.ACCT_REQUEST
                 WHERE REQ_STATUS = 'P'
                 ORDER BY REQ_ID
                 FETCH FIRST 1 ROW ONLY
           END-EXEC
           EVALUATE TRUE
               WHEN SQLCODE = 0
                   CONTINUE
               WHEN SQLCODE = 100
                   SET NO-MORE-REQUESTS TO TRUE
               WHEN OTHER
                   MOVE 'Read of the next request' TO WS-DB2-ACTION
                   PERFORM 9900-DB2-ABEND
           END-EVALUATE
           .

      *----------------------------------------------------------------*
      * One request, one unit of work: apply it or find why not, record
      * the outcome on the request row, then SYNCPOINT
      *----------------------------------------------------------------*
       2000-APPLY-REQUEST.
           MOVE SPACES TO WS-REASON
                          HV-TRAN-ID
           EVALUATE DCL-REQ-ACTION
               WHEN 'A'
                   PERFORM 3000-ADJUST
               WHEN 'S'
               WHEN 'C'
                   PERFORM 4000-SET-OR-CLEAR-FLAG
               WHEN OTHER
                   MOVE RSN-BAD-ACTION TO WS-REASON
           END-EVALUATE

           PERFORM 5000-CLOSE-REQUEST

           EXEC CICS SYNCPOINT
           END-EXEC
           .

      *----------------------------------------------------------------*
      * A: post the amount as a TRAN_HIST row and add it to the day's
      * balance. Every check comes before the first write.
      *----------------------------------------------------------------*
       3000-ADJUST.
           EVALUATE TRUE
               WHEN HV-AMT-IND < 0
               WHEN DCL-REQ-AMT = 0
                   MOVE RSN-BAD-AMOUNT TO WS-REASON
               WHEN HV-CARD-IND < 0
               WHEN DCL-REQ-CARD-NUM = SPACES
                   MOVE RSN-NO-CARD    TO WS-REASON
               WHEN OTHER
                   PERFORM 6000-READ-BALANCE
           END-EVALUATE

           IF WS-REASON = SPACES
               PERFORM 3100-POST-ADJUSTMENT
               PERFORM 3200-UPDATE-BALANCE
           END-IF
           .

      *    The TRAN_HIST row. Its ID is ADJ followed by the request ID;
      *    its dates and timestamps are the request's business date.
       3100-POST-ADJUSTMENT.
           STRING LIT-ADJ-PREFIX DELIMITED BY SIZE
                  DCL-REQ-ID     DELIMITED BY SIZE
             INTO HV-TRAN-ID
           END-STRING

           MOVE HV-TRAN-ID         TO DCL-TH-TRAN-ID
           MOVE DCL-REQ-ACCT-ID    TO DCL-TH-ACCT-ID
           MOVE DCL-REQ-CARD-NUM   TO DCL-TH-CARD-NUM
           MOVE LIT-ADJ-TYPE-CD    TO DCL-TH-TYPE-CD
           MOVE LIT-ADJ-CAT-CD     TO DCL-TH-CAT-CD
           MOVE LIT-ADJ-SOURCE     TO DCL-TH-SOURCE
           IF HV-DESC-IND < 0 OR DCL-REQ-DESC-LEN = 0
               MOVE LENGTH OF LIT-ADJ-DESC TO DCL-TH-DESC-LEN
               MOVE LIT-ADJ-DESC   TO DCL-TH-DESC-TEXT
           ELSE
               MOVE DCL-REQ-DESC-LEN  TO DCL-TH-DESC-LEN
               MOVE DCL-REQ-DESC-TEXT TO DCL-TH-DESC-TEXT
           END-IF
           MOVE DCL-REQ-AMT        TO DCL-TH-AMT
           MOVE DCL-REQ-BAL-DATE   TO DCL-TH-TRAN-DATE
           STRING DCL-REQ-BAL-DATE DELIMITED BY SIZE
                  LIT-MIDNIGHT     DELIMITED BY SIZE
             INTO DCL-TH-ORIG-TS
           END-STRING
           MOVE DCL-TH-ORIG-TS     TO DCL-TH-PROC-TS

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
                     , TH_PROC_TS )
                VALUES
                     ( :DCL-TH-TRAN-ID
                     , :DCL-TH-ACCT-ID
                     , :DCL-TH-CARD-NUM
                     , :DCL-TH-TYPE-CD
                     , :DCL-TH-CAT-CD
                     , :DCL-TH-SOURCE
                     , :DCL-TH-DESC
                     , :DCL-TH-AMT
                     , NULL
                     , NULL
                     , NULL
                     , NULL
                     , :DCL-TH-TRAN-DATE
                     , :DCL-TH-ORIG-TS
                     , :DCL-TH-PROC-TS )
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Insert of the adjustment' TO WS-DB2-ACTION
               PERFORM 9900-DB2-ABEND
           END-IF
           .

      *    The day's balance: a credit (positive) or a debit (negative,
      *    as the debit total is kept), the close balance and the count.
      *    Going over the credit limit sets the over-limit flag, dated
      *    with the business date.
       3200-UPDATE-BALANCE.
           IF DCL-REQ-AMT > 0
               ADD DCL-REQ-AMT TO DCL-ADB-CREDIT-AMT
           ELSE
               ADD DCL-REQ-AMT TO DCL-ADB-DEBIT-AMT
           END-IF
           ADD DCL-REQ-AMT TO DCL-ADB-CLOSE-BAL
           ADD 1           TO DCL-ADB-TRAN-CNT
           IF  DCL-ADB-CLOSE-BAL > DCL-ADB-CREDIT-LIMIT
           AND DCL-ADB-OVERLIMIT-FLG = 'N'
               MOVE 'Y'              TO DCL-ADB-OVERLIMIT-FLG
               MOVE DCL-REQ-BAL-DATE TO HV-FLAG-DATE
               MOVE 0                TO HV-FLAG-DATE-IND
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
                 WHERE ADB_ACCT_ID       = :DCL-REQ-ACCT-ID
                   AND ADB_BAL_DATE      = :DCL-REQ-BAL-DATE
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Update of the daily balance' TO WS-DB2-ACTION
               PERFORM 9900-DB2-ABEND
           END-IF
           .

      *----------------------------------------------------------------*
      * S or C: set or clear the over-limit flag. Setting it dates it
      * with the business date; clearing it sets the date to NULL.
      *----------------------------------------------------------------*
       4000-SET-OR-CLEAR-FLAG.
           IF DCL-REQ-ACTION = 'S'
               MOVE 'Y' TO WS-NEW-FLAG
           ELSE
               MOVE 'N' TO WS-NEW-FLAG
           END-IF

           PERFORM 6000-READ-BALANCE
           IF WS-REASON = SPACES
           AND DCL-ADB-OVERLIMIT-FLG = WS-NEW-FLAG
               MOVE RSN-ALREADY TO WS-REASON
           END-IF

           IF WS-REASON = SPACES
               IF WS-NEW-FLAG = 'Y'
                   MOVE DCL-REQ-BAL-DATE TO HV-FLAG-DATE
                   MOVE 0                TO HV-FLAG-DATE-IND
               ELSE
                   MOVE SPACES           TO HV-FLAG-DATE
                   MOVE -1               TO HV-FLAG-DATE-IND
               END-IF
               EXEC SQL
                    UPDATE CARDDEMO.ACCT_DAILY_BAL
                       SET ADB_OVERLIMIT_FLG = :WS-NEW-FLAG
                         , ADB_FLAG_DATE     = :HV-FLAG-DATE
                                               :HV-FLAG-DATE-IND
                     WHERE ADB_ACCT_ID       = :DCL-REQ-ACCT-ID
                       AND ADB_BAL_DATE      = :DCL-REQ-BAL-DATE
               END-EXEC
               IF SQLCODE NOT = 0
                   MOVE 'Update of the over-limit flag'
                                          TO WS-DB2-ACTION
                   PERFORM 9900-DB2-ABEND
               END-IF
           END-IF
           .

      *----------------------------------------------------------------*
      * Record the outcome on the request: D, or R with the reason;
      * REQ_TRAN_ID names the TRAN_HIST row an adjustment posted
      *----------------------------------------------------------------*
       5000-CLOSE-REQUEST.
           IF WS-REASON = SPACES
               MOVE 'D'       TO HV-STATUS
               MOVE SPACES    TO HV-REASON
               MOVE -1        TO HV-REASON-IND
           ELSE
               MOVE 'R'       TO HV-STATUS
               MOVE WS-REASON TO HV-REASON
               MOVE 0         TO HV-REASON-IND
           END-IF
           IF HV-TRAN-ID = SPACES
               MOVE -1        TO HV-TRAN-ID-IND
           ELSE
               MOVE 0         TO HV-TRAN-ID-IND
           END-IF

           EXEC SQL
                UPDATE CARDDEMO.ACCT_REQUEST
                   SET REQ_STATUS  = :HV-STATUS
                     , REQ_REASON  = :HV-REASON  :HV-REASON-IND
                     , REQ_TRAN_ID = :HV-TRAN-ID :HV-TRAN-ID-IND
                 WHERE REQ_ID      = :DCL-REQ-ID
                   AND REQ_STATUS  = 'P'
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Update of the request' TO WS-DB2-ACTION
               PERFORM 9900-DB2-ABEND
           END-IF
           .

      *----------------------------------------------------------------*
      * The day's balance row for the request's account and date, or
      * reason NOROW when there is none
      *----------------------------------------------------------------*
       6000-READ-BALANCE.
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
                 WHERE ADB_ACCT_ID  = :DCL-REQ-ACCT-ID
                   AND ADB_BAL_DATE = :DCL-REQ-BAL-DATE
           END-EXEC
           EVALUATE TRUE
               WHEN SQLCODE = 0
                   CONTINUE
               WHEN SQLCODE = 100
                   MOVE RSN-NO-ROW TO WS-REASON
               WHEN OTHER
                   MOVE 'Read of the daily balance' TO WS-DB2-ACTION
                   PERFORM 9900-DB2-ABEND
           END-EVALUATE
           .

      *----------------------------------------------------------------*
      * A Db2 error: show the message, roll back this request's work
      * and abend, so a run never leaves a request half applied
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
