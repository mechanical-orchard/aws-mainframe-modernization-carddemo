//MODBRPT  JOB (COBOL),'MO DB2 REPORT',CLASS=A,MSGCLASS=H,
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
//* PROGRAM CBMOD03C JOINS CARDDEMO.TRAN_HIST TO THE TRANSACTION
//* TYPE AND CATEGORY TABLES OF APP-TRANSACTION-TYPE-DB2 AND WRITES
//* ONE LINE PER TRANSACTION IN THE DATE RANGE, WITH SUBTOTALS PER
//* TYPE AND ACCOUNT AND A GRAND TOTAL.
//*
//* PARMFILE - COLS  1-10: FIRST DATE OF THE RANGE, YYYY-MM-DD
//*            COLS 12-21: LAST DATE OF THE RANGE,  YYYY-MM-DD
//* REPTFILE - THE REPORT, 133 BYTE LINES
//*
//* PREREQUISITES: MODBLOAD, AND THE APP-TRANSACTION-TYPE-DB2
//* TABLES (JOB CREADB21).
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*    HLQ     - HIGH LEVEL QUALIFIER OF THE CARDDEMO DATASETS
//*    DB2S    - DB2 SUBSYSTEM ID
//*    DB2EXIT - DB2 SDSNEXIT LIBRARY
//*    DB2LOAD - DB2 SDSNLOAD LIBRARY
//*    PLAN    - PLAN THE APP-MO-DB2 PROGRAMS ARE BOUND INTO
//*********************************************************************
//   SET HLQ=AWS.M2.CARDDEMO
//   SET DB2S=DAZ1
//   SET DB2EXIT=OEM.DB2.&DB2S..SDSNEXIT
//   SET DB2LOAD=OEMA.DB2.VERSIONA.SDSNLOAD
//   SET PLAN=CARDDEMO
//*********************************************************************
//*  MAKE THE JCL SYMBOLS AVAILABLE TO THE IN-STREAM SYSTSIN DATA
//*********************************************************************
// EXPORT SYMLIST=*
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
