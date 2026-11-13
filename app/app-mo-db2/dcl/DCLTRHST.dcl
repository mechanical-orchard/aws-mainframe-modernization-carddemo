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
      * DCLGEN TABLE(CARDDEMO.TRAN_HIST)                               *
      *        LIBRARY(AWS.M2.CARDDEMO.DCL(DCLTRHST))                  *
      *        ACTION(REPLACE)                                         *
      *        LANGUAGE(COBOL)                                         *
      *        NAMES(DCL-)                                             *
      *        QUOTE                                                   *
      *        LABEL(YES)                                              *
      *        COLSUFFIX(YES)                                          *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE CARDDEMO.TRAN_HIST TABLE
           ( TH_TRAN_ID                     CHAR(16) NOT NULL,
             TH_ACCT_ID                     DECIMAL(11, 0) NOT NULL,
             TH_CARD_NUM                    CHAR(16) NOT NULL,
             TH_TYPE_CD                     CHAR(2) NOT NULL,
             TH_CAT_CD                      CHAR(4) NOT NULL,
             TH_SOURCE                      CHAR(10) NOT NULL,
             TH_DESC                        VARCHAR(100) NOT NULL,
             TH_AMT                         DECIMAL(11, 2) NOT NULL,
             TH_MERCHANT_ID                 DECIMAL(9, 0),
             TH_MERCHANT_NAME               VARCHAR(50),
             TH_MERCHANT_CITY               VARCHAR(50),
             TH_MERCHANT_ZIP                CHAR(10),
             TH_TRAN_DATE                   DATE NOT NULL,
             TH_ORIG_TS                     TIMESTAMP NOT NULL,
             TH_PROC_TS                     TIMESTAMP
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE CARDDEMO.TRAN_HIST                 *
      ******************************************************************
       01  DCLTRAN-HIST.
      *    *************************************************************
      *                       TH_TRAN_ID
           10 DCL-TH-TRAN-ID       PIC X(16).
      *    *************************************************************
      *                       TH_ACCT_ID
           10 DCL-TH-ACCT-ID       PIC S9(11)V USAGE COMP-3.
      *    *************************************************************
      *                       TH_CARD_NUM
           10 DCL-TH-CARD-NUM      PIC X(16).
      *    *************************************************************
      *                       TH_TYPE_CD
           10 DCL-TH-TYPE-CD       PIC X(2).
      *    *************************************************************
      *                       TH_CAT_CD
           10 DCL-TH-CAT-CD        PIC X(4).
      *    *************************************************************
      *                       TH_SOURCE
           10 DCL-TH-SOURCE        PIC X(10).
      *    *************************************************************
           10 DCL-TH-DESC.
      *                       TH_DESC LENGTH
              49 DCL-TH-DESC-LEN
                 PIC S9(4) USAGE COMP.
      *                       TH_DESC
              49 DCL-TH-DESC-TEXT
                 PIC X(100).
      *    *************************************************************
      *                       TH_AMT
           10 DCL-TH-AMT           PIC S9(9)V9(2) USAGE COMP-3.
      *    *************************************************************
      *                       TH_MERCHANT_ID
           10 DCL-TH-MERCHANT-ID   PIC S9(9)V USAGE COMP-3.
      *    *************************************************************
           10 DCL-TH-MERCHANT-NAME.
      *                       TH_MERCHANT_NAME LENGTH
              49 DCL-TH-MERCHANT-NAME-LEN
                 PIC S9(4) USAGE COMP.
      *                       TH_MERCHANT_NAME
              49 DCL-TH-MERCHANT-NAME-TEXT
                 PIC X(50).
      *    *************************************************************
           10 DCL-TH-MERCHANT-CITY.
      *                       TH_MERCHANT_CITY LENGTH
              49 DCL-TH-MERCHANT-CITY-LEN
                 PIC S9(4) USAGE COMP.
      *                       TH_MERCHANT_CITY
              49 DCL-TH-MERCHANT-CITY-TEXT
                 PIC X(50).
      *    *************************************************************
      *                       TH_MERCHANT_ZIP
           10 DCL-TH-MERCHANT-ZIP  PIC X(10).
      *    *************************************************************
      *                       TH_TRAN_DATE
           10 DCL-TH-TRAN-DATE     PIC X(10).
      *    *************************************************************
      *                       TH_ORIG_TS
           10 DCL-TH-ORIG-TS       PIC X(26).
      *    *************************************************************
      *                       TH_PROC_TS
           10 DCL-TH-PROC-TS       PIC X(26).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 15      *
      ******************************************************************
