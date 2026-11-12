//BATDBCMP JOB 'Compile Batch DB2 PGM',CLASS=A,MSGCLASS=H,
//             MSGLEVEL=(1,1),REGION=0M,NOTIFY=&SYSUID,TIME=1440
//*********************************************************************
//*  Compile, link and bind one batch COBOL Db2 program.
//*  Set MEMNAME to the program to build and submit once per
//*  program. The app-mo-db2 programs are:
//*     CBMOD01C  CBMOD02C  CBMOD03C  CBMOD04C
//*  set    HLQ  to your high level qualifier
//*  set    SSID to your DB2 SSID  !!!
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
//****  Sample batch COBOL Db2 compile JCL                       ******
//****  Check with your Administrator for                        ******
//****  JCL suitable to your environment                         ******
//*********************************************************************
//*  Set Parms for this compile:
//*    MEMNAME - program to compile, link and bind
//*    HLQ     - high level qualifier of the CardDemo libraries
//*    SSID    - Db2 subsystem id
//*    PLAN    - plan the batch jobs run with
//*    COLL    - package collection the plan includes
//*    QUAL    - qualifier for unqualified table names
//*********************************************************************
//*  Export comes first: JES substitutes only the symbols set after
//*  it into the in-stream SYSTSIN data of the PROC
//*********************************************************************
// EXPORT SYMLIST=*
//   SET MEMNAME=CBMOD01C
//   SET HLQ=AWS.M2.CARDDEMO
//   SET SSID=DAZ1
//   SET PLAN=CARDMODB
//   SET COLL=CARDMODB
//   SET QUAL=CARDDEMO
//*********************************************************************
//*  Add proclib reference
//*********************************************************************
//CCLIBS  JCLLIB ORDER=&HLQ..PROC.UTIL
//*********************************************************************
//*  compile the COBOL code:
//*********************************************************************
//BATDBCMP EXEC BLDBTDB2,MEMNAME=&MEMNAME,HLQ=&HLQ,SSID=&SSID,
//             PLAN=&PLAN,COLL=&COLL,QUAL=&QUAL
