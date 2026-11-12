//MODBMNT  JOB (COBOL),'MO DB2 MAINT',CLASS=A,MSGCLASS=0,
//         MSGLEVEL=(1,1),NOTIFY=&SYSUID,TIME=1440
//*********************************************************************
//* Copyright (c) 2026 Mechanical Orchard, Inc.
//* All Rights Reserved.
//*
//* Licensed under the Apache License, Version 2.0 (the "License").
//* You may not use this file except in compliance with the License.
//* You may obtain a copy of the License at
//*
//*    http://www.apache.org/licenses/LICENSE-2.0
//*
//* Unless required by applicable law or agreed to in writing,
//* software distributed under the License is distributed on an
//* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//* either express or implied. See the License for the specific
//* language governing permissions and limitations under the License
//*********************************************************************
//* DAILY MAINTENANCE OF THE APP-MO-DB2 TABLES.
//*
//* PROGRAM CBMOD04C:
//*   1. FLAGS ACCOUNTS WHOSE CLOSING BALANCE ON THE AS-OF DATE IS
//*      ABOVE THEIR CREDIT LIMIT, AND CLEARS THE FLAG FOR ACCOUNTS
//*      BACK WITHIN THEIR LIMIT (CARDDEMO.ACCT_DAILY_BAL)
//*   2. DELETES CARDDEMO.TRAN_HIST ROWS DATED BEFORE THE AS-OF
//*      DATE MINUS THE RETENTION DAYS
//*
//* PARMFILE - COLS  1-10: AS-OF DATE, YYYY-MM-DD
//*            COLS 12-21: NOT USED, LEAVE BLANK
//*            COLS 23-26: RETENTION DAYS, 4 DIGITS (E.G. 0030)
//*
//* RC 0 - MAINTENANCE DONE
//* RC 4 - THE PURGED ROW COUNT DIFFERS FROM THE COUNT TAKEN FIRST
//*
//* PREREQUISITES: MODBBAL FOR THE AS-OF DATE.
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*    HLQ     - HIGH LEVEL QUALIFIER OF THE CARDDEMO DATASETS
//*    DB2S    - DB2 SUBSYSTEM ID
//*    DB2EXIT - DB2 SDSNEXIT LIBRARY
//*    DB2LOAD - DB2 SDSNLOAD LIBRARY
//*    PLAN    - PLAN THE APP-MO-DB2 PROGRAMS ARE BOUND INTO
//*********************************************************************
//   SET HLQ=MO.CARDDEMO
//   SET DB2S=DS13
//   SET DB2EXIT=DSNV13.SDSNEXIT
//   SET DB2LOAD=DSNV13.SDSNLOAD
//   SET PLAN=CARDMODB
//*********************************************************************
//*  MAKE THE JCL SYMBOLS AVAILABLE TO THE IN-STREAM SYSTSIN DATA
//*********************************************************************
// EXPORT SYMLIST=*
//*********************************************************************
//*  STEP10 : RUN CBMOD04C UNDER THE TSO ATTACH
//*********************************************************************
//STEP10   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//         DD DISP=SHR,DSN=&HLQ..LOADLIB
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//PARMFILE DD *
2022-06-10            0030
/*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(CBMOD04C) PLAN(&PLAN)
  END
/*
