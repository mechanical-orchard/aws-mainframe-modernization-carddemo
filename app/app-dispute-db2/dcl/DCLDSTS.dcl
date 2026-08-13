      ******************************************************************
      * DCLGEN TABLE(CARDDEMO.DISPUTE_STATUS)                          *
      *        LIBRARY(SNJARAO.AWS.DCL(DCLDSTS))                       *
      *        ACTION(REPLACE)                                         *
      *        LANGUAGE(COBOL)                                         *
      *        NAMES(DCL-)                                             *
      *        QUOTE                                                   *
      *        LABEL(YES)                                              *
      *        COLSUFFIX(YES)                                          *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE CARDDEMO.DISPUTE_STATUS TABLE
           ( DST_STATUS_CD                  CHAR(2) NOT NULL,
             DST_STATUS_DESC                VARCHAR(30) NOT NULL,
             DST_OPEN_FLAG                  CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE CARDDEMO.DISPUTE_STATUS            *
      ******************************************************************
       01  DCLDISPUTE-STATUS.
      *    *************************************************************
      *                       DST_STATUS_CD
           10 DCL-DST-STATUS-CD    PIC X(2).
      *    *************************************************************
           10 DCL-DST-STATUS-DESC.
      *                       DST_STATUS_DESC LENGTH
              49 DCL-DST-STATUS-DESC-LEN
                 PIC S9(4) USAGE COMP.
      *                       DST_STATUS_DESC
              49 DCL-DST-STATUS-DESC-TEXT
                 PIC X(30).
      *    *************************************************************
      *                       DST_OPEN_FLAG
           10 DCL-DST-OPEN-FLAG    PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 3       *
      ******************************************************************
