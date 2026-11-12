      ******************************************************************
      * Program     : CBMOD04C.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : BATCH COBOL Db2 Program (TSO attach)
      * Function    : Daily maintenance of the app-mo-db2 tables for
      *               the as-of date in DD PARMFILE (cols 1-10) and
      *               the retention in days (cols 23-26).
      *               1. Over-limit flagging. For each ACCT_DAILY_BAL
      *                  row of the as-of date, flag the account when
      *                  the closing balance is above a non-zero
      *                  credit limit, and clear the flag otherwise.
      *                  Rows are updated through the cursor (WHERE
      *                  CURRENT OF) only when the flag changes; the
      *                  flag date is set when flagging and set to
      *                  NULL when clearing. Commits every 100 updates.
      *               2. History purge. Deletes TRAN_HIST rows dated
      *                  before the as-of date minus the retention
      *                  days, and checks the deleted count against a
      *                  count taken first.
      *               Sets RC 4 when the purge counts disagree.
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
       PROGRAM-ID.    CBMOD04C.
       AUTHOR.        MECHANICAL ORCHARD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PARM-FILE ASSIGN TO PARMFILE
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE  IS SEQUENTIAL
                  FILE STATUS  IS PARMFILE-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  PARM-FILE.
       01  FD-PARM-REC                          PIC X(80).

       WORKING-STORAGE SECTION.

      *****************************************************************
       COPY CVMOD01Y.
       01  PARMFILE-STATUS.
           05  PARMFILE-STAT1                   PIC X.
           05  PARMFILE-STAT2                   PIC X.

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
           05  WS-ASOF-DATE                     PIC X(10).
           05  WS-RETAIN-DAYS                   PIC S9(9) COMP.
           05  WS-CUTOFF-DATE                   PIC X(10).
           05  WS-PURGE-CANDIDATES              PIC S9(9) COMP.
           05  WS-IND-FLAG-DATE                 PIC S9(4) COMP.

      *****************************************************************
      *    Snapshots of the as-of date, for positioned update.
      *    A FOR UPDATE cursor cannot have ORDER BY, so nothing that
      *    depends on the fetch order is written out.
      *****************************************************************
           EXEC SQL
                DECLARE C-OVERLIMIT CURSOR WITH HOLD FOR
                SELECT ADB_ACCT_ID
                     , ADB_CLOSE_BAL
                     , ADB_CREDIT_LIMIT
                     , ADB_OVERLIMIT_FLG
                  FROM CARDDEMO.ACCT_DAILY_BAL
                 WHERE ADB_BAL_DATE = :WS-ASOF-DATE
                   FOR UPDATE OF ADB_OVERLIMIT_FLG
                               , ADB_FLAG_DATE
           END-EXEC.

      *****************************************************************
       01  WS-FLAGS.
           05  WS-END-OF-CURSOR                 PIC X(01) VALUE 'N'.
               88  END-OF-CURSOR                          VALUE 'Y'.
           05  WS-NEW-FLAG                      PIC X(01).
               88  NEW-FLAG-OVERLIMIT                     VALUE 'Y'.
               88  NEW-FLAG-WITHIN-LIMIT                  VALUE 'N'.

       01  WS-COUNTERS.
           05  WS-CHECKED-COUNT                 PIC 9(09) VALUE 0.
           05  WS-OVERLIMIT-COUNT               PIC 9(09) VALUE 0.
           05  WS-FLAGGED-COUNT                 PIC 9(09) VALUE 0.
           05  WS-CLEARED-COUNT                 PIC 9(09) VALUE 0.
           05  WS-PURGED-COUNT                  PIC 9(09) VALUE 0.
           05  WS-CANDIDATE-COUNT               PIC 9(09) VALUE 0.
           05  WS-UNCOMMITTED-COUNT             PIC 9(09) VALUE 0.
           05  WS-COMMIT-COUNT                  PIC 9(09) VALUE 0.

       01  WS-COMMIT-FREQUENCY                  PIC 9(09) VALUE 100.

      *****************************************************************
       PROCEDURE DIVISION.
           DISPLAY 'START OF EXECUTION OF PROGRAM CBMOD04C'.
           PERFORM 0100-READ-PARMS.
           PERFORM 0200-VALIDATE-PARMS.

           PERFORM 1000-OPEN-CURSOR.
           PERFORM 1100-FETCH-SNAPSHOT.
           PERFORM UNTIL END-OF-CURSOR
               ADD 1 TO WS-CHECKED-COUNT
               PERFORM 2000-CHECK-CREDIT-LIMIT
               PERFORM 1100-FETCH-SNAPSHOT
           END-PERFORM.
           PERFORM 1200-CLOSE-CURSOR.
           PERFORM 4000-COMMIT-WORK.

           PERFORM 3000-PURGE-HISTORY.
           PERFORM 4000-COMMIT-WORK.

           DISPLAY 'AS-OF DATE               :' WS-ASOF-DATE.
           DISPLAY 'SNAPSHOTS CHECKED        :' WS-CHECKED-COUNT.
           DISPLAY 'ACCOUNTS OVER LIMIT      :' WS-OVERLIMIT-COUNT.
           DISPLAY 'FLAGS SET                :' WS-FLAGGED-COUNT.
           DISPLAY 'FLAGS CLEARED            :' WS-CLEARED-COUNT.
           DISPLAY 'PURGE CUTOFF DATE        :' WS-CUTOFF-DATE.
           DISPLAY 'TRAN_HIST ROWS TO PURGE  :' WS-CANDIDATE-COUNT.
           DISPLAY 'TRAN_HIST ROWS PURGED    :' WS-PURGED-COUNT.
           DISPLAY 'COMMITS ISSUED           :' WS-COMMIT-COUNT.
           IF WS-PURGED-COUNT NOT = WS-CANDIDATE-COUNT
              DISPLAY 'WARNING: PURGED COUNT DIFFERS FROM CANDIDATES'
              MOVE 4 TO RETURN-CODE
           END-IF.
           DISPLAY 'END OF EXECUTION OF PROGRAM CBMOD04C'.

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
      * Check the retention days, then let Db2 check the as-of date
      * and work out the purge cutoff. DAYS turns the date into a day
      * number, the retention days are subtracted, and DATE turns the
      * result back into a date.
      *---------------------------------------------------------------*
       0200-VALIDATE-PARMS.
           IF MODB-PARM-RETAIN-DAYS IS NOT NUMERIC
              DISPLAY 'RETENTION DAYS IN PARMFILE ARE NOT NUMERIC: '
                      MODB-PARM-RETAIN-DAYS
              MOVE 997 TO ABCODE
              PERFORM 9999-ABEND-PROGRAM
           END-IF
           MOVE MODB-PARM-RETAIN-DAYS TO WS-RETAIN-DAYS

           EXEC SQL
                SELECT CHAR(DATE(:WS-PARM-DATE), ISO)
                     , CHAR(DATE(DAYS(DATE(:WS-PARM-DATE))
                                 - :WS-RETAIN-DAYS), ISO)
                  INTO :WS-ASOF-DATE
                     , :WS-CUTOFF-DATE
                  FROM SYSIBM.SYSDUMMY1
           END-EXEC
           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN SQLCODE = -180
              WHEN SQLCODE = -181
                 DISPLAY 'INVALID AS-OF DATE IN PARMFILE: '
                         WS-PARM-DATE
                 MOVE 997 TO ABCODE
                 PERFORM 9999-ABEND-PROGRAM
              WHEN OTHER
                 MOVE 'VALIDATE AS-OF DATE' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE.
      *---------------------------------------------------------------*
       1000-OPEN-CURSOR.
           EXEC SQL
                OPEN C-OVERLIMIT
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'OPEN CURSOR C-OVERLIMIT' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF.
      *---------------------------------------------------------------*
       1100-FETCH-SNAPSHOT.
           EXEC SQL
                FETCH C-OVERLIMIT
                 INTO :DCL-ADB-ACCT-ID
                    , :DCL-ADB-CLOSE-BAL
                    , :DCL-ADB-CREDIT-LIMIT
                    , :DCL-ADB-OVERLIMIT-FLG
           END-EXEC
           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN SQLCODE = +100
                 SET END-OF-CURSOR TO TRUE
              WHEN OTHER
                 MOVE 'FETCH CURSOR C-OVERLIMIT' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE.
      *---------------------------------------------------------------*
       1200-CLOSE-CURSOR.
           EXEC SQL
                CLOSE C-OVERLIMIT
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'CLOSE CURSOR C-OVERLIMIT' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF.
      *---------------------------------------------------------------*
      * A zero credit limit means no limit is known (the account was
      * not in ACCTDATA when the snapshot was built), so never flag.
      *---------------------------------------------------------------*
       2000-CHECK-CREDIT-LIMIT.
           IF  DCL-ADB-CREDIT-LIMIT > ZERO
           AND DCL-ADB-CLOSE-BAL > DCL-ADB-CREDIT-LIMIT
              SET NEW-FLAG-OVERLIMIT TO TRUE
              ADD 1 TO WS-OVERLIMIT-COUNT
           ELSE
              SET NEW-FLAG-WITHIN-LIMIT TO TRUE
           END-IF

           IF WS-NEW-FLAG NOT = DCL-ADB-OVERLIMIT-FLG
              IF NEW-FLAG-OVERLIMIT
                 MOVE WS-ASOF-DATE TO DCL-ADB-FLAG-DATE
                 MOVE 0            TO WS-IND-FLAG-DATE
                 ADD 1 TO WS-FLAGGED-COUNT
              ELSE
                 MOVE SPACES       TO DCL-ADB-FLAG-DATE
                 MOVE -1           TO WS-IND-FLAG-DATE
                 ADD 1 TO WS-CLEARED-COUNT
              END-IF
              MOVE WS-NEW-FLAG TO DCL-ADB-OVERLIMIT-FLG
              PERFORM 2100-UPDATE-FLAG
           END-IF.
      *---------------------------------------------------------------*
       2100-UPDATE-FLAG.
           EXEC SQL
                UPDATE CARDDEMO.ACCT_DAILY_BAL
                   SET ADB_OVERLIMIT_FLG = :DCL-ADB-OVERLIMIT-FLG
                     , ADB_FLAG_DATE     = :DCL-ADB-FLAG-DATE
                                           :WS-IND-FLAG-DATE
                 WHERE CURRENT OF C-OVERLIMIT
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'UPDATE ACCT_DAILY_BAL WHERE CURRENT OF'
                TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF
           ADD 1 TO WS-UNCOMMITTED-COUNT
           IF WS-UNCOMMITTED-COUNT >= WS-COMMIT-FREQUENCY
              PERFORM 4000-COMMIT-WORK
           END-IF.
      *---------------------------------------------------------------*
       3000-PURGE-HISTORY.
           EXEC SQL
                SELECT COUNT(*)
                  INTO :WS-PURGE-CANDIDATES
                  FROM CARDDEMO.TRAN_HIST
                 WHERE TH_TRAN_DATE < :WS-CUTOFF-DATE
           END-EXEC
           IF SQLCODE NOT = ZERO
              MOVE 'COUNT TRAN_HIST PURGE CANDIDATES' TO WS-SQL-ACTION
              PERFORM 9800-SQL-ERROR
           END-IF
           MOVE WS-PURGE-CANDIDATES TO WS-CANDIDATE-COUNT

           EXEC SQL
                DELETE FROM CARDDEMO.TRAN_HIST
                 WHERE TH_TRAN_DATE < :WS-CUTOFF-DATE
           END-EXEC
           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 MOVE SQLERRD(3) TO WS-PURGED-COUNT
              WHEN SQLCODE = +100
                 MOVE 0 TO WS-PURGED-COUNT
              WHEN OTHER
                 MOVE 'DELETE FROM CARDDEMO.TRAN_HIST' TO WS-SQL-ACTION
                 PERFORM 9800-SQL-ERROR
           END-EVALUATE.
      *---------------------------------------------------------------*
       4000-COMMIT-WORK.
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
