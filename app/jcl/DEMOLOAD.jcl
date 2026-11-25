//DEMOLOAD JOB 'DEMO CDC LOAD',CLASS=A,MSGCLASS=0,
//         NOTIFY=&SYSUID
//******************************************************************
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
//******************************************************************
//* DEMO CDC setup/load. Reset-then-load both the demo VSAM KSDS
//* (STEP10 IDCAMS DELETE + STEP20 IDCAMS DEFINE) and MODATA1.MOCDC
//* (STEP30 CBDMO01C DELETE + INSERT) so the job is idempotent.
//* Determinism relies on the fixed contents of the checked-in seed
//* PS AWS.M2.CARDDEMO.DEMO.SEEDACCT.PS being loaded in file order
//* (equal to ascending key order) into the freshly-defined KSDS.
//*
//* STEP10 : IDCAMS delete of any leftover VSAM cluster.
//* STEP20 : IDCAMS define of AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS
//*          (KEYS(11 0), RECORDSIZE(100 100), INDEXED).
//* STEP30 : run CBDMO01C under IKJEFT01 (DB2 attach) to load VSAM
//*          and reset+load MOCDC.
//******************************************************************
//STEP10 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
   DELETE AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS CLUSTER
   IF MAXCC LE 08 THEN SET MAXCC = 0
/*
//STEP20 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
   DEFINE CLUSTER (NAME(AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS) -
          CYLINDERS(1 1) -
          KEYS(11 0) -
          RECORDSIZE(100 100) -
          SHAREOPTIONS(2 3) -
          INDEXED) -
          DATA  (NAME(AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS.DATA)) -
          INDEX (NAME(AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS.INDEX))
/*
//STEP30   EXEC PGM=IKJEFT01,REGION=0M
//STEPLIB  DD DISP=SHR,DSN=OEM.DB2.DAZ1.SDSNEXIT
//         DD DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//         DD DISP=SHR,DSN=AWS.M2.CARDDEMO.LOADLIB
//DBRMLIB  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DBRMLIB
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SEEDACCT DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.SEEDACCT.PS
//CDCACCT  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS
//SYSTSIN  DD *
     DSN SYSTEM(DAZ1)
          RUN PROGRAM(CBDMO01C) PLAN(CARDDEMO)
/*
