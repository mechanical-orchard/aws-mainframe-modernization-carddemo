      ******************************************************************
      * Program     : COMODUPC.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : CICS COBOL Db2 Program, without a screen
      * Transaction : CMDU
      * Function    : Read one row of CARDDEMO.ACCT_DAILY_BAL, with
      *               that day's totals from CARDDEMO.TRAN_HIST, and
      *               set or clear its over-limit flag.
      *               - A caller LINKs to it with the request in the
      *                 COMMAREA (COMOD02Y) and gets the response back
      *                 in the same COMMAREA
      *               - R reads the row; S sets the flag and C clears
      *                 it. Setting the flag records today's date in
      *                 ADB_FLAG_DATE; clearing it sets it to NULL
      *               - The update applies only if the row still
      *                 matches the row the caller passes; then
      *                 SYNCPOINT, or SYNCPOINT ROLLBACK on any failure
      *               Writes ACCT_DAILY_BAL only.
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
       PROGRAM-ID.    COMODUPC.
       AUTHOR.        MECHANICAL ORCHARD.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *----------------------------------------------------------------*
      * Literals
      *----------------------------------------------------------------*
       01  WS-CONSTANTS.
           05  LIT-THISPGM            PIC X(8)  VALUE 'COMODUPC'.
      *    Abend code when a caller passes no COMMAREA, or one too
      *    short for COMOD02Y: there is nowhere to put a response
           05  LIT-NO-COMMAREA-ABEND  PIC X(4)  VALUE 'MDUC'.
           05  LIT-LOW-DATE           PIC X(10) VALUE '0001-01-01'.

       01  WS-MESSAGES.
           05  MSG-BAD-ACTION         PIC X(60) VALUE
               'Action must be R, S or C'.
           05  MSG-BAD-ACCOUNT        PIC X(60) VALUE
               'Account ID must be a number of 1 to 11 digits'.
           05  MSG-BAD-DATE           PIC X(60) VALUE
               'Balance date must be a valid date in YYYY-MM-DD form'.
           05  MSG-BAD-ROW            PIC X(60) VALUE
               'The row passed with S or C is not valid'.
           05  MSG-SAVED-SET          PIC X(60) VALUE
               'Saved. The over-limit flag is set'.
           05  MSG-SAVED-CLEAR        PIC X(60) VALUE
               'Saved. The over-limit flag is cleared'.
           05  MSG-NOT-FOUND          PIC X(60) VALUE
               'No daily balance for that account and date'.
           05  MSG-ROW-CHANGED        PIC X(60) VALUE
               'Not saved: the row changed since it was read'.

      *----------------------------------------------------------------*
      * Work fields
      *----------------------------------------------------------------*
       01  WS-MISC-STORAGE.
           05  WS-INTERFACE-LEN       PIC S9(4) COMP VALUE 0.
           05  WS-INPUT-FLAG          PIC X     VALUE '0'.
               88  INPUT-OK                     VALUE '0'.
               88  INPUT-ERROR                  VALUE '1'.
           05  WS-KEY-ACCT            PIC 9(11) VALUE 0.
           05  WS-KEY-DATE            PIC X(10) VALUE SPACES.
           05  WS-NEW-FLAG            PIC X     VALUE SPACE.

      *----------------------------------------------------------------*
      * Db2
      *----------------------------------------------------------------*
       01  WS-HOST-VARS.
           05  HV-ACCT-ID             PIC S9(11) COMP-3.
           05  HV-BAL-DATE            PIC X(10).
           05  HV-FLAG-DATE           PIC X(10).
           05  HV-FLAG-DATE-IND       PIC S9(4) COMP.
           05  HV-TH-COUNT            PIC S9(9) COMP.
           05  HV-TH-CREDITS          PIC S9(13)V99 COMP-3.
           05  HV-TH-DEBITS           PIC S9(13)V99 COMP-3.
           05  HV-TH-NET              PIC S9(13)V99 COMP-3.
           05  HV-NEW-FLAG            PIC X.
           05  HV-NEW-FLAG-DATE       PIC X(10).
           05  HV-NEW-FLAG-DATE-IND   PIC S9(4) COMP.
           05  HV-OLD-FLAG-DATE       PIC X(10).
           05  HV-OLD-FLAG-NULL       PIC X.

           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL INCLUDE DCLACDBL END-EXEC.
           EXEC SQL INCLUDE DCLTRHST END-EXEC.

      *----------------------------------------------------------------*
      * Dates, and the checks and formats shared with COMODLIC
      *----------------------------------------------------------------*
       COPY CSDAT01Y.
       COPY CSMODCWY.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           COPY COMOD02Y.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Check the request, act on it, and return the response in the
      * caller's COMMAREA
      *----------------------------------------------------------------*
       0000-MAIN.
           COMPUTE WS-INTERFACE-LEN = LENGTH OF CMDU-REQUEST
                                    + LENGTH OF CMDU-RESPONSE
           IF EIBCALEN < WS-INTERFACE-LEN
               EXEC CICS ABEND ABCODE(LIT-NO-COMMAREA-ABEND)
               END-EXEC
           END-IF

           INITIALIZE CMDU-RESPONSE
           SET CMDU-RS-OK            TO TRUE
           SET CMDU-RS-ROW-NOT-FOUND TO TRUE
           MOVE SPACE                TO CMDU-RS-ERR-FIELD
           MOVE SPACES               TO CMDU-RS-MESSAGE
                                        CMDU-RS-FLAG-DATE
           SET INPUT-OK              TO TRUE

           PERFORM 1000-EDIT-REQUEST
           IF INPUT-OK
               MOVE WS-KEY-ACCT      TO CMDU-RS-ACCT-ID
               MOVE WS-KEY-DATE      TO CMDU-RS-BAL-DATE
               EVALUATE TRUE
                   WHEN CMDU-RQ-READ
                       PERFORM 8100-READ-ROW
                   WHEN OTHER
                       PERFORM 8300-UPDATE-FLAG
               END-EVALUATE
           END-IF

           EXEC CICS RETURN
           END-EXEC
           GOBACK
           .

      *----------------------------------------------------------------*
      * Check the action, the key and, for S and C, the row as read
      *----------------------------------------------------------------*
       1000-EDIT-REQUEST.
           IF NOT CMDU-RQ-READ
           AND NOT CMDU-RQ-SET-FLAG
           AND NOT CMDU-RQ-CLEAR-FLAG
               MOVE 'R'              TO CMDU-RS-ERR-FIELD
               MOVE MSG-BAD-ACTION   TO CMDU-RS-MESSAGE
               SET INPUT-ERROR       TO TRUE
           END-IF

           IF INPUT-OK
               MOVE CMDU-RQ-ACCT-ID  TO WS-AC-INPUT
               INSPECT WS-AC-INPUT REPLACING ALL LOW-VALUE BY SPACE
               PERFORM 9720-PARSE-ACCOUNT
               IF WS-AC-INVALID OR WS-AC-NUM = 0
                   MOVE 'A'             TO CMDU-RS-ERR-FIELD
                   MOVE MSG-BAD-ACCOUNT TO CMDU-RS-MESSAGE
                   SET INPUT-ERROR      TO TRUE
               ELSE
                   MOVE WS-AC-NUM       TO WS-KEY-ACCT
               END-IF
           END-IF

           IF INPUT-OK
               MOVE FUNCTION TRIM(CMDU-RQ-BAL-DATE) TO WS-DC-DATE
               PERFORM 9700-VALIDATE-DATE
               IF WS-DC-VALID
                   MOVE WS-DC-DATE      TO WS-KEY-DATE
               ELSE
                   MOVE 'D'             TO CMDU-RS-ERR-FIELD
                   MOVE MSG-BAD-DATE    TO CMDU-RS-MESSAGE
                   SET INPUT-ERROR      TO TRUE
               END-IF
           END-IF

           IF INPUT-OK AND NOT CMDU-RQ-READ
               PERFORM 1100-EDIT-ROW
           END-IF

           IF INPUT-ERROR
               SET CMDU-RS-BAD-REQUEST TO TRUE
           END-IF
           .

      *    S or C: the row must be one an R response returned, and the
      *    flag must change
       1100-EDIT-ROW.
           IF CMDU-RQ-SET-FLAG
               MOVE 'Y' TO WS-NEW-FLAG
           ELSE
               MOVE 'N' TO WS-NEW-FLAG
           END-IF

           IF CMDU-RQ-OPEN-BAL     IS NOT NUMERIC
           OR CMDU-RQ-CREDIT-AMT   IS NOT NUMERIC
           OR CMDU-RQ-DEBIT-AMT    IS NOT NUMERIC
           OR CMDU-RQ-CLOSE-BAL    IS NOT NUMERIC
           OR CMDU-RQ-TRAN-CNT     IS NOT NUMERIC
           OR CMDU-RQ-CREDIT-LIMIT IS NOT NUMERIC
           OR (CMDU-RQ-OVERLIMIT-FLG NOT = 'Y'
           AND CMDU-RQ-OVERLIMIT-FLG NOT = 'N')
               MOVE 'F'             TO CMDU-RS-ERR-FIELD
               MOVE MSG-BAD-ROW     TO CMDU-RS-MESSAGE
               SET INPUT-ERROR      TO TRUE
           END-IF

           IF INPUT-OK AND CMDU-RQ-FLAG-DATE NOT = SPACES
               MOVE CMDU-RQ-FLAG-DATE TO WS-DC-DATE
               PERFORM 9700-VALIDATE-DATE
               IF WS-DC-INVALID
                   MOVE 'F'         TO CMDU-RS-ERR-FIELD
                   MOVE MSG-BAD-ROW TO CMDU-RS-MESSAGE
                   SET INPUT-ERROR  TO TRUE
               END-IF
           END-IF

           IF INPUT-OK AND WS-NEW-FLAG = CMDU-RQ-OVERLIMIT-FLG
               MOVE 'F'             TO CMDU-RS-ERR-FIELD
               STRING 'The over-limit flag is already '
                                    DELIMITED BY SIZE
                      WS-NEW-FLAG   DELIMITED BY SIZE
                 INTO CMDU-RS-MESSAGE
               END-STRING
               SET INPUT-ERROR      TO TRUE
           END-IF
           .

      *----------------------------------------------------------------*
      * Read the row for the request's key, and that day's transaction
      * history totals
      *----------------------------------------------------------------*
       8100-READ-ROW.
           MOVE WS-KEY-ACCT       TO HV-ACCT-ID
           MOVE WS-KEY-DATE       TO HV-BAL-DATE
           EXEC SQL
                SELECT ADB_OPEN_BAL
                     , ADB_CREDIT_AMT
                     , ADB_DEBIT_AMT
                     , ADB_CLOSE_BAL
                     , ADB_TRAN_CNT
                     , ADB_CREDIT_LIMIT
                     , ADB_OVERLIMIT_FLG
                     , CHAR(ADB_FLAG_DATE, ISO)
                  INTO :DCL-ADB-OPEN-BAL
                     , :DCL-ADB-CREDIT-AMT
                     , :DCL-ADB-DEBIT-AMT
                     , :DCL-ADB-CLOSE-BAL
                     , :DCL-ADB-TRAN-CNT
                     , :DCL-ADB-CREDIT-LIMIT
                     , :DCL-ADB-OVERLIMIT-FLG
                     , :HV-FLAG-DATE :HV-FLAG-DATE-IND
                  FROM CARDDEMO.ACCT_DAILY_BAL
                 WHERE ADB_ACCT_ID  = :HV-ACCT-ID
                   AND ADB_BAL_DATE = :HV-BAL-DATE
           END-EXEC
           EVALUATE TRUE
               WHEN SQLCODE = 0
                   SET CMDU-RS-ROW-FOUND      TO TRUE
                   MOVE DCL-ADB-OPEN-BAL      TO CMDU-RS-OPEN-BAL
                   MOVE DCL-ADB-CREDIT-AMT    TO CMDU-RS-CREDIT-AMT
                   MOVE DCL-ADB-DEBIT-AMT     TO CMDU-RS-DEBIT-AMT
                   MOVE DCL-ADB-CLOSE-BAL     TO CMDU-RS-CLOSE-BAL
                   MOVE DCL-ADB-TRAN-CNT      TO CMDU-RS-TRAN-CNT
                   MOVE DCL-ADB-CREDIT-LIMIT  TO CMDU-RS-CREDIT-LIMIT
                   MOVE DCL-ADB-OVERLIMIT-FLG TO CMDU-RS-OVERLIMIT-FLG
                   IF HV-FLAG-DATE-IND < 0
                       MOVE SPACES            TO CMDU-RS-FLAG-DATE
                   ELSE
                       MOVE HV-FLAG-DATE      TO CMDU-RS-FLAG-DATE
                   END-IF
                   PERFORM 8200-READ-HISTORY
               WHEN SQLCODE = 100
                   SET CMDU-RS-ROW-NOT-FOUND  TO TRUE
                   SET CMDU-RS-NOTICE         TO TRUE
                   MOVE MSG-NOT-FOUND         TO CMDU-RS-MESSAGE
               WHEN OTHER
                   SET CMDU-RS-ROW-NOT-FOUND  TO TRUE
                   MOVE 'Read of the daily balance' TO WS-DB2-ACTION
                   PERFORM 8900-DB2-ERROR
           END-EVALUATE
           .

       8200-READ-HISTORY.
           EXEC SQL
                SELECT COUNT(*)
                     , COALESCE(SUM(CASE WHEN TH_AMT >= 0
                                         THEN TH_AMT ELSE 0 END), 0)
                     , COALESCE(SUM(CASE WHEN TH_AMT < 0
                                         THEN TH_AMT ELSE 0 END), 0)
                     , COALESCE(SUM(TH_AMT), 0)
                  INTO :HV-TH-COUNT
                     , :HV-TH-CREDITS
                     , :HV-TH-DEBITS
                     , :HV-TH-NET
                  FROM CARDDEMO.TRAN_HIST
                 WHERE TH_ACCT_ID   = :HV-ACCT-ID
                   AND TH_TRAN_DATE = :HV-BAL-DATE
           END-EXEC
           IF SQLCODE = 0
               MOVE HV-TH-COUNT   TO CMDU-RS-TH-COUNT
               MOVE HV-TH-CREDITS TO CMDU-RS-TH-CREDITS
               MOVE HV-TH-DEBITS  TO CMDU-RS-TH-DEBITS
               MOVE HV-TH-NET     TO CMDU-RS-TH-NET
           ELSE
               INITIALIZE CMDU-RS-HISTORY
               MOVE 'Read of transaction history' TO WS-DB2-ACTION
               PERFORM 8900-DB2-ERROR
           END-IF
           .

      *----------------------------------------------------------------*
      * S or C: set or clear the flag, only if the row still matches
      * the row the caller passes. One unit of work: SYNCPOINT on
      * success, SYNCPOINT ROLLBACK otherwise.
      *----------------------------------------------------------------*
       8300-UPDATE-FLAG.
           MOVE WS-KEY-ACCT           TO HV-ACCT-ID
           MOVE WS-KEY-DATE           TO HV-BAL-DATE
           MOVE WS-NEW-FLAG           TO HV-NEW-FLAG
           IF WS-NEW-FLAG = 'Y'
               MOVE FUNCTION CURRENT-DATE TO WS-CURDATE-DATA
               STRING WS-CURDATE(1:4) '-'
                      WS-CURDATE(5:2) '-'
                      WS-CURDATE(7:2)
                      DELIMITED BY SIZE
                 INTO HV-NEW-FLAG-DATE
               END-STRING
               MOVE 0                 TO HV-NEW-FLAG-DATE-IND
           ELSE
               MOVE LIT-LOW-DATE      TO HV-NEW-FLAG-DATE
               MOVE -1                TO HV-NEW-FLAG-DATE-IND
           END-IF

      *    The row as the caller read it
           MOVE CMDU-RQ-OPEN-BAL      TO DCL-ADB-OPEN-BAL
           MOVE CMDU-RQ-CREDIT-AMT    TO DCL-ADB-CREDIT-AMT
           MOVE CMDU-RQ-DEBIT-AMT     TO DCL-ADB-DEBIT-AMT
           MOVE CMDU-RQ-CLOSE-BAL     TO DCL-ADB-CLOSE-BAL
           MOVE CMDU-RQ-TRAN-CNT      TO DCL-ADB-TRAN-CNT
           MOVE CMDU-RQ-CREDIT-LIMIT  TO DCL-ADB-CREDIT-LIMIT
           MOVE CMDU-RQ-OVERLIMIT-FLG TO DCL-ADB-OVERLIMIT-FLG
           IF CMDU-RQ-FLAG-DATE = SPACES
               MOVE LIT-LOW-DATE      TO HV-OLD-FLAG-DATE
               MOVE 'Y'               TO HV-OLD-FLAG-NULL
           ELSE
               MOVE CMDU-RQ-FLAG-DATE TO HV-OLD-FLAG-DATE
               MOVE 'N'               TO HV-OLD-FLAG-NULL
           END-IF

           EXEC SQL
                UPDATE CARDDEMO.ACCT_DAILY_BAL
                   SET ADB_OVERLIMIT_FLG = :HV-NEW-FLAG
                     , ADB_FLAG_DATE     = :HV-NEW-FLAG-DATE
                                           :HV-NEW-FLAG-DATE-IND
                 WHERE ADB_ACCT_ID       = :HV-ACCT-ID
                   AND ADB_BAL_DATE      = :HV-BAL-DATE
                   AND ADB_OPEN_BAL      = :DCL-ADB-OPEN-BAL
                   AND ADB_CREDIT_AMT    = :DCL-ADB-CREDIT-AMT
                   AND ADB_DEBIT_AMT     = :DCL-ADB-DEBIT-AMT
                   AND ADB_CLOSE_BAL     = :DCL-ADB-CLOSE-BAL
                   AND ADB_TRAN_CNT      = :DCL-ADB-TRAN-CNT
                   AND ADB_CREDIT_LIMIT  = :DCL-ADB-CREDIT-LIMIT
                   AND ADB_OVERLIMIT_FLG = :DCL-ADB-OVERLIMIT-FLG
                   AND ((ADB_FLAG_DATE IS NULL
                   AND   :HV-OLD-FLAG-NULL = 'Y')
                    OR  (ADB_FLAG_DATE = :HV-OLD-FLAG-DATE
                   AND   :HV-OLD-FLAG-NULL = 'N'))
           END-EXEC

           EVALUATE TRUE
               WHEN SQLCODE = 0
                   EXEC CICS SYNCPOINT
                   END-EXEC
                   PERFORM 8100-READ-ROW
                   IF CMDU-RS-OK
                       IF WS-NEW-FLAG = 'Y'
                           MOVE MSG-SAVED-SET   TO CMDU-RS-MESSAGE
                       ELSE
                           MOVE MSG-SAVED-CLEAR TO CMDU-RS-MESSAGE
                       END-IF
                   END-IF
               WHEN SQLCODE = 100
      *            Changed or deleted since it was read: return the
      *            current row, if there is one
                   EXEC CICS SYNCPOINT ROLLBACK
                   END-EXEC
                   PERFORM 8100-READ-ROW
                   IF CMDU-RS-OK
                       SET CMDU-RS-NOTICE       TO TRUE
                       MOVE MSG-ROW-CHANGED     TO CMDU-RS-MESSAGE
                   END-IF
               WHEN OTHER
      *            Format the message first: ROLLBACK resets the SQLCA
                   MOVE 'Update of the over-limit flag'
                                            TO WS-DB2-ACTION
                   PERFORM 8900-DB2-ERROR
                   EXEC CICS SYNCPOINT ROLLBACK
                   END-EXEC
           END-EVALUATE
           .

       8900-DB2-ERROR.
           SET CMDU-RS-DB2-ERROR TO TRUE
           PERFORM 9800-FORMAT-DB2-MESSAGE
           MOVE WS-DB2-MESSAGE   TO CMDU-RS-MESSAGE
           .

      *----------------------------------------------------------------*
      * Shared procedures
      *----------------------------------------------------------------*
       COPY CSMODCPY.
