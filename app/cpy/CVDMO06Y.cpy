      *****************************************************************
      *    Data-structure for DEMO CDC control-totals PS               *
      *    (FB LRECL 80).                                              *
      *    Six records emitted in fixed order by CBDMO02C:             *
      *       INPUT-READ, POSTED-OK, POSTED-REJECT, OPENED, CLOSED,    *
      *       UNCHANGED.                                               *
      *    Layout: 30 + 15 + 35 = 80.                                  *
      *****************************************************************
       01  DEMO-CONTROLS-RECORD.
           05  CTL-LABEL                     PIC X(30).
           05  CTL-VALUE                     PIC 9(15).
           05  FILLER                        PIC X(35).
