//MODBDRP  JOB (DB2CR),'DROP MO DB2',CLASS=A,MSGCLASS=H,
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
//* DROP THE CARDMODB DATABASE.
//*
//* *** WARNING ***
//* THIS DROPS CARDDEMO.TRAN_HIST AND CARDDEMO.ACCT_DAILY_BAL AND
//* ALL OF THEIR DATA. USE IT TO RESET APP-MO-DB2 BEFORE RERUNNING
//* MODBCRT. THE STEP ENDS WITH RC 0 EVEN IF THE DATABASE DOES NOT
//* EXIST (DSNTIAD PARM RC0), SO CHECK SYSPRINT FOR SQL ERRORS.
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*    HLQ     - HIGH LEVEL QUALIFIER OF THE CARDDEMO LIBRARIES
//*    DB2S    - DB2 SUBSYSTEM ID
//*    DB2EXIT - DB2 SDSNEXIT LIBRARY
//*    DB2LOAD - DB2 SDSNLOAD LIBRARY
//*    DB2RUNL - DB2 RUNLIB.LOAD LIBRARY (DSNTIAD)
//*    TIADPLN - PLAN NAME FOR DSNTIAD
//*********************************************************************
//   SET HLQ=AWS.M2.CARDDEMO
//   SET DB2S=DAZ1
//   SET DB2EXIT=OEM.DB2.&DB2S..SDSNEXIT
//   SET DB2LOAD=OEMA.DB2.VERSIONA.SDSNLOAD
//   SET DB2RUNL=OEM.DB2.&DB2S..RUNLIB.LOAD
//   SET TIADPLN=DSNTIAD
//*********************************************************************
//*  MAKE THE JCL SYMBOLS AVAILABLE TO THE IN-STREAM SYSTSIN DATA
//*********************************************************************
// EXPORT SYMLIST=*
//*********************************************************************
//*  STEP10 : DROP THE DATABASE WITH DSNTIAD
//*********************************************************************
//STEP10   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2RUNL
//         DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSIN    DD DISP=SHR,DSN=&HLQ..CNTL(MODBDRP)
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(DSNTIAD) PLAN(&TIADPLN) PARMS('RC0')
  END
/*
