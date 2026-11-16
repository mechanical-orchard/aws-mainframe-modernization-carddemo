      *****************************************************************
      *    Data-structure for DEMO CDC trial-balance report line       *
      *    (FBA LRECL 133).                                            *
      *    TB-CC is the ANSI carriage-control byte:                    *
      *       '1' on header, ' ' on detail, '-' on total.              *
      *    Layout: 1 + 11 + 2 + 50 + 2 + 11 + 2 + 1 + 53 = 133.        *
      *    TB-AMOUNT-DISPLAY PIC -Z(6)9.99 = 11 print positions        *
      *    ("-ZZZZZZ9.99").                                            *
      *****************************************************************
       01  DEMO-TRIAL-BAL-LINE.
           05  TB-CC                         PIC X(01).
           05  TB-DETAIL.
              10  TB-ACCT-ID                 PIC 9(11).
              10  FILLER                     PIC X(02).
              10  TB-DESCR                   PIC X(50).
              10  FILLER                     PIC X(02).
              10  TB-AMOUNT-DISPLAY          PIC -Z(6)9.99.
              10  FILLER                     PIC X(02).
              10  TB-STATUS                  PIC X(01).
              10  FILLER                     PIC X(53).
