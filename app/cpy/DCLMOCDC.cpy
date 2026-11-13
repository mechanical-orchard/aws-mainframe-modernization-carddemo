      ******************************************************************
      * DCLGEN-STYLE DECLARATION FOR EXISTING TABLE MODATA1.MOCDC       *
      *   THIS COPYBOOK IS DECLARE-ONLY. NO DDL IS ISSUED.              *
      *   PHYSICAL TYPES ARE ASSUMED (see docs/DEMO-JOBS-SPEC.md 4.3):  *
      *      ID      INTEGER      NOT NULL                              *
      *      DESCR   VARCHAR(50)  NOT NULL                              *
      *      AMOUNT  DECIMAL(9,2) NOT NULL                              *
      ******************************************************************
           EXEC SQL DECLARE MODATA1.MOCDC TABLE
           ( ID                            INTEGER      NOT NULL,
             DESCR                         VARCHAR(50)  NOT NULL,
             AMOUNT                        DECIMAL(9,2) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE MODATA1.MOCDC                       *
      ******************************************************************
       01  DCLMOCDC.
           10 DCL-MOCDC-ID          PIC S9(9)   USAGE COMP.
           10 DCL-MOCDC-DESCR.
              49 DCL-MOCDC-DESCR-LEN
                                    PIC S9(4)   USAGE COMP.
              49 DCL-MOCDC-DESCR-TEXT
                                    PIC X(50).
           10 DCL-MOCDC-AMOUNT      PIC S9(7)V99 USAGE COMP-3.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 3        *
      ******************************************************************
