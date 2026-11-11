//MODBLOAD JOB (COBOL),'MO DB2 LOAD',CLASS=A,MSGCLASS=H,
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
//* LOAD POSTED TRANSACTIONS INTO DB2 TABLE CARDDEMO.TRAN_HIST.
//*
//* PROGRAM CBMOD01C READS THE TRANSACT VSAM FILE, LOOKS UP EACH
//* CARD IN CARDXREF AND INSERTS ONE ROW PER TRANSACTION.
//* TRANSACTIONS THAT ARE ALREADY LOADED ARE SKIPPED, SO THE JOB CAN
//* BE RERUN.
//*
//* RUN IT AFTER THE BASE COMBTRAN JOB. TRANBKP EMPTIES TRANSACT AND
//* COMBTRAN RELOADS IT WITH THE TRANSACTIONS POSTED BY POSTTRAN AND
//* THE INTEREST TRANSACTIONS FROM INTCALC. BETWEEN THE TWO JOBS
//* TRANSACT IS EMPTY AND THIS JOB LOADS NOTHING.
//*
//* REJFILE - TRANSACTIONS THAT COULD NOT BE LOADED: THE 350 BYTE
//*           TRANSACTION RECORD PLUS AN 80 BYTE REASON TRAILER.
//*
//* RC 0 - ALL TRANSACTIONS LOADED OR ALREADY PRESENT
//* RC 4 - SOME TRANSACTIONS WERE WRITTEN TO REJFILE
//*
//* PREREQUISITES: MODBCRT, THE BASE BATCH THROUGH COMBTRAN, AND
//* CBMOD01C COMPILED AND BOUND INTO PLAN &PLAN
//* (SAMPLES/JCL/BATDBCMP.JCL).
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
//   SET PLAN=CARDMODB
//*********************************************************************
//*  MAKE THE JCL SYMBOLS AVAILABLE TO THE IN-STREAM SYSTSIN DATA
//*********************************************************************
// EXPORT SYMLIST=*
//*********************************************************************
//*  STEP05 : DELETE THE REJECT FILE OF THE PREVIOUS RUN
//*********************************************************************
//STEP05   EXEC PGM=IEFBR14
//REJFILE  DD DISP=(MOD,DELETE,DELETE),UNIT=SYSDA,
//            SPACE=(TRK,(1,1)),
//            DSN=&HLQ..MODB.LOADREJS
//*********************************************************************
//*  STEP10 : RUN CBMOD01C UNDER THE TSO ATTACH
//*********************************************************************
//STEP10   EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=&DB2EXIT
//         DD DISP=SHR,DSN=&DB2LOAD
//         DD DISP=SHR,DSN=&HLQ..LOADLIB
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//TRANFILE DD DISP=SHR,
//            DSN=&HLQ..TRANSACT.VSAM.KSDS
//XREFFILE DD DISP=SHR,
//            DSN=&HLQ..CARDXREF.VSAM.KSDS
//REJFILE  DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=430,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=&HLQ..MODB.LOADREJS
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  DSN SYSTEM(&DB2S)
  RUN PROGRAM(CBMOD01C) PLAN(&PLAN)
  END
/*
