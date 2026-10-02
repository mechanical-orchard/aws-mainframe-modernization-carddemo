//MNTDSDB2 JOB (COBOL),'MNTDSDB2',CLASS=A,MSGCLASS=H,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID,TIME=1440
//*******************************************************************//
//*                                                                 *//
//* USE THIS JOB TO MAINTAIN THE DB2 DISPUTE TABLE IN BATCH,        *//
//* UPDATING DISPUTE STATUS OR REMOVING DISPUTES FROM A FILE.       *//
//*                                                                 *//
//* INPFILE - THE INPUT FILE TO USE FOR MAINTENANCE. THE ALLOWED    *//
//*           VALUES ARE:                                           *//
//*                                                                 *//
//* COLUMN 1      - U - UPDATE STATUS                               *//
//*                 D - DELETE DISPUTE                              *//
//*                 * - COMMENT                                     *//
//*                                                                 *//
//* COLUMNS 2-13  - DISPUTE ID. 12 CHARACTERS                       *//
//*                                                                 *//
//* COLUMNS 14-15 - NEW STATUS CODE (USED FOR 'U' ONLY)             *//
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
//INPFILE  DD  DSN=&HLQ..DISPUTE.MAINT,DISP=SHR
//SYSTSIN DD *
     DSN SYSTEM(DAZ1)
          RUN PROGRAM(COBDSUPD) PLAN(CARDDEMO)
