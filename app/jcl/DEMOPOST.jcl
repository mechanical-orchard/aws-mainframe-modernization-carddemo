//DEMOPOST JOB 'DEMO CDC POST',CLASS=A,MSGCLASS=0,
//         NOTIFY=&SYSUID
//******************************************************************
//* Copyright Amazon.com, Inc. or its affiliates.
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
//******************************************************************
//* DEMO CDC daily-post. Reads the fixed daily-input PS
//* AWS.M2.CARDDEMO.DEMO.DALYIN.PS in file order; for each record
//* applies POST/CHARGE/OPEN/CLOSE to the demo VSAM KSDS (random
//* READ/REWRITE/WRITE) and mirrors the change into MODATA1.MOCDC
//* via DML (UPDATE / INSERT only, no DELETE, no DDL). Writes three
//* sequential outputs: POSTED, TRIALBAL, CONTROLS.
//*
//* Determinism relies on the fixed contents of the checked-in
//* daily-input PS and the starting state produced by DEMOLOAD.
//* STEP10 IDCAMS deletes any leftover copy of the three output
//* datasets from a prior run so DEMOPOST is idempotent for its
//* output datasets. STEP20 recreates them DISP=(NEW,CATLG,DELETE)
//* and runs CBDMO02C under the DB2 attach.
//*
//* STEP10 : IDCAMS delete of leftover output PS from prior run.
//* STEP20 : run CBDMO02C under IKJEFT01 (DB2 attach) to post
//*          DALYIN against VSAM + MOCDC and write the three
//*          output datasets.
//******************************************************************
//STEP10 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
   DELETE AWS.M2.CARDDEMO.DEMO.POSTED.PS
   DELETE AWS.M2.CARDDEMO.DEMO.TRIALBAL.PS
   DELETE AWS.M2.CARDDEMO.DEMO.CONTROLS.PS
   IF MAXCC LE 08 THEN SET MAXCC = 0
/*
//STEP20   EXEC PGM=IKJEFT01,REGION=0M
//STEPLIB  DD DISP=SHR,DSN=OEM.DB2.DAZ1.SDSNEXIT
//         DD DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//         DD DISP=SHR,DSN=AWS.M2.CARDDEMO.LOADLIB
//DBRMLIB  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DBRMLIB
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//DALYIN   DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.DALYIN.PS
//CDCACCT  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS
//POSTED   DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=AWS.M2.CARDDEMO.DEMO.POSTED.PS
//TRIALBAL DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=AWS.M2.CARDDEMO.DEMO.TRIALBAL.PS
//CONTROLS DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=AWS.M2.CARDDEMO.DEMO.CONTROLS.PS
//SYSTSIN  DD *
     DSN SYSTEM(DAZ1)
          RUN PROGRAM(CBDMO02C) PLAN(CARDDEMO)
/*
