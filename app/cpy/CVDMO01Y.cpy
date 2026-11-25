      *****************************************************************
      *    Data-structure for DEMO CDC account (VSAM KSDS, RECLN 100)   *
      *    Key = DEMO-ACCT-ID (11 bytes zoned, offset 0, KEYS(11 0))    *
      *****************************************************************
       01  DEMO-ACCT-RECORD.
           05  DEMO-ACCT-ID                  PIC 9(11).
           05  DEMO-ACCT-DESCR               PIC X(50).
           05  DEMO-ACCT-AMOUNT              PIC S9(7)V99 USAGE COMP-3.
           05  DEMO-ACCT-STATUS              PIC X(01).
               88  DEMO-ACCT-OPEN            VALUE 'O'.
               88  DEMO-ACCT-CLOSED          VALUE 'C'.
           05  FILLER                        PIC X(33).
