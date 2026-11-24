      ******************************************************************
      * Program     : COMODLIC.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : CICS COBOL Db2 Program, without a screen
      * Transaction : CMDL
      * Function    : List the daily account balances in
      *               CARDDEMO.ACCT_DAILY_BAL, 10 rows a page, in
      *               account and balance date order.
      *               - A caller LINKs to it with the request in the
      *                 COMMAREA (COMOD01Y) and gets the page back in
      *                 the same COMMAREA
      *               - Optional filters: account ID and balance date
      *               - F reads the first page; N and P page forward
      *                 and back with cursors; C reads the same page
      *                 again
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
       PROGRAM-ID.    COMODLIC.
       AUTHOR.        MECHANICAL ORCHARD.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Literals
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  LIT-THISPGM            PIC X(8)  VALUE 'COMODLIC'.
      *    Abend code when a caller passes no COMMAREA, or one too
      *    short for COMOD01Y: there is nowhere to put a response
           05  LIT-NO-COMMAREA-ABEND  PIC X(4)  VALUE 'MDLC'.
           05  LIT-LOW-DATE           PIC X(10) VALUE '0001-01-01'.
           05  LIT-PAGE-ROWS          PIC S9(4) COMP VALUE 10.

       01  WS-MESSAGES.
           05  MSG-BAD-ACTION         PIC X(60) VALUE
               'Action must be F, N, P or C'.
           05  MSG-BAD-ACCOUNT        PIC X(60) VALUE
               'Account ID must be a number of up to 11 digits'.
           05  MSG-BAD-DATE           PIC X(60) VALUE
               'Balance date must be a valid date in YYYY-MM-DD form'.
           05  MSG-BAD-KEYS           PIC X(60) VALUE
               'Page keys must come from the previous response'.
           05  MSG-TOP-OF-LIST        PIC X(60) VALUE
               'You are at the top of the list'.
           05  MSG-BOTTOM-OF-LIST     PIC X(60) VALUE
               'You are at the bottom of the list'.
           05  MSG-NO-ROWS            PIC X(60) VALUE
               'No daily balances match the filters'.

      *----------------------------------------------------------------*
      * Work fields
      *----------------------------------------------------------------*
       01  WS-MISC-STORAGE.
           05  WS-INTERFACE-LEN       PIC S9(4) COMP VALUE 0.
           05  WS-FETCH-COUNT         PIC S9(4) COMP VALUE 0.
           05  WS-ROW-IX              PIC S9(4) COMP VALUE 0.
           05  WS-INPUT-FLAG          PIC X     VALUE '0'.
               88  INPUT-OK                     VALUE '0'.
               88  INPUT-ERROR                  VALUE '1'.
           05  WS-FETCH-FLAG          PIC X     VALUE 'N'.
               88  FETCH-DONE                   VALUE 'Y'.
               88  FETCH-MORE                   VALUE 'N'.
           05  WS-DB2-FLAG            PIC X     VALUE '0'.
               88  DB2-OK                       VALUE '0'.
               88  DB2-ERROR                    VALUE '1'.
           05  WS-NOTICE              PIC X(60) VALUE SPACES.
           05  WS-FILTER-ACCT         PIC X(11) VALUE SPACES.
           05  WS-FILTER-DATE         PIC X(10) VALUE SPACES.
           05  WS-ACCT-NUM            PIC 9(11) VALUE 0.
           05  WS-PAGE-NUM            PIC 9(3)  VALUE 0.
           05  WS-FIRST-ACCT          PIC 9(11) VALUE 0.
      *    The page's first and last keys; the lowest key while no
      *    page has rows, so a response's keys are always valid in the
      *    next request
           05  WS-FIRST-DATE          PIC X(10) VALUE '0001-01-01'.
           05  WS-LAST-ACCT           PIC 9(11) VALUE 0.
           05  WS-LAST-DATE           PIC X(10) VALUE '0001-01-01'.
           05  WS-BACK-ACCT           PIC 9(11) VALUE 0.
           05  WS-BACK-DATE           PIC X(10) VALUE SPACES.

      *----------------------------------------------------------------*
      * Db2
      *----------------------------------------------------------------*
       01  WS-HOST-VARS.
           05  HV-START-ACCT          PIC S9(11) COMP-3.
           05  HV-START-DATE          PIC X(10).
           05  HV-START-INCL          PIC X.
           05  HV-FILTER-ACCT-FLG     PIC X.
           05  HV-FILTER-ACCT         PIC S9(11) COMP-3.
           05  HV-FILTER-DATE-FLG     PIC X.
           05  HV-FILTER-DATE         PIC X(10).

           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE DCLACDBL END-EXEC.

      *    Rows from a start key, in key order. HV-START-INCL = 'Y'
      *    includes the start key itself. One row more than a page is
      *    fetched to tell whether another page follows.
           EXEC SQL
                DECLARE C-ADB-FORWARD CURSOR FOR
                SELECT ADB_ACCT_ID
                     , CHAR(ADB_BAL_DATE, ISO)
                     , ADB_OPEN_BAL
                     , ADB_CREDIT_AMT
                     , ADB_DEBIT_AMT
                     , ADB_CLOSE_BAL
                     , ADB_TRAN_CNT
                     , ADB_OVERLIMIT_FLG
                  FROM CARDDEMO.ACCT_DAILY_BAL
                 WHERE (ADB_ACCT_ID > :HV-START-ACCT
                    OR (ADB_ACCT_ID = :HV-START-ACCT
                   AND (ADB_BAL_DATE > :HV-START-DATE
                    OR (ADB_BAL_DATE = :HV-START-DATE
                   AND :HV-START-INCL = 'Y'))))
                   AND (:HV-FILTER-ACCT-FLG = 'N'
                    OR ADB_ACCT_ID = :HV-FILTER-ACCT)
                   AND (:HV-FILTER-DATE-FLG = 'N'
                    OR ADB_BAL_DATE = :HV-FILTER-DATE)
                 ORDER BY ADB_ACCT_ID, ADB_BAL_DATE
                 FETCH FIRST 11 ROWS ONLY
           END-EXEC.

      *    Keys before a start key, nearest first, to find where the
      *    previous page starts.
           EXEC SQL
                DECLARE C-ADB-BACKWARD CURSOR FOR
                SELECT ADB_ACCT_ID
                     , CHAR(ADB_BAL_DATE, ISO)
                  FROM CARDDEMO.ACCT_DAILY_BAL
                 WHERE (ADB_ACCT_ID < :HV-START-ACCT
                    OR (ADB_ACCT_ID = :HV-START-ACCT
                   AND ADB_BAL_DATE < :HV-START-DATE))
                   AND (:HV-FILTER-ACCT-FLG = 'N'
                    OR ADB_ACCT_ID = :HV-FILTER-ACCT)
                   AND (:HV-FILTER-DATE-FLG = 'N'
                    OR ADB_BAL_DATE = :HV-FILTER-DATE)
                 ORDER BY ADB_ACCT_ID DESC, ADB_BAL_DATE DESC
                 FETCH FIRST 10 ROWS ONLY
           END-EXEC.

      *----------------------------------------------------------------*
      * The checks and formats shared with COMODUPC
      *----------------------------------------------------------------*
       COPY CSMODCWY.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           COPY COMOD01Y.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Check the request, read the page, and return it in the
      * caller's COMMAREA
      *----------------------------------------------------------------*
       0000-MAIN.
           COMPUTE WS-INTERFACE-LEN = LENGTH OF CMDL-REQUEST
                                    + LENGTH OF CMDL-RESPONSE
           IF EIBCALEN < WS-INTERFACE-LEN
               EXEC CICS ABEND ABCODE(LIT-NO-COMMAREA-ABEND)
               END-EXEC
           END-IF

           INITIALIZE CMDL-RESPONSE
           SET CMDL-RS-OK                   TO TRUE
           SET CMDL-RS-NEXT-PAGE-NOT-EXISTS TO TRUE
           MOVE SPACE                       TO CMDL-RS-ERR-FIELD
           MOVE SPACES                      TO CMDL-RS-MESSAGE
           SET INPUT-OK                     TO TRUE
           SET DB2-OK                       TO TRUE

           PERFORM 1000-EDIT-REQUEST
           IF INPUT-OK
               EVALUATE TRUE
                   WHEN CMDL-RQ-FIRST-PAGE
                       PERFORM 8000-READ-FIRST-PAGE
                   WHEN CMDL-RQ-SAME-PAGE
                       PERFORM 8010-READ-CURRENT-PAGE
                   WHEN CMDL-RQ-NEXT-PAGE
                       PERFORM 8020-READ-NEXT-PAGE
                   WHEN CMDL-RQ-PREV-PAGE
                       IF WS-PAGE-NUM > 1
                           PERFORM 8300-READ-PREVIOUS-PAGE
                       ELSE
                           MOVE MSG-TOP-OF-LIST TO WS-NOTICE
                           PERFORM 8010-READ-CURRENT-PAGE
                       END-IF
               END-EVALUATE
               PERFORM 9000-BUILD-RESPONSE
           END-IF

           EXEC CICS RETURN
           END-EXEC
           GOBACK
           .

      *----------------------------------------------------------------*
      * Check the action, the filters and, for N, P and C, the keys of
      * the previous page
      *----------------------------------------------------------------*
       1000-EDIT-REQUEST.
           IF NOT CMDL-RQ-FIRST-PAGE
           AND NOT CMDL-RQ-NEXT-PAGE
           AND NOT CMDL-RQ-PREV-PAGE
           AND NOT CMDL-RQ-SAME-PAGE
               MOVE 'R'              TO CMDL-RS-ERR-FIELD
               MOVE MSG-BAD-ACTION   TO CMDL-RS-MESSAGE
               SET INPUT-ERROR       TO TRUE
           END-IF

           MOVE SPACES TO WS-FILTER-ACCT
           IF INPUT-OK AND CMDL-RQ-FILTER-ACCT NOT = SPACES
               MOVE CMDL-RQ-FILTER-ACCT TO WS-AC-INPUT
               INSPECT WS-AC-INPUT REPLACING ALL LOW-VALUE BY SPACE
               PERFORM 9720-PARSE-ACCOUNT
               IF WS-AC-VALID
                   MOVE WS-AC-NUM       TO WS-FILTER-ACCT
               ELSE
                   MOVE 'A'             TO CMDL-RS-ERR-FIELD
                   MOVE MSG-BAD-ACCOUNT TO CMDL-RS-MESSAGE
                   SET INPUT-ERROR      TO TRUE
               END-IF
           END-IF

           MOVE SPACES TO WS-FILTER-DATE
           IF INPUT-OK AND CMDL-RQ-FILTER-DATE NOT = SPACES
               MOVE FUNCTION TRIM(CMDL-RQ-FILTER-DATE) TO WS-DC-DATE
               PERFORM 9700-VALIDATE-DATE
               IF WS-DC-VALID
                   MOVE WS-DC-DATE      TO WS-FILTER-DATE
               ELSE
                   MOVE 'D'             TO CMDL-RS-ERR-FIELD
                   MOVE MSG-BAD-DATE    TO CMDL-RS-MESSAGE
                   SET INPUT-ERROR      TO TRUE
               END-IF
           END-IF

           IF INPUT-OK AND NOT CMDL-RQ-FIRST-PAGE
               PERFORM 1100-EDIT-PAGE-KEYS
           END-IF

           IF INPUT-ERROR
               SET CMDL-RS-BAD-REQUEST TO TRUE
           END-IF
           .

       1100-EDIT-PAGE-KEYS.
           IF CMDL-RQ-PAGE-NUM   IS NOT NUMERIC
           OR CMDL-RQ-PAGE-NUM   = 0
           OR CMDL-RQ-FIRST-ACCT IS NOT NUMERIC
           OR CMDL-RQ-LAST-ACCT  IS NOT NUMERIC
               MOVE 'R'              TO CMDL-RS-ERR-FIELD
               MOVE MSG-BAD-KEYS     TO CMDL-RS-MESSAGE
               SET INPUT-ERROR       TO TRUE
           END-IF
           IF INPUT-OK
               MOVE CMDL-RQ-FIRST-DATE TO WS-DC-DATE
               PERFORM 9700-VALIDATE-DATE
               IF WS-DC-VALID
                   MOVE CMDL-RQ-LAST-DATE TO WS-DC-DATE
                   PERFORM 9700-VALIDATE-DATE
               END-IF
               IF WS-DC-INVALID
                   MOVE 'R'          TO CMDL-RS-ERR-FIELD
                   MOVE MSG-BAD-KEYS TO CMDL-RS-MESSAGE
                   SET INPUT-ERROR   TO TRUE
               END-IF
           END-IF
           IF INPUT-OK
               MOVE CMDL-RQ-PAGE-NUM   TO WS-PAGE-NUM
               MOVE CMDL-RQ-FIRST-ACCT TO WS-FIRST-ACCT
               MOVE CMDL-RQ-FIRST-DATE TO WS-FIRST-DATE
               MOVE CMDL-RQ-LAST-ACCT  TO WS-LAST-ACCT
               MOVE CMDL-RQ-LAST-DATE  TO WS-LAST-DATE
           END-IF
           .

      *----------------------------------------------------------------*
      * Paging. Every request re-reads its page, so the rows returned
      * are always current.
      *----------------------------------------------------------------*
       8000-READ-FIRST-PAGE.
           MOVE 1                 TO WS-PAGE-NUM
           MOVE ZERO              TO HV-START-ACCT
           MOVE LIT-LOW-DATE      TO HV-START-DATE
           MOVE 'Y'               TO HV-START-INCL
           PERFORM 8200-READ-FORWARD
           .

       8010-READ-CURRENT-PAGE.
           MOVE WS-FIRST-ACCT     TO HV-START-ACCT
           MOVE WS-FIRST-DATE     TO HV-START-DATE
           MOVE 'Y'               TO HV-START-INCL
           PERFORM 8200-READ-FORWARD
           IF CMDL-RS-ROW-COUNT = 0 AND DB2-OK
               MOVE SPACES        TO WS-NOTICE
               PERFORM 8000-READ-FIRST-PAGE
           END-IF
           .

      *    The page after the last key. When nothing follows it, the
      *    caller was on the last page: say so and return that page.
       8020-READ-NEXT-PAGE.
           MOVE WS-LAST-ACCT      TO HV-START-ACCT
           MOVE WS-LAST-DATE      TO HV-START-DATE
           MOVE 'N'               TO HV-START-INCL
           ADD 1                  TO WS-PAGE-NUM
           PERFORM 8200-READ-FORWARD
           IF CMDL-RS-ROW-COUNT = 0 AND DB2-OK
               SUBTRACT 1            FROM WS-PAGE-NUM
               MOVE SPACES           TO WS-NOTICE
               PERFORM 8010-READ-CURRENT-PAGE
               IF CMDL-RS-ROW-COUNT > 0
                   MOVE MSG-BOTTOM-OF-LIST TO WS-NOTICE
               END-IF
           END-IF
           .

       8100-SET-FILTERS.
           IF WS-FILTER-ACCT = SPACES
               MOVE 'N'               TO HV-FILTER-ACCT-FLG
               MOVE ZERO              TO HV-FILTER-ACCT
           ELSE
               MOVE 'Y'               TO HV-FILTER-ACCT-FLG
               MOVE WS-FILTER-ACCT    TO WS-ACCT-NUM
               MOVE WS-ACCT-NUM       TO HV-FILTER-ACCT
           END-IF
      *    The date host variable must hold a valid date even when the
      *    filter is off, or Db2 cannot convert it.
           IF WS-FILTER-DATE = SPACES
               MOVE 'N'               TO HV-FILTER-DATE-FLG
               MOVE LIT-LOW-DATE      TO HV-FILTER-DATE
           ELSE
               MOVE 'Y'               TO HV-FILTER-DATE-FLG
               MOVE WS-FILTER-DATE    TO HV-FILTER-DATE
           END-IF
           .

      *    Read up to a page from the start key set by the caller
       8200-READ-FORWARD.
           PERFORM 8100-SET-FILTERS
           PERFORM VARYING WS-ROW-IX FROM 1 BY 1
                   UNTIL WS-ROW-IX > LIT-PAGE-ROWS
               INITIALIZE CMDL-RS-ROW(WS-ROW-IX)
           END-PERFORM
           MOVE 0 TO CMDL-RS-ROW-COUNT
                     WS-FETCH-COUNT
           SET CMDL-RS-NEXT-PAGE-NOT-EXISTS TO TRUE

           EXEC SQL
                OPEN C-ADB-FORWARD
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Open of the list cursor' TO WS-DB2-ACTION
               PERFORM 8900-DB2-ERROR
           ELSE
               SET FETCH-MORE TO TRUE
               PERFORM 8210-FETCH-FORWARD
                 UNTIL FETCH-DONE
               EXEC SQL
                    CLOSE C-ADB-FORWARD
               END-EXEC
           END-IF

           IF CMDL-RS-ROW-COUNT > 0
               MOVE CMDL-RS-ACCT-ID(1)  TO WS-FIRST-ACCT
               MOVE CMDL-RS-BAL-DATE(1) TO WS-FIRST-DATE
               MOVE CMDL-RS-ACCT-ID(CMDL-RS-ROW-COUNT)
                                        TO WS-LAST-ACCT
               MOVE CMDL-RS-BAL-DATE(CMDL-RS-ROW-COUNT)
                                        TO WS-LAST-DATE
           ELSE
               IF DB2-OK AND WS-NOTICE = SPACES
                   MOVE MSG-NO-ROWS     TO WS-NOTICE
               END-IF
           END-IF
           .

       8210-FETCH-FORWARD.
           EXEC SQL
                FETCH C-ADB-FORWARD
                 INTO :DCL-ADB-ACCT-ID
                    , :DCL-ADB-BAL-DATE
                    , :DCL-ADB-OPEN-BAL
                    , :DCL-ADB-CREDIT-AMT
                    , :DCL-ADB-DEBIT-AMT
                    , :DCL-ADB-CLOSE-BAL
                    , :DCL-ADB-TRAN-CNT
                    , :DCL-ADB-OVERLIMIT-FLG
           END-EXEC
           EVALUATE TRUE
               WHEN SQLCODE = 0
                   ADD 1 TO WS-FETCH-COUNT
                   IF WS-FETCH-COUNT > LIT-PAGE-ROWS
                       SET CMDL-RS-NEXT-PAGE-EXISTS TO TRUE
                       SET FETCH-DONE               TO TRUE
                   ELSE
                       PERFORM 8220-STORE-ROW
                   END-IF
               WHEN SQLCODE = 100
                   SET FETCH-DONE TO TRUE
               WHEN OTHER
                   MOVE 'Fetch of the list rows' TO WS-DB2-ACTION
                   PERFORM 8900-DB2-ERROR
                   SET FETCH-DONE TO TRUE
           END-EVALUATE
           .

       8220-STORE-ROW.
           ADD 1 TO CMDL-RS-ROW-COUNT
           MOVE DCL-ADB-ACCT-ID
             TO CMDL-RS-ACCT-ID(CMDL-RS-ROW-COUNT)
           MOVE DCL-ADB-BAL-DATE
             TO CMDL-RS-BAL-DATE(CMDL-RS-ROW-COUNT)
           MOVE DCL-ADB-OPEN-BAL
             TO CMDL-RS-OPEN-BAL(CMDL-RS-ROW-COUNT)
           MOVE DCL-ADB-CREDIT-AMT
             TO CMDL-RS-CREDIT-AMT(CMDL-RS-ROW-COUNT)
           MOVE DCL-ADB-DEBIT-AMT
             TO CMDL-RS-DEBIT-AMT(CMDL-RS-ROW-COUNT)
           MOVE DCL-ADB-CLOSE-BAL
             TO CMDL-RS-CLOSE-BAL(CMDL-RS-ROW-COUNT)
           MOVE DCL-ADB-TRAN-CNT
             TO CMDL-RS-TRAN-CNT(CMDL-RS-ROW-COUNT)
           MOVE DCL-ADB-OVERLIMIT-FLG
             TO CMDL-RS-OVERLIMIT-FLG(CMDL-RS-ROW-COUNT)
           .

      *    Step back up to a page from the first key, then read that
      *    page forward so rows always come in key order.
       8300-READ-PREVIOUS-PAGE.
           PERFORM 8100-SET-FILTERS
           MOVE WS-FIRST-ACCT     TO HV-START-ACCT
           MOVE WS-FIRST-DATE     TO HV-START-DATE
           MOVE 0                 TO WS-FETCH-COUNT

           EXEC SQL
                OPEN C-ADB-BACKWARD
           END-EXEC
           IF SQLCODE NOT = 0
               MOVE 'Open of the backward cursor' TO WS-DB2-ACTION
               PERFORM 8900-DB2-ERROR
           ELSE
               SET FETCH-MORE TO TRUE
               PERFORM 8310-FETCH-BACKWARD
                 UNTIL FETCH-DONE
               EXEC SQL
                    CLOSE C-ADB-BACKWARD
               END-EXEC
           END-IF

           EVALUATE TRUE
               WHEN DB2-ERROR
                   CONTINUE
               WHEN WS-FETCH-COUNT < LIT-PAGE-ROWS
                   PERFORM 8000-READ-FIRST-PAGE
               WHEN OTHER
                   SUBTRACT 1        FROM WS-PAGE-NUM
                   MOVE WS-BACK-ACCT TO HV-START-ACCT
                   MOVE WS-BACK-DATE TO HV-START-DATE
                   MOVE 'Y'          TO HV-START-INCL
                   PERFORM 8200-READ-FORWARD
           END-EVALUATE
           .

       8310-FETCH-BACKWARD.
           EXEC SQL
                FETCH C-ADB-BACKWARD
                 INTO :DCL-ADB-ACCT-ID
                    , :DCL-ADB-BAL-DATE
           END-EXEC
           EVALUATE TRUE
               WHEN SQLCODE = 0
                   ADD 1 TO WS-FETCH-COUNT
                   MOVE DCL-ADB-ACCT-ID  TO WS-BACK-ACCT
                   MOVE DCL-ADB-BAL-DATE TO WS-BACK-DATE
                   IF WS-FETCH-COUNT NOT < LIT-PAGE-ROWS
                       SET FETCH-DONE TO TRUE
                   END-IF
               WHEN SQLCODE = 100
                   SET FETCH-DONE TO TRUE
               WHEN OTHER
                   MOVE 'Fetch of the previous rows' TO WS-DB2-ACTION
                   PERFORM 8900-DB2-ERROR
                   SET FETCH-DONE TO TRUE
           END-EVALUATE
           .

       8900-DB2-ERROR.
           SET DB2-ERROR         TO TRUE
           PERFORM 9800-FORMAT-DB2-MESSAGE
           .

      *----------------------------------------------------------------*
      * The status, message and keys for the caller's next request
      *----------------------------------------------------------------*
       9000-BUILD-RESPONSE.
           EVALUATE TRUE
               WHEN DB2-ERROR
                   SET CMDL-RS-DB2-ERROR TO TRUE
                   MOVE WS-DB2-MESSAGE   TO CMDL-RS-MESSAGE
               WHEN WS-NOTICE NOT = SPACES
                   SET CMDL-RS-NOTICE    TO TRUE
                   MOVE WS-NOTICE        TO CMDL-RS-MESSAGE
               WHEN OTHER
                   SET CMDL-RS-OK        TO TRUE
           END-EVALUATE
           MOVE WS-PAGE-NUM              TO CMDL-RS-PAGE-NUM
           MOVE WS-FIRST-ACCT            TO CMDL-RS-FIRST-ACCT
           MOVE WS-FIRST-DATE            TO CMDL-RS-FIRST-DATE
           MOVE WS-LAST-ACCT             TO CMDL-RS-LAST-ACCT
           MOVE WS-LAST-DATE             TO CMDL-RS-LAST-DATE
           .

      *----------------------------------------------------------------*
      * Shared procedures
      *----------------------------------------------------------------*
       COPY CSMODCPY.
