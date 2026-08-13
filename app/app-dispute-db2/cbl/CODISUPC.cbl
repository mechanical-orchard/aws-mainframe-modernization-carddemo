      ******************************************************************
      * Program:     CODISUPC.CBL
      * Layer:       Business logic
      * Function:    Accept and process TRANSACTION DISPUTE MAINTAIN
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           CODISUPC.
       DATE-WRITTEN.
           Jul 2026.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.

       DATA DIVISION.

       WORKING-STORAGE SECTION.
       01  WS-MISC-STORAGE.
      ******************************************************************
      * General CICS related                                           *
      ******************************************************************
           05 WS-CICS-PROCESSNG-VARS.
              07 WS-RESP-CD                     PIC S9(09) COMP
                                                VALUE ZEROS.
              07 WS-REAS-CD                     PIC S9(09) COMP
                                                VALUE ZEROS.
              07 WS-TRANID                       PIC X(4)
                                                VALUE SPACES.
      ******************************************************************
      * Work variables                                                 *
      ******************************************************************
           05 WS-MISC-VARS.
              10 WS-DISP-SQLCODE               PIC ----9.
              10 WS-STRING-MID                 PIC 9(3) VALUE 0.
              10 WS-STRING-LEN                 PIC 9(3) VALUE 0.
              10 WS-STRING-OUT                 PIC X(45).
              10 WS-MAX-DISP-ID                PIC X(12).
              10 WS-DISP-ID-NIND               PIC S9(4) COMP.
              10 WS-NEW-DISP-NUM               PIC 9(9).
              10 WS-NEW-DISP-ID                PIC X(12).
              10 WS-MAX-SEQ                    PIC S9(4) COMP.
              10 WS-SEQ-NIND                   PIC S9(4) COMP.
              10 WS-NEXT-SEQ                   PIC S9(4) COMP.
              10 WS-DISP-AMT-O                 PIC -ZZZZZZZZ9.99.
      ******************************************************************
      * Flags                                                          *
      ******************************************************************
           05 WS-INPUT-FLAG                    PIC X(1).
              88 INPUT-OK                       VALUE '0'.
              88 INPUT-ERROR                    VALUE '1'.
           05 WS-PFK-FLAG                      PIC X(1).
              88 PFK-VALID                      VALUE '0'.
              88 PFK-INVALID                    VALUE '1'.
           05 WS-DISP-READ-FLG                 PIC X(1).
              88 FOUND-DISPUTE                  VALUE '1'.
              88 NOTFOUND-DISPUTE               VALUE '0'.
      ******************************************************************
      * Information message                                            *
      ******************************************************************
           05 WS-INFO-MSG                      PIC X(45).
              88 WS-NO-INFO-MESSAGE             VALUES
                                                SPACES LOW-VALUES.
              88 PROMPT-FOR-DISPUTE-ID          VALUE
                 'Enter Dispute ID or Tran ID + F5 to open'.
              88 PROMPT-DISPUTE-NOT-FOUND       VALUE
                 'Dispute not found. Check Dispute ID'.
              88 PROMPT-ADVANCE-STATUS          VALUE
                 'Enter New Status and Note, F5 to update'.
              88 CONFIRM-OPEN-SUCCESS           VALUE
                 'Dispute opened successfully'.
              88 CONFIRM-STATUS-SUCCESS         VALUE
                 'Dispute status updated successfully'.
      ******************************************************************
      * Return / error message                                         *
      ******************************************************************
           05 WS-RETURN-MSG                    PIC X(75).
              88 WS-RETURN-MSG-OFF              VALUE SPACES.
              88 WS-EXIT-MESSAGE               VALUE
                 'PF03 pressed. Exiting.'.
              88 WS-INVALID-KEY-PRESSED        VALUE
                 'Invalid key pressed. Please see below.'.
              88 WS-DISPUTE-NOT-FOUND          VALUE
                 'No dispute found for this Dispute ID'.
              88 WS-TRAN-NOT-FOUND             VALUE
                 'Transaction ID not found'.
              88 WS-INVALID-STATUS             VALUE
                 'Invalid status code entered'.
              88 WS-NO-DISPUTE-ID              VALUE
                 'Please enter a Dispute ID'.
              88 WS-MISSING-NEW-INPUT          VALUE
                 'Tran ID, Reason and Description are required'.
              88 WS-MISSING-STATUS-INPUT       VALUE
                 'New status code is required'.
              88 COULD-NOT-LOCK-REC            VALUE
                 'Could not lock record for update'.
              88 INFORM-FAILURE                VALUE
                 'Operation was unsuccessful'.
      ******************************************************************
      * Literals and Constants                                         *
      ******************************************************************
       01 WS-LITERALS.
          05 LIT-THISPGM                        PIC X(8)
                                                VALUE 'CODISUPC'.
          05 LIT-THISTRANID                     PIC X(4)
                                                VALUE 'CDSU'.
          05 LIT-THISMAPSET                     PIC X(8)
                                                VALUE 'CODISUP '.
          05 LIT-THISMAP                        PIC X(7)
                                                VALUE 'CDISUPA'.
          05 LIT-ADMINPGM                       PIC X(8)
                                                VALUE 'COADM01C'.
          05 LIT-ADMINTRANID                    PIC X(4)
                                                VALUE 'CA00'.
          05 LIT-ADMINMAPSET                    PIC X(7)
                                                VALUE 'COADM01'.
          05 LIT-ADMINMAP                       PIC X(7)
                                                VALUE 'COADM1A'.
          05 LIT-LISTPGM                        PIC X(8)
                                                VALUE 'CODISLIC'.
          05 LIT-LISTTRANID                     PIC X(4)
                                                VALUE 'CDSL'.
          05 LIT-LISTMAPSET                     PIC X(7)
                                                VALUE 'CODISLI'.
          05 LIT-LISTMAP                        PIC X(7)
                                                VALUE 'CDISLIA'.
          05 LIT-TRANSACT-FILE                  PIC X(8)
                                                VALUE 'TRANSACT'.

      *Other common working storage Variables
       COPY CVCRD01Y.

      *IBM SUPPLIED COPYBOOKS
       COPY DFHBMSCA.
       COPY DFHAID.

      *COMMON COPYBOOKS
      *Screen Titles
       COPY COTTL01Y.

      *Transaction Dispute Maintain Screen Layout
       COPY CODISUP.

      *Current Date
       COPY CSDAT01Y.

      *Common Messages
       COPY CSMSG01Y.

      *Abend Variables
       COPY CSMSG02Y.

      *Signed on user data
       COPY CSUSR01Y.

      *Transaction (VSAM) record layout
       COPY CVTRA05Y.

      ******************************************************************
      * Relational Database stuff                                      *
      ******************************************************************
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC

           EXEC SQL INCLUDE DCLDISP END-EXEC

           EXEC SQL INCLUDE DCLDSTS END-EXEC

           EXEC SQL INCLUDE DCLDSHS END-EXEC

      *Application Commmarea Copybook
       COPY COCOM01Y.

       01 WS-THIS-PROGCOMMAREA.
          05 DISP-SCREEN-DATA.
             10 DISP-CHANGE-ACTION              PIC X(1)
                                                VALUE LOW-VALUES.
                88 DISP-DETAILS-NOT-FETCHED     VALUES
                                                LOW-VALUES, SPACES.
                88 DISP-DETAILS-NOT-FOUND       VALUE 'X'.
                88 DISP-SHOW-DETAILS            VALUE 'S'.
                88 DISP-OPEN-DONE               VALUE 'O'.
                88 DISP-STATUS-DONE             VALUE 'C'.
                88 DISP-DETAILS-AVAILABLE       VALUES
                                                'S', 'O', 'C'.
          05 DISP-OLD-DETAILS.
             10 DISP-OLD-DISP-ID                PIC X(12).
             10 DISP-OLD-TRAN-ID                PIC X(16).
             10 DISP-OLD-CARD-NUM               PIC X(16).
             10 DISP-OLD-AMT                    PIC S9(9)V99.
             10 DISP-OLD-REASON-CD              PIC X(4).
             10 DISP-OLD-STATUS-CD              PIC X(2).
             10 DISP-OLD-STATUS-DESC            PIC X(30).
             10 DISP-OLD-OPEN-TS                PIC X(26).
             10 DISP-OLD-LAST-UPD-TS            PIC X(26).
             10 DISP-OLD-DESC                   PIC X(50).
       01 WS-COMMAREA                           PIC X(2000).

       LINKAGE SECTION.
       01  DFHCOMMAREA.
         05  FILLER                            PIC X(1)
             OCCURS 1 TO 32767 TIMES DEPENDING ON EIBCALEN.

       PROCEDURE DIVISION.
       0000-MAIN.

           EXEC CICS HANDLE ABEND
                     LABEL(ABEND-ROUTINE)
           END-EXEC

           INITIALIZE CC-WORK-AREA
                      WS-MISC-STORAGE
                      WS-COMMAREA
      *****************************************************************
      * Store our context
      *****************************************************************
           MOVE LIT-THISTRANID       TO WS-TRANID
      *****************************************************************
      * Ensure error message is cleared                               *
      *****************************************************************
           SET WS-RETURN-MSG-OFF  TO TRUE
      *****************************************************************
      * Store passed data if any                                      *
      *****************************************************************
           IF EIBCALEN IS EQUAL TO 0
              INITIALIZE CARDDEMO-COMMAREA
                         WS-THIS-PROGCOMMAREA
              SET CDEMO-PGM-ENTER TO TRUE
              SET DISP-DETAILS-NOT-FETCHED TO TRUE
           ELSE
              MOVE DFHCOMMAREA (1:LENGTH OF CARDDEMO-COMMAREA) TO
                               CARDDEMO-COMMAREA
              IF (CDEMO-FROM-PROGRAM = LIT-ADMINPGM
                 AND NOT CDEMO-PGM-REENTER)
              OR (CDEMO-FROM-PROGRAM = LIT-LISTPGM
                 AND NOT CDEMO-PGM-REENTER)
                 INITIALIZE WS-THIS-PROGCOMMAREA
                 SET CDEMO-PGM-ENTER TO TRUE
                 SET DISP-DETAILS-NOT-FETCHED TO TRUE
              ELSE
                 MOVE DFHCOMMAREA(LENGTH OF CARDDEMO-COMMAREA + 1:
                                  LENGTH OF WS-THIS-PROGCOMMAREA ) TO
                                  WS-THIS-PROGCOMMAREA
              END-IF
           END-IF
      *****************************************************************
      * Store the Mapped PF Key
      *****************************************************************
           PERFORM YYYY-STORE-PFKEY
              THRU YYYY-STORE-PFKEY-EXIT

           SET PFK-INVALID TO TRUE
           PERFORM 0001-CHECK-PFKEYS
              THRU 0001-CHECK-PFKEYS-EXIT
      *****************************************************************
      * Decide what to do based on PF KEY PRESSED AND CONTEXT
      *****************************************************************
           EVALUATE TRUE
      ******************************************************************
      *       USER PRESSES PF03 TO EXIT
      ******************************************************************
              WHEN CCARD-AID-PFK03
                   PERFORM 8000-EXIT-PROGRAM
                      THRU 8000-EXIT-PROGRAM-EXIT
      ******************************************************************
      *       FRESH ENTRY. FETCH FROM LIST OR PROMPT FOR INPUT
      ******************************************************************
              WHEN CDEMO-PGM-ENTER
               AND DISP-DETAILS-NOT-FETCHED
                   PERFORM 1000-ENTRY-PROCESSING
                      THRU 1000-ENTRY-PROCESSING-EXIT
                   PERFORM 3000-SEND-MAP
                      THRU 3000-SEND-MAP-EXIT
                   SET CDEMO-PGM-REENTER TO TRUE
                   GO TO COMMON-RETURN
      ******************************************************************
      *       INVALID KEY. JUST RE-SHOW WITH ERROR
      ******************************************************************
              WHEN PFK-INVALID
                   PERFORM 3000-SEND-MAP
                      THRU 3000-SEND-MAP-EXIT
                   GO TO COMMON-RETURN
      ******************************************************************
      *       USER PRESSED F05. SAVE (OPEN NEW OR ADVANCE STATUS)
      ******************************************************************
              WHEN CCARD-AID-PFK05
                   PERFORM 1000-PROCESS-INPUTS
                      THRU 1000-PROCESS-INPUTS-EXIT
                   PERFORM 2000-DECIDE-SAVE
                      THRU 2000-DECIDE-SAVE-EXIT
                   PERFORM 3000-SEND-MAP
                      THRU 3000-SEND-MAP-EXIT
                   GO TO COMMON-RETURN
      ******************************************************************
      *       USER PRESSED F12. CANCEL THE ACTION
      ******************************************************************
              WHEN CCARD-AID-PFK12
                   PERFORM 1000-PROCESS-INPUTS
                      THRU 1000-PROCESS-INPUTS-EXIT
                   PERFORM 2000-CANCEL-ACTION
                      THRU 2000-CANCEL-ACTION-EXIT
                   PERFORM 3000-SEND-MAP
                      THRU 3000-SEND-MAP-EXIT
                   GO TO COMMON-RETURN
      ******************************************************************
      *       ENTER. FETCH THE DISPUTE FOR THE KEY SUPPLIED
      ******************************************************************
              WHEN OTHER
                   PERFORM 1000-PROCESS-INPUTS
                      THRU 1000-PROCESS-INPUTS-EXIT
                   PERFORM 2000-FETCH-ACTION
                      THRU 2000-FETCH-ACTION-EXIT
                   PERFORM 3000-SEND-MAP
                      THRU 3000-SEND-MAP-EXIT
                   GO TO COMMON-RETURN
           END-EVALUATE
           .

       COMMON-RETURN.
           MOVE WS-RETURN-MSG     TO CCARD-ERROR-MSG

           MOVE  CARDDEMO-COMMAREA    TO WS-COMMAREA
           MOVE  WS-THIS-PROGCOMMAREA TO
                  WS-COMMAREA(LENGTH OF CARDDEMO-COMMAREA + 1:
                               LENGTH OF WS-THIS-PROGCOMMAREA )

           EXEC CICS RETURN
                TRANSID (LIT-THISTRANID)
                COMMAREA (WS-COMMAREA)
                LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC
           .
       0000-MAIN-EXIT.
           EXIT
           .

       0001-CHECK-PFKEYS.
           IF  CCARD-AID-ENTER
           OR  CCARD-AID-PFK03
           OR  CCARD-AID-PFK05
           OR  CCARD-AID-PFK12
               SET PFK-VALID                  TO TRUE
           ELSE
               SET PFK-INVALID                TO TRUE
               IF WS-RETURN-MSG-OFF
                  SET WS-INVALID-KEY-PRESSED  TO TRUE
               END-IF
           END-IF
           .
       0001-CHECK-PFKEYS-EXIT.
           EXIT
           .

       1000-ENTRY-PROCESSING.
      *    If a Dispute ID was passed from the list program then fetch
      *    and show it immediately. Otherwise prompt for input.
           IF  CDEMO-DISP-ID > SPACES
               MOVE CDEMO-DISP-ID          TO DCL-DISP-ID
               SET  WS-RETURN-MSG-OFF       TO TRUE
               PERFORM 9000-READ-DISPUTE
                  THRU 9000-READ-DISPUTE-EXIT
               IF FOUND-DISPUTE
                  SET DISP-SHOW-DETAILS     TO TRUE
               ELSE
                  SET DISP-DETAILS-NOT-FOUND TO TRUE
               END-IF
               MOVE SPACES                 TO CDEMO-DISP-ID
           ELSE
               SET DISP-DETAILS-NOT-FETCHED TO TRUE
           END-IF
           .
       1000-ENTRY-PROCESSING-EXIT.
           EXIT
           .

       1000-PROCESS-INPUTS.
           PERFORM 1100-RECEIVE-MAP
              THRU 1100-RECEIVE-MAP-EXIT
           MOVE LIT-THISPGM    TO CCARD-NEXT-PROG
           MOVE LIT-THISMAPSET TO CCARD-NEXT-MAPSET
           MOVE LIT-THISMAP    TO CCARD-NEXT-MAP
           .
       1000-PROCESS-INPUTS-EXIT.
           EXIT
           .

       1100-RECEIVE-MAP.
           EXEC CICS RECEIVE MAP(LIT-THISMAP)
                     MAPSET(LIT-THISMAPSET)
                     INTO(CDISUPAI)
                     RESP(WS-RESP-CD)
                     RESP2(WS-REAS-CD)
           END-EXEC
           .
       1100-RECEIVE-MAP-EXIT.
           EXIT
           .

       2000-FETCH-ACTION.
      *    ENTER pressed. Fetch the dispute for the key supplied.
           IF  DISPIDFI OF CDISUPAI = SPACES
           OR  DISPIDFI OF CDISUPAI = LOW-VALUES
               SET DISP-DETAILS-NOT-FETCHED TO TRUE
               IF WS-RETURN-MSG-OFF
                  SET WS-NO-DISPUTE-ID      TO TRUE
               END-IF
           ELSE
               MOVE FUNCTION TRIM(DISPIDFI OF CDISUPAI)
                                          TO DCL-DISP-ID
               SET WS-RETURN-MSG-OFF       TO TRUE
               PERFORM 9000-READ-DISPUTE
                  THRU 9000-READ-DISPUTE-EXIT
               IF FOUND-DISPUTE
                  SET DISP-SHOW-DETAILS     TO TRUE
               ELSE
                  SET DISP-DETAILS-NOT-FOUND TO TRUE
               END-IF
           END-IF
           .
       2000-FETCH-ACTION-EXIT.
           EXIT
           .

       2000-DECIDE-SAVE.
      *    F5 pressed. When a dispute is on display advance its status,
      *    otherwise open a brand new dispute.
           IF DISP-DETAILS-AVAILABLE
              PERFORM 9300-ADVANCE-STATUS
                 THRU 9300-ADVANCE-STATUS-EXIT
           ELSE
              PERFORM 9200-OPEN-NEW-DISPUTE
                 THRU 9200-OPEN-NEW-DISPUTE-EXIT
           END-IF
           .
       2000-DECIDE-SAVE-EXIT.
           EXIT
           .

       2000-CANCEL-ACTION.
           IF DISP-DETAILS-AVAILABLE
              SET DISP-SHOW-DETAILS         TO TRUE
           ELSE
              INITIALIZE DISP-OLD-DETAILS
              SET DISP-DETAILS-NOT-FETCHED  TO TRUE
           END-IF
           .
       2000-CANCEL-ACTION-EXIT.
           EXIT
           .

       3000-SEND-MAP.
           PERFORM 3100-SCREEN-INIT
              THRU 3100-SCREEN-INIT-EXIT
           PERFORM 3200-SETUP-SCREEN-VARS
              THRU 3200-SETUP-SCREEN-VARS-EXIT
           PERFORM 3250-SETUP-INFOMSG
              THRU 3250-SETUP-INFOMSG-EXIT
           PERFORM 3300-SETUP-SCREEN-ATTRS
              THRU 3300-SETUP-SCREEN-ATTRS-EXIT
           PERFORM 3400-SEND-SCREEN
              THRU 3400-SEND-SCREEN-EXIT
           .
       3000-SEND-MAP-EXIT.
           EXIT
           .

       3100-SCREEN-INIT.
           MOVE LOW-VALUES                TO CDISUPAO

           MOVE FUNCTION CURRENT-DATE     TO WS-CURDATE-DATA

           MOVE CCDA-TITLE01              TO TITLE01O OF CDISUPAO
           MOVE CCDA-TITLE02              TO TITLE02O OF CDISUPAO
           MOVE LIT-THISTRANID            TO TRNNAMEO OF CDISUPAO
           MOVE LIT-THISPGM               TO PGMNAMEO OF CDISUPAO

           MOVE WS-CURDATE-MONTH          TO WS-CURDATE-MM
           MOVE WS-CURDATE-DAY            TO WS-CURDATE-DD
           MOVE WS-CURDATE-YEAR(3:2)      TO WS-CURDATE-YY

           MOVE WS-CURDATE-MM-DD-YY       TO CURDATEO OF CDISUPAO

           MOVE WS-CURTIME-HOURS          TO WS-CURTIME-HH
           MOVE WS-CURTIME-MINUTE         TO WS-CURTIME-MM
           MOVE WS-CURTIME-SECOND         TO WS-CURTIME-SS

           MOVE WS-CURTIME-HH-MM-SS       TO CURTIMEO OF CDISUPAO
           .
       3100-SCREEN-INIT-EXIT.
           EXIT
           .

       3200-SETUP-SCREEN-VARS.
           EVALUATE TRUE
              WHEN DISP-DETAILS-NOT-FETCHED
                   CONTINUE
              WHEN DISP-DETAILS-NOT-FOUND
                   MOVE DCL-DISP-ID       TO DISPIDFO OF CDISUPAO
              WHEN DISP-DETAILS-AVAILABLE
                   PERFORM 3202-SHOW-ORIGINAL-VALUES
                      THRU 3202-SHOW-ORIGINAL-VALUES-EXIT
              WHEN OTHER
                   CONTINUE
           END-EVALUATE
           .
       3200-SETUP-SCREEN-VARS-EXIT.
           EXIT
           .

       3202-SHOW-ORIGINAL-VALUES.
           MOVE DISP-OLD-DISP-ID          TO DISPIDFO OF CDISUPAO
           MOVE DISP-OLD-TRAN-ID          TO DTRANIDO OF CDISUPAO
           MOVE DISP-OLD-CARD-NUM         TO DCARDNOO OF CDISUPAO
           MOVE DISP-OLD-AMT              TO WS-DISP-AMT-O
           MOVE WS-DISP-AMT-O             TO DAMTO    OF CDISUPAO
           MOVE DISP-OLD-REASON-CD        TO DREASONO OF CDISUPAO
           MOVE DISP-OLD-STATUS-CD        TO DSTATUSO OF CDISUPAO
           MOVE DISP-OLD-STATUS-DESC      TO DSTSDSCO OF CDISUPAO
           MOVE DISP-OLD-OPEN-TS          TO DOPENTSO OF CDISUPAO
           MOVE DISP-OLD-LAST-UPD-TS      TO DUPDTSO  OF CDISUPAO
           MOVE DISP-OLD-DESC             TO DDESCO   OF CDISUPAO
           .
       3202-SHOW-ORIGINAL-VALUES-EXIT.
           EXIT
           .

       3250-SETUP-INFOMSG.
           EVALUATE TRUE
              WHEN DISP-DETAILS-NOT-FOUND
                   SET PROMPT-DISPUTE-NOT-FOUND   TO TRUE
              WHEN DISP-OPEN-DONE
                   SET CONFIRM-OPEN-SUCCESS       TO TRUE
              WHEN DISP-STATUS-DONE
                   SET CONFIRM-STATUS-SUCCESS     TO TRUE
              WHEN DISP-SHOW-DETAILS
                   SET PROMPT-ADVANCE-STATUS      TO TRUE
              WHEN OTHER
                   SET PROMPT-FOR-DISPUTE-ID      TO TRUE
           END-EVALUATE

      * Center justify the text
           COMPUTE WS-STRING-LEN =
                   FUNCTION LENGTH(
                            FUNCTION TRIM(WS-INFO-MSG)
                                  )
           COMPUTE WS-STRING-MID =
                  (FUNCTION LENGTH(WS-INFO-MSG)
                                - WS-STRING-LEN) / 2 + 1
           MOVE WS-INFO-MSG(1:WS-STRING-LEN)
             TO WS-STRING-OUT(WS-STRING-MID:
                              WS-STRING-LEN)

           MOVE WS-STRING-OUT              TO INFOMSGO OF CDISUPAO
           MOVE WS-RETURN-MSG              TO ERRMSGO  OF CDISUPAO
           .
       3250-SETUP-INFOMSG-EXIT.
           EXIT
           .

       3300-SETUP-SCREEN-ATTRS.
           PERFORM 3310-PROTECT-ALL-ATTRS
              THRU 3310-PROTECT-ALL-ATTRS-EXIT

           EVALUATE TRUE
              WHEN DISP-DETAILS-NOT-FETCHED
              WHEN DISP-DETAILS-NOT-FOUND
                   PERFORM 3320-UNPROTECT-NEW-INPUT
                      THRU 3320-UNPROTECT-NEW-INPUT-EXIT
              WHEN DISP-DETAILS-AVAILABLE
                   PERFORM 3330-UNPROTECT-ADVANCE
                      THRU 3330-UNPROTECT-ADVANCE-EXIT
              WHEN OTHER
                   PERFORM 3320-UNPROTECT-NEW-INPUT
                      THRU 3320-UNPROTECT-NEW-INPUT-EXIT
           END-EVALUATE

      * Position the cursor
           EVALUATE TRUE
              WHEN DISP-DETAILS-AVAILABLE
                   MOVE -1             TO DNEWSTSL OF CDISUPAI
              WHEN OTHER
                   MOVE -1             TO DISPIDFL OF CDISUPAI
           END-EVALUATE

      * Highlight the key field on error
           IF NOT WS-RETURN-MSG-OFF
              IF DISP-DETAILS-NOT-FETCHED
              OR DISP-DETAILS-NOT-FOUND
                 MOVE DFHRED           TO DISPIDFC OF CDISUPAO
              END-IF
           END-IF
           .
       3300-SETUP-SCREEN-ATTRS-EXIT.
           EXIT
           .

       3310-PROTECT-ALL-ATTRS.
           MOVE DFHBMPRF              TO DISPIDFA OF CDISUPAI
                                         DTRANIDA OF CDISUPAI
                                         DREASONA OF CDISUPAI
                                         DNEWSTSA OF CDISUPAI
                                         DDESCA   OF CDISUPAI
                                         DNOTEA   OF CDISUPAI
           .
       3310-PROTECT-ALL-ATTRS-EXIT.
           EXIT
           .

       3320-UNPROTECT-NEW-INPUT.
           MOVE DFHBMFSE             TO DISPIDFA OF CDISUPAI
                                         DTRANIDA OF CDISUPAI
                                         DREASONA OF CDISUPAI
                                         DDESCA   OF CDISUPAI
                                         DNOTEA   OF CDISUPAI
           .
       3320-UNPROTECT-NEW-INPUT-EXIT.
           EXIT
           .

       3330-UNPROTECT-ADVANCE.
           MOVE DFHBMFSE             TO DNEWSTSA OF CDISUPAI
                                         DNOTEA   OF CDISUPAI
           .
       3330-UNPROTECT-ADVANCE-EXIT.
           EXIT
           .

       3400-SEND-SCREEN.
           MOVE LIT-THISMAPSET         TO CCARD-NEXT-MAPSET
           MOVE LIT-THISMAP            TO CCARD-NEXT-MAP

           EXEC CICS SEND MAP(CCARD-NEXT-MAP)
                          MAPSET(CCARD-NEXT-MAPSET)
                          FROM(CDISUPAO)
                          CURSOR
                          ERASE
                          FREEKB
                          RESP(WS-RESP-CD)
           END-EXEC
           .
       3400-SEND-SCREEN-EXIT.
           EXIT
           .

       8000-EXIT-PROGRAM.
           IF CDEMO-FROM-TRANID    EQUAL LOW-VALUES
           OR CDEMO-FROM-TRANID    EQUAL SPACES
              MOVE LIT-ADMINTRANID   TO CDEMO-TO-TRANID
           ELSE
              MOVE CDEMO-FROM-TRANID TO CDEMO-TO-TRANID
           END-IF

           IF CDEMO-FROM-PROGRAM   EQUAL LOW-VALUES
           OR CDEMO-FROM-PROGRAM   EQUAL SPACES
              MOVE LIT-ADMINPGM     TO CDEMO-TO-PROGRAM
           ELSE
              MOVE CDEMO-FROM-PROGRAM TO CDEMO-TO-PROGRAM
           END-IF

           MOVE LIT-THISTRANID     TO CDEMO-FROM-TRANID
           MOVE LIT-THISPGM        TO CDEMO-FROM-PROGRAM

           SET  CDEMO-USRTYP-ADMIN TO TRUE
           SET  CDEMO-PGM-ENTER    TO TRUE
           MOVE LIT-THISMAPSET     TO CDEMO-LAST-MAPSET
           MOVE LIT-THISMAP        TO CDEMO-LAST-MAP

           EXEC CICS
                SYNCPOINT
           END-EXEC

           EXEC CICS XCTL
                PROGRAM (CDEMO-TO-PROGRAM)
                COMMAREA(CARDDEMO-COMMAREA)
           END-EXEC
           .
       8000-EXIT-PROGRAM-EXIT.
           EXIT
           .

       9000-READ-DISPUTE.
           INITIALIZE DISP-OLD-DETAILS
           SET  WS-NO-INFO-MESSAGE      TO TRUE
           SET  NOTFOUND-DISPUTE        TO TRUE

           PERFORM 9100-GET-DISPUTE
              THRU 9100-GET-DISPUTE-EXIT

           IF FOUND-DISPUTE
              PERFORM 9500-STORE-FETCHED-DATA
                 THRU 9500-STORE-FETCHED-DATA-EXIT
           END-IF
           .
       9000-READ-DISPUTE-EXIT.
           EXIT
           .

       9100-GET-DISPUTE.
           EXEC SQL
                SELECT A.DISP_TRAN_ID
                      ,A.DISP_CARD_NUM
                      ,A.DISP_AMT
                      ,A.DISP_REASON_CD
                      ,A.DISP_STATUS_CD
                      ,B.DST_STATUS_DESC
                      ,A.DISP_OPEN_TS
                      ,A.DISP_LAST_UPD_TS
                      ,A.DISP_DESC
                  INTO :DCL-DISP-TRAN-ID
                      ,:DCL-DISP-CARD-NUM
                      ,:DCL-DISP-AMT
                      ,:DCL-DISP-REASON-CD
                      ,:DCL-DISP-STATUS-CD
                      ,:DCL-DST-STATUS-DESC
                      ,:DCL-DISP-OPEN-TS
                      ,:DCL-DISP-LAST-UPD-TS
                      ,:DCL-DISP-DESC
                  FROM CARDDEMO.DISPUTE A
                      ,CARDDEMO.DISPUTE_STATUS B
                 WHERE A.DISP_STATUS_CD = B.DST_STATUS_CD
                   AND A.DISP_ID = :DCL-DISP-ID
           END-EXEC

           MOVE SQLCODE                            TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  SET FOUND-DISPUTE               TO TRUE
               WHEN SQLCODE = +100
                  SET NOTFOUND-DISPUTE            TO TRUE
                  IF WS-RETURN-MSG-OFF
                    SET WS-DISPUTE-NOT-FOUND      TO TRUE
                  END-IF
               WHEN SQLCODE < 0
                  SET NOTFOUND-DISPUTE            TO TRUE
                  IF WS-RETURN-MSG-OFF
                    STRING
                    'Error accessing:'
                    ' DISPUTE table. SQLCODE:'
                    WS-DISP-SQLCODE
                    ':'
                    SQLERRM OF SQLCA
                    DELIMITED BY SIZE
                    INTO WS-RETURN-MSG
                    END-STRING
                  END-IF
           END-EVALUATE
           .
       9100-GET-DISPUTE-EXIT.
           EXIT
           .

       9500-STORE-FETCHED-DATA.
           MOVE DCL-DISP-ID           TO DISP-OLD-DISP-ID
           MOVE DCL-DISP-TRAN-ID      TO DISP-OLD-TRAN-ID
           MOVE DCL-DISP-CARD-NUM     TO DISP-OLD-CARD-NUM
           MOVE DCL-DISP-AMT          TO DISP-OLD-AMT
           MOVE DCL-DISP-REASON-CD    TO DISP-OLD-REASON-CD
           MOVE DCL-DISP-STATUS-CD    TO DISP-OLD-STATUS-CD
           MOVE DCL-DISP-OPEN-TS      TO DISP-OLD-OPEN-TS
           MOVE DCL-DISP-LAST-UPD-TS  TO DISP-OLD-LAST-UPD-TS

           IF DCL-DST-STATUS-DESC-LEN > 0
              MOVE DCL-DST-STATUS-DESC-TEXT(1:DCL-DST-STATUS-DESC-LEN)
                                      TO DISP-OLD-STATUS-DESC
           ELSE
              MOVE SPACES             TO DISP-OLD-STATUS-DESC
           END-IF

           IF DCL-DISP-DESC-LEN > 0
              MOVE DCL-DISP-DESC-TEXT(1:DCL-DISP-DESC-LEN)
                                      TO DISP-OLD-DESC
           ELSE
              MOVE SPACES             TO DISP-OLD-DESC
           END-IF
           .
       9500-STORE-FETCHED-DATA-EXIT.
           EXIT
           .

       9200-OPEN-NEW-DISPUTE.
           SET INPUT-OK               TO TRUE
           SET WS-RETURN-MSG-OFF       TO TRUE
      *    Validate required inputs for a new dispute
           IF  DTRANIDI OF CDISUPAI = SPACES
           OR  DTRANIDI OF CDISUPAI = LOW-VALUES
           OR  DREASONI OF CDISUPAI = SPACES
           OR  DREASONI OF CDISUPAI = LOW-VALUES
           OR  DDESCI   OF CDISUPAI = SPACES
           OR  DDESCI   OF CDISUPAI = LOW-VALUES
               SET INPUT-ERROR         TO TRUE
               IF WS-RETURN-MSG-OFF
                  SET WS-MISSING-NEW-INPUT TO TRUE
               END-IF
               SET DISP-DETAILS-NOT-FETCHED TO TRUE
               GO TO 9200-OPEN-NEW-DISPUTE-EXIT
           END-IF

      *    Read the transaction from the VSAM TRANSACT file
           MOVE FUNCTION TRIM(DTRANIDI OF CDISUPAI)
                                      TO TRAN-ID
           PERFORM 9210-READ-TRANSACTION
              THRU 9210-READ-TRANSACTION-EXIT
           IF INPUT-ERROR
              SET DISP-DETAILS-NOT-FETCHED TO TRUE
              GO TO 9200-OPEN-NEW-DISPUTE-EXIT
           END-IF

      *    Generate the next Dispute ID
           PERFORM 9220-GEN-NEW-DISP-ID
              THRU 9220-GEN-NEW-DISP-ID-EXIT
           IF INPUT-ERROR
              SET DISP-DETAILS-NOT-FETCHED TO TRUE
              GO TO 9200-OPEN-NEW-DISPUTE-EXIT
           END-IF

      *    Build the DISPUTE host variables
           MOVE WS-NEW-DISP-ID        TO DCL-DISP-ID
           MOVE TRAN-ID               TO DCL-DISP-TRAN-ID
           MOVE TRAN-CARD-NUM         TO DCL-DISP-CARD-NUM
           MOVE TRAN-AMT              TO DCL-DISP-AMT
           MOVE FUNCTION TRIM(DREASONI OF CDISUPAI)
                                      TO DCL-DISP-REASON-CD
           MOVE FUNCTION TRIM(DDESCI OF CDISUPAI)
                                      TO DCL-DISP-DESC-TEXT
           MOVE FUNCTION LENGTH(FUNCTION TRIM(DDESCI OF CDISUPAI))
                                      TO DCL-DISP-DESC-LEN

           PERFORM 9230-INSERT-DISPUTE
              THRU 9230-INSERT-DISPUTE-EXIT
           IF INPUT-ERROR
              GO TO 9200-OPEN-NEW-DISPUTE-EXIT
           END-IF

      *    Build the first DISPUTE_HISTORY row
           MOVE DCL-DISP-ID           TO DCL-DSH-DISP-ID
           MOVE 1                     TO DCL-DSH-SEQ
           MOVE '00'                  TO DCL-DSH-FROM-STATUS
           MOVE '01'                  TO DCL-DSH-TO-STATUS
           MOVE CDEMO-USER-ID         TO DCL-DSH-CHG-USER
           IF  DNOTEI OF CDISUPAI = SPACES
           OR  DNOTEI OF CDISUPAI = LOW-VALUES
               MOVE 'Dispute opened'  TO DCL-DSH-NOTE-TEXT
               MOVE 14                TO DCL-DSH-NOTE-LEN
           ELSE
               MOVE FUNCTION TRIM(DNOTEI OF CDISUPAI)
                                      TO DCL-DSH-NOTE-TEXT
               MOVE FUNCTION LENGTH(FUNCTION TRIM(DNOTEI OF CDISUPAI))
                                      TO DCL-DSH-NOTE-LEN
           END-IF

           PERFORM 9240-INSERT-HISTORY
              THRU 9240-INSERT-HISTORY-EXIT

           IF INPUT-ERROR
      *       Roll back both inserts via ABEND
              MOVE LIT-THISPGM        TO ABEND-CULPRIT
              MOVE '0002'             TO ABEND-CODE
              MOVE SPACES             TO ABEND-REASON
              MOVE 'DISPUTE OPEN FAILED - BACKING OUT'
                                      TO ABEND-MSG
              PERFORM ABEND-ROUTINE
                 THRU ABEND-ROUTINE-EXIT
           ELSE
              EXEC CICS SYNCPOINT END-EXEC
              MOVE WS-NEW-DISP-ID     TO DCL-DISP-ID
              SET  WS-RETURN-MSG-OFF   TO TRUE
              PERFORM 9000-READ-DISPUTE
                 THRU 9000-READ-DISPUTE-EXIT
              SET  DISP-OPEN-DONE     TO TRUE
           END-IF
           .
       9200-OPEN-NEW-DISPUTE-EXIT.
           EXIT
           .

       9210-READ-TRANSACTION.
           EXEC CICS READ
                DATASET   (LIT-TRANSACT-FILE)
                INTO      (TRAN-RECORD)
                LENGTH    (LENGTH OF TRAN-RECORD)
                RIDFLD    (TRAN-ID)
                KEYLENGTH (LENGTH OF TRAN-ID)
                RESP      (WS-RESP-CD)
                RESP2     (WS-REAS-CD)
           END-EXEC

           EVALUATE WS-RESP-CD
               WHEN DFHRESP(NORMAL)
                    CONTINUE
               WHEN DFHRESP(NOTFND)
                    SET INPUT-ERROR         TO TRUE
                    IF WS-RETURN-MSG-OFF
                       SET WS-TRAN-NOT-FOUND TO TRUE
                    END-IF
               WHEN OTHER
                    SET INPUT-ERROR         TO TRUE
                    IF WS-RETURN-MSG-OFF
                       SET INFORM-FAILURE   TO TRUE
                    END-IF
           END-EVALUATE
           .
       9210-READ-TRANSACTION-EXIT.
           EXIT
           .

       9220-GEN-NEW-DISP-ID.
           EXEC SQL
                SELECT MAX(DISP_ID)
                  INTO :WS-MAX-DISP-ID :WS-DISP-ID-NIND
                  FROM CARDDEMO.DISPUTE
           END-EXEC

           MOVE SQLCODE                            TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  IF WS-DISP-ID-NIND < 0
                     MOVE 1               TO WS-NEW-DISP-NUM
                  ELSE
                     COMPUTE WS-NEW-DISP-NUM =
                       FUNCTION NUMVAL(WS-MAX-DISP-ID(4:9)) + 1
                  END-IF
               WHEN SQLCODE = +100
                  MOVE 1                  TO WS-NEW-DISP-NUM
               WHEN SQLCODE < 0
                  SET INPUT-ERROR         TO TRUE
                  IF WS-RETURN-MSG-OFF
                    STRING
                    'Error generating Dispute ID. SQLCODE:'
                    WS-DISP-SQLCODE
                    ':'
                    SQLERRM OF SQLCA
                    DELIMITED BY SIZE
                    INTO WS-RETURN-MSG
                    END-STRING
                  END-IF
                  GO TO 9220-GEN-NEW-DISP-ID-EXIT
           END-EVALUATE

           STRING 'DSP'         DELIMITED BY SIZE
                  WS-NEW-DISP-NUM DELIMITED BY SIZE
                  INTO WS-NEW-DISP-ID
           END-STRING
           .
       9220-GEN-NEW-DISP-ID-EXIT.
           EXIT
           .

       9230-INSERT-DISPUTE.
           EXEC SQL
                INSERT INTO CARDDEMO.DISPUTE
                     ( DISP_ID
                     , DISP_TRAN_ID
                     , DISP_CARD_NUM
                     , DISP_AMT
                     , DISP_REASON_CD
                     , DISP_STATUS_CD
                     , DISP_OPEN_TS
                     , DISP_LAST_UPD_TS
                     , DISP_DESC )
                VALUES ( :DCL-DISP-ID
                       , :DCL-DISP-TRAN-ID
                       , :DCL-DISP-CARD-NUM
                       , :DCL-DISP-AMT
                       , :DCL-DISP-REASON-CD
                       , '01'
                       , CURRENT TIMESTAMP
                       , CURRENT TIMESTAMP
                       , :DCL-DISP-DESC )
           END-EXEC

           MOVE SQLCODE                            TO WS-DISP-SQLCODE

           IF SQLCODE NOT = ZERO
              SET INPUT-ERROR          TO TRUE
              IF WS-RETURN-MSG-OFF
                STRING
                'Error inserting DISPUTE. SQLCODE:'
                WS-DISP-SQLCODE
                ':'
                SQLERRM OF SQLCA
                DELIMITED BY SIZE
                INTO WS-RETURN-MSG
                END-STRING
              END-IF
           END-IF
           .
       9230-INSERT-DISPUTE-EXIT.
           EXIT
           .

       9240-INSERT-HISTORY.
           EXEC SQL
                INSERT INTO CARDDEMO.DISPUTE_HISTORY
                     ( DSH_DISP_ID
                     , DSH_SEQ
                     , DSH_FROM_STATUS
                     , DSH_TO_STATUS
                     , DSH_CHG_TS
                     , DSH_CHG_USER
                     , DSH_NOTE )
                VALUES ( :DCL-DSH-DISP-ID
                       , :DCL-DSH-SEQ
                       , :DCL-DSH-FROM-STATUS
                       , :DCL-DSH-TO-STATUS
                       , CURRENT TIMESTAMP
                       , :DCL-DSH-CHG-USER
                       , :DCL-DSH-NOTE )
           END-EXEC

           MOVE SQLCODE                            TO WS-DISP-SQLCODE

           IF SQLCODE NOT = ZERO
              SET INPUT-ERROR          TO TRUE
              IF WS-RETURN-MSG-OFF
                STRING
                'Error inserting DISPUTE_HISTORY. SQLCODE:'
                WS-DISP-SQLCODE
                ':'
                SQLERRM OF SQLCA
                DELIMITED BY SIZE
                INTO WS-RETURN-MSG
                END-STRING
              END-IF
           END-IF
           .
       9240-INSERT-HISTORY-EXIT.
           EXIT
           .

       9300-ADVANCE-STATUS.
           SET INPUT-OK               TO TRUE
           SET WS-RETURN-MSG-OFF       TO TRUE

      *    New status code is required
           IF  DNEWSTSI OF CDISUPAI = SPACES
           OR  DNEWSTSI OF CDISUPAI = LOW-VALUES
               SET INPUT-ERROR         TO TRUE
               IF WS-RETURN-MSG-OFF
                  SET WS-MISSING-STATUS-INPUT TO TRUE
               END-IF
               SET DISP-SHOW-DETAILS   TO TRUE
               GO TO 9300-ADVANCE-STATUS-EXIT
           END-IF

           MOVE FUNCTION TRIM(DNEWSTSI OF CDISUPAI)
                                      TO DCL-DST-STATUS-CD

      *    Validate the new status code exists
           PERFORM 9310-VALIDATE-STATUS
              THRU 9310-VALIDATE-STATUS-EXIT
           IF INPUT-ERROR
              SET DISP-SHOW-DETAILS    TO TRUE
              GO TO 9300-ADVANCE-STATUS-EXIT
           END-IF

      *    Determine next history sequence number
           MOVE DISP-OLD-DISP-ID      TO DCL-DSH-DISP-ID
           PERFORM 9320-GET-MAX-SEQ
              THRU 9320-GET-MAX-SEQ-EXIT
           IF INPUT-ERROR
              SET DISP-SHOW-DETAILS    TO TRUE
              GO TO 9300-ADVANCE-STATUS-EXIT
           END-IF

      *    Update the dispute status
           MOVE DISP-OLD-DISP-ID      TO DCL-DISP-ID
           MOVE FUNCTION TRIM(DNEWSTSI OF CDISUPAI)
                                      TO DCL-DISP-STATUS-CD
           PERFORM 9330-UPDATE-DISPUTE-STATUS
              THRU 9330-UPDATE-DISPUTE-STATUS-EXIT
           IF INPUT-ERROR
              SET DISP-SHOW-DETAILS    TO TRUE
              GO TO 9300-ADVANCE-STATUS-EXIT
           END-IF

      *    Record the change in history
           MOVE DISP-OLD-DISP-ID      TO DCL-DSH-DISP-ID
           MOVE WS-NEXT-SEQ           TO DCL-DSH-SEQ
           MOVE DISP-OLD-STATUS-CD    TO DCL-DSH-FROM-STATUS
           MOVE FUNCTION TRIM(DNEWSTSI OF CDISUPAI)
                                      TO DCL-DSH-TO-STATUS
           MOVE CDEMO-USER-ID         TO DCL-DSH-CHG-USER
           IF  DNOTEI OF CDISUPAI = SPACES
           OR  DNOTEI OF CDISUPAI = LOW-VALUES
               MOVE 'Status updated'  TO DCL-DSH-NOTE-TEXT
               MOVE 14                TO DCL-DSH-NOTE-LEN
           ELSE
               MOVE FUNCTION TRIM(DNOTEI OF CDISUPAI)
                                      TO DCL-DSH-NOTE-TEXT
               MOVE FUNCTION LENGTH(FUNCTION TRIM(DNOTEI OF CDISUPAI))
                                      TO DCL-DSH-NOTE-LEN
           END-IF

           PERFORM 9240-INSERT-HISTORY
              THRU 9240-INSERT-HISTORY-EXIT

           IF INPUT-ERROR
      *       Roll back the update and history insert via ABEND
              MOVE LIT-THISPGM        TO ABEND-CULPRIT
              MOVE '0003'             TO ABEND-CODE
              MOVE SPACES             TO ABEND-REASON
              MOVE 'STATUS UPDATE FAILED - BACKING OUT'
                                      TO ABEND-MSG
              PERFORM ABEND-ROUTINE
                 THRU ABEND-ROUTINE-EXIT
           ELSE
              EXEC CICS SYNCPOINT END-EXEC
              MOVE DISP-OLD-DISP-ID   TO DCL-DISP-ID
              SET  WS-RETURN-MSG-OFF   TO TRUE
              PERFORM 9000-READ-DISPUTE
                 THRU 9000-READ-DISPUTE-EXIT
              SET  DISP-STATUS-DONE   TO TRUE
           END-IF
           .
       9300-ADVANCE-STATUS-EXIT.
           EXIT
           .

       9310-VALIDATE-STATUS.
           EXEC SQL
                SELECT DST_STATUS_DESC
                  INTO :DCL-DST-STATUS-DESC
                  FROM CARDDEMO.DISPUTE_STATUS
                 WHERE DST_STATUS_CD = :DCL-DST-STATUS-CD
           END-EXEC

           MOVE SQLCODE                            TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN SQLCODE = +100
                  SET INPUT-ERROR         TO TRUE
                  IF WS-RETURN-MSG-OFF
                     SET WS-INVALID-STATUS TO TRUE
                  END-IF
               WHEN SQLCODE < 0
                  SET INPUT-ERROR         TO TRUE
                  IF WS-RETURN-MSG-OFF
                    STRING
                    'Error reading DISPUTE_STATUS. SQLCODE:'
                    WS-DISP-SQLCODE
                    ':'
                    SQLERRM OF SQLCA
                    DELIMITED BY SIZE
                    INTO WS-RETURN-MSG
                    END-STRING
                  END-IF
           END-EVALUATE
           .
       9310-VALIDATE-STATUS-EXIT.
           EXIT
           .

       9320-GET-MAX-SEQ.
           EXEC SQL
                SELECT MAX(DSH_SEQ)
                  INTO :WS-MAX-SEQ :WS-SEQ-NIND
                  FROM CARDDEMO.DISPUTE_HISTORY
                 WHERE DSH_DISP_ID = :DCL-DSH-DISP-ID
           END-EXEC

           MOVE SQLCODE                            TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  IF WS-SEQ-NIND < 0
                     MOVE 1               TO WS-NEXT-SEQ
                  ELSE
                     COMPUTE WS-NEXT-SEQ = WS-MAX-SEQ + 1
                  END-IF
               WHEN SQLCODE = +100
                  MOVE 1                  TO WS-NEXT-SEQ
               WHEN SQLCODE < 0
                  SET INPUT-ERROR         TO TRUE
                  IF WS-RETURN-MSG-OFF
                    STRING
                    'Error reading DISPUTE_HISTORY. SQLCODE:'
                    WS-DISP-SQLCODE
                    ':'
                    SQLERRM OF SQLCA
                    DELIMITED BY SIZE
                    INTO WS-RETURN-MSG
                    END-STRING
                  END-IF
           END-EVALUATE
           .
       9320-GET-MAX-SEQ-EXIT.
           EXIT
           .

       9330-UPDATE-DISPUTE-STATUS.
           EXEC SQL
                UPDATE CARDDEMO.DISPUTE
                   SET DISP_STATUS_CD   = :DCL-DISP-STATUS-CD
                     , DISP_LAST_UPD_TS = CURRENT TIMESTAMP
                 WHERE DISP_ID = :DCL-DISP-ID
           END-EXEC

           MOVE SQLCODE                            TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN SQLCODE = +100
                  SET INPUT-ERROR         TO TRUE
                  IF WS-RETURN-MSG-OFF
                     SET WS-DISPUTE-NOT-FOUND TO TRUE
                  END-IF
               WHEN SQLCODE = -911
                  SET INPUT-ERROR         TO TRUE
                  IF WS-RETURN-MSG-OFF
                     SET COULD-NOT-LOCK-REC TO TRUE
                  END-IF
               WHEN SQLCODE < 0
                  SET INPUT-ERROR         TO TRUE
                  IF WS-RETURN-MSG-OFF
                    STRING
                    'Error updating DISPUTE. SQLCODE:'
                    WS-DISP-SQLCODE
                    ':'
                    SQLERRM OF SQLCA
                    DELIMITED BY SIZE
                    INTO WS-RETURN-MSG
                    END-STRING
                  END-IF
           END-EVALUATE
           .
       9330-UPDATE-DISPUTE-STATUS-EXIT.
           EXIT
           .

      ******************************************************************
      *Common code to store PFKey
      ******************************************************************
       COPY 'CSSTRPFY'
           .

       ABEND-ROUTINE.
           IF ABEND-MSG EQUAL LOW-VALUES
              MOVE 'UNEXPECTED ABEND OCCURRED.' TO ABEND-MSG
           END-IF

           MOVE LIT-THISPGM       TO ABEND-CULPRIT
           MOVE '9999'            TO ABEND-CODE

           EXEC CICS SEND
                            FROM (ABEND-DATA)
                            LENGTH(LENGTH OF ABEND-DATA)
                            NOHANDLE
                            ERASE
           END-EXEC

           EXEC CICS HANDLE ABEND
                CANCEL
           END-EXEC

           EXEC CICS ABEND
                ABCODE(ABEND-CODE)
           END-EXEC
           .
       ABEND-ROUTINE-EXIT.
           EXIT
           .
