//MODBCRT  JOB (DB2CR),'CREATE MO DB2',CLASS=A,MSGCLASS=0,
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
//* EACH TABLE GETS ITS OWN TABLESPACE (MOTHST01 AND MOADBL01), WHICH
//* USES THE DEFAULT STORAGE GROUP OF THE DATABASE, SO JOB MODBDRP CAN
//* REMOVE THEM WITHOUT TOUCHING ANYTHING ELSE IN CARDDEMO.
//*
//* STEP05 CREATES THE CARDDEMO DATABASE IF IT DOES NOT EXIST YET. IF
//* IT EXISTS, THE CREATE FAILS AND THE STEP STILL ENDS WITH RC 0
//* (DSNTIAD PARM RC0). THE DDL FOR STEP10 IS IN &HLQ..CNTL(MODBCRT).
//* THE SUBMITTING USER NEEDS CREATETS AND CREATETAB (OR DBADM) ON
//* DATABASE CARDDEMO AND CREATEIN ON SCHEMA CARDDEMO. TO START OVER,
//* RUN JOB MODBDRP FIRST.
//*
//* DSNTIAD DOES NOT SUPPORT COMMENTS IN ITS INPUT, SO MEMBERS MODBDB
//* AND MODBCRT HAVE NONE. KEEP IT THAT WAY.
//*
//* STEP05 - CREATE THE CARDDEMO DATABASE IF IT IS MISSING
//* STEP10 - CREATE THE TABLESPACES, TABLES AND INDEXES
//* STEP20 - LIST THE NEW OBJECTS FROM THE DB2 CATALOG
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*    HLQ     - HIGH LEVEL QUALIFIER OF THE CARDDEMO LIBRARIES
//*    DB2S    - DB2 SUBSYSTEM ID
//*    DB2EXIT - DB2 SDSNEXIT LIBRARY
//*    DB2LOAD - DB2 SDSNLOAD LIBRARY
//*    DB2RUNL - DB2 RUNLIB.LOAD LIBRARY (DSNTIAD AND DSNTEP2)
//*    TIADPLN - PLAN NAME FOR DSNTIAD
//*    TEP2PLN - PLAN NAME FOR DSNTEP2
//*********************************************************************
//   SET HLQ=MO.CARDDEMO
//   SET DB2S=DS13
//   SET DB2EXIT=DSNV13.SDSNEXIT
//   SET DB2LOAD=DSNV13.SDSNLOAD
//   SET DB2RUNL=DSNV13.RUNLIB.LOAD
//   SET TIADPLN=DSNTIA13
//   SET TEP2PLN=DSNTEP13
//*********************************************************************
//*  MAKE THE JCL SYMBOLS AVAILABLE TO THE IN-STREAM SYSTSIN DATA
//*********************************************************************
// EXPORT SYMLIST=*
//*********************************************************************
//*  STEP05 : CREATE THE CARDDEMO DATABASE IF IT IS MISSING (DSNTIAD)
//*********************************************************************
//STEP05   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2RUNL
//         DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSIN    DD DISP=SHR,DSN=&HLQ..CNTL(MODBDB)
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(DSNTIAD) PLAN(&TIADPLN) PARMS('RC0')
  END
/*
//*********************************************************************
//*  STEP10 : CREATE THE TABLESPACES, TABLES AND INDEXES WITH DSNTIAD
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
//*  STEP20 : LIST THE NEW OBJECTS FROM THE CATALOG WITH DSNTEP2
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
  RUN PROGRAM(DSNTEP2) PLAN(&TEP2PLN) -
      PARMS('/ALIGN(LHS) MIXED')
  END
/*
