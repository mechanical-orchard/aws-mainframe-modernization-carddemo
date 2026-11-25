  SET CURRENT SQLID = 'SYSADM';

/* ---------------------------------------------------------------- */
/* Dispute status reference table                                   */
/* ---------------------------------------------------------------- */
      CREATE TABLESPACE DISPSPC1
        IN CARDDEMO
        USING STOGROUP AWST1STG
        SEGSIZE 4
        LOCKSIZE TABLE
        BUFFERPOOL BP0
        CLOSE NO
        CCSID EBCDIC;

      COMMIT ;

      GRANT USE OF TABLESPACE CARDDEMO.DISPSPC1
            TO PUBLIC;

      CREATE TABLE CARDDEMO.DISPUTE_STATUS
       (DST_STATUS_CD     CHAR(2)        NOT NULL,
        DST_STATUS_DESC   VARCHAR(30)    NOT NULL,
        DST_OPEN_FLAG     CHAR(1)        NOT NULL,
        PRIMARY KEY(DST_STATUS_CD))
        IN CARDDEMO.DISPSPC1
        CCSID EBCDIC;

      COMMIT ;

      CREATE UNIQUE INDEX CARDDEMO.XDISPUTE_STATUS
                    ON CARDDEMO.DISPUTE_STATUS
                        (DST_STATUS_CD   ASC)
                    USING STOGROUP AWST1STG
                    ERASE NO
                    BUFFERPOOL BP0
                    CLOSE NO;

      COMMIT ;

      GRANT DELETE, INSERT, SELECT, UPDATE
            ON TABLE CARDDEMO.DISPUTE_STATUS
            TO PUBLIC;

/* ---------------------------------------------------------------- */
/* Dispute case table                                               */
/* ---------------------------------------------------------------- */
      CREATE TABLESPACE DISPSPC2
        IN CARDDEMO
        USING STOGROUP AWST1STG
        SEGSIZE 4
        LOCKSIZE TABLE
        BUFFERPOOL BP0
        CLOSE NO
        CCSID EBCDIC;

      COMMIT ;

      GRANT USE OF TABLESPACE CARDDEMO.DISPSPC2
            TO PUBLIC;

      CREATE TABLE CARDDEMO.DISPUTE
       (DISP_ID           CHAR(12)       NOT NULL,
        DISP_TRAN_ID      CHAR(16)       NOT NULL,
        DISP_CARD_NUM     CHAR(16)       NOT NULL,
        DISP_AMT          DECIMAL(11, 2) NOT NULL,
        DISP_REASON_CD    CHAR(4)        NOT NULL,
        DISP_STATUS_CD    CHAR(2)        NOT NULL,
        DISP_OPEN_TS      TIMESTAMP      NOT NULL,
        DISP_LAST_UPD_TS  TIMESTAMP      NOT NULL,
        DISP_DESC         VARCHAR(100)   NOT NULL,
        PRIMARY KEY(DISP_ID))
        IN CARDDEMO.DISPSPC2
        CCSID EBCDIC;

      COMMIT ;

      CREATE UNIQUE INDEX CARDDEMO.XDISPUTE
                    ON CARDDEMO.DISPUTE
                        (DISP_ID   ASC)
                    USING STOGROUP AWST1STG
                    ERASE NO
                    BUFFERPOOL BP0
                    CLOSE NO;

      COMMIT ;

      GRANT DELETE, INSERT, SELECT, UPDATE
            ON TABLE CARDDEMO.DISPUTE
            TO PUBLIC;

/* ---------------------------------------------------------------- */
/* Dispute status-change history table                              */
/* ---------------------------------------------------------------- */
      CREATE TABLESPACE DISPSPC3
        IN CARDDEMO
        USING STOGROUP AWST1STG
        SEGSIZE 4
        LOCKSIZE TABLE
        BUFFERPOOL BP0
        CLOSE NO
        CCSID EBCDIC;

      COMMIT ;

      GRANT USE OF TABLESPACE CARDDEMO.DISPSPC3
            TO PUBLIC;

      CREATE TABLE CARDDEMO.DISPUTE_HISTORY
       (DSH_DISP_ID       CHAR(12)       NOT NULL,
        DSH_SEQ           SMALLINT       NOT NULL,
        DSH_FROM_STATUS   CHAR(2)        NOT NULL,
        DSH_TO_STATUS     CHAR(2)        NOT NULL,
        DSH_CHG_TS        TIMESTAMP      NOT NULL,
        DSH_CHG_USER      CHAR(8)        NOT NULL,
        DSH_NOTE          VARCHAR(100)   NOT NULL,
        PRIMARY KEY(DSH_DISP_ID, DSH_SEQ))
        IN CARDDEMO.DISPSPC3
        CCSID EBCDIC;

      COMMIT ;

      CREATE UNIQUE INDEX CARDDEMO.XDISPUTE_HISTORY
                    ON CARDDEMO.DISPUTE_HISTORY
                        (DSH_DISP_ID   ASC,
                         DSH_SEQ       ASC)
                    USING STOGROUP AWST1STG
                    ERASE NO
                    BUFFERPOOL BP0
                    CLOSE NO;

      COMMIT ;

      GRANT DELETE, INSERT, SELECT, UPDATE
            ON TABLE CARDDEMO.DISPUTE_HISTORY
            TO PUBLIC;

/* ---------------------------------------------------------------- */
/* Referential integrity                                            */
/* ---------------------------------------------------------------- */
      ALTER TABLE CARDDEMO.DISPUTE
        FOREIGN KEY DISP_STATUS_FK (DISP_STATUS_CD)
          REFERENCES CARDDEMO.DISPUTE_STATUS (DST_STATUS_CD)
      ON DELETE RESTRICT;

      COMMIT ;

      ALTER TABLE CARDDEMO.DISPUTE_HISTORY
        FOREIGN KEY DSH_DISP_FK (DSH_DISP_ID)
          REFERENCES CARDDEMO.DISPUTE (DISP_ID)
      ON DELETE CASCADE;

      COMMIT ;
