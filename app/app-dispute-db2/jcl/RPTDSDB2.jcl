//RPTDSDB2 JOB (COBOL),'RPTDSDB2',CLASS=A,MSGCLASS=H,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,TIME=1440
//*******************************************************************//
//*                                                                 *//
//* USE THIS JOB TO PRODUCE THE DISPUTE AGING REPORT FROM THE DB2   *//
//* DISPUTE / DISPUTE_STATUS TABLES.                                *//
//*                                                                 *//
//* THE REPORT LISTS EVERY OPEN DISPUTE WITH ITS AGE IN DAYS,       *//
//* FLAGS ROWS AGED OVER 60 DAYS AS ESCALATION CANDIDATES, AND      *//
//* PRINTS AGING BUCKET TOTALS AND A PER-STATUS SUMMARY.            *//
//*                                                                 *//
//* REPORT - THE 132-COLUMN PRINT REPORT (SYSOUT).                  *//
//*                                                                 *//
//*******************************************************************//
//         SET HLQ=AWS.M2.CARDDEMO
//         SET DB2S=DAZ1
//STEP1   EXEC PGM=IKJEFT01,REGION=0M
//STEPLIB  DD DISP=SHR,DSN=OEM.DB2.DAZ1.SDSNEXIT
//         DD DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//         DD DISP=SHR,DSN=&HLQ..LOADLIB
//DBRMLIB  DD DISP=SHR,DSN=&HLQ..DBRMLIB
//SYSTSPRT DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//REPORT   DD  SYSOUT=*
//SYSTSIN DD *
     DSN SYSTEM(DAZ1)
          RUN PROGRAM(CBDISRPT) PLAN(CARDDEMO)
