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
      ******************************************************************
      * DCLGEN TABLE(CARDDEMO.ACCT_REQUEST)                            *
      *        LIBRARY(AWS.M2.CARDDEMO.DCL(DCLACREQ))                  *
      *        ACTION(REPLACE)                                         *
      *        LANGUAGE(COBOL)                                         *
      *        NAMES(DCL-)                                             *
      *        QUOTE                                                   *
      *        LABEL(YES)                                              *
      *        COLSUFFIX(YES)                                          *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE CARDDEMO.ACCT_REQUEST TABLE
           ( REQ_ID                         CHAR(12) NOT NULL,
             REQ_ACTION                     CHAR(1) NOT NULL,
             REQ_ACCT_ID                    DECIMAL(11, 0) NOT NULL,
             REQ_BAL_DATE                   DATE NOT NULL,
             REQ_CARD_NUM                   CHAR(16),
             REQ_AMT                        DECIMAL(11, 2),
             REQ_DESC                       VARCHAR(100),
             REQ_STATUS                     CHAR(1) NOT NULL,
             REQ_REASON                     CHAR(8),
             REQ_TRAN_ID                    CHAR(16)
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE CARDDEMO.ACCT_REQUEST              *
      ******************************************************************
       01  DCLACCT-REQUEST.
      *    *************************************************************
      *                       REQ_ID
           10 DCL-REQ-ID           PIC X(12).
      *    *************************************************************
      *                       REQ_ACTION
           10 DCL-REQ-ACTION       PIC X(1).
      *    *************************************************************
      *                       REQ_ACCT_ID
           10 DCL-REQ-ACCT-ID      PIC S9(11)V USAGE COMP-3.
      *    *************************************************************
      *                       REQ_BAL_DATE
           10 DCL-REQ-BAL-DATE     PIC X(10).
      *    *************************************************************
      *                       REQ_CARD_NUM
           10 DCL-REQ-CARD-NUM     PIC X(16).
      *    *************************************************************
      *                       REQ_AMT
           10 DCL-REQ-AMT          PIC S9(9)V9(2) USAGE COMP-3.
      *    *************************************************************
           10 DCL-REQ-DESC.
      *                       REQ_DESC LENGTH
              49 DCL-REQ-DESC-LEN
                 PIC S9(4) USAGE COMP.
      *                       REQ_DESC
              49 DCL-REQ-DESC-TEXT
                 PIC X(100).
      *    *************************************************************
      *                       REQ_STATUS
           10 DCL-REQ-STATUS       PIC X(1).
      *    *************************************************************
      *                       REQ_REASON
           10 DCL-REQ-REASON       PIC X(8).
      *    *************************************************************
      *                       REQ_TRAN_ID
           10 DCL-REQ-TRAN-ID      PIC X(16).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10      *
      ******************************************************************
