//*********************************************************************
//*  THIS PROC IS USED TO COMPILE CICS COBOL + DB2 PROGRAMS
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
//****  Sample CICS COBOL Db2 compile proc                       ******
//****  Programs built with it run under the CICS Db2 attach,    ******
//****  with the plan named in the DB2ENTRY of their CSD group   ******
//****  Compile the related BMS maps first (samples/jcl/BMSCMP)  ******
//****  Check with your Administrator for                        ******
//****  JCL suitable to your environment                         ******
//*********************************************************************
//*  PRECMP - Db2 precompile. SQL goes to &DBRMLIB(&MEMNAME)
//*  COBOL  - COBOL compile with the integrated CICS translator
//*  LKED   - Link-edit with the CICS stub DFHELII and the CICS Db2
//*           attach interface DSNCLI
//*  BINDPK - Bind package &MEMNAME into collection &COLL
//*  BINDPL - Bind plan &PLAN with PKLIST(&COLL..*)
//*
//*  The SYSTSIN data of the bind steps uses JCL symbols, so the
//*  calling job must SET MEMNAME, SSID, PLAN, COLL and QUAL and
//*  code // EXPORT SYMLIST=* (see samples/jcl/ONLDBCMP.jcl).
//*********************************************************************
//*
//BLDONDB2 PROC MEMNAME=,
//            HLQ=,
//            SSID=,
//            PLAN=,
//            COLL=,
//            QUAL=CARDDEMO,
//            SDSNEXIT=DSNV13.SDSNEXIT,
//            SDSNLOAD=DSNV13.SDSNLOAD,
//            SDFHLOAD=DFH410.CICS.SDFHLOAD,
//            SDFHCOB=DFH410.CICS.SDFHCOB,
//            COBLIB=IGY.V6R3M0.SIGYCOMP,
//            LIBPRFX=CEE,
//            SRCLIB=&HLQ..CBL,
//            CPYLIB=&HLQ..CPY,
//            DCLLIB=&HLQ..DCL,
//            DBRMLIB=&HLQ..DBRMLIB,
//            LOADLIB=&HLQ..LOADLIB
//*
//*********************************************************
//*       Db2 Precompile the Cobol Program
//*       Draw all SQL statements out into DBRMLIB
//*********************************************************
//PRECMP  EXEC PGM=DSNHPC,
//             PARM='HOST(IBMCOB),XREF,SOURCE,FLAG(I),APOST'
//STEPLIB  DD  DISP=SHR,DSN=&SDSNEXIT
//         DD  DISP=SHR,DSN=&SDSNLOAD
//SYSIN    DD  DISP=SHR,DSN=&SRCLIB(&MEMNAME)
//SYSCIN   DD  DSN=&&DSNHOUT,UNIT=SYSDA,
//             DISP=(NEW,PASS),SPACE=(800,(500,500))
//DBRMLIB  DD  DISP=OLD,DSN=&DBRMLIB(&MEMNAME)
//SYSLIB   DD  DISP=SHR,DSN=&DCLLIB
//         DD  DISP=SHR,DSN=&CPYLIB
//SYSPRINT DD  SYSOUT=*
//SYSTERM  DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//SYSUT1   DD  SPACE=(800,(500,500),,,ROUND),UNIT=SYSDA
//SYSUT2   DD  SPACE=(800,(500,500),,,ROUND),UNIT=SYSDA
//*
//*********************************************************
//*       COBOL compile; the CICS option translates the
//*       EXEC CICS commands during the compile
//*********************************************************
//COBOL   EXEC PGM=IGYCRCTL,REGION=0M,COND=(4,LT,PRECMP),
//             PARM='CICS,RENT,APOST,NODYNAM,NOSEQ,LIST,MAP,XREF'
//STEPLIB  DD DISP=SHR,DSN=&COBLIB
//         DD DISP=SHR,DSN=&SDFHLOAD
//SYSLIB   DD DISP=SHR,DSN=&CPYLIB
//         DD DISP=SHR,DSN=&DCLLIB
//         DD DISP=SHR,DSN=&SDFHCOB
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DSN=&&DSNHOUT,DISP=(OLD,DELETE)
//SYSLIN   DD DSN=&&LOADSET,UNIT=SYSDA,
//            DISP=(MOD,PASS),SPACE=(800,(500,500))
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT4   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT5   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT6   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT7   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT8   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT9   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT10  DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT11  DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT12  DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT13  DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT14  DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT15  DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSMDECK DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//*
//OKCOMP  IF (RC <= 4) THEN
//*********************************************************
//*       Link Edit with the CICS stub DFHELII and the
//*       CICS Db2 attach interface DSNCLI
//*********************************************************
//LKED    EXEC PGM=HEWL,REGION=0M,
//             PARM='LIST,XREF,RENT,MAP,AMODE(31),RMODE(ANY)'
//SYSLIB   DD DISP=SHR,DSN=&LIBPRFX..SCEELKED
//         DD DISP=SHR,DSN=&LIBPRFX..SCEELKEX
//         DD DISP=SHR,DSN=&SDFHLOAD
//         DD DISP=SHR,DSN=&SDSNLOAD
//         DD DISP=SHR,DSN=&LOADLIB
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DISP=SHR,DSN=&LOADLIB(&MEMNAME)
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSIN    DD *
  INCLUDE SYSLIB(DFHELII)
  INCLUDE SYSLIB(DSNCLI)
/*
//*********************************************************
//*       Bind the DBRM into a package in collection &COLL
//*********************************************************
//BINDPK  EXEC PGM=IKJEFT01,COND=(4,LT,LKED)
//STEPLIB  DD DISP=SHR,DSN=&SDSNEXIT
//         DD DISP=SHR,DSN=&SDSNLOAD
//DBRMLIB  DD DISP=SHR,DSN=&DBRMLIB
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
 DSN     SYSTEM    (&SSID)
 BIND    PACKAGE   (&COLL) -
         MEMBER    (&MEMNAME) -
         QUALIFIER (&QUAL) -
         ACTION    (REPLACE)  -
         ISOLATION (CS)       -
         CURRENTDATA(YES)     -
         EXPLAIN   (NO)       -
         ENCODING  (EBCDIC)
 END
/*
//OKBIND  IF (RC <= 4) THEN
//*********************************************************
//*       Bind plan &PLAN over every package in &COLL.
//*       The batch build binds the same plan; binding it
//*       again here is harmless and makes this proc work
//*       on its own.
//*********************************************************
//BINDPL  EXEC PGM=IKJEFT01
//STEPLIB  DD DISP=SHR,DSN=&SDSNEXIT
//         DD DISP=SHR,DSN=&SDSNLOAD
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
 DSN     SYSTEM    (&SSID)
 BIND    PLAN      (&PLAN) -
         PKLIST    (&COLL..*) -
         QUALIFIER (&QUAL) -
         ACTION    (REPLACE)  RETAIN   -
         ISOLATION (CS)       -
         CURRENTDATA(YES)     -
         ENCODING  (EBCDIC)
 END
/*
//        ENDIF
//        ENDIF
