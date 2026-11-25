//MODBREQ  JOB (DB2CR),'ADD MO PENDING',CLASS=A,MSGCLASS=H,
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
//* ADD PENDING ONLINE TRANSACTIONS TO CARDDEMO.TRAN_HIST FOR
//* TRANSACTION CMDR, WHICH POSTS THEM TO CARDDEMO.ACCT_DAILY_BAL.
//*
//* A ROW IS PENDING WHEN TH_SOURCE IS CICS AND TH_PROC_TS IS NULL.
//* CMDR POSTS THE PENDING ROWS IN TH_TRAN_ID ORDER: IT ADDS TH_AMT TO
//* THE DAILY BALANCE OF TH_ACCT_ID FOR TH_TRAN_DATE AND SETS
//* TH_PROC_TS. A ROW IT CANNOT POST GETS CATEGORY 9901 (NO DAILY
//* BALANCE) OR 9902 (AMOUNT OF ZERO). TH_TRAN_IDS MUST BE NEW: AN
//* EXISTING ONE STOPS THE STEP WITH AN SQL ERROR.
//*
//* EDIT THE INSERTS IN STEP10 FOR THE ROWS TO ADD. DSNTIAD DOES NOT
//* SUPPORT COMMENTS IN ITS INPUT, SO KEEP THE INPUT TO SQL ONLY. THEN
//* START CMDR, FOR EXAMPLE WITH CECI START TRANSID(CMDR). DO NOT RUN
//* THIS JOB WHILE CMDR IS RUNNING.
//*
//* THE SUBMITTING USER NEEDS INSERT ON CARDDEMO.TRAN_HIST.
//*
//* STEP10 - INSERT THE PENDING ROWS (DSNTIAD)
//*
//* RC 0 - THE ROWS ARE ADDED
//* RC 8 OR MORE - AN SQL ERROR, SEE SYSPRINT. DSNTIAD COMMITS AFTER
//*                EACH STATEMENT, SO THE ROWS BEFORE THE ERROR ARE
//*                ADDED
//*
//* PREREQUISITES: MODBCRT, AND MODBLOAD AND MODBBAL FOR THE DAILY
//* BALANCES THE ROWS POST TO.
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*    DB2S    - DB2 SUBSYSTEM ID
//*    DB2EXIT - DB2 SDSNEXIT LIBRARY
//*    DB2LOAD - DB2 SDSNLOAD LIBRARY
//*    DB2RUNL - DB2 RUNLIB.LOAD LIBRARY (DSNTIAD)
//*    TIADPLN - PLAN NAME FOR DSNTIAD
//*********************************************************************
//*  EXPORT COMES FIRST: JES SUBSTITUTES ONLY THE SYMBOLS SET AFTER IT
//*  INTO THE IN-STREAM SYSTSIN DATA (SYMBOLS=JCLONLY)
//*********************************************************************
// EXPORT SYMLIST=*
//   SET DB2S=DAZ1
//   SET DB2EXIT=OEM.DB2.&DB2S..SDSNEXIT
//   SET DB2LOAD=OEMA.DB2.VERSIONA.SDSNLOAD
//   SET DB2RUNL=OEM.DB2.&DB2S..RUNLIB.LOAD
//   SET TIADPLN=DSNTIAD
//*********************************************************************
//*  STEP10 : INSERT THE PENDING ROWS WITH DSNTIAD
//*********************************************************************
//STEP10   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2RUNL
//         DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(DSNTIAD) PLAN(&TIADPLN)
  END
/*
//SYSIN    DD *
  INSERT INTO CARDDEMO.TRAN_HIST
         (TH_TRAN_ID, TH_ACCT_ID, TH_CARD_NUM, TH_TYPE_CD, TH_CAT_CD,
          TH_SOURCE, TH_DESC, TH_AMT, TH_TRAN_DATE, TH_ORIG_TS)
  VALUES ('CICS000000000001', 1, '9680294154603697', '07', '0001',
          'CICS', 'Goodwill credit', 25.00, '2026-10-15',
          '2026-10-15-12.00.00.000000');
/*
