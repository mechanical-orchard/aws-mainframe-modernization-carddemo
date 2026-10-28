      *****************************************************************
      *    Data-structure for DEMO CDC seed account PS (FB LRECL 100)  *
      *    Identical layout to CVDMO01Y (VSAM KSDS record); the seed   *
      *    PS is loaded 1:1 into the KSDS by CBDMO01C.                 *
      *****************************************************************
       01  DEMO-SEEDACCT-RECORD.
           05  SEED-ACCT-ID                  PIC 9(11).
           05  SEED-ACCT-DESCR               PIC X(50).
           05  SEED-ACCT-AMOUNT              PIC S9(7)V99 USAGE COMP-3.
           05  SEED-ACCT-STATUS              PIC X(01).
           05  FILLER                        PIC X(33).
