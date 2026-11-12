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
      * DCLGEN TABLE(CARDDEMO.ACCT_DAILY_BAL)                          *
      *        LIBRARY(MO.CARDDEMO.DCL(DCLACDBL))                      *
      *        ACTION(REPLACE)                                         *
      *        LANGUAGE(COBOL)                                         *
      *        NAMES(DCL-)                                             *
      *        QUOTE                                                   *
      *        LABEL(YES)                                              *
      *        COLSUFFIX(YES)                                          *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE CARDDEMO.ACCT_DAILY_BAL TABLE
           ( ADB_ACCT_ID                    DECIMAL(11, 0) NOT NULL,
             ADB_BAL_DATE                   DATE NOT NULL,
             ADB_OPEN_BAL                   DECIMAL(12, 2) NOT NULL,
             ADB_CREDIT_AMT                 DECIMAL(12, 2) NOT NULL,
             ADB_DEBIT_AMT                  DECIMAL(12, 2) NOT NULL,
             ADB_CLOSE_BAL                  DECIMAL(12, 2) NOT NULL,
             ADB_TRAN_CNT                   INTEGER NOT NULL,
             ADB_CREDIT_LIMIT               DECIMAL(12, 2) NOT NULL,
             ADB_OVERLIMIT_FLG              CHAR(1) NOT NULL,
             ADB_FLAG_DATE                  DATE
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE CARDDEMO.ACCT_DAILY_BAL            *
      ******************************************************************
       01  DCLACCT-DAILY-BAL.
      *    *************************************************************
      *                       ADB_ACCT_ID
           10 DCL-ADB-ACCT-ID      PIC S9(11)V USAGE COMP-3.
      *    *************************************************************
      *                       ADB_BAL_DATE
           10 DCL-ADB-BAL-DATE     PIC X(10).
      *    *************************************************************
      *                       ADB_OPEN_BAL
           10 DCL-ADB-OPEN-BAL     PIC S9(10)V9(2) USAGE COMP-3.
      *    *************************************************************
      *                       ADB_CREDIT_AMT
           10 DCL-ADB-CREDIT-AMT   PIC S9(10)V9(2) USAGE COMP-3.
      *    *************************************************************
      *                       ADB_DEBIT_AMT
           10 DCL-ADB-DEBIT-AMT    PIC S9(10)V9(2) USAGE COMP-3.
      *    *************************************************************
      *                       ADB_CLOSE_BAL
           10 DCL-ADB-CLOSE-BAL    PIC S9(10)V9(2) USAGE COMP-3.
      *    *************************************************************
      *                       ADB_TRAN_CNT
           10 DCL-ADB-TRAN-CNT     PIC S9(9) USAGE COMP.
      *    *************************************************************
      *                       ADB_CREDIT_LIMIT
           10 DCL-ADB-CREDIT-LIMIT PIC S9(10)V9(2) USAGE COMP-3.
      *    *************************************************************
      *                       ADB_OVERLIMIT_FLG
           10 DCL-ADB-OVERLIMIT-FLG
              PIC X(1).
      *    *************************************************************
      *                       ADB_FLAG_DATE
           10 DCL-ADB-FLAG-DATE    PIC X(10).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10      *
      ******************************************************************
