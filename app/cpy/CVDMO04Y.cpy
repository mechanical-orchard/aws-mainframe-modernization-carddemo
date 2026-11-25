      *****************************************************************
      *    Data-structure for DEMO CDC posted-output PS (FB LRECL 80)  *
      *    One record per daily-input record processed by CBDMO02C,    *
      *    written in daily-input order regardless of outcome.         *
      *    Layout: 1 + 11 + 50 + 10 + 2 + 6 = 80.                      *
      *****************************************************************
       01  DEMO-POSTED-RECORD.
           05  POST-ACTION                   PIC X(01).
           05  POST-ACCT-ID                  PIC 9(11).
           05  POST-DESCR                    PIC X(50).
           05  POST-AMOUNT                   PIC S9(7)V99
                                              SIGN IS LEADING SEPARATE.
           05  POST-RESULT-CODE              PIC X(02).
               88  POST-OK                   VALUE 'OK'.
               88  POST-REJECT               VALUE 'RJ'.
           05  FILLER                        PIC X(06).
