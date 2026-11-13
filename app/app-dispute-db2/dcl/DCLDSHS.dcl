      ******************************************************************
      * DCLGEN TABLE(CARDDEMO.DISPUTE_HISTORY)                         *
      *        LIBRARY(SNJARAO.AWS.DCL(DCLDSHS))                       *
      *        ACTION(REPLACE)                                         *
      *        LANGUAGE(COBOL)                                         *
      *        NAMES(DCL-)                                             *
      *        QUOTE                                                   *
      *        LABEL(YES)                                              *
      *        COLSUFFIX(YES)                                          *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE CARDDEMO.DISPUTE_HISTORY TABLE
           ( DSH_DISP_ID                    CHAR(12) NOT NULL,
             DSH_SEQ                        SMALLINT NOT NULL,
             DSH_FROM_STATUS                CHAR(2) NOT NULL,
             DSH_TO_STATUS                  CHAR(2) NOT NULL,
             DSH_CHG_TS                     TIMESTAMP NOT NULL,
             DSH_CHG_USER                   CHAR(8) NOT NULL,
             DSH_NOTE                       VARCHAR(100) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE CARDDEMO.DISPUTE_HISTORY           *
      ******************************************************************
       01  DCLDISPUTE-HISTORY.
      *    *************************************************************
      *                       DSH_DISP_ID
           10 DCL-DSH-DISP-ID      PIC X(12).
      *    *************************************************************
      *                       DSH_SEQ
           10 DCL-DSH-SEQ          PIC S9(4) USAGE COMP.
      *    *************************************************************
      *                       DSH_FROM_STATUS
           10 DCL-DSH-FROM-STATUS  PIC X(2).
      *    *************************************************************
      *                       DSH_TO_STATUS
           10 DCL-DSH-TO-STATUS    PIC X(2).
      *    *************************************************************
      *                       DSH_CHG_TS
           10 DCL-DSH-CHG-TS       PIC X(26).
      *    *************************************************************
      *                       DSH_CHG_USER
           10 DCL-DSH-CHG-USER     PIC X(8).
      *    *************************************************************
           10 DCL-DSH-NOTE.
      *                       DSH_NOTE LENGTH
              49 DCL-DSH-NOTE-LEN
                 PIC S9(4) USAGE COMP.
      *                       DSH_NOTE
              49 DCL-DSH-NOTE-TEXT
                 PIC X(100).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7       *
      ******************************************************************
