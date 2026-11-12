//MODBBAL  JOB (COBOL),'MO DB2 DAILY BAL',CLASS=A,MSGCLASS=0,
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
//* BUILD THE DAILY BALANCE SNAPSHOT IN CARDDEMO.ACCT_DAILY_BAL.
//*
//* PROGRAM CBMOD02C TOTALS EACH ACCOUNT'S TRAN_HIST ACTIVITY FOR
//* THE BALANCE DATE AND WRITES ONE SNAPSHOT ROW PER ACCOUNT. THE
//* OPENING BALANCE IS THE PREVIOUS SNAPSHOT'S CLOSING BALANCE, OR
//* IS SEEDED FROM ACCTDATA FOR AN ACCOUNT'S FIRST SNAPSHOT.
//* RERUNNING FOR THE SAME DATE REPLACES THAT DATE'S SNAPSHOTS.
//*
//* PARMFILE - COLS 1-10: BALANCE DATE, YYYY-MM-DD
//*
//* RC 0 - SNAPSHOTS BUILT
//* RC 4 - AN ACCOUNT WAS NOT FOUND IN ACCTDATA (LIMIT SET TO 0)
//*
//* PREREQUISITES: MODBLOAD.
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
//*  STEP10 : RUN CBMOD02C UNDER THE TSO ATTACH
//*********************************************************************
//STEP10   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//         DD DISP=SHR,DSN=&HLQ..LOADLIB
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//ACCTFILE DD DISP=SHR,
//            DSN=&HLQ..ACCTDATA.VSAM.KSDS
//PARMFILE DD *
2022-06-10
/*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(CBMOD02C) PLAN(&PLAN)
  END
/*
