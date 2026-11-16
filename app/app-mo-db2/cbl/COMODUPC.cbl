      ******************************************************************
      * Program     : COMODUPC.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : CICS COBOL Db2 Program
      * Transaction : CMDU
      * Function    : Show one row of CARDDEMO.ACCT_DAILY_BAL, with
      *               that day's totals from CARDDEMO.TRAN_HIST, and
      *               set or clear its over-limit flag.
      *               - The key (account ID and balance date) comes
      *                 from CMDL (COMODLIC) or is typed in
      *               - Y or N in New flag, then F5 to save or F12 to
      *                 cancel. Setting the flag records today's date
      *                 in ADB_FLAG_DATE; clearing it sets it to NULL
      *               - The update applies only if the row still
      *                 matches what was shown; then SYNCPOINT, or
      *                 SYNCPOINT ROLLBACK on any failure
      *               - F3 returns to the caller, by default the
      *                 CardDemo admin menu
      *               It can also be started by typing CMDU.
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
           05  LIT-THISTRANID         PIC X(4)  VALUE 'CMDU'.
           05  LIT-THISMAPSET         PIC X(7)  VALUE 'COMODUP'.
           05  LIT-THISMAP            PIC X(7)  VALUE 'CMODUPA'.
           05  LIT-ADMINPGM           PIC X(8)  VALUE 'COADM01C'.
           05  LIT-ADMINTRANID        PIC X(4)  VALUE 'CA00'.
           05  LIT-LISTPGM            PIC X(8)  VALUE 'COMODLIC'.
           05  LIT-LOW-DATE           PIC X(10) VALUE '0001-01-01'.

       01  WS-MESSAGES.
           05  MSG-ENTER-KEY          PIC X(60) VALUE
               'Type an account ID and balance date, then press ENTER'.
           05  MSG-ENTER-FLAG         PIC X(60) VALUE
               'Type Y or N in New flag and press ENTER'.
           05  MSG-CONFIRM-SET        PIC X(60) VALUE
               'Press F5 to set the flag, or F12 to cancel'.
           05  MSG-CONFIRM-CLEAR      PIC X(60) VALUE
               'Press F5 to clear the flag, or F12 to cancel'.
           05  MSG-SAVED-SET          PIC X(60) VALUE
               'Saved. The over-limit flag is set'.
           05  MSG-SAVED-CLEAR        PIC X(60) VALUE
               'Saved. The over-limit flag is cleared'.
           05  MSG-CANCELLED          PIC X(60) VALUE
               'Change cancelled'.
           05  MSG-BAD-ACCOUNT        PIC X(60) VALUE
               'Account ID must be a number of 1 to 11 digits'.
           05  MSG-BAD-DATE           PIC X(60) VALUE
               'Balance date must be a valid date in YYYY-MM-DD form'.
           05  MSG-BAD-FLAG           PIC X(60) VALUE
               'New flag must be Y or N'.
           05  MSG-NOT-FOUND          PIC X(60) VALUE
               'No daily balance for that account and date'.
           05  MSG-ROW-CHANGED        PIC X(60) VALUE
               'Not saved: the row changed since it was shown'.
           05  MSG-CONFIRM-FIRST      PIC X(60) VALUE
               'Type Y or N in New flag and press ENTER first'.

      *----------------------------------------------------------------*
      * Work fields
      *----------------------------------------------------------------*
       01  WS-MISC-STORAGE.
           05  WS-RESP-CD             PIC S9(9) COMP VALUE 0.
           05  WS-REAS-CD             PIC S9(9) COMP VALUE 0.
           05  WS-COMMAREA-LEN        PIC S9(4) COMP VALUE 0.
           05  WS-KEY-LEN             PIC S9(4) COMP VALUE 0.
           05  WS-INPUT-FLAG          PIC X     VALUE '0'.
               88  INPUT-OK                     VALUE '0'.
               88  INPUT-ERROR                  VALUE '1'.
           05  WS-ERR-FIELD           PIC X     VALUE SPACE.
               88  ERR-ON-NONE                  VALUE SPACE.
               88  ERR-ON-ACCT                  VALUE 'A'.
               88  ERR-ON-DATE                  VALUE 'D'.
               88  ERR-ON-FLAG                  VALUE 'F'.
           05  WS-MAP-FLAG            PIC X     VALUE 'N'.
               88  MAP-RECEIVED                 VALUE 'Y'.
               88  MAP-NOT-RECEIVED             VALUE 'N'.
           05  WS-DB2-FLAG            PIC X     VALUE '0'.
               88  DB2-OK                       VALUE '0'.
               88  DB2-ERROR                    VALUE '1'.
           05  WS-MESSAGE             PIC X(78) VALUE SPACES.
           05  WS-INFO-MSG            PIC X(60) VALUE SPACES.
           05  WS-END-MSG             PIC X(60) VALUE SPACES.
           05  WS-ACCT-IN             PIC X(11) VALUE SPACES.
           05  WS-DATE-IN             PIC X(10) VALUE SPACES.
           05  WS-KEY-ACCT            PIC 9(11) VALUE 0.
           05  WS-KEY-DATE            PIC X(10) VALUE SPACES.
           05  WS-NEW-FLAG            PIC X     VALUE SPACE.
           05  WS-SAVED-FLAG          PIC X     VALUE SPACE.
           05  WS-CNT-EDIT            PIC -(10)9.

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
      * COMMAREA: the CardDemo area, then this program's own state.
      * CA-ROW keeps the row as shown, to detect later changes.
      *----------------------------------------------------------------*
       COPY COCOM01Y.
       COPY COMOD01Y.

       01  WS-THIS-PROGCOMMAREA.
           05  CA-CALLER-TRANID       PIC X(4).
           05  CA-CALLER-PGM          PIC X(8).
           05  CA-STATE               PIC X.
               88  CA-KEY-NEEDED                VALUES SPACE
                                                       LOW-VALUE
                                                       'K'.
               88  CA-ROW-SHOWN                 VALUE 'S'.
               88  CA-CONFIRM-PENDING           VALUE 'C'.
           05  CA-ACCT-ID             PIC 9(11).
           05  CA-BAL-DATE            PIC X(10).
           05  CA-NEW-FLAG            PIC X.
           05  CA-ROW.
               10  CA-OPEN-BAL        PIC S9(10)V99 COMP-3.
               10  CA-CREDIT-AMT      PIC S9(10)V99 COMP-3.
               10  CA-DEBIT-AMT       PIC S9(10)V99 COMP-3.
               10  CA-CLOSE-BAL       PIC S9(10)V99 COMP-3.
               10  CA-TRAN-CNT        PIC S9(9) COMP.
               10  CA-CREDIT-LIMIT    PIC S9(10)V99 COMP-3.
               10  CA-OVERLIMIT-FLG   PIC X.
               10  CA-FLAG-DATE       PIC X(10).
               10  CA-FLAG-DATE-NULL  PIC X.
           05  CA-HISTORY.
               10  CA-TH-COUNT        PIC S9(9) COMP.
               10  CA-TH-CREDITS      PIC S9(13)V99 COMP-3.
               10  CA-TH-DEBITS       PIC S9(13)V99 COMP-3.
               10  CA-TH-NET          PIC S9(13)V99 COMP-3.

       01  WS-COMMAREA                PIC X(1000).

      *----------------------------------------------------------------*
      * Screen, titles, dates, messages and PF keys
      *----------------------------------------------------------------*
       COPY DFHBMSCA.
       COPY DFHAID.
       COPY COTTL01Y.
       COPY CSDAT01Y.
       COPY CSMSG01Y.
       COPY CVCRD01Y.
       COPY CSMODCWY.
       COPY COMODUP.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05  FILLER                 PIC X(1)
               OCCURS 1 TO 32767 TIMES DEPENDING ON EIBCALEN.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Started by CMDU (no COMMAREA), by another program's XCTL, or
      * again after this program's own screen.
      *----------------------------------------------------------------*
       0000-MAIN.
           INITIALIZE CC-WORK-AREA
           MOVE SPACES TO WS-MESSAGE
                          WS-INFO-MSG
           SET INPUT-OK     TO TRUE
           SET ERR-ON-NONE  TO TRUE
           SET DB2-OK       TO TRUE
           COMPUTE WS-COMMAREA-LEN = LENGTH OF CARDDEMO-COMMAREA
                                   + LENGTH OF WS-THIS-PROGCOMMAREA
           COMPUTE WS-KEY-LEN      = LENGTH OF CARDDEMO-COMMAREA
                                   + LENGTH OF CMOD-PASSED-KEY

           IF EIBCALEN < LENGTH OF CARDDEMO-COMMAREA
               INITIALIZE CARDDEMO-COMMAREA
                          WS-THIS-PROGCOMMAREA
               MOVE LIT-THISTRANID     TO CDEMO-FROM-TRANID
               MOVE LIT-THISPGM        TO CDEMO-FROM-PROGRAM
               SET CDEMO-USRTYP-ADMIN  TO TRUE
               SET CDEMO-PGM-ENTER     TO TRUE
               MOVE LIT-ADMINTRANID    TO CA-CALLER-TRANID
               MOVE LIT-ADMINPGM       TO CA-CALLER-PGM
               MOVE MSG-ENTER-KEY      TO WS-INFO-MSG
           ELSE
               MOVE DFHCOMMAREA(1:LENGTH OF CARDDEMO-COMMAREA)
                 TO CARDDEMO-COMMAREA
               IF  CDEMO-FROM-PROGRAM = LIT-THISPGM
               AND EIBCALEN NOT < WS-COMMAREA-LEN
                   MOVE DFHCOMMAREA(LENGTH OF CARDDEMO-COMMAREA + 1:
                                    LENGTH OF WS-THIS-PROGCOMMAREA)
                     TO WS-THIS-PROGCOMMAREA
                   PERFORM YYYY-STORE-PFKEY
                      THRU YYYY-STORE-PFKEY-EXIT
                   PERFORM 2000-PROCESS-INPUT
               ELSE
                   PERFORM 1000-ENTER-FROM-CALLER
               END-IF
           END-IF

           PERFORM 3000-SEND-MAP
           PERFORM 9000-RETURN
           GOBACK
           .

      *----------------------------------------------------------------*
      * Entered by XCTL: remember the caller. From CMDL, show the row
      * it passed.
      *----------------------------------------------------------------*
       1000-ENTER-FROM-CALLER.
           INITIALIZE WS-THIS-PROGCOMMAREA
           IF CDEMO-FROM-PROGRAM = SPACES OR LOW-VALUES
               MOVE LIT-ADMINTRANID    TO CA-CALLER-TRANID
               MOVE LIT-ADMINPGM       TO CA-CALLER-PGM
           ELSE
               MOVE CDEMO-FROM-TRANID  TO CA-CALLER-TRANID
               MOVE CDEMO-FROM-PROGRAM TO CA-CALLER-PGM
           END-IF
           IF  CDEMO-FROM-PROGRAM = LIT-LISTPGM
           AND EIBCALEN NOT < WS-KEY-LEN
               MOVE DFHCOMMAREA(LENGTH OF CARDDEMO-COMMAREA + 1:
                                LENGTH OF CMOD-PASSED-KEY)
                 TO CMOD-PASSED-KEY
               IF CMOD-KEY-ACCT-ID IS NUMERIC
                   MOVE CMOD-KEY-ACCT-ID  TO CA-ACCT-ID
                   MOVE CMOD-KEY-BAL-DATE TO CA-BAL-DATE
                   PERFORM 8100-READ-ROW
               END-IF
           END-IF
           IF CA-KEY-NEEDED AND WS-MESSAGE = SPACES
               MOVE MSG-ENTER-KEY      TO WS-INFO-MSG
           END-IF
           .

      *----------------------------------------------------------------*
      * Act on the key the user pressed
      *----------------------------------------------------------------*
       2000-PROCESS-INPUT.
           IF CCARD-AID-PFK03
               PERFORM 9100-RETURN-TO-CALLER
           END-IF

           PERFORM 2100-RECEIVE-MAP

           EVALUATE TRUE
               WHEN CCARD-AID-ENTER
                   IF MAP-RECEIVED
                       PERFORM 2200-PROCESS-ENTER
                   ELSE
                       MOVE MSG-ENTER-KEY        TO WS-INFO-MSG
                   END-IF
               WHEN CCARD-AID-PFK05
                   IF CA-CONFIRM-PENDING
                       PERFORM 8300-UPDATE-FLAG
                   ELSE
                       MOVE MSG-CONFIRM-FIRST    TO WS-MESSAGE
                   END-IF
               WHEN CCARD-AID-PFK12
                   IF CA-ROW-SHOWN OR CA-CONFIRM-PENDING
                       PERFORM 8100-READ-ROW
                       IF CA-ROW-SHOWN
                           MOVE MSG-CANCELLED    TO WS-INFO-MSG
                       END-IF
                   ELSE
                       MOVE MSG-ENTER-KEY        TO WS-INFO-MSG
                   END-IF
               WHEN OTHER
                   MOVE CCDA-MSG-INVALID-KEY     TO WS-MESSAGE
           END-EVALUATE
           .

       2100-RECEIVE-MAP.
           EXEC CICS RECEIVE MAP(LIT-THISMAP)
                             MAPSET(LIT-THISMAPSET)
                             INTO(CMODUPAI)
                             RESP(WS-RESP-CD)
                             RESP2(WS-REAS-CD)
           END-EXEC
      *    CLEAR and the PA keys send no data (MAPFAIL)
           IF WS-RESP-CD = DFHRESP(NORMAL)
               SET MAP-RECEIVED     TO TRUE
           ELSE
               SET MAP-NOT-RECEIVED TO TRUE
           END-IF
           .

      *----------------------------------------------------------------*
      * ENTER: a new key reads that row; the same key checks the new
      * flag and asks for confirmation.
      *----------------------------------------------------------------*
       2200-PROCESS-ENTER.
           PERFORM 2210-EDIT-KEY
           IF INPUT-OK
               IF CA-KEY-NEEDED
               OR WS-KEY-ACCT NOT = CA-ACCT-ID
               OR WS-KEY-DATE NOT = CA-BAL-DATE
                   MOVE WS-KEY-ACCT TO CA-ACCT-ID
                   MOVE WS-KEY-DATE TO CA-BAL-DATE
                   PERFORM 8100-READ-ROW
               ELSE
                   PERFORM 2220-EDIT-NEW-FLAG
               END-IF
           END-IF
           .

       2210-EDIT-KEY.
           MOVE ACCTIDI OF CMODUPAI  TO WS-ACCT-IN
           MOVE BALDATEI OF CMODUPAI TO WS-DATE-IN
           INSPECT WS-ACCT-IN REPLACING ALL LOW-VALUE BY SPACE
           INSPECT WS-DATE-IN REPLACING ALL LOW-VALUE BY SPACE

           MOVE WS-ACCT-IN TO WS-AC-INPUT
           PERFORM 9720-PARSE-ACCOUNT
           IF WS-AC-INVALID OR WS-AC-NUM = 0
               SET INPUT-ERROR      TO TRUE
               SET ERR-ON-ACCT      TO TRUE
               MOVE MSG-BAD-ACCOUNT TO WS-MESSAGE
           ELSE
               MOVE WS-AC-NUM       TO WS-KEY-ACCT
               MOVE FUNCTION TRIM(WS-DATE-IN) TO WS-DC-DATE
               PERFORM 9700-VALIDATE-DATE
               IF WS-DC-VALID
                   MOVE WS-DC-DATE  TO WS-KEY-DATE
               ELSE
                   SET INPUT-ERROR  TO TRUE
                   SET ERR-ON-DATE  TO TRUE
                   MOVE MSG-BAD-DATE TO WS-MESSAGE
               END-IF
           END-IF
           .

       2220-EDIT-NEW-FLAG.
           MOVE NEWFLGI OF CMODUPAI TO WS-NEW-FLAG
           IF WS-NEW-FLAG = LOW-VALUE
               MOVE SPACE TO WS-NEW-FLAG
           END-IF
           INSPECT WS-NEW-FLAG CONVERTING 'yn' TO 'YN'

           EVALUATE TRUE
               WHEN WS-NEW-FLAG = SPACE
                   SET CA-ROW-SHOWN       TO TRUE
                   MOVE SPACE             TO CA-NEW-FLAG
                   MOVE MSG-ENTER-FLAG    TO WS-INFO-MSG
               WHEN WS-NEW-FLAG NOT = 'Y' AND WS-NEW-FLAG NOT = 'N'
                   SET CA-ROW-SHOWN       TO TRUE
                   SET INPUT-ERROR        TO TRUE
                   SET ERR-ON-FLAG        TO TRUE
                   MOVE MSG-BAD-FLAG      TO WS-MESSAGE
               WHEN WS-NEW-FLAG = CA-OVERLIMIT-FLG
                   SET CA-ROW-SHOWN       TO TRUE
                   SET INPUT-ERROR        TO TRUE
                   SET ERR-ON-FLAG        TO TRUE
                   STRING 'The over-limit flag is already '
                                          DELIMITED BY SIZE
                          WS-NEW-FLAG     DELIMITED BY SIZE
                     INTO WS-MESSAGE
                   END-STRING
               WHEN OTHER
                   MOVE WS-NEW-FLAG       TO CA-NEW-FLAG
                   SET CA-CONFIRM-PENDING TO TRUE
                   IF WS-NEW-FLAG = 'Y'
                       MOVE MSG-CONFIRM-SET   TO WS-INFO-MSG
                   ELSE
                       MOVE MSG-CONFIRM-CLEAR TO WS-INFO-MSG
                   END-IF
           END-EVALUATE
           .

      *----------------------------------------------------------------*
      * Build and send the screen
      *----------------------------------------------------------------*
       3000-SEND-MAP.
           MOVE LOW-VALUES TO CMODUPAO
           PERFORM 3100-SCREEN-HEADER

           IF ERR-ON-ACCT OR ERR-ON-DATE
               MOVE WS-ACCT-IN        TO ACCTIDO OF CMODUPAO
               MOVE WS-DATE-IN        TO BALDATEO OF CMODUPAO
           ELSE
               IF CA-ACCT-ID > 0
                   MOVE CA-ACCT-ID    TO ACCTIDO OF CMODUPAO
                   MOVE CA-BAL-DATE   TO BALDATEO OF CMODUPAO
               END-IF
           END-IF

           IF CA-ROW-SHOWN OR CA-CONFIRM-PENDING
               PERFORM 3200-SHOW-ROW
           ELSE
      *        No row yet: nothing to flag
               MOVE DFHBMASK          TO NEWFLGA OF CMODUPAI
           END-IF

           IF CA-CONFIRM-PENDING
               MOVE CA-NEW-FLAG       TO NEWFLGO OF CMODUPAO
               MOVE DFHBMASB          TO FKEY05A OF CMODUPAI
               MOVE DFHBMASB          TO FKEY12A OF CMODUPAI
           END-IF
           IF ERR-ON-FLAG
               MOVE WS-NEW-FLAG       TO NEWFLGO OF CMODUPAO
           END-IF

           MOVE WS-INFO-MSG TO INFOMSGO OF CMODUPAO
           MOVE WS-MESSAGE  TO ERRMSGO OF CMODUPAO

           EVALUATE TRUE
               WHEN ERR-ON-DATE
                   MOVE -1 TO BALDATEL OF CMODUPAI
               WHEN ERR-ON-ACCT
                   MOVE -1 TO ACCTIDL OF CMODUPAI
               WHEN CA-ROW-SHOWN OR CA-CONFIRM-PENDING
                   MOVE -1 TO NEWFLGL OF CMODUPAI
               WHEN OTHER
                   MOVE -1 TO ACCTIDL OF CMODUPAI
           END-EVALUATE

           EXEC CICS SEND MAP(LIT-THISMAP)
                          MAPSET(LIT-THISMAPSET)
                          FROM(CMODUPAO)
                          CURSOR
                          ERASE
                          FREEKB
                          RESP(WS-RESP-CD)
           END-EXEC
           .

       3100-SCREEN-HEADER.
           MOVE FUNCTION CURRENT-DATE  TO WS-CURDATE-DATA
           MOVE CCDA-TITLE01           TO TITLE01O OF CMODUPAO
           MOVE CCDA-TITLE02           TO TITLE02O OF CMODUPAO
           MOVE LIT-THISTRANID         TO TRNNAMEO OF CMODUPAO
           MOVE LIT-THISPGM            TO PGMNAMEO OF CMODUPAO
           MOVE WS-CURDATE-MONTH       TO WS-CURDATE-MM
           MOVE WS-CURDATE-DAY         TO WS-CURDATE-DD
           MOVE WS-CURDATE-YEAR(3:2)   TO WS-CURDATE-YY
           MOVE WS-CURDATE-MM-DD-YY    TO CURDATEO OF CMODUPAO
           MOVE WS-CURTIME-HOURS       TO WS-CURTIME-HH
           MOVE WS-CURTIME-MINUTE      TO WS-CURTIME-MM
           MOVE WS-CURTIME-SECOND      TO WS-CURTIME-SS
           MOVE WS-CURTIME-HH-MM-SS    TO CURTIMEO OF CMODUPAO
           .

       3200-SHOW-ROW.
           MOVE CA-OPEN-BAL       TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO OPENBALO OF CMODUPAO
           MOVE CA-CREDIT-AMT     TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO CREDITSO OF CMODUPAO
           MOVE CA-DEBIT-AMT      TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO DEBITSO OF CMODUPAO
           MOVE CA-CLOSE-BAL      TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO CLOSBALO OF CMODUPAO
           MOVE CA-CREDIT-LIMIT   TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO CRLIMITO OF CMODUPAO
           MOVE CA-TRAN-CNT       TO WS-CNT-EDIT
           MOVE WS-CNT-EDIT       TO TRANCNTO OF CMODUPAO

           MOVE CA-TH-COUNT       TO WS-CNT-EDIT
           MOVE WS-CNT-EDIT       TO THCOUNTO OF CMODUPAO
           MOVE CA-TH-NET         TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO THNETO OF CMODUPAO
           MOVE CA-TH-CREDITS     TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO THCREDO OF CMODUPAO
           MOVE CA-TH-DEBITS      TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-LONG   TO THDEBTO OF CMODUPAO

           MOVE CA-OVERLIMIT-FLG  TO CURFLGO OF CMODUPAO
           MOVE CA-FLAG-DATE      TO FLGDATEO OF CMODUPAO
           .

      *----------------------------------------------------------------*
      * Read the row for CA-ACCT-ID and CA-BAL-DATE, and that day's
      * transaction history totals
      *----------------------------------------------------------------*
       8100-READ-ROW.
           MOVE CA-ACCT-ID        TO HV-ACCT-ID
           MOVE CA-BAL-DATE       TO HV-BAL-DATE
           MOVE SPACE             TO CA-NEW-FLAG
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
                   MOVE DCL-ADB-OPEN-BAL      TO CA-OPEN-BAL
                   MOVE DCL-ADB-CREDIT-AMT    TO CA-CREDIT-AMT
                   MOVE DCL-ADB-DEBIT-AMT     TO CA-DEBIT-AMT
                   MOVE DCL-ADB-CLOSE-BAL     TO CA-CLOSE-BAL
                   MOVE DCL-ADB-TRAN-CNT      TO CA-TRAN-CNT
                   MOVE DCL-ADB-CREDIT-LIMIT  TO CA-CREDIT-LIMIT
                   MOVE DCL-ADB-OVERLIMIT-FLG TO CA-OVERLIMIT-FLG
                   IF HV-FLAG-DATE-IND < 0
                       MOVE SPACES            TO CA-FLAG-DATE
                       MOVE 'Y'               TO CA-FLAG-DATE-NULL
                   ELSE
                       MOVE HV-FLAG-DATE      TO CA-FLAG-DATE
                       MOVE 'N'               TO CA-FLAG-DATE-NULL
                   END-IF
                   SET CA-ROW-SHOWN           TO TRUE
                   MOVE MSG-ENTER-FLAG        TO WS-INFO-MSG
                   PERFORM 8200-READ-HISTORY
               WHEN SQLCODE = 100
                   SET CA-KEY-NEEDED          TO TRUE
                   MOVE MSG-NOT-FOUND         TO WS-MESSAGE
               WHEN OTHER
                   SET CA-KEY-NEEDED          TO TRUE
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
               MOVE HV-TH-COUNT   TO CA-TH-COUNT
               MOVE HV-TH-CREDITS TO CA-TH-CREDITS
               MOVE HV-TH-DEBITS  TO CA-TH-DEBITS
               MOVE HV-TH-NET     TO CA-TH-NET
           ELSE
               INITIALIZE CA-HISTORY
               MOVE 'Read of transaction history' TO WS-DB2-ACTION
               PERFORM 8900-DB2-ERROR
           END-IF
           .

      *----------------------------------------------------------------*
      * F5: set or clear the flag, only if the row is unchanged since
      * it was shown. One unit of work: SYNCPOINT on success,
      * SYNCPOINT ROLLBACK otherwise.
      *----------------------------------------------------------------*
       8300-UPDATE-FLAG.
           MOVE CA-ACCT-ID            TO HV-ACCT-ID
           MOVE CA-BAL-DATE           TO HV-BAL-DATE
           MOVE CA-NEW-FLAG           TO HV-NEW-FLAG
                                         WS-SAVED-FLAG
           IF CA-NEW-FLAG = 'Y'
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

      *    The row as shown
           MOVE CA-OPEN-BAL           TO DCL-ADB-OPEN-BAL
           MOVE CA-CREDIT-AMT         TO DCL-ADB-CREDIT-AMT
           MOVE CA-DEBIT-AMT          TO DCL-ADB-DEBIT-AMT
           MOVE CA-CLOSE-BAL          TO DCL-ADB-CLOSE-BAL
           MOVE CA-TRAN-CNT           TO DCL-ADB-TRAN-CNT
           MOVE CA-CREDIT-LIMIT       TO DCL-ADB-CREDIT-LIMIT
           MOVE CA-OVERLIMIT-FLG      TO DCL-ADB-OVERLIMIT-FLG
           IF CA-FLAG-DATE-NULL = 'Y'
               MOVE LIT-LOW-DATE      TO HV-OLD-FLAG-DATE
               MOVE 'Y'               TO HV-OLD-FLAG-NULL
           ELSE
               MOVE CA-FLAG-DATE      TO HV-OLD-FLAG-DATE
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
                   IF WS-SAVED-FLAG = 'Y'
                       MOVE MSG-SAVED-SET   TO WS-INFO-MSG
                   ELSE
                       MOVE MSG-SAVED-CLEAR TO WS-INFO-MSG
                   END-IF
               WHEN SQLCODE = 100
      *            Changed or deleted since it was shown: show it again
                   EXEC CICS SYNCPOINT ROLLBACK
                   END-EXEC
                   PERFORM 8100-READ-ROW
                   IF CA-ROW-SHOWN
                       MOVE MSG-ROW-CHANGED TO WS-MESSAGE
                   END-IF
               WHEN OTHER
      *            Format the message first: ROLLBACK resets the SQLCA
                   MOVE 'Update of the over-limit flag'
                                            TO WS-DB2-ACTION
                   PERFORM 8900-DB2-ERROR
                   EXEC CICS SYNCPOINT ROLLBACK
                   END-EXEC
                   SET CA-ROW-SHOWN         TO TRUE
                   MOVE SPACE               TO CA-NEW-FLAG
           END-EVALUATE
           .

       8900-DB2-ERROR.
           SET DB2-ERROR TO TRUE
           PERFORM 9800-FORMAT-DB2-MESSAGE
           MOVE WS-DB2-MESSAGE TO WS-MESSAGE
           .

      *----------------------------------------------------------------*
      * Leave this screen
      *----------------------------------------------------------------*
       9000-RETURN.
           MOVE LIT-THISTRANID        TO CDEMO-FROM-TRANID
           MOVE LIT-THISPGM           TO CDEMO-FROM-PROGRAM
           MOVE LIT-THISMAPSET        TO CDEMO-LAST-MAPSET
           MOVE LIT-THISMAP           TO CDEMO-LAST-MAP
           SET CDEMO-PGM-REENTER      TO TRUE
           MOVE CARDDEMO-COMMAREA
             TO WS-COMMAREA(1:LENGTH OF CARDDEMO-COMMAREA)
           MOVE WS-THIS-PROGCOMMAREA
             TO WS-COMMAREA(LENGTH OF CARDDEMO-COMMAREA + 1:
                            LENGTH OF WS-THIS-PROGCOMMAREA)
           EXEC CICS RETURN TRANSID(LIT-THISTRANID)
                            COMMAREA(WS-COMMAREA)
                            LENGTH(WS-COMMAREA-LEN)
           END-EXEC
           .

      *    F3: back to the program that started this one. CMDL then
      *    lists the account shown here.
       9100-RETURN-TO-CALLER.
           MOVE CA-CALLER-TRANID      TO CDEMO-TO-TRANID
           MOVE CA-CALLER-PGM         TO CDEMO-TO-PROGRAM
           IF CDEMO-TO-PROGRAM = SPACES OR LOW-VALUES
               MOVE LIT-ADMINTRANID   TO CDEMO-TO-TRANID
               MOVE LIT-ADMINPGM      TO CDEMO-TO-PROGRAM
           END-IF
           IF CA-ACCT-ID > 0
               MOVE CA-ACCT-ID        TO CDEMO-ACCT-ID
           END-IF
           MOVE LIT-THISTRANID        TO CDEMO-FROM-TRANID
           MOVE LIT-THISPGM           TO CDEMO-FROM-PROGRAM
           MOVE LIT-THISMAPSET        TO CDEMO-LAST-MAPSET
           MOVE LIT-THISMAP           TO CDEMO-LAST-MAP
           SET CDEMO-USRTYP-ADMIN     TO TRUE
           SET CDEMO-PGM-ENTER        TO TRUE
           EXEC CICS XCTL PROGRAM(CDEMO-TO-PROGRAM)
                          COMMAREA(CARDDEMO-COMMAREA)
                          RESP(WS-RESP-CD)
                          RESP2(WS-REAS-CD)
           END-EXEC
      *    XCTL comes back only when it fails, for example when the
      *    CardDemo admin menu is not installed in this region
           MOVE SPACES TO WS-END-MSG
           STRING LIT-THISTRANID      DELIMITED BY SIZE
                  ' ended. Program '  DELIMITED BY SIZE
                  CDEMO-TO-PROGRAM    DELIMITED BY SPACE
                  ' is not available.' DELIMITED BY SIZE
             INTO WS-END-MSG
           END-STRING
           PERFORM 9300-END-SESSION
           .

       9300-END-SESSION.
           EXEC CICS SEND TEXT FROM(WS-END-MSG)
                               LENGTH(LENGTH OF WS-END-MSG)
                               ERASE
                               FREEKB
           END-EXEC
           EXEC CICS RETURN
           END-EXEC
           .

      *----------------------------------------------------------------*
      * Shared procedures
      *----------------------------------------------------------------*
       COPY CSMODCPY.
       COPY CSSTRPFY.
