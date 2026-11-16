      ******************************************************************
      * Program:     CODISLIC.CBL                                      *
      * Layer:       Business logic                                    *
      * Function:    List Transaction Disputes for browse and select   *
      *              Demonstrates paging with cursors in Db2           *
      ******************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID.
           CODISLIC.
       DATE-WRITTEN.
           Jul 2026.
       DATE-COMPILED.
           Today.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.

       DATA DIVISION.

       WORKING-STORAGE SECTION.

      ******************************************************************
      * Literals and Constants
      ******************************************************************
       01 WS-CONSTANTS.
         05  LIT-THISPGM             PIC X(8)        VALUE 'CODISLIC'.
         05  LIT-THISTRANID          PIC X(4)        VALUE 'CDSL'.
         05  LIT-THISMAPSET          PIC X(7)        VALUE 'CODISLI'.
         05  LIT-THISMAP             PIC X(7)        VALUE 'CDISLIA'.
         05  LIT-ADMINPGM            PIC X(8)        VALUE 'COADM01C'.
         05  LIT-ADMINTRANID         PIC X(4)        VALUE 'CA00'.
         05  LIT-ADMINMAPSET         PIC X(7)        VALUE 'COADM01'.
         05  LIT-MNTPGM              PIC X(8)        VALUE 'CODISUPC'.
         05  LIT-MNTTRANID           PIC X(4)        VALUE 'CDSU'.
         05  LIT-MNTMAPSET           PIC X(7)        VALUE 'CODISUP'.
         05  LIT-MNTMAP              PIC X(7)        VALUE 'CDISUPA'.
         05  LIT-DSNTIAC             PIC X(7)        VALUE 'DSNTIAC'.
         05  LIT-ASTERISK            PIC X(1)        VALUE '*'.
         05  WS-MAX-SCREEN-LINES     PIC S9(4) COMP  VALUE 7.

       01  WS-MISC-STORAGE.
      ******************************************************************
      * General CICS related
      ******************************************************************
         05 WS-CICS-PROCESSNG-VARS.
            07 WS-RESP-CD            PIC S9(9) COMP VALUE ZEROS.
            07 WS-REAS-CD            PIC S9(9) COMP VALUE ZEROS.
            07 WS-TRANID             PIC X(4)       VALUE SPACES.

      ******************************************************************
      * Input edits
      ******************************************************************
         05 WS-INPUT-FLAG                          PIC X(1).
           88  INPUT-OK                            VALUES '0'
                                                          ' '
                                                   LOW-VALUES.
           88  INPUT-ERROR                         VALUE '1'.
         05  WS-EDIT-STAT-FLAG                     PIC X(1).
           88  FLG-STATFILTER-NOT-OK               VALUE '0'.
           88  FLG-STATFILTER-ISVALID              VALUE '1'.
           88  FLG-STATFILTER-BLANK                VALUE ' '.
         05  WS-EDIT-CARD-FLAG                     PIC X(1).
           88  FLG-CARDFILTER-NOT-OK               VALUE '0'.
           88  FLG-CARDFILTER-ISVALID              VALUE '1'.
           88  FLG-CARDFILTER-BLANK                VALUE ' '.
         05 WS-STATFILTER-CHANGED                  PIC X(1).
           88  FLG-STATFILTER-CHANGED-NO           VALUE LOW-VALUES.
           88  FLG-STATFILTER-CHANGED-YES          VALUE 'Y'.
         05 WS-CARDFILTER-CHANGED                  PIC X(1).
           88  FLG-CARDFILTER-CHANGED-NO           VALUE LOW-VALUES.
           88  FLG-CARDFILTER-CHANGED-YES          VALUE 'Y'.

         05  WS-OTHER-EDIT-VARS.
            10 WS-RECORDS-COUNT                    PIC S9(4) COMP-3
                                                   VALUE 0.
            10 WS-SELECTIONS-COUNT                 PIC S9(4) COMP-3
                                                   VALUE 0.

      ******************************************************************
      *  Input edits array variables
      ******************************************************************
         05 WS-EDIT-SELECT-FLAGS                   PIC X(7)
                                                   VALUE LOW-VALUES.
         05 FILLER  REDEFINES  WS-EDIT-SELECT-FLAGS.
            10 WS-EDIT-SELECT                      PIC X(1)
                                                   OCCURS 7 TIMES.
               88 SELECT-OK                        VALUES 'S', 'X'.
               88 SELECT-BLANK                     VALUES
                                                   ' ',
                                                   LOW-VALUES.

         05 WS-EDIT-SELECT-ERROR-FLAGS             PIC X(7)
                                                   VALUE LOW-VALUES.
         05 FILLER  REDEFINES WS-EDIT-SELECT-ERROR-FLAGS.
            10 WS-EDIT-SELECT-ERRORS               OCCURS 7 TIMES.
               20 WS-ROW-DISPSELECT-ERROR          PIC X(1).
                  88 WS-ROW-SELECT-ERROR           VALUE '1'.

         05 WS-SUBSCRIPT-VARS.
            10 I                                  PIC S9(4) COMP
                                                  VALUE 0.
            10 I-SELECTED                         PIC S9(4) COMP
                                                  VALUE 0.

      ******************************************************************
      * Output edits
      ******************************************************************
         05 CICS-OUTPUT-EDIT-VARS.
            10  FLG-PROTECT-SELECT-ROWS             PIC X(1).
            88  FLG-PROTECT-SELECT-ROWS-NO          VALUE '0'.
            88  FLG-PROTECT-SELECT-ROWS-YES         VALUE '1'.

      ******************************************************************
      * Output Message Construction
      ******************************************************************
         05  WS-LONG-MSG                           PIC X(800).
         05  WS-INFO-MSG                           PIC X(45).
           88  WS-NO-INFO-MESSAGE                  VALUES
                                                   SPACES LOW-VALUES.
           88  WS-INFORM-REC-ACTIONS               VALUE
               'Type S to select a dispute to maintain'.
         05  WS-RETURN-MSG                         PIC X(75).
           88  WS-RETURN-MSG-OFF                   VALUE SPACES.
           88  WS-EXIT-MESSAGE                     VALUE
               'PF03 pressed. Exiting'.
           88  WS-MESG-NO-RECORDS-FOUND            VALUE
               'No records found for this search condition.'.
           88  WS-MESG-NO-MORE-RECORDS             VALUE
               'No more pages for these search conditions'.
           88  WS-MESG-MORE-THAN-1-DISPUTE         VALUE
               'Please select only 1 dispute'.
           88  WS-MESG-INVALID-SELECTION           VALUE
               'Selection value must be S to select a dispute'.
         05  WS-PFK-FLAG                           PIC X(1).
           88  PFK-VALID                           VALUE '0'.
           88  PFK-INVALID                         VALUE '1'.
         05 WS-STRING-FORMAT-VARS.
            10 WS-STRING-MID                      PIC 9(3) VALUE 0.
            10 WS-STRING-LEN                      PIC 9(3) VALUE 0.
            10 WS-STRING-OUT                      PIC X(45).

      ******************************************************************
      * Data Handling
      ******************************************************************
         05 WS-DATA-FILTERS.
            10  WS-START-KEY                      PIC X(12).
            10  WS-STAT-FILTER                    PIC X(02)
                                                  VALUE SPACES.
            10  WS-CARD-FILTER                    PIC X(16)
                                                  VALUE SPACES.

           EXEC SQL INCLUDE CSDB2RWY END-EXEC

      ******************************************************************
      * Screen Edit Vars
      ******************************************************************
         05 WS-SCREEN-EDIT-VARS.
            10 WS-IN-STAT-CD                      PIC X(02)
                                                  VALUE SPACES.
            10 WS-IN-CARD-NUM                     PIC X(16)
                                                  VALUE SPACES.

      ******************************************************************
      * Screen Output Display Vars
      ******************************************************************
         05 WS-OUTPUT-DISPLAY-VARS.
            10 WS-EDITED-AMOUNT                   PIC -ZZZZZZZZ9.99.
            10 WS-STATUS-DISPLAY                  PIC X(24).

      ******************************************************************
      * Screen Array Vars
      ******************************************************************
         05  WS-ROW-NUMBER               PIC S9(4) COMP VALUE 0.

         05  WS-RECORDS-TO-PROCESS-FLAG            PIC X(1).
           88  READ-LOOP-EXIT                      VALUE '0'.
           88  MORE-RECORDS-TO-READ                VALUE '1'.

      ******************************************************************
      *Other common working storage Variables
      ******************************************************************
       COPY CVCRD01Y.
      ******************************************************************
      * Relational Database stuff
      ******************************************************************
            EXEC SQL INCLUDE SQLCA    END-EXEC

            EXEC SQL INCLUDE DCLDISP  END-EXEC

            EXEC SQL INCLUDE DCLDSTS  END-EXEC

      ******************************************************************
      *Cursor Declarations
      ******************************************************************
            EXEC SQL
                 DECLARE C-DISP-FORWARD CURSOR FOR
                     SELECT A.DISP_ID
                           ,A.DISP_CARD_NUM
                           ,A.DISP_AMT
                           ,A.DISP_STATUS_CD
                           ,B.DST_STATUS_DESC
                       FROM CARDDEMO.DISPUTE A
                           ,CARDDEMO.DISPUTE_STATUS B
                      WHERE A.DISP_STATUS_CD = B.DST_STATUS_CD
                        AND A.DISP_ID >= :WS-START-KEY
                        AND ((:WS-EDIT-STAT-FLAG = '1'
                        AND   A.DISP_STATUS_CD = :WS-STAT-FILTER)
                        OR   (:WS-EDIT-STAT-FLAG <> '1'))
                        AND ((:WS-EDIT-CARD-FLAG = '1'
                        AND   A.DISP_CARD_NUM = :WS-CARD-FILTER)
                        OR   (:WS-EDIT-CARD-FLAG <> '1'))
                      ORDER BY A.DISP_ID
            END-EXEC

            EXEC SQL
                 DECLARE C-DISP-BACKWARD CURSOR FOR
                     SELECT A.DISP_ID
                           ,A.DISP_CARD_NUM
                           ,A.DISP_AMT
                           ,A.DISP_STATUS_CD
                           ,B.DST_STATUS_DESC
                       FROM CARDDEMO.DISPUTE A
                           ,CARDDEMO.DISPUTE_STATUS B
                      WHERE A.DISP_STATUS_CD = B.DST_STATUS_CD
                        AND A.DISP_ID < :WS-START-KEY
                        AND ((:WS-EDIT-STAT-FLAG = '1'
                        AND   A.DISP_STATUS_CD = :WS-STAT-FILTER)
                        OR   (:WS-EDIT-STAT-FLAG <> '1'))
                        AND ((:WS-EDIT-CARD-FLAG = '1'
                        AND   A.DISP_CARD_NUM = :WS-CARD-FILTER)
                        OR   (:WS-EDIT-CARD-FLAG <> '1'))
                      ORDER BY A.DISP_ID DESC
            END-EXEC

      ******************************************************************
      *  Commarea manipulations
      ******************************************************************
      *Application Commmarea Copybook
       COPY COCOM01Y.

       01 WS-THIS-PROGCOMMAREA.
            10 WS-CA-STAT-FILTER                      PIC X(02)
                                                      VALUE SPACES.
            10 WS-CA-CARD-FILTER                      PIC X(16)
                                                      VALUE SPACES.

      ******************************************************************
      *  Screen Data Array   66 CHARS X 7 ROWS = 462
      ******************************************************************
            10 FILLER.
               15 WS-CA-ALL-ROWS-OUT                 PIC X(462).
               15 FILLER REDEFINES WS-CA-ALL-ROWS-OUT.
                  20 WS-CA-SCREEN-ROWS-OUT   OCCURS  7 TIMES.
                     30 WS-CA-EACH-ROW-OUT.
                        35 WS-CA-ROW-DISP-ID-OUT     PIC X(12).
                        35 WS-CA-ROW-CARD-OUT        PIC X(16).
                        35 WS-CA-ROW-AMT-OUT         PIC S9(9)V99
                                                     COMP-3.
                        35 WS-CA-ROW-STATUS-CD-OUT   PIC X(02).
                        35 WS-CA-ROW-STATUS-DESC-OUT PIC X(30).

            10 WS-CA-ROW-SELECTED                     PIC S9(4) COMP
                                                      VALUE 0.
            10 WS-CA-PAGING-VARIABLES.
               15 WS-CA-LAST-DISPKEY.
                  20  WS-CA-LAST-DISP-ID             PIC X(12).
               15 WS-CA-FIRST-DISPKEY.
                  20  WS-CA-FIRST-DISP-ID            PIC X(12).

               15 WS-CA-SCREEN-NUM                    PIC 9(1).
                  88 CA-FIRST-PAGE                    VALUE 1.
               15 WS-CA-LAST-PAGE-DISPLAYED           PIC 9(1).
                  88 CA-LAST-PAGE-SHOWN               VALUE 0.
                  88 CA-LAST-PAGE-NOT-SHOWN           VALUE 9.
               15 WS-CA-NEXT-PAGE-IND                 PIC X(1).
                  88 CA-NEXT-PAGE-NOT-EXISTS          VALUE LOW-VALUES.
                  88 CA-NEXT-PAGE-EXISTS              VALUE 'Y'.

       01  WS-COMMAREA                                PIC X(2000).

      *IBM SUPPLIED COPYBOOKS
       COPY DFHBMSCA.
       COPY DFHAID.

      *COMMON COPYBOOKS
      *Screen Titles
       COPY COTTL01Y.

      *Transaction Dispute List Screen Layout
       COPY CODISLI.
         01 FILLER REDEFINES CDISLIAI.
          05 FILLER                           PIC X(204).
          05 WS-ROW-DATAI.
               06 EACH-ROWI OCCURS 7 TIMES.
                  07 DSPSELL                  PIC S9(4) COMP.
                  07 DSPSELF                  PIC X.
                  07 FILLER REDEFINES DSPSELF.
                     10 DSPSELA               PIC X.
                  07 FILLER                   PIC X(4).
                  07 DSPSELI                  PIC X(1).
                  07 DSPIDL                   PIC S9(4) COMP.
                  07 DSPIDF                   PIC X.
                  07 FILLER REDEFINES DSPIDF.
                     10 DSPIDA                PIC X.
                  07 FILLER                   PIC X(4).
                  07 DSPIDI                   PIC X(12).
                  07 DSPCRDL                  PIC S9(4) COMP.
                  07 DSPCRDF                  PIC X.
                  07 FILLER REDEFINES DSPCRDF.
                     10 DSPCRDA               PIC X.
                  07 FILLER                   PIC X(4).
                  07 DSPCRDI                  PIC X(16).
                  07 DSPAMTL                  PIC S9(4) COMP.
                  07 DSPAMTF                  PIC X.
                  07 FILLER REDEFINES DSPAMTF.
                     10 DSPAMTA               PIC X.
                  07 FILLER                   PIC X(4).
                  07 DSPAMTI                  PIC X(13).
                  07 DSPSTSL                  PIC S9(4) COMP.
                  07 DSPSTSF                  PIC X.
                  07 FILLER REDEFINES DSPSTSF.
                     10 DSPSTSA               PIC X.
                  07 FILLER                   PIC X(4).
                  07 DSPSTSI                  PIC X(24).
          05 FILLER                           PIC X(199).
         01 FILLER REDEFINES CDISLIAO.
          05 FILLER                           PIC X(204).
          05 EACH-ROWO OCCURS 7 TIMES.
                  07 FILLER                   PIC X(3).
                  07 DSPSELC                  PIC X.
                  07 DSPSELP                  PIC X.
                  07 DSPSELH                  PIC X.
                  07 DSPSELV                  PIC X.
                  07 DSPSELO                  PIC X(1).
                  07 FILLER                   PIC X(3).
                  07 DSPIDC                   PIC X.
                  07 DSPIDP                   PIC X.
                  07 DSPIDH                   PIC X.
                  07 DSPIDV                   PIC X.
                  07 DSPIDO                   PIC X(12).
                  07 FILLER                   PIC X(3).
                  07 DSPCRDC                  PIC X.
                  07 DSPCRDP                  PIC X.
                  07 DSPCRDH                  PIC X.
                  07 DSPCRDV                  PIC X.
                  07 DSPCRDO                  PIC X(16).
                  07 FILLER                   PIC X(3).
                  07 DSPAMTC                  PIC X.
                  07 DSPAMTP                  PIC X.
                  07 DSPAMTH                  PIC X.
                  07 DSPAMTV                  PIC X.
                  07 DSPAMTO                  PIC X(13).
                  07 FILLER                   PIC X(3).
                  07 DSPSTSC                  PIC X.
                  07 DSPSTSP                  PIC X.
                  07 DSPSTSH                  PIC X.
                  07 DSPSTSV                  PIC X.
                  07 DSPSTSO                  PIC X(24).
          05 FILLER                           PIC X(199).
      *Current Date
       COPY CSDAT01Y.
      *Common Messages
       COPY CSMSG01Y.

      *Signed on user data
       COPY CSUSR01Y.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
         05  FILLER                                PIC X(1)
             OCCURS 1 TO 32767 TIMES DEPENDING ON EIBCALEN.

       PROCEDURE DIVISION.
       0000-MAIN.

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
      * Retrieve passed data if  any. Initialize them if first run.
      *****************************************************************
           IF EIBCALEN = 0
              INITIALIZE CARDDEMO-COMMAREA
                         WS-THIS-PROGCOMMAREA
              MOVE LIT-THISTRANID        TO CDEMO-FROM-TRANID
              MOVE LIT-THISPGM           TO CDEMO-FROM-PROGRAM
              SET CDEMO-USRTYP-ADMIN     TO TRUE
              SET CDEMO-PGM-ENTER        TO TRUE
              MOVE LIT-THISMAP           TO CDEMO-LAST-MAP
              MOVE LIT-THISMAPSET        TO CDEMO-LAST-MAPSET
              SET CA-FIRST-PAGE          TO TRUE
              SET CA-LAST-PAGE-NOT-SHOWN TO TRUE
           ELSE
              MOVE DFHCOMMAREA (1:LENGTH OF CARDDEMO-COMMAREA) TO
                                CARDDEMO-COMMAREA
              MOVE DFHCOMMAREA(LENGTH OF CARDDEMO-COMMAREA + 1:
                               LENGTH OF WS-THIS-PROGCOMMAREA )TO
                                WS-THIS-PROGCOMMAREA
           END-IF

      *****************************************************************
      * Remap PFkeys as needed.
      * Store the Mapped PF Key
      *****************************************************************
           PERFORM YYYY-STORE-PFKEY
              THRU YYYY-STORE-PFKEY-EXIT

      *****************************************************************
      * If coming in from menu. Lets forget the past and start afresh *
      *****************************************************************
           IF (CDEMO-PGM-ENTER
           AND CDEMO-FROM-PROGRAM NOT EQUAL LIT-THISPGM)
           OR ( CCARD-AID-PFK03
           AND CDEMO-FROM-TRANID  EQUAL LIT-MNTTRANID)
               INITIALIZE WS-THIS-PROGCOMMAREA
               SET CDEMO-PGM-ENTER      TO TRUE
               SET CCARD-AID-ENTER      TO TRUE
               MOVE LIT-THISMAP         TO CDEMO-LAST-MAP
               SET CA-FIRST-PAGE        TO TRUE
               SET CA-LAST-PAGE-NOT-SHOWN TO TRUE
           END-IF

      *****************************************************************
      * If something is present in commarea
      * and the from program is this program itself,
      * read and edit the inputs given
      *****************************************************************
           IF  EIBCALEN > 0
           AND CDEMO-FROM-PROGRAM  EQUAL LIT-THISPGM
               PERFORM 1000-RECEIVE-MAP
               THRU    1000-RECEIVE-MAP-EXIT

           END-IF
      *****************************************************************
      * Check the mapped key  to see if its valid at this point       *
      * F3    - Exit
      * F2    - Add a new dispute
      * Enter - Refresh / Select a dispute
      * F8    - Page down
      * F7    - Page up
      *****************************************************************
           SET PFK-INVALID TO TRUE
           IF CCARD-AID-ENTER OR
              CCARD-AID-PFK02 OR
              CCARD-AID-PFK03 OR
              CCARD-AID-PFK07 OR
              CCARD-AID-PFK08
              SET PFK-VALID TO TRUE
           END-IF

           IF PFK-INVALID
              SET CCARD-AID-ENTER TO TRUE
           END-IF
      *****************************************************************
      * If the user pressed PF3 go back to admin/caller
      *****************************************************************
           IF CCARD-AID-PFK03
              IF CDEMO-FROM-TRANID     EQUAL LOW-VALUES
              OR CDEMO-FROM-TRANID     EQUAL SPACES
              OR CDEMO-FROM-TRANID     EQUAL LIT-THISTRANID
                 MOVE LIT-ADMINTRANID   TO CDEMO-TO-TRANID
              ELSE
                 MOVE CDEMO-FROM-TRANID TO CDEMO-TO-TRANID
              END-IF

              IF CDEMO-FROM-PROGRAM   EQUAL LOW-VALUES
              OR CDEMO-FROM-PROGRAM   EQUAL SPACES
              OR CDEMO-FROM-PROGRAM   EQUAL LIT-THISPGM
                 MOVE LIT-ADMINPGM       TO CDEMO-TO-PROGRAM
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
      *
              EXEC CICS XCTL
                   PROGRAM (CDEMO-TO-PROGRAM)
                   COMMAREA(CARDDEMO-COMMAREA)
              END-EXEC

           END-IF

      *****************************************************************
      * If the user pressed PF2 transfer to add a new dispute
      *****************************************************************
           IF  (CCARD-AID-PFK02
           AND CDEMO-FROM-PROGRAM  EQUAL LIT-THISPGM)
              MOVE LIT-THISTRANID   TO CDEMO-FROM-TRANID
              MOVE LIT-THISPGM      TO CDEMO-FROM-PROGRAM
              SET  CDEMO-USRTYP-USER TO TRUE
              SET  CDEMO-PGM-ENTER  TO TRUE
              MOVE LIT-THISMAPSET   TO CDEMO-LAST-MAPSET
              MOVE LIT-THISMAP      TO CDEMO-LAST-MAP
              MOVE LIT-MNTPGM       TO CDEMO-TO-PROGRAM

              MOVE LIT-MNTMAPSET    TO CCARD-NEXT-MAPSET
              MOVE LIT-MNTMAP       TO CCARD-NEXT-MAP
              MOVE SPACES           TO CDEMO-DISP-ID

              EXEC CICS
                   SYNCPOINT
              END-EXEC

              EXEC CICS XCTL
                        PROGRAM (LIT-MNTPGM)
                        COMMAREA(CARDDEMO-COMMAREA)
              END-EXEC
           END-IF

      *****************************************************************
      * If the user selected exactly one dispute and pressed ENTER
      * transfer to the dispute maintenance program
      *****************************************************************
           IF  CCARD-AID-ENTER
           AND CDEMO-FROM-PROGRAM  EQUAL LIT-THISPGM
           AND INPUT-OK
           AND WS-SELECTIONS-COUNT = 1
              MOVE WS-CA-ROW-DISP-ID-OUT(I-SELECTED)
                                    TO CDEMO-DISP-ID
              MOVE LIT-THISTRANID   TO CDEMO-FROM-TRANID
              MOVE LIT-THISPGM      TO CDEMO-FROM-PROGRAM
              SET  CDEMO-USRTYP-USER TO TRUE
              SET  CDEMO-PGM-ENTER  TO TRUE
              MOVE LIT-THISMAPSET   TO CDEMO-LAST-MAPSET
              MOVE LIT-THISMAP      TO CDEMO-LAST-MAP
              MOVE LIT-MNTPGM       TO CDEMO-TO-PROGRAM

              MOVE LIT-MNTMAPSET    TO CCARD-NEXT-MAPSET
              MOVE LIT-MNTMAP       TO CCARD-NEXT-MAP

              EXEC CICS
                   SYNCPOINT
              END-EXEC

              EXEC CICS XCTL
                        PROGRAM (LIT-MNTPGM)
                        COMMAREA(CARDDEMO-COMMAREA)
              END-EXEC
           END-IF

      *****************************************************************
      * If the user did not press PF8, lets reset the last page flag
      *****************************************************************
           IF CCARD-AID-PFK08
              CONTINUE
           ELSE
              SET CA-LAST-PAGE-NOT-SHOWN   TO TRUE
           END-IF

      *****************************************************************
      *  Check Db2 connectivity. Quit if no Access.
      *****************************************************************
           PERFORM 9998-PRIMING-QUERY
              THRU 9998-PRIMING-QUERY-EXIT

           IF WS-DB2-ERROR
              PERFORM SEND-LONG-TEXT
                 THRU SEND-LONG-TEXT-EXIT
              GO TO COMMON-RETURN
           END-IF

      *****************************************************************
      * Now we decide what to do
      *****************************************************************
           EVALUATE TRUE
               WHEN INPUT-ERROR
      *****************************************************************
      *        ASK FOR CORRECTIONS TO INPUTS
      *****************************************************************
                    MOVE WS-RETURN-MSG   TO CCARD-ERROR-MSG
                    MOVE LIT-THISPGM     TO CDEMO-FROM-PROGRAM
                    MOVE LIT-THISMAPSET  TO CDEMO-LAST-MAPSET
                    MOVE LIT-THISMAP     TO CDEMO-LAST-MAP

                    MOVE LIT-THISPGM     TO CCARD-NEXT-PROG
                    MOVE LIT-THISMAPSET  TO CCARD-NEXT-MAPSET
                    MOVE LIT-THISMAP     TO CCARD-NEXT-MAP
                    MOVE WS-CA-FIRST-DISP-ID
                                         TO WS-START-KEY
                    IF  NOT FLG-STATFILTER-NOT-OK
                    AND NOT FLG-CARDFILTER-NOT-OK
                       PERFORM 8000-READ-FORWARD
                          THRU 8000-READ-FORWARD-EXIT
                    END-IF
                    PERFORM 2000-SEND-MAP
                       THRU 2000-SEND-MAP-EXIT
                    GO TO COMMON-RETURN
      *****************************************************************
      *        PAGE UP - PF7 - BUT ALREADY ON FIRST PAGE
      *****************************************************************
               WHEN CCARD-AID-PFK07
                    AND CA-FIRST-PAGE
                    MOVE WS-CA-FIRST-DISP-ID
                                  TO WS-START-KEY
                    PERFORM 8000-READ-FORWARD
                       THRU 8000-READ-FORWARD-EXIT
                    PERFORM 2000-SEND-MAP
                       THRU 2000-SEND-MAP-EXIT
                    GO TO COMMON-RETURN
      *****************************************************************
      *        BACK - PF3 IF WE CAME FROM SOME OTHER PROGRAM
      *****************************************************************
               WHEN CCARD-AID-PFK03
               WHEN CDEMO-PGM-REENTER AND
                    CDEMO-FROM-PROGRAM NOT EQUAL LIT-THISPGM

                    INITIALIZE CARDDEMO-COMMAREA
                               WS-THIS-PROGCOMMAREA
                               WS-MISC-STORAGE

                    MOVE LIT-THISTRANID      TO CDEMO-FROM-TRANID
                    MOVE LIT-THISPGM         TO CDEMO-FROM-PROGRAM
                    MOVE LIT-THISMAP         TO CDEMO-LAST-MAP
                    MOVE LIT-THISMAPSET      TO CDEMO-LAST-MAPSET

                    SET CDEMO-USRTYP-ADMIN   TO TRUE
                    SET CDEMO-PGM-ENTER      TO TRUE
                    SET CA-FIRST-PAGE        TO TRUE
                    SET CA-LAST-PAGE-NOT-SHOWN TO TRUE

                    MOVE WS-CA-FIRST-DISP-ID TO WS-START-KEY

                    PERFORM 8000-READ-FORWARD
                       THRU 8000-READ-FORWARD-EXIT
                    PERFORM 2000-SEND-MAP
                       THRU 2000-SEND-MAP-EXIT
                    GO TO COMMON-RETURN
      *****************************************************************
      *        PAGE DOWN
      *****************************************************************
               WHEN CCARD-AID-PFK08
                    AND CA-NEXT-PAGE-EXISTS
                    MOVE WS-CA-LAST-DISP-ID
                                  TO WS-START-KEY
                    ADD   +1      TO WS-CA-SCREEN-NUM
                    PERFORM 8000-READ-FORWARD
                       THRU 8000-READ-FORWARD-EXIT
                    INITIALIZE WS-EDIT-SELECT-FLAGS
                    PERFORM 2000-SEND-MAP
                       THRU 2000-SEND-MAP-EXIT
                    GO TO COMMON-RETURN
      *****************************************************************
      *        PAGE UP
      *****************************************************************
               WHEN CCARD-AID-PFK07
                    AND NOT CA-FIRST-PAGE
                    MOVE WS-CA-FIRST-DISP-ID
                                  TO WS-START-KEY
                    SUBTRACT 1    FROM WS-CA-SCREEN-NUM
                    PERFORM 8100-READ-BACKWARDS
                       THRU 8100-READ-BACKWARDS-EXIT
                    INITIALIZE WS-EDIT-SELECT-FLAGS
                    PERFORM 2000-SEND-MAP
                       THRU 2000-SEND-MAP-EXIT
                    GO TO COMMON-RETURN
      *****************************************************************
      *        ENTER / REFRESH THE LIST
      *****************************************************************
               WHEN OTHER
                    MOVE WS-CA-FIRST-DISP-ID
                                  TO WS-START-KEY
                    PERFORM 8000-READ-FORWARD
                       THRU 8000-READ-FORWARD-EXIT
                    PERFORM 2000-SEND-MAP
                       THRU 2000-SEND-MAP-EXIT
                    GO TO COMMON-RETURN
           END-EVALUATE

      * If we had an error setup error message to display and return
           IF INPUT-ERROR
              MOVE WS-RETURN-MSG   TO CCARD-ERROR-MSG
              MOVE LIT-THISPGM     TO CDEMO-FROM-PROGRAM
              MOVE LIT-THISMAPSET  TO CDEMO-LAST-MAPSET
              MOVE LIT-THISMAP     TO CDEMO-LAST-MAP

              MOVE LIT-THISPGM     TO CCARD-NEXT-PROG
              MOVE LIT-THISMAPSET  TO CCARD-NEXT-MAPSET
              MOVE LIT-THISMAP     TO CCARD-NEXT-MAP

              GO TO COMMON-RETURN
           END-IF

           MOVE LIT-THISPGM        TO CCARD-NEXT-PROG
           GO TO COMMON-RETURN
           .

       COMMON-RETURN.
           MOVE  LIT-THISTRANID  TO CDEMO-FROM-TRANID
           MOVE  LIT-THISPGM     TO CDEMO-FROM-PROGRAM
           MOVE  LIT-THISMAPSET  TO CDEMO-LAST-MAPSET
           MOVE  LIT-THISMAP     TO CDEMO-LAST-MAP
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

       1000-RECEIVE-MAP.
           PERFORM 1100-RECEIVE-SCREEN
              THRU 1100-RECEIVE-SCREEN-EXIT

           PERFORM 1200-EDIT-INPUTS
            THRU   1200-EDIT-INPUTS-EXIT
           .
       1000-RECEIVE-MAP-EXIT.
           EXIT
           .

       1100-RECEIVE-SCREEN.
           EXEC CICS RECEIVE MAP(LIT-THISMAP)
                          MAPSET(LIT-THISMAPSET)
                          INTO(CDISLIAI)
                          RESP(WS-RESP-CD)
           END-EXEC

           MOVE DSTATFI  OF CDISLIAI  TO WS-IN-STAT-CD
           MOVE DCARDFI  OF CDISLIAI  TO WS-IN-CARD-NUM

           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-MAX-SCREEN-LINES
               MOVE DSPSELI(I)           TO WS-EDIT-SELECT(I)
           END-PERFORM
           .
       1100-RECEIVE-SCREEN-EXIT.
           EXIT
           .

       1200-EDIT-INPUTS.

           SET INPUT-OK                   TO TRUE
           SET FLG-PROTECT-SELECT-ROWS-NO TO TRUE

           PERFORM 1220-EDIT-STATCD
              THRU 1220-EDIT-STATCD-EXIT

           PERFORM 1230-EDIT-CARDNUM
              THRU 1230-EDIT-CARDNUM-EXIT

           PERFORM 1210-EDIT-ARRAY
              THRU 1210-EDIT-ARRAY-EXIT

           PERFORM 1290-CROSS-EDITS
              THRU 1290-CROSS-EDITS-EXIT
           .
       1200-EDIT-INPUTS-EXIT.
           EXIT
           .

       1210-EDIT-ARRAY.

           MOVE ZERO                     TO WS-SELECTIONS-COUNT
           MOVE ZERO                     TO I-SELECTED

           IF  FLG-STATFILTER-CHANGED-YES
           OR  FLG-CARDFILTER-CHANGED-YES
               INITIALIZE                 WS-EDIT-SELECT-FLAGS
               GO TO 1210-EDIT-ARRAY-EXIT
           END-IF

           PERFORM VARYING I
                      FROM WS-MAX-SCREEN-LINES
                        BY -1
                     UNTIL I = 0
               EVALUATE TRUE
                 WHEN SELECT-BLANK(I)
                   CONTINUE
                 WHEN SELECT-OK(I)
                   ADD 1 TO WS-SELECTIONS-COUNT
                   MOVE I TO I-SELECTED
                 WHEN OTHER
                   SET INPUT-ERROR TO TRUE
                   MOVE '1' TO WS-ROW-DISPSELECT-ERROR(I)
                   SET WS-MESG-INVALID-SELECTION       TO TRUE
              END-EVALUATE
           END-PERFORM

           IF WS-SELECTIONS-COUNT > 1
               SET INPUT-ERROR                          TO TRUE
               SET WS-MESG-MORE-THAN-1-DISPUTE          TO TRUE
           END-IF
           .

       1210-EDIT-ARRAY-EXIT.
            EXIT
            .

       1220-EDIT-STATCD.

           SET FLG-STATFILTER-BLANK TO TRUE

      *    Not supplied
           IF WS-IN-STAT-CD   EQUAL LOW-VALUES
           OR WS-IN-STAT-CD   EQUAL SPACES
              SET FLG-STATFILTER-BLANK  TO TRUE
              MOVE SPACES       TO WS-STAT-FILTER
              GO TO  1220-EDIT-STATCD-EXIT
           ELSE
              MOVE WS-IN-STAT-CD TO WS-STAT-FILTER
              SET FLG-STATFILTER-ISVALID TO TRUE
           END-IF
           .

       1220-EDIT-STATCD-EXIT.

           IF WS-IN-STAT-CD EQUAL WS-CA-STAT-FILTER
           OR FLG-STATFILTER-BLANK
                            AND  (WS-CA-STAT-FILTER EQUAL LOW-VALUES
                             OR   WS-CA-STAT-FILTER EQUAL SPACES)
              SET FLG-STATFILTER-CHANGED-NO  TO TRUE
           ELSE
              INITIALIZE WS-CA-PAGING-VARIABLES
              MOVE WS-IN-STAT-CD             TO WS-CA-STAT-FILTER
              SET FLG-STATFILTER-CHANGED-YES TO TRUE
           END-IF

           EXIT
           .

       1230-EDIT-CARDNUM.

           SET FLG-CARDFILTER-BLANK TO TRUE

      *    Not supplied
           IF WS-IN-CARD-NUM   EQUAL LOW-VALUES
           OR WS-IN-CARD-NUM   EQUAL SPACES
              SET FLG-CARDFILTER-BLANK  TO TRUE
              MOVE SPACES       TO WS-CARD-FILTER
              GO TO  1230-EDIT-CARDNUM-EXIT
           END-IF

      *    Not numeric
           IF WS-IN-CARD-NUM  IS NOT NUMERIC
              SET INPUT-ERROR TO TRUE
              SET FLG-CARDFILTER-NOT-OK TO TRUE
              SET FLG-PROTECT-SELECT-ROWS-YES TO TRUE
              MOVE
              'CARD NUMBER FILTER, IF SUPPLIED MUST BE NUMERIC'
                              TO WS-RETURN-MSG
              GO TO 1230-EDIT-CARDNUM-EXIT
           ELSE
              MOVE WS-IN-CARD-NUM TO WS-CARD-FILTER
              SET FLG-CARDFILTER-ISVALID TO TRUE
           END-IF
           .

       1230-EDIT-CARDNUM-EXIT.

           IF WS-IN-CARD-NUM EQUAL WS-CA-CARD-FILTER
           OR FLG-CARDFILTER-BLANK
                            AND  (WS-CA-CARD-FILTER EQUAL LOW-VALUES
                             OR   WS-CA-CARD-FILTER EQUAL SPACES)
              SET FLG-CARDFILTER-CHANGED-NO   TO TRUE
           ELSE
              INITIALIZE WS-CA-PAGING-VARIABLES
              MOVE WS-IN-CARD-NUM            TO WS-CA-CARD-FILTER
              SET FLG-CARDFILTER-CHANGED-YES  TO TRUE
           END-IF

           EXIT
           .

       1290-CROSS-EDITS.

           IF FLG-STATFILTER-ISVALID
           OR FLG-CARDFILTER-ISVALID
              CONTINUE
           ELSE
               GO TO 1290-CROSS-EDITS-EXIT
           END-IF

           PERFORM 9100-CHECK-FILTERS
              THRU 9100-CHECK-FILTERS-EXIT

           IF WS-RECORDS-COUNT = 0
              SET INPUT-ERROR TO TRUE
              IF FLG-STATFILTER-ISVALID
                 SET FLG-STATFILTER-NOT-OK TO TRUE
              END-IF

              IF FLG-CARDFILTER-ISVALID
                 SET FLG-CARDFILTER-NOT-OK TO TRUE
              END-IF

              SET FLG-PROTECT-SELECT-ROWS-YES TO TRUE
              MOVE
              'No Records found for these filter conditions'
                              TO WS-RETURN-MSG
              GO TO 1290-CROSS-EDITS-EXIT
           END-IF
           .
       1290-CROSS-EDITS-EXIT.
           EXIT
           .

       2000-SEND-MAP
            .
           PERFORM 2100-SCREEN-INIT
              THRU 2100-SCREEN-INIT-EXIT
           PERFORM 2200-SETUP-ARRAY-ATTRIBS
              THRU 2200-SETUP-ARRAY-ATTRIBS-EXIT
           PERFORM 2300-SCREEN-ARRAY-INIT
              THRU 2300-SCREEN-ARRAY-INIT-EXIT
           PERFORM 2400-SETUP-SCREEN-ATTRS
              THRU 2400-SETUP-SCREEN-ATTRS-EXIT
           PERFORM 2500-SETUP-MESSAGE
              THRU 2500-SETUP-MESSAGE-EXIT
           PERFORM 2600-SEND-SCREEN
              THRU 2600-SEND-SCREEN-EXIT
           .

       2000-SEND-MAP-EXIT.
           EXIT
           .
       2100-SCREEN-INIT.
           MOVE LOW-VALUES             TO CDISLIAO

           MOVE FUNCTION CURRENT-DATE  TO WS-CURDATE-DATA

           MOVE CCDA-TITLE01           TO TITLE01O OF CDISLIAO
           MOVE CCDA-TITLE02           TO TITLE02O OF CDISLIAO
           MOVE LIT-THISTRANID         TO TRNNAMEO OF CDISLIAO
           MOVE LIT-THISPGM            TO PGMNAMEO OF CDISLIAO

           MOVE FUNCTION CURRENT-DATE  TO WS-CURDATE-DATA

           MOVE WS-CURDATE-MONTH       TO WS-CURDATE-MM
           MOVE WS-CURDATE-DAY         TO WS-CURDATE-DD
           MOVE WS-CURDATE-YEAR(3:2)   TO WS-CURDATE-YY

           MOVE WS-CURDATE-MM-DD-YY    TO CURDATEO OF CDISLIAO

           MOVE WS-CURTIME-HOURS       TO WS-CURTIME-HH
           MOVE WS-CURTIME-MINUTE      TO WS-CURTIME-MM
           MOVE WS-CURTIME-SECOND      TO WS-CURTIME-SS

           MOVE WS-CURTIME-HH-MM-SS    TO CURTIMEO OF CDISLIAO
      *    PAGE NUMBER
      *
           MOVE WS-CA-SCREEN-NUM       TO PAGENOO  OF CDISLIAO

           SET WS-NO-INFO-MESSAGE      TO TRUE
           MOVE WS-INFO-MSG            TO INFOMSGO OF CDISLIAO
           MOVE DFHBMDAR               TO INFOMSGC OF CDISLIAO
           .

       2100-SCREEN-INIT-EXIT.
           EXIT
           .

       2200-SETUP-ARRAY-ATTRIBS.
      *    REPLACE BMS GENERATED MAP WITH PROVIDED COPYBOOK
      *    AND CLEAN UP REPETITIVE CODE !!

           PERFORM VARYING I
                      FROM WS-MAX-SCREEN-LINES
                        BY -1
                     UNTIL I = 0
              IF   WS-CA-EACH-ROW-OUT(I)    EQUAL LOW-VALUES
              OR   FLG-PROTECT-SELECT-ROWS-YES
                 MOVE DFHBMPRO              TO DSPSELA (I)
              ELSE
                 IF WS-ROW-DISPSELECT-ERROR(I) = '1'
                    MOVE DFHRED             TO DSPSELC(I)
                    MOVE -1                 TO DSPSELL(I)
                 END-IF
                 MOVE DFHBMFSE             TO DSPSELA(I)
              END-IF
           END-PERFORM
           .

       2200-SETUP-ARRAY-ATTRIBS-EXIT.
           EXIT
           .

       2300-SCREEN-ARRAY-INIT.
      *    USING REDEFINES TO AVOID UP REPETITIVE CODE !!
      *
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-MAX-SCREEN-LINES

              IF   WS-CA-EACH-ROW-OUT(I)         EQUAL LOW-VALUES
                 CONTINUE
              ELSE
                 MOVE WS-CA-ROW-DISP-ID-OUT(I)   TO DSPIDO(I)
                 MOVE WS-CA-ROW-CARD-OUT(I)      TO DSPCRDO(I)

                 MOVE WS-CA-ROW-AMT-OUT(I)       TO WS-EDITED-AMOUNT
                 MOVE WS-EDITED-AMOUNT           TO DSPAMTO(I)

                 MOVE SPACES                     TO WS-STATUS-DISPLAY
                 STRING WS-CA-ROW-STATUS-CD-OUT(I)
                        ' '
                        WS-CA-ROW-STATUS-DESC-OUT(I)
                    DELIMITED BY SIZE
                    INTO WS-STATUS-DISPLAY
                 END-STRING
                 MOVE WS-STATUS-DISPLAY          TO DSPSTSO(I)

                 MOVE WS-EDIT-SELECT(I)          TO DSPSELO(I)
              END-IF
           END-PERFORM
           .

       2300-SCREEN-ARRAY-INIT-EXIT.
           EXIT
           .

       2400-SETUP-SCREEN-ATTRS.
      *    INITIALIZE SEARCH CRITERIA
           IF EIBCALEN = 0
           OR (CDEMO-PGM-ENTER
           AND CDEMO-FROM-PROGRAM = LIT-ADMINPGM)
              CONTINUE
           ELSE
              MOVE WS-IN-STAT-CD    TO DSTATFO OF CDISLIAO
              MOVE DFHBMFSE         TO DSTATFA OF CDISLIAI
              MOVE WS-IN-CARD-NUM   TO DCARDFO OF CDISLIAO
              MOVE DFHBMFSE         TO DCARDFA OF CDISLIAI
           END-IF

      *    POSITION CURSOR

           IF FLG-STATFILTER-NOT-OK
              MOVE  DFHRED                 TO DSTATFC OF CDISLIAO
              MOVE  -1                     TO DSTATFL OF CDISLIAI
           END-IF

           IF FLG-CARDFILTER-NOT-OK
              MOVE  DFHRED                 TO DCARDFC OF CDISLIAO
              MOVE  -1                     TO DCARDFL OF CDISLIAI
           END-IF

      *    IF NO ERRORS POSITION CURSOR ON THE STATUS FILTER
           IF INPUT-OK
              MOVE   -1                    TO DSTATFL OF CDISLIAI
           END-IF
           .
       2400-SETUP-SCREEN-ATTRS-EXIT.
           EXIT
           .

       2500-SETUP-MESSAGE.
      *    SETUP MESSAGE
           EVALUATE TRUE
                WHEN FLG-STATFILTER-NOT-OK
                WHEN FLG-CARDFILTER-NOT-OK
                  CONTINUE
                WHEN CCARD-AID-PFK07
                    AND CA-FIRST-PAGE
                  MOVE 'No previous pages to display'
                  TO WS-RETURN-MSG
                WHEN CCARD-AID-PFK08
                 AND CA-NEXT-PAGE-NOT-EXISTS
                 AND CA-LAST-PAGE-SHOWN
                  MOVE 'No more pages to display'
                  TO WS-RETURN-MSG
                WHEN CCARD-AID-PFK08
                 AND CA-NEXT-PAGE-NOT-EXISTS
                  IF WS-NO-INFO-MESSAGE
                     SET WS-INFORM-REC-ACTIONS    TO TRUE
                  END-IF
                  IF  CA-LAST-PAGE-NOT-SHOWN
                  AND CA-NEXT-PAGE-NOT-EXISTS
                      SET CA-LAST-PAGE-SHOWN      TO TRUE
                  END-IF
                WHEN WS-NO-INFO-MESSAGE
                WHEN CA-NEXT-PAGE-EXISTS
                  SET WS-INFORM-REC-ACTIONS       TO TRUE
                WHEN OTHER
                   SET WS-NO-INFO-MESSAGE         TO TRUE
           END-EVALUATE

           MOVE WS-RETURN-MSG          TO ERRMSGO OF CDISLIAO

      * Center justify the text
      *
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

           IF  NOT WS-NO-INFO-MESSAGE
           AND NOT WS-MESG-NO-RECORDS-FOUND
              MOVE WS-STRING-OUT      TO INFOMSGO OF CDISLIAO
              MOVE DFHNEUTR           TO INFOMSGC OF CDISLIAO
           END-IF

           .
       2500-SETUP-MESSAGE-EXIT.
           EXIT
           .

       2600-SEND-SCREEN.
           EXEC CICS SEND MAP(LIT-THISMAP)
                          MAPSET(LIT-THISMAPSET)
                          FROM(CDISLIAO)
                          CURSOR
                          ERASE
                          RESP(WS-RESP-CD)
                          FREEKB
           END-EXEC
           .
       2600-SEND-SCREEN-EXIT.
           EXIT
           .

       8000-READ-FORWARD.
           MOVE LOW-VALUES           TO WS-CA-ALL-ROWS-OUT

      *****************************************************************
      *    Start Reading
      *****************************************************************
           PERFORM 9400-OPEN-FORWARD-CURSOR
              THRU 9400-OPEN-FORWARD-CURSOR-EXIT

           IF WS-DB2-ERROR
              GO TO 8000-READ-FORWARD-EXIT
           END-IF
      *****************************************************************
      *    Loop through records and fetch max screen records
      *****************************************************************
           MOVE ZEROES TO WS-ROW-NUMBER
           SET CA-NEXT-PAGE-EXISTS    TO TRUE
           SET MORE-RECORDS-TO-READ   TO TRUE

           PERFORM UNTIL READ-LOOP-EXIT

           INITIALIZE DCLDISPUTE
                      DCLDISPUTE-STATUS

           EXEC SQL
                FETCH C-DISP-FORWARD
                INTO :DCL-DISP-ID
                    ,:DCL-DISP-CARD-NUM
                    ,:DCL-DISP-AMT
                    ,:DCL-DISP-STATUS-CD
                    ,:DCL-DST-STATUS-DESC
           END-EXEC

           MOVE SQLCODE               TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                   ADD 1              TO WS-ROW-NUMBER

                   MOVE DCL-DISP-ID
                     TO WS-CA-ROW-DISP-ID-OUT(WS-ROW-NUMBER)
                   MOVE DCL-DISP-CARD-NUM
                     TO WS-CA-ROW-CARD-OUT(WS-ROW-NUMBER)
                   MOVE DCL-DISP-AMT
                     TO WS-CA-ROW-AMT-OUT(WS-ROW-NUMBER)
                   MOVE DCL-DISP-STATUS-CD
                     TO WS-CA-ROW-STATUS-CD-OUT(WS-ROW-NUMBER)
                   MOVE DCL-DST-STATUS-DESC-TEXT
                     TO WS-CA-ROW-STATUS-DESC-OUT(WS-ROW-NUMBER)

                   IF WS-ROW-NUMBER = 1
                      MOVE DCL-DISP-ID  TO WS-CA-FIRST-DISP-ID
                      IF   WS-CA-SCREEN-NUM = 0
                           ADD   +1     TO WS-CA-SCREEN-NUM
                      ELSE
                          CONTINUE
                      END-IF
                   ELSE
                      CONTINUE
                   END-IF
      ******************************************************************
      *            Max Screen size
      ******************************************************************
                   IF WS-ROW-NUMBER = WS-MAX-SCREEN-LINES
                      SET READ-LOOP-EXIT  TO TRUE
                      MOVE DCL-DISP-ID    TO WS-CA-LAST-DISP-ID

                      EXEC SQL
                               FETCH C-DISP-FORWARD
                               INTO :DCL-DISP-ID
                                   ,:DCL-DISP-CARD-NUM
                                   ,:DCL-DISP-AMT
                                   ,:DCL-DISP-STATUS-CD
                                   ,:DCL-DST-STATUS-DESC
                      END-EXEC

                      MOVE SQLCODE        TO WS-DISP-SQLCODE

                      EVALUATE TRUE
                         WHEN SQLCODE = ZERO
                              SET CA-NEXT-PAGE-EXISTS
                                                TO TRUE
                              MOVE DCL-DISP-ID  TO WS-CA-LAST-DISP-ID
                         WHEN SQLCODE = +100
                            SET CA-NEXT-PAGE-NOT-EXISTS     TO TRUE

                            IF WS-RETURN-MSG-OFF
                            AND CCARD-AID-PFK08
                                SET WS-MESG-NO-MORE-RECORDS TO TRUE
                            END-IF
                         WHEN OTHER
      *                     This is some kind of error. Close Cursor
      *                     And exit
                            SET READ-LOOP-EXIT      TO TRUE
                            IF WS-RETURN-MSG-OFF
                               MOVE 'C-DISP-FORWARD fetch'
                                                    TO
                                                  WS-DB2-CURRENT-ACTION
                               PERFORM 9999-FORMAT-DB2-MESSAGE
                                  THRU 9999-FORMAT-DB2-MESSAGE-EXIT
                            END-IF
                      END-EVALUATE
                  END-IF
              WHEN SQLCODE = +100
                  SET READ-LOOP-EXIT              TO TRUE
                  SET CA-NEXT-PAGE-NOT-EXISTS     TO TRUE
                  MOVE DCL-DISP-ID                TO WS-CA-LAST-DISP-ID
                  IF WS-RETURN-MSG-OFF
                  AND CCARD-AID-PFK08
                     SET  WS-MESG-NO-MORE-RECORDS     TO TRUE
                  END-IF
                  IF WS-CA-SCREEN-NUM = 1
                  AND WS-ROW-NUMBER = 0
                      SET WS-MESG-NO-RECORDS-FOUND    TO TRUE
                  END-IF
               WHEN OTHER
      *           This is some kind of error. Change to END BR
      *           And exit
                  SET READ-LOOP-EXIT             TO TRUE
                  SET WS-DB2-ERROR               TO TRUE
                  IF WS-RETURN-MSG-OFF
                    MOVE 'C-DISP-FORWARD fetch'
                                    TO WS-DB2-CURRENT-ACTION

                    PERFORM 9999-FORMAT-DB2-MESSAGE
                       THRU 9999-FORMAT-DB2-MESSAGE-EXIT
                   END-IF
           END-EVALUATE
           END-PERFORM

           PERFORM 9450-CLOSE-FORWARD-CURSOR
              THRU 9450-CLOSE-FORWARD-CURSOR-EXIT
           .
       8000-READ-FORWARD-EXIT.
           EXIT
           .
       8100-READ-BACKWARDS.

           MOVE LOW-VALUES           TO WS-CA-ALL-ROWS-OUT

           MOVE WS-CA-FIRST-DISPKEY TO WS-CA-LAST-DISPKEY
      *****************************************************************
      *    Loop through records and fetch max screen records
      *****************************************************************
           COMPUTE WS-ROW-NUMBER =
                                   WS-MAX-SCREEN-LINES
           END-COMPUTE
           SET CA-NEXT-PAGE-EXISTS    TO TRUE
           SET MORE-RECORDS-TO-READ   TO TRUE

      *****************************************************************
      *    Now we show the records from previous set.
      *****************************************************************
      *    Start Reading Backwards
      *****************************************************************
           PERFORM 9500-OPEN-BACKWARD-CURSOR
              THRU 9500-OPEN-BACKWARD-CURSOR-EXIT

           PERFORM UNTIL READ-LOOP-EXIT

           INITIALIZE DCLDISPUTE
                      DCLDISPUTE-STATUS

           EXEC SQL
                FETCH C-DISP-BACKWARD
                INTO :DCL-DISP-ID
                    ,:DCL-DISP-CARD-NUM
                    ,:DCL-DISP-AMT
                    ,:DCL-DISP-STATUS-CD
                    ,:DCL-DST-STATUS-DESC
           END-EXEC

           MOVE SQLCODE               TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                    MOVE DCL-DISP-ID
                      TO WS-CA-ROW-DISP-ID-OUT(WS-ROW-NUMBER)
                    MOVE DCL-DISP-CARD-NUM
                      TO WS-CA-ROW-CARD-OUT(WS-ROW-NUMBER)
                    MOVE DCL-DISP-AMT
                      TO WS-CA-ROW-AMT-OUT(WS-ROW-NUMBER)
                    MOVE DCL-DISP-STATUS-CD
                      TO WS-CA-ROW-STATUS-CD-OUT(WS-ROW-NUMBER)
                    MOVE DCL-DST-STATUS-DESC-TEXT
                      TO WS-CA-ROW-STATUS-DESC-OUT(WS-ROW-NUMBER)

                    SUBTRACT 1  FROM WS-ROW-NUMBER
                    IF WS-ROW-NUMBER = 0
                       SET READ-LOOP-EXIT  TO TRUE
                       MOVE DCL-DISP-ID
                                TO WS-CA-FIRST-DISP-ID
                    ELSE
                       CONTINUE
                    END-IF
               WHEN OTHER
      *           This is some kind of error. Change to END BR
      *           And exit
                  SET READ-LOOP-EXIT             TO TRUE
                  SET WS-DB2-ERROR               TO TRUE

                  IF WS-RETURN-MSG-OFF
                     MOVE 'Error on fetch Cursor C-DISP-BACKWARD'
                                              TO WS-DB2-CURRENT-ACTION
                     PERFORM 9999-FORMAT-DB2-MESSAGE
                        THRU 9999-FORMAT-DB2-MESSAGE-EXIT

                   END-IF
           END-EVALUATE
           END-PERFORM
           .

       8100-READ-BACKWARDS-EXIT.
           PERFORM 9550-CLOSE-BACK-CURSOR
              THRU 9550-CLOSE-BACK-CURSOR-EXIT

           EXIT
           .

       9100-CHECK-FILTERS.

           EXEC SQL
                SELECT COUNT(1)
                  INTO :WS-RECORDS-COUNT
                  FROM CARDDEMO.DISPUTE A
                      ,CARDDEMO.DISPUTE_STATUS B
                 WHERE A.DISP_STATUS_CD = B.DST_STATUS_CD
                   AND ((:WS-EDIT-STAT-FLAG = '1'
                   AND   A.DISP_STATUS_CD = :WS-STAT-FILTER)
                   OR   (:WS-EDIT-STAT-FLAG <> '1'))
                   AND ((:WS-EDIT-CARD-FLAG = '1'
                   AND   A.DISP_CARD_NUM = :WS-CARD-FILTER)
                   OR   (:WS-EDIT-CARD-FLAG <> '1'))
           END-EXEC

           MOVE SQLCODE                             TO WS-DISP-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                   CONTINUE
               WHEN OTHER
                  SET INPUT-ERROR                   TO TRUE

                  IF WS-RETURN-MSG-OFF
                      MOVE 'Error reading DISPUTE tables '
                                               TO WS-DB2-CURRENT-ACTION
                      PERFORM 9999-FORMAT-DB2-MESSAGE
                         THRU 9999-FORMAT-DB2-MESSAGE-EXIT
                  END-IF
                  GO TO 9100-CHECK-FILTERS-EXIT
           END-EVALUATE
           .
       9100-CHECK-FILTERS-EXIT.
           EXIT
           .

       9400-OPEN-FORWARD-CURSOR.
           EXEC SQL
                OPEN C-DISP-FORWARD
           END-EXEC

           MOVE SQLCODE        TO WS-DISP-SQLCODE

           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN OTHER
      *          This is some kind of error. Close Cursor
      *          And exit
                 SET WS-DB2-ERROR        TO TRUE
                 IF WS-RETURN-MSG-OFF
                      MOVE
                      'C-DISP-FORWARD Open'
                                               TO WS-DB2-CURRENT-ACTION
                      PERFORM 9999-FORMAT-DB2-MESSAGE
                         THRU 9999-FORMAT-DB2-MESSAGE-EXIT
                 END-IF
            END-EVALUATE
            .
       9400-OPEN-FORWARD-CURSOR-EXIT.
           EXIT
           .

       9450-CLOSE-FORWARD-CURSOR.
           EXEC SQL
                CLOSE C-DISP-FORWARD
           END-EXEC

           MOVE SQLCODE        TO WS-DISP-SQLCODE

           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN OTHER
      *          This is some kind of error. Close Cursor
      *          And exit
                 SET WS-DB2-ERROR        TO TRUE
                 IF WS-RETURN-MSG-OFF
                      MOVE
                      'C-DISP-FORWARD close'
                                               TO WS-DB2-CURRENT-ACTION
                      PERFORM 9999-FORMAT-DB2-MESSAGE
                         THRU 9999-FORMAT-DB2-MESSAGE-EXIT
                 END-IF
            END-EVALUATE
            .
       9450-CLOSE-FORWARD-CURSOR-EXIT.
           EXIT
           .

       9500-OPEN-BACKWARD-CURSOR.
           EXEC SQL
                OPEN C-DISP-BACKWARD
           END-EXEC

           MOVE SQLCODE        TO WS-DISP-SQLCODE

           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN OTHER
      *          This is some kind of error. Close Cursor
      *          And exit
                 SET WS-DB2-ERROR        TO TRUE
                 IF WS-RETURN-MSG-OFF
                      MOVE
                      'C-DISP-BACKWARD Open'
                                               TO WS-DB2-CURRENT-ACTION
                      PERFORM 9999-FORMAT-DB2-MESSAGE
                         THRU 9999-FORMAT-DB2-MESSAGE-EXIT
                 END-IF
      *
            END-EVALUATE
            .
       9500-OPEN-BACKWARD-CURSOR-EXIT.
           EXIT
           .

       9550-CLOSE-BACK-CURSOR.
           EXEC SQL
                CLOSE C-DISP-BACKWARD
           END-EXEC

           MOVE SQLCODE        TO WS-DISP-SQLCODE

           EVALUATE TRUE
              WHEN SQLCODE = ZERO
                 CONTINUE
              WHEN OTHER
      *          This is some kind of error. Close Cursor
      *          And exit
                 SET WS-DB2-ERROR        TO TRUE
                 IF WS-RETURN-MSG-OFF
                      MOVE
                      'C-DISP-BACKWARD close'
                                               TO WS-DB2-CURRENT-ACTION
                      PERFORM 9999-FORMAT-DB2-MESSAGE
                         THRU 9999-FORMAT-DB2-MESSAGE-EXIT
                 END-IF
            END-EVALUATE
            .
       9550-CLOSE-BACK-CURSOR-EXIT.
           EXIT
           .
      *****************************************************************
      *Common Db2 routines
      *****************************************************************
           EXEC SQL INCLUDE CSDB2RPY END-EXEC

      *****************************************************************
      *Common code to store PFKey
      *****************************************************************
       COPY 'CSSTRPFY'
           .

      *****************************************************************
      * Plain text exit - Dont use in production                      *
      *****************************************************************
       SEND-PLAIN-TEXT.
           EXEC CICS SEND TEXT
                     FROM(WS-RETURN-MSG)
                     LENGTH(LENGTH OF WS-RETURN-MSG)
                     ERASE
                     FREEKB
           END-EXEC

           EXEC CICS RETURN
           END-EXEC
           .
       SEND-PLAIN-TEXT-EXIT.
           EXIT
           .
      *****************************************************************
      * Display Long text and exit                                    *
      * This is primarily for debugging and should not be used in     *
      * regular course                                                *
      *****************************************************************
       SEND-LONG-TEXT.
           EXEC CICS SEND TEXT
                     FROM(WS-LONG-MSG)
                     LENGTH(LENGTH OF WS-LONG-MSG)
                     ERASE
                     FREEKB
           END-EXEC

           EXEC CICS RETURN
           END-EXEC
           .
       SEND-LONG-TEXT-EXIT.
           EXIT
           .
