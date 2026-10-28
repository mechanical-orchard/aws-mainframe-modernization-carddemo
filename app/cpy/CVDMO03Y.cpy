      *****************************************************************
      *    Data-structure for DEMO CDC daily-input PS (FB LRECL 80)    *
      *    Consumed by CBDMO02C as the fixed deterministic input.      *
      *    Layout: 1 + 11 + 50 + 10 + 8 = 80.                          *
      *    DIN-AMOUNT is SIGN LEADING SEPARATE so the file stays       *
      *    portable display text and can be diffed byte-for-byte.      *
      *****************************************************************
       01  DEMO-DALYIN-RECORD.
           05  DIN-ACTION                    PIC X(01).
               88  DIN-POST                  VALUE 'P'.
               88  DIN-CHARGE                VALUE 'C'.
               88  DIN-OPEN                  VALUE 'N'.
               88  DIN-CLOSE                 VALUE 'X'.
           05  DIN-ACCT-ID                   PIC 9(11).
           05  DIN-DESCR                     PIC X(50).
           05  DIN-AMOUNT                    PIC S9(7)V99
                                              SIGN IS LEADING SEPARATE.
           05  FILLER                        PIC X(08).
