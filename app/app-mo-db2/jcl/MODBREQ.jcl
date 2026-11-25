//MODBREQ  JOB (DB2CR),'ADD MO REQUESTS',CLASS=A,MSGCLASS=0,
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
//* ADD PENDING REQUESTS TO CARDDEMO.ACCT_REQUEST FOR TRANSACTION
//* CMDR, WHICH APPLIES THEM:
//*   A - POST AN ADJUSTMENT (REQ_CARD_NUM AND REQ_AMT REQUIRED)
//*   S - SET THE OVER-LIMIT FLAG
//*   C - CLEAR THE OVER-LIMIT FLAG
//*
//* EACH REQUEST NAMES THE ACCOUNT AND THE BUSINESS DATE (REQ_BAL_DATE)
//* OF THE DAILY BALANCE IT APPLIES TO. REQ_STATUS DEFAULTS TO P
//* (PENDING). CMDR APPLIES THE PENDING REQUESTS IN REQ_ID ORDER AND
//* MARKS EACH ONE D (DONE) OR R (REJECTED, WITH REQ_REASON). REQ_IDS
//* MUST BE NEW: AN EXISTING ONE STOPS THE STEP WITH AN SQL ERROR.
//*
//* EDIT THE INSERTS IN STEP10 FOR THE REQUESTS TO ADD. DSNTIAD DOES
//* NOT SUPPORT COMMENTS IN ITS INPUT, SO KEEP THE INPUT TO SQL ONLY.
//* THEN START CMDR, FOR EXAMPLE WITH CECI START TRANSID(CMDR). DO NOT
//* RUN THIS JOB WHILE CMDR IS RUNNING.
//*
//* THE SUBMITTING USER NEEDS INSERT ON CARDDEMO.ACCT_REQUEST.
//*
//* STEP10 - INSERT THE REQUESTS (DSNTIAD)
//*
//* RC 0 - THE REQUESTS ARE ADDED
//* RC 8 OR MORE - AN SQL ERROR, SEE SYSPRINT. DSNTIAD COMMITS AFTER
//*                EACH STATEMENT, SO THE ROWS BEFORE THE ERROR ARE
//*                ADDED
//*
//* PREREQUISITES: MODBCRT, AND MODBLOAD AND MODBBAL FOR THE DAILY
//* BALANCES THE REQUESTS APPLY TO.
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
//   SET DB2S=DS13
//   SET DB2EXIT=DSNV13.SDSNEXIT
//   SET DB2LOAD=DSNV13.SDSNLOAD
//   SET DB2RUNL=DSNV13.RUNLIB.LOAD
//   SET TIADPLN=DSNTIA13
//*********************************************************************
//*  STEP10 : INSERT THE REQUESTS WITH DSNTIAD
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
  INSERT INTO CARDDEMO.ACCT_REQUEST
         (REQ_ID, REQ_ACTION, REQ_ACCT_ID, REQ_BAL_DATE,
          REQ_CARD_NUM, REQ_AMT, REQ_DESC)
  VALUES ('R00000000001', 'A', 1, '2026-10-15',
          '9680294154603697', 25.00, 'Goodwill credit');

  INSERT INTO CARDDEMO.ACCT_REQUEST
         (REQ_ID, REQ_ACTION, REQ_ACCT_ID, REQ_BAL_DATE)
  VALUES ('R00000000002', 'S', 1, '2026-10-15');
/*
