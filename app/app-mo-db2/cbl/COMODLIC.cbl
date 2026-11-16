      ******************************************************************
      * Program     : COMODLIC.CBL
      * Application : CardDemo - app-mo-db2
      * Type        : CICS COBOL Db2 Program
      * Transaction : CMDL
      * Function    : List the daily account balances in
      *               CARDDEMO.ACCT_DAILY_BAL, 10 rows a page, in
      *               account and balance date order.
      *               - Optional filters: account ID and balance date
      *               - F8 and F7 page forward and back with cursors
      *               - S next to a row transfers control to CMDU
      *                 (COMODUPC) to view it and set or clear its
      *                 over-limit flag
      *               - F3 returns to the caller, by default the
      *                 CardDemo admin menu
      *               It can also be started by typing CMDL.
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
           05  LIT-THISTRANID         PIC X(4)  VALUE 'CMDL'.
           05  LIT-THISMAPSET         PIC X(7)  VALUE 'COMODLI'.
           05  LIT-THISMAP            PIC X(7)  VALUE 'CMODLIA'.
           05  LIT-ADMINPGM           PIC X(8)  VALUE 'COADM01C'.
           05  LIT-ADMINTRANID        PIC X(4)  VALUE 'CA00'.
           05  LIT-DETAILPGM          PIC X(8)  VALUE 'COMODUPC'.
           05  LIT-DETAILTRANID       PIC X(4)  VALUE 'CMDU'.
           05  LIT-LOW-DATE           PIC X(10) VALUE '0001-01-01'.
           05  LIT-PAGE-ROWS          PIC S9(4) COMP VALUE 10.

       01  WS-MESSAGES.
           05  MSG-BAD-ACCOUNT        PIC X(60) VALUE
               'Account ID must be a number of up to 11 digits'.
           05  MSG-BAD-DATE           PIC X(60) VALUE
               'Balance date must be a valid date in YYYY-MM-DD form'.
           05  MSG-BAD-SELECTION      PIC X(60) VALUE
               'Type S next to a row to select it'.
           05  MSG-ONE-SELECTION      PIC X(60) VALUE
               'Select only one row at a time'.
           05  MSG-TOP-OF-LIST        PIC X(60) VALUE
               'You are at the top of the list'.
           05  MSG-BOTTOM-OF-LIST     PIC X(60) VALUE
               'You are at the bottom of the list'.
           05  MSG-NO-ROWS            PIC X(60) VALUE
               'No daily balances match the filters'.
           05  MSG-LIST-CHANGED       PIC X(60) VALUE
               'The list changed. Showing the first page'.
           05  MSG-FROM-DETAIL        PIC X(60) VALUE
               'Clear Account ID and press ENTER to list all accounts'.
           05  MSG-SELECT-HINT        PIC X(60) VALUE
               'Type S next to a row to view it or change its flag'.

      *----------------------------------------------------------------*
      * Work fields
      *----------------------------------------------------------------*
       01  WS-MISC-STORAGE.
           05  WS-RESP-CD             PIC S9(9) COMP VALUE 0.
           05  WS-REAS-CD             PIC S9(9) COMP VALUE 0.
           05  WS-COMMAREA-LEN        PIC S9(4) COMP VALUE 0.
           05  WS-XCTL-LEN            PIC S9(4) COMP VALUE 0.
           05  WS-ROW-IX              PIC S9(4) COMP VALUE 0.
           05  WS-FETCH-COUNT         PIC S9(4) COMP VALUE 0.
           05  WS-SEL-COUNT           PIC S9(4) COMP VALUE 0.
           05  WS-SEL-ROW             PIC S9(4) COMP VALUE 0.
           05  WS-ERR-ROW             PIC S9(4) COMP VALUE 1.
           05  WS-SEL-CHAR            PIC X     VALUE SPACE.
           05  WS-INPUT-FLAG          PIC X     VALUE '0'.
               88  INPUT-OK                     VALUE '0'.
               88  INPUT-ERROR                  VALUE '1'.
           05  WS-ERR-FIELD           PIC X     VALUE SPACE.
               88  ERR-ON-NONE                  VALUE SPACE.
               88  ERR-ON-ACCT                  VALUE 'A'.
               88  ERR-ON-DATE                  VALUE 'D'.
               88  ERR-ON-SEL                   VALUE 'S'.
           05  WS-FILTER-FLAG         PIC X     VALUE 'N'.
               88  FILTERS-CHANGED              VALUE 'Y'.
               88  FILTERS-SAME                 VALUE 'N'.
           05  WS-MAP-FLAG            PIC X     VALUE 'N'.
               88  MAP-RECEIVED                 VALUE 'Y'.
               88  MAP-NOT-RECEIVED             VALUE 'N'.
           05  WS-FETCH-FLAG          PIC X     VALUE 'N'.
               88  FETCH-DONE                   VALUE 'Y'.
               88  FETCH-MORE                   VALUE 'N'.
           05  WS-DB2-FLAG            PIC X     VALUE '0'.
               88  DB2-OK                       VALUE '0'.
               88  DB2-ERROR                    VALUE '1'.
           05  WS-MESSAGE             PIC X(78) VALUE SPACES.
           05  WS-INFO-MSG            PIC X(60) VALUE SPACES.
           05  WS-END-MSG             PIC X(60) VALUE SPACES.
           05  WS-ACCT-IN             PIC X(11) VALUE SPACES.
           05  WS-ACCT-NORM           PIC X(11) VALUE SPACES.
           05  WS-ACCT-NUM            PIC 9(11) VALUE 0.
           05  WS-DATE-IN             PIC X(10) VALUE SPACES.
           05  WS-PAGE-DISP           PIC ZZ9.
           05  WS-CNT-EDIT            PIC ZZ9.
           05  WS-BACK-ACCT           PIC 9(11) VALUE 0.
           05  WS-BACK-DATE           PIC X(10) VALUE SPACES.

      *----------------------------------------------------------------*
      * The page being shown, formatted for the screen
      *----------------------------------------------------------------*
       01  WS-PAGE-DATA.
           05  WS-PAGE-ROW OCCURS 10 TIMES.
               10  WS-PR-ACCT         PIC 9(11).
               10  WS-PR-DATE         PIC X(10).
               10  WS-PR-OPEN         PIC X(11).
               10  WS-PR-CRED         PIC X(11).
               10  WS-PR-DEBT         PIC X(11).
               10  WS-PR-CLOSE        PIC X(11).
               10  WS-PR-CNT          PIC X(3).
               10  WS-PR-FLAG         PIC X(2).

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
      * COMMAREA: the CardDemo area, then this program's own state
      *----------------------------------------------------------------*
       COPY COCOM01Y.
       COPY COMOD01Y.

       01  WS-THIS-PROGCOMMAREA.
           05  CA-CALLER-TRANID       PIC X(4).
           05  CA-CALLER-PGM          PIC X(8).
           05  CA-FILTER-ACCT         PIC X(11).
           05  CA-FILTER-DATE         PIC X(10).
           05  CA-FIRST-ACCT          PIC 9(11).
           05  CA-FIRST-DATE          PIC X(10).
           05  CA-LAST-ACCT           PIC 9(11).
           05  CA-LAST-DATE           PIC X(10).
           05  CA-PAGE-NUM            PIC 9(3).
           05  CA-NEXT-PAGE-FLG       PIC X.
               88  CA-NEXT-PAGE-EXISTS          VALUE 'Y'.
               88  CA-NEXT-PAGE-NOT-EXISTS      VALUE 'N'.
           05  CA-ROW-COUNT           PIC 9(2).
           05  CA-ROW-KEY OCCURS 10 TIMES.
               10  CA-ROW-ACCT        PIC 9(11).
               10  CA-ROW-DATE        PIC X(10).

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
       COPY COMODLI.

      *    The 10 list rows as arrays. The offsets come from the
      *    generated map: 207 bytes before the rows, 134 per row and
      *    214 after them.
       01  FILLER REDEFINES CMODLIAI.
           05  FILLER                 PIC X(207).
           05  LI-ROW OCCURS 10 TIMES.
               10  LI-SEL-L           PIC S9(4) COMP.
               10  LI-SEL-F           PIC X.
               10  FILLER             PIC X(4).
               10  LI-SEL-I           PIC X.
               10  FILLER             PIC X(126).
           05  FILLER                 PIC X(214).

       01  FILLER REDEFINES CMODLIAI.
           05  FILLER                 PIC X(207).
           05  LO-ROW OCCURS 10 TIMES.
               10  FILLER             PIC X(7).
               10  LO-SEL-O           PIC X.
               10  FILLER             PIC X(7).
               10  LO-ACT-O           PIC X(11).
               10  FILLER             PIC X(7).
               10  LO-DAT-O           PIC X(10).
               10  FILLER             PIC X(7).
               10  LO-OPB-O           PIC X(11).
               10  FILLER             PIC X(7).
               10  LO-CRD-O           PIC X(11).
               10  FILLER             PIC X(7).
               10  LO-DBT-O           PIC X(11).
               10  FILLER             PIC X(7).
               10  LO-CLB-O           PIC X(11).
               10  FILLER             PIC X(7).
               10  LO-CNT-O           PIC X(3).
               10  FILLER             PIC X(7).
               10  LO-FLG-O           PIC X(2).
           05  FILLER                 PIC X(214).

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05  FILLER                 PIC X(1)
               OCCURS 1 TO 32767 TIMES DEPENDING ON EIBCALEN.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * Started by CMDL (no COMMAREA), by another program's XCTL, or
      * again after this program's own screen.
      *----------------------------------------------------------------*
       0000-MAIN.
           INITIALIZE CC-WORK-AREA
           MOVE SPACES TO WS-MESSAGE
                          WS-INFO-MSG
           SET INPUT-OK     TO TRUE
           SET ERR-ON-NONE  TO TRUE
           SET FILTERS-SAME TO TRUE
           SET DB2-OK       TO TRUE
           COMPUTE WS-COMMAREA-LEN = LENGTH OF CARDDEMO-COMMAREA
                                   + LENGTH OF WS-THIS-PROGCOMMAREA

           IF EIBCALEN < LENGTH OF CARDDEMO-COMMAREA
               INITIALIZE CARDDEMO-COMMAREA
               MOVE LIT-THISTRANID     TO CDEMO-FROM-TRANID
               MOVE LIT-THISPGM        TO CDEMO-FROM-PROGRAM
               SET CDEMO-USRTYP-ADMIN  TO TRUE
               SET CDEMO-PGM-ENTER     TO TRUE
               PERFORM 1000-START-AFRESH
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
                   PERFORM 1000-START-AFRESH
               END-IF
           END-IF

           PERFORM 3000-SEND-MAP
           PERFORM 9000-RETURN
           GOBACK
           .

      *----------------------------------------------------------------*
      * First screen: remember the caller and show the first page.
      * Coming back from CMDU, list the account it showed.
      *----------------------------------------------------------------*
       1000-START-AFRESH.
           INITIALIZE WS-THIS-PROGCOMMAREA
           IF CDEMO-FROM-PROGRAM = SPACES OR LOW-VALUES
           OR CDEMO-FROM-PROGRAM = LIT-THISPGM
           OR CDEMO-FROM-PROGRAM = LIT-DETAILPGM
               MOVE LIT-ADMINTRANID    TO CA-CALLER-TRANID
               MOVE LIT-ADMINPGM       TO CA-CALLER-PGM
           ELSE
               MOVE CDEMO-FROM-TRANID  TO CA-CALLER-TRANID
               MOVE CDEMO-FROM-PROGRAM TO CA-CALLER-PGM
           END-IF
           IF  CDEMO-FROM-PROGRAM = LIT-DETAILPGM
           AND CDEMO-ACCT-ID IS NUMERIC
           AND CDEMO-ACCT-ID > 0
               MOVE CDEMO-ACCT-ID      TO CA-FILTER-ACCT
               MOVE MSG-FROM-DETAIL    TO WS-INFO-MSG
           END-IF
           PERFORM 8000-READ-FIRST-PAGE
           IF WS-INFO-MSG = SPACES AND CA-ROW-COUNT > 0
               MOVE MSG-SELECT-HINT    TO WS-INFO-MSG
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
           IF MAP-RECEIVED
               PERFORM 2200-EDIT-FILTERS
           END-IF

           EVALUATE TRUE
               WHEN INPUT-ERROR
                   PERFORM 8010-READ-CURRENT-PAGE
               WHEN FILTERS-CHANGED
                   PERFORM 8000-READ-FIRST-PAGE
               WHEN CCARD-AID-ENTER
                   IF MAP-RECEIVED
                       PERFORM 2300-EDIT-SELECTION
                   END-IF
                   IF INPUT-OK AND WS-SEL-COUNT = 1
                       PERFORM 9200-SHOW-DETAIL
                   END-IF
                   PERFORM 8010-READ-CURRENT-PAGE
               WHEN CCARD-AID-PFK07
                   IF CA-PAGE-NUM > 1
                       PERFORM 8300-READ-PREVIOUS-PAGE
                   ELSE
                       MOVE MSG-TOP-OF-LIST    TO WS-INFO-MSG
                       PERFORM 8010-READ-CURRENT-PAGE
                   END-IF
               WHEN CCARD-AID-PFK08
                   IF CA-NEXT-PAGE-EXISTS
                       PERFORM 8020-READ-NEXT-PAGE
                   ELSE
                       MOVE MSG-BOTTOM-OF-LIST TO WS-INFO-MSG
                       PERFORM 8010-READ-CURRENT-PAGE
                   END-IF
               WHEN OTHER
                   MOVE CCDA-MSG-INVALID-KEY   TO WS-MESSAGE
                   PERFORM 8010-READ-CURRENT-PAGE
           END-EVALUATE
           .

       2100-RECEIVE-MAP.
           EXEC CICS RECEIVE MAP(LIT-THISMAP)
                             MAPSET(LIT-THISMAPSET)
                             INTO(CMODLIAI)
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
      * Check the filters. New, valid filters restart the list.
      *----------------------------------------------------------------*
       2200-EDIT-FILTERS.
           MOVE ACCTIDI OF CMODLIAI  TO WS-ACCT-IN
           MOVE BALDATEI OF CMODLIAI TO WS-DATE-IN
           INSPECT WS-ACCT-IN REPLACING ALL LOW-VALUE BY SPACE
           INSPECT WS-DATE-IN REPLACING ALL LOW-VALUE BY SPACE

           MOVE SPACES TO WS-ACCT-NORM
           IF WS-ACCT-IN NOT = SPACES
               MOVE WS-ACCT-IN TO WS-AC-INPUT
               PERFORM 9720-PARSE-ACCOUNT
               IF WS-AC-VALID
                   MOVE WS-AC-NUM       TO WS-ACCT-NORM
               ELSE
                   SET INPUT-ERROR      TO TRUE
                   SET ERR-ON-ACCT      TO TRUE
                   MOVE MSG-BAD-ACCOUNT TO WS-MESSAGE
               END-IF
           END-IF

           IF INPUT-OK AND WS-DATE-IN NOT = SPACES
               MOVE FUNCTION TRIM(WS-DATE-IN) TO WS-DC-DATE
               PERFORM 9700-VALIDATE-DATE
               IF WS-DC-VALID
                   MOVE WS-DC-DATE      TO WS-DATE-IN
               ELSE
                   SET INPUT-ERROR      TO TRUE
                   SET ERR-ON-DATE      TO TRUE
                   MOVE MSG-BAD-DATE    TO WS-MESSAGE
               END-IF
           END-IF

           IF INPUT-OK
               IF WS-ACCT-NORM NOT = CA-FILTER-ACCT
               OR WS-DATE-IN   NOT = CA-FILTER-DATE
                   SET FILTERS-CHANGED  TO TRUE
                   MOVE WS-ACCT-NORM    TO CA-FILTER-ACCT
                   MOVE WS-DATE-IN      TO CA-FILTER-DATE
               END-IF
           END-IF
           .

      *----------------------------------------------------------------*
      * Find the row marked S, if any
      *----------------------------------------------------------------*
       2300-EDIT-SELECTION.
           MOVE 0 TO WS-SEL-COUNT
                     WS-SEL-ROW
           PERFORM VARYING WS-ROW-IX FROM 1 BY 1
                   UNTIL WS-ROW-IX > LIT-PAGE-ROWS
               MOVE LI-SEL-I(WS-ROW-IX) TO WS-SEL-CHAR
               EVALUATE TRUE
                   WHEN WS-SEL-CHAR = SPACE OR LOW-VALUE
                       CONTINUE
                   WHEN (WS-SEL-CHAR = 'S' OR 's')
                    AND WS-ROW-IX NOT > CA-ROW-COUNT
                       ADD 1 TO WS-SEL-COUNT
                       MOVE WS-ROW-IX TO WS-SEL-ROW
                   WHEN OTHER
                       IF INPUT-OK
                           SET INPUT-ERROR        TO TRUE
                           SET ERR-ON-SEL         TO TRUE
                           MOVE WS-ROW-IX         TO WS-ERR-ROW
                           MOVE MSG-BAD-SELECTION TO WS-MESSAGE
                       END-IF
               END-EVALUATE
           END-PERFORM
           IF INPUT-OK AND WS-SEL-COUNT > 1
               SET INPUT-ERROR        TO TRUE
               SET ERR-ON-SEL         TO TRUE
               MOVE WS-SEL-ROW        TO WS-ERR-ROW
               MOVE MSG-ONE-SELECTION TO WS-MESSAGE
           END-IF
           .

      *----------------------------------------------------------------*
      * Build and send the screen
      *----------------------------------------------------------------*
       3000-SEND-MAP.
           MOVE LOW-VALUES TO CMODLIAO
           PERFORM 3100-SCREEN-HEADER

           IF ERR-ON-ACCT OR ERR-ON-DATE
               MOVE WS-ACCT-IN     TO ACCTIDO OF CMODLIAO
               MOVE WS-DATE-IN     TO BALDATEO OF CMODLIAO
           ELSE
               MOVE CA-FILTER-ACCT TO ACCTIDO OF CMODLIAO
               MOVE CA-FILTER-DATE TO BALDATEO OF CMODLIAO
           END-IF

           PERFORM VARYING WS-ROW-IX FROM 1 BY 1
                   UNTIL WS-ROW-IX > LIT-PAGE-ROWS
               IF WS-ROW-IX NOT > CA-ROW-COUNT
                   MOVE WS-PR-ACCT(WS-ROW-IX)  TO LO-ACT-O(WS-ROW-IX)
                   MOVE WS-PR-DATE(WS-ROW-IX)  TO LO-DAT-O(WS-ROW-IX)
                   MOVE WS-PR-OPEN(WS-ROW-IX)  TO LO-OPB-O(WS-ROW-IX)
                   MOVE WS-PR-CRED(WS-ROW-IX)  TO LO-CRD-O(WS-ROW-IX)
                   MOVE WS-PR-DEBT(WS-ROW-IX)  TO LO-DBT-O(WS-ROW-IX)
                   MOVE WS-PR-CLOSE(WS-ROW-IX) TO LO-CLB-O(WS-ROW-IX)
                   MOVE WS-PR-CNT(WS-ROW-IX)   TO LO-CNT-O(WS-ROW-IX)
                   MOVE WS-PR-FLAG(WS-ROW-IX)  TO LO-FLG-O(WS-ROW-IX)
               ELSE
      *            No row here: protect its selection field
                   MOVE DFHBMASK               TO LI-SEL-F(WS-ROW-IX)
               END-IF
           END-PERFORM

           MOVE WS-INFO-MSG TO INFOMSGO OF CMODLIAO
           MOVE WS-MESSAGE  TO ERRMSGO OF CMODLIAO

           EVALUATE TRUE
               WHEN ERR-ON-DATE
                   MOVE -1 TO BALDATEL OF CMODLIAI
               WHEN ERR-ON-SEL
                   MOVE -1 TO LI-SEL-L(WS-ERR-ROW)
               WHEN OTHER
                   MOVE -1 TO ACCTIDL OF CMODLIAI
           END-EVALUATE

           EXEC CICS SEND MAP(LIT-THISMAP)
                          MAPSET(LIT-THISMAPSET)
                          FROM(CMODLIAO)
                          CURSOR
                          ERASE
                          FREEKB
                          RESP(WS-RESP-CD)
           END-EXEC
           .

       3100-SCREEN-HEADER.
           MOVE FUNCTION CURRENT-DATE  TO WS-CURDATE-DATA
           MOVE CCDA-TITLE01           TO TITLE01O OF CMODLIAO
           MOVE CCDA-TITLE02           TO TITLE02O OF CMODLIAO
           MOVE LIT-THISTRANID         TO TRNNAMEO OF CMODLIAO
           MOVE LIT-THISPGM            TO PGMNAMEO OF CMODLIAO
           MOVE WS-CURDATE-MONTH       TO WS-CURDATE-MM
           MOVE WS-CURDATE-DAY         TO WS-CURDATE-DD
           MOVE WS-CURDATE-YEAR(3:2)   TO WS-CURDATE-YY
           MOVE WS-CURDATE-MM-DD-YY    TO CURDATEO OF CMODLIAO
           MOVE WS-CURTIME-HOURS       TO WS-CURTIME-HH
           MOVE WS-CURTIME-MINUTE      TO WS-CURTIME-MM
           MOVE WS-CURTIME-SECOND      TO WS-CURTIME-SS
           MOVE WS-CURTIME-HH-MM-SS    TO CURTIMEO OF CMODLIAO
           MOVE CA-PAGE-NUM            TO WS-PAGE-DISP
           MOVE WS-PAGE-DISP           TO PAGENOO OF CMODLIAO
           .

      *----------------------------------------------------------------*
      * Paging. Every screen re-reads its page, so the rows shown are
      * always current.
      *----------------------------------------------------------------*
       8000-READ-FIRST-PAGE.
           MOVE 1                 TO CA-PAGE-NUM
           MOVE ZERO              TO HV-START-ACCT
           MOVE LIT-LOW-DATE      TO HV-START-DATE
           MOVE 'Y'               TO HV-START-INCL
           PERFORM 8200-READ-FORWARD
           .

       8010-READ-CURRENT-PAGE.
           IF CA-ROW-COUNT = 0
               PERFORM 8000-READ-FIRST-PAGE
           ELSE
               MOVE CA-FIRST-ACCT TO HV-START-ACCT
               MOVE CA-FIRST-DATE TO HV-START-DATE
               MOVE 'Y'           TO HV-START-INCL
               PERFORM 8200-READ-FORWARD
               IF CA-ROW-COUNT = 0 AND DB2-OK
                   MOVE SPACES    TO WS-INFO-MSG
                   PERFORM 8000-READ-FIRST-PAGE
               END-IF
           END-IF
           .

       8020-READ-NEXT-PAGE.
           MOVE CA-LAST-ACCT      TO HV-START-ACCT
           MOVE CA-LAST-DATE      TO HV-START-DATE
           MOVE 'N'               TO HV-START-INCL
           ADD 1                  TO CA-PAGE-NUM
           PERFORM 8200-READ-FORWARD
           IF CA-ROW-COUNT = 0 AND DB2-OK
               MOVE SPACES           TO WS-INFO-MSG
               PERFORM 8000-READ-FIRST-PAGE
               MOVE MSG-LIST-CHANGED TO WS-INFO-MSG
           END-IF
           .

       8100-SET-FILTERS.
           IF CA-FILTER-ACCT = SPACES
               MOVE 'N'               TO HV-FILTER-ACCT-FLG
               MOVE ZERO              TO HV-FILTER-ACCT
           ELSE
               MOVE 'Y'               TO HV-FILTER-ACCT-FLG
               MOVE CA-FILTER-ACCT    TO WS-ACCT-NUM
               MOVE WS-ACCT-NUM       TO HV-FILTER-ACCT
           END-IF
      *    The date host variable must hold a valid date even when the
      *    filter is off, or Db2 cannot convert it.
           IF CA-FILTER-DATE = SPACES
               MOVE 'N'               TO HV-FILTER-DATE-FLG
               MOVE LIT-LOW-DATE      TO HV-FILTER-DATE
           ELSE
               MOVE 'Y'               TO HV-FILTER-DATE-FLG
               MOVE CA-FILTER-DATE    TO HV-FILTER-DATE
           END-IF
           .

      *    Read up to a page from the start key set by the caller
       8200-READ-FORWARD.
           PERFORM 8100-SET-FILTERS
           INITIALIZE WS-PAGE-DATA
           MOVE 0 TO CA-ROW-COUNT
                     WS-FETCH-COUNT
           SET CA-NEXT-PAGE-NOT-EXISTS TO TRUE

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

           IF CA-ROW-COUNT > 0
               MOVE CA-ROW-ACCT(1)            TO CA-FIRST-ACCT
               MOVE CA-ROW-DATE(1)            TO CA-FIRST-DATE
               MOVE CA-ROW-ACCT(CA-ROW-COUNT) TO CA-LAST-ACCT
               MOVE CA-ROW-DATE(CA-ROW-COUNT) TO CA-LAST-DATE
           ELSE
               IF DB2-OK AND WS-INFO-MSG = SPACES
                   MOVE MSG-NO-ROWS           TO WS-INFO-MSG
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
                       SET CA-NEXT-PAGE-EXISTS TO TRUE
                       SET FETCH-DONE          TO TRUE
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
           ADD 1 TO CA-ROW-COUNT
           MOVE DCL-ADB-ACCT-ID   TO CA-ROW-ACCT(CA-ROW-COUNT)
                                     WS-PR-ACCT(CA-ROW-COUNT)
           MOVE DCL-ADB-BAL-DATE  TO CA-ROW-DATE(CA-ROW-COUNT)
                                     WS-PR-DATE(CA-ROW-COUNT)
           MOVE DCL-ADB-OPEN-BAL  TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-SHORT  TO WS-PR-OPEN(CA-ROW-COUNT)
           MOVE DCL-ADB-CREDIT-AMT TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-SHORT  TO WS-PR-CRED(CA-ROW-COUNT)
           MOVE DCL-ADB-DEBIT-AMT TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-SHORT  TO WS-PR-DEBT(CA-ROW-COUNT)
           MOVE DCL-ADB-CLOSE-BAL TO WS-FMT-AMT
           PERFORM 9710-FORMAT-AMOUNT
           MOVE WS-FMT-AMT-SHORT  TO WS-PR-CLOSE(CA-ROW-COUNT)
           IF DCL-ADB-TRAN-CNT > 999
               MOVE '***'         TO WS-PR-CNT(CA-ROW-COUNT)
           ELSE
               MOVE DCL-ADB-TRAN-CNT TO WS-CNT-EDIT
               MOVE WS-CNT-EDIT   TO WS-PR-CNT(CA-ROW-COUNT)
           END-IF
           MOVE SPACES            TO WS-PR-FLAG(CA-ROW-COUNT)
           MOVE DCL-ADB-OVERLIMIT-FLG
                                  TO WS-PR-FLAG(CA-ROW-COUNT)(2:1)
           .

      *    Step back up to a page from the first key shown, then read
      *    that page forward so rows always show in key order.
       8300-READ-PREVIOUS-PAGE.
           PERFORM 8100-SET-FILTERS
           MOVE CA-FIRST-ACCT     TO HV-START-ACCT
           MOVE CA-FIRST-DATE     TO HV-START-DATE
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
                   PERFORM 8010-READ-CURRENT-PAGE
               WHEN WS-FETCH-COUNT < LIT-PAGE-ROWS
                   PERFORM 8000-READ-FIRST-PAGE
               WHEN OTHER
                   IF CA-PAGE-NUM > 1
                       SUBTRACT 1 FROM CA-PAGE-NUM
                   END-IF
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

      *    F3: back to the program that started this one
       9100-RETURN-TO-CALLER.
           MOVE CA-CALLER-TRANID      TO CDEMO-TO-TRANID
           MOVE CA-CALLER-PGM         TO CDEMO-TO-PROGRAM
           IF CDEMO-TO-PROGRAM = SPACES OR LOW-VALUES
               MOVE LIT-ADMINTRANID   TO CDEMO-TO-TRANID
               MOVE LIT-ADMINPGM      TO CDEMO-TO-PROGRAM
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

      *    S on a row: show it in CMDU
       9200-SHOW-DETAIL.
           MOVE CA-ROW-ACCT(WS-SEL-ROW) TO CMOD-KEY-ACCT-ID
                                           CDEMO-ACCT-ID
           MOVE CA-ROW-DATE(WS-SEL-ROW) TO CMOD-KEY-BAL-DATE
           MOVE LIT-THISTRANID          TO CDEMO-FROM-TRANID
           MOVE LIT-THISPGM             TO CDEMO-FROM-PROGRAM
           MOVE LIT-DETAILTRANID        TO CDEMO-TO-TRANID
           MOVE LIT-DETAILPGM           TO CDEMO-TO-PROGRAM
           MOVE LIT-THISMAPSET          TO CDEMO-LAST-MAPSET
           MOVE LIT-THISMAP             TO CDEMO-LAST-MAP
           SET CDEMO-PGM-ENTER          TO TRUE
           MOVE SPACES                  TO WS-COMMAREA
           MOVE CARDDEMO-COMMAREA
             TO WS-COMMAREA(1:LENGTH OF CARDDEMO-COMMAREA)
           MOVE CMOD-PASSED-KEY
             TO WS-COMMAREA(LENGTH OF CARDDEMO-COMMAREA + 1:
                            LENGTH OF CMOD-PASSED-KEY)
           COMPUTE WS-XCTL-LEN = LENGTH OF CARDDEMO-COMMAREA
                               + LENGTH OF CMOD-PASSED-KEY
           EXEC CICS XCTL PROGRAM(LIT-DETAILPGM)
                          COMMAREA(WS-COMMAREA)
                          LENGTH(WS-XCTL-LEN)
                          RESP(WS-RESP-CD)
                          RESP2(WS-REAS-CD)
           END-EXEC
      *    XCTL comes back only when it fails
           MOVE SPACES TO WS-MESSAGE
           STRING 'Program '            DELIMITED BY SIZE
                  LIT-DETAILPGM         DELIMITED BY SIZE
                  ' is not available'   DELIMITED BY SIZE
             INTO WS-MESSAGE
           END-STRING
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
