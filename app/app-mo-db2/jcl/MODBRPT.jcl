//MODBRPT  JOB (COBOL),'MO DB2 REPORT',CLASS=A,MSGCLASS=0,
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
//* PRINT THE TRANSACTION HISTORY REPORT FROM DB2.
//*
//* PROGRAM CBMOD03C READS CARDDEMO.TRAN_HIST, OUTER JOINED TO
//* CARDDEMO.ACCT_DAILY_BAL FOR THE LAST DATE OF THE RANGE, AND
//* WRITES ONE LINE PER TRANSACTION IN THE DATE RANGE, WITH
//* SUBTOTALS PER TYPE AND ACCOUNT, EACH ACCOUNT'S CLOSING BALANCE
//* AND CREDIT LIMIT, AND A GRAND TOTAL. TYPE AND CATEGORY NAMES
//* COME FROM THE BASE TRANTYPE AND TRANCATG VSAM FILES.
//*
//* PARMFILE - COLS  1-10: FIRST DATE OF THE RANGE, YYYY-MM-DD
//*            COLS 12-21: LAST DATE OF THE RANGE,  YYYY-MM-DD
//* REPTFILE - THE REPORT, 133 BYTE LINES
//*
//* PREREQUISITES: MODBLOAD. RUN MODBBAL FOR THE LAST DATE OF THE
//* RANGE FIRST, OR EACH ACCOUNT SAYS IT HAS NO DAILY BALANCE.
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*    HLQ     - HIGH LEVEL QUALIFIER OF THE CARDDEMO DATASETS
//*    DB2S    - DB2 SUBSYSTEM ID
//*    DB2EXIT - DB2 SDSNEXIT LIBRARY
//*    DB2LOAD - DB2 SDSNLOAD LIBRARY
//*    PLAN    - PLAN THE APP-MO-DB2 PROGRAMS ARE BOUND INTO
//*********************************************************************
//*  EXPORT COMES FIRST: JES SUBSTITUTES ONLY THE SYMBOLS SET AFTER IT
//*  INTO THE IN-STREAM SYSTSIN DATA (SYMBOLS=JCLONLY)
//*********************************************************************
// EXPORT SYMLIST=*
//   SET HLQ=MO.CARDDEMO
//   SET DB2S=DS13
//   SET DB2EXIT=DSNV13.SDSNEXIT
//   SET DB2LOAD=DSNV13.SDSNLOAD
//   SET PLAN=CARDMODB
//*********************************************************************
//*  STEP05 : DELETE THE REPORT OF THE PREVIOUS RUN
//*********************************************************************
//STEP05   EXEC PGM=IEFBR14
//REPTFILE DD DISP=(MOD,DELETE,DELETE),UNIT=SYSDA,
//            SPACE=(TRK,(1,1)),
//            DSN=&HLQ..MODB.TRANRPT
//*********************************************************************
//*  STEP10 : RUN CBMOD03C UNDER THE TSO ATTACH
//*********************************************************************
//STEP10   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//         DD DISP=SHR,DSN=&HLQ..LOADLIB
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//TRANTYPE DD DISP=SHR,
//            DSN=&HLQ..TRANTYPE.VSAM.KSDS
//TRANCATG DD DISP=SHR,
//            DSN=&HLQ..TRANCATG.VSAM.KSDS
//REPTFILE DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=&HLQ..MODB.TRANRPT
//PARMFILE DD *
2022-06-10 2022-06-10
/*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(CBMOD03C) PLAN(&PLAN)
  END
/*
