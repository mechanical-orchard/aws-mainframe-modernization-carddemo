//CREADDB2 JOB (DB2CR),'DISPUTE DB2',CLASS=A,MSGCLASS=A,
//         TIME=1440,NOTIFY=&SYSUID,TYPRUN=SCAN
//*********************************************************************
//****  Create CARDDEMO Dispute tables in DAZ1 subsystem        ******
//*********************************************************************
//****  Prereq: the CARDDEMO DB2 database already exists         *****
//****  (created by app-transaction-type-db2 job CREADB21).      *****
//****  This job only adds the DISPUTE_STATUS, DISPUTE and       *****
//****  DISPUTE_HISTORY tablespaces/tables and loads seed data.  *****
//*********************************************************************
//*  SET PARMS FOR THIS JOB:
//*********************************************************************
//   SET CODER=AWS
//   SET LBNM=&CODER..M2.CARDDEMO
//   SET DB2S=DAZ1
//*********************************************************************
//JOBLIB  DD  DSN=OEM.DB2.&DB2S..SDSNLOAD,DISP=SHR
//  DD  DSN=OEM.DB2.&DB2S..SDSNLOAD,DISP=SHR
//  DD  DSN=CEE.SCEERUN,DISP=SHR
//*********************************************************************
//****  STEP 10 : Use Utility DSNTIAD to create the tables       *****
//****            This uses an existing STOGROUP AWST1STG        *****
//*********************************************************************
//CRDSPDB  EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DISP=SHR,DSN=OEM.DB2.&DB2S..RUNLIB.LOAD
//         DD DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//SYSTSPRT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD DISP=SHR,DSN=&LBNM..CNTL(DB2DIAD)
//SYSIN    DD DISP=SHR,DSN=&LBNM..CNTL(DB2DCRT)
//*********************************************************************
//****  STEP 20 : Load the dispute status reference table        *****
//****            using DSNTEP4 utility                          *****
//*********************************************************************
//LDDSTS   EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(0,NE)
//STEPLIB  DD DISP=SHR,DSN=OEM.DB2.&DB2S..RUNLIB.LOAD
//         DD DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//SYSTSPRT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD DISP=SHR,DSN=&LBNM..CNTL(DB2DTEP)
//SYSIN    DD DISP=SHR,DSN=&LBNM..CNTL(DB2DSTS)
//*********************************************************************
//****  STEP 30 : Load sample disputes and history               *****
//****            using DSNTEP4 utility                          *****
//*********************************************************************
//LDDSMP   EXEC PGM=IKJEFT01,DYNAMNBR=20,COND=(0,NE)
//STEPLIB  DD  DISP=SHR,DSN=OEM.DB2.&DB2S..RUNLIB.LOAD
//         DD  DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//SYSTSPRT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSTSIN  DD DISP=SHR,DSN=&LBNM..CNTL(DB2DTEP)
//SYSIN    DD DISP=SHR,DSN=&LBNM..CNTL(DB2DSMP)
