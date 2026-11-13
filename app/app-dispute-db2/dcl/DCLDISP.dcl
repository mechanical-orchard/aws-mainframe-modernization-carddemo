      ******************************************************************
      * DCLGEN TABLE(CARDDEMO.DISPUTE)                                 *
      *        LIBRARY(SNJARAO.AWS.DCL(DCLDISP))                       *
      *        ACTION(REPLACE)                                         *
      *        LANGUAGE(COBOL)                                         *
      *        NAMES(DCL-)                                             *
      *        QUOTE                                                   *
      *        LABEL(YES)                                              *
      *        COLSUFFIX(YES)                                          *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE CARDDEMO.DISPUTE TABLE
           ( DISP_ID                        CHAR(12) NOT NULL,
             DISP_TRAN_ID                   CHAR(16) NOT NULL,
             DISP_CARD_NUM                  CHAR(16) NOT NULL,
             DISP_AMT                       DECIMAL(11, 2) NOT NULL,
             DISP_REASON_CD                 CHAR(4) NOT NULL,
             DISP_STATUS_CD                 CHAR(2) NOT NULL,
             DISP_OPEN_TS                   TIMESTAMP NOT NULL,
             DISP_LAST_UPD_TS               TIMESTAMP NOT NULL,
             DISP_DESC                      VARCHAR(100) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE CARDDEMO.DISPUTE                   *
      ******************************************************************
       01  DCLDISPUTE.
      *    *************************************************************
      *                       DISP_ID
           10 DCL-DISP-ID          PIC X(12).
      *    *************************************************************
      *                       DISP_TRAN_ID
           10 DCL-DISP-TRAN-ID     PIC X(16).
      *    *************************************************************
      *                       DISP_CARD_NUM
           10 DCL-DISP-CARD-NUM    PIC X(16).
      *    *************************************************************
      *                       DISP_AMT
           10 DCL-DISP-AMT         PIC S9(9)V99 USAGE COMP-3.
      *    *************************************************************
      *                       DISP_REASON_CD
           10 DCL-DISP-REASON-CD   PIC X(4).
      *    *************************************************************
      *                       DISP_STATUS_CD
           10 DCL-DISP-STATUS-CD   PIC X(2).
      *    *************************************************************
      *                       DISP_OPEN_TS
           10 DCL-DISP-OPEN-TS     PIC X(26).
      *    *************************************************************
      *                       DISP_LAST_UPD_TS
           10 DCL-DISP-LAST-UPD-TS PIC X(26).
      *    *************************************************************
           10 DCL-DISP-DESC.
      *                       DISP_DESC LENGTH
              49 DCL-DISP-DESC-LEN
                 PIC S9(4) USAGE COMP.
      *                       DISP_DESC
              49 DCL-DISP-DESC-TEXT
                 PIC X(100).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 9       *
      ******************************************************************
