//MODBCRT  JOB (DB2CR),'CREATE MO DB2',CLASS=A,MSGCLASS=H,
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
//* CREATE THE APP-MO-DB2 TABLES IN THE CARDDEMO DATABASE:
//*   CARDDEMO.TRAN_HIST       - POSTED TRANSACTION HISTORY
//*   CARDDEMO.ACCT_DAILY_BAL  - ACCOUNT DAILY BALANCE SNAPSHOTS
//*
//* THE DDL IS IN &HLQ..CNTL(MODBCRT). THE CARDDEMO DATABASE MUST
//* ALREADY EXIST: RUN JOB CREADB21 OF APP-TRANSACTION-TYPE-DB2
//* FIRST. TO START OVER, RUN JOB MODBDRP FIRST.
//*
//* STEP10 - CREATE THE TABLESPACES, TABLES AND INDEXES
//* STEP20 - LIST THE NEW OBJECTS AND CHECK THAT THE
//*          APP-TRANSACTION-TYPE-DB2 TABLES USED BY MODBRPT EXIST
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*    HLQ     - HIGH LEVEL QUALIFIER OF THE CARDDEMO LIBRARIES
//*    DB2S    - DB2 SUBSYSTEM ID
//*    DB2EXIT - DB2 SDSNEXIT LIBRARY
//*    DB2LOAD - DB2 SDSNLOAD LIBRARY
//*    DB2RUNL - DB2 RUNLIB.LOAD LIBRARY (DSNTIAD AND DSNTEP4)
//*    TIADPLN - PLAN NAME FOR DSNTIAD
//*    TEP4PLN - PLAN NAME FOR DSNTEP4
//*********************************************************************
//   SET HLQ=MO.CARDDEMO
//   SET DB2S=DAZ1
//   SET DB2EXIT=OEM.DB2.&DB2S..SDSNEXIT
//   SET DB2LOAD=OEMA.DB2.VERSIONA.SDSNLOAD
//   SET DB2RUNL=OEM.DB2.&DB2S..RUNLIB.LOAD
//   SET TIADPLN=DSNTIAD
//   SET TEP4PLN=DSNTEP4
//*********************************************************************
//*  MAKE THE JCL SYMBOLS AVAILABLE TO THE IN-STREAM SYSTSIN DATA
//*********************************************************************
// EXPORT SYMLIST=*
//*********************************************************************
//*  STEP10 : CREATE THE DATABASE OBJECTS WITH DSNTIAD
//*********************************************************************
//STEP10   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2RUNL
//         DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSIN    DD DISP=SHR,DSN=&HLQ..CNTL(MODBCRT)
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(DSNTIAD) PLAN(&TIADPLN)
  END
/*
//*********************************************************************
//*  STEP20 : LIST THE NEW OBJECTS FROM THE CATALOG WITH DSNTEP4
//*********************************************************************
//STEP20   EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(4,LT,STEP10)
//STEPLIB  DD DISP=SHR,DSN=&DB2RUNL
//         DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSIN    DD DISP=SHR,DSN=&HLQ..CNTL(MODBVER)
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(DSNTEP4) PLAN(&TEP4PLN) -
      PARMS('/ALIGN(LHS) MIXED')
  END
/*
