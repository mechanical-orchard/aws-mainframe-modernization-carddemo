-- ------------------------------------------------------------------
-- Copyright (c) 2026 Mechanical Orchard, Inc.
-- All Rights Reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License").
-- You may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
-- either express or implied. See the License for the specific
-- language governing permissions and limitations under the License.
-- ------------------------------------------------------------------
-- CREATE THE APP-MO-DB2 TABLES IN THE CARDDEMO DATABASE.
-- RUN THROUGH DSNTIAD BY JOB MODBCRT.
--
-- THE CARDDEMO DATABASE AND STORAGE GROUP AWST1STG MUST ALREADY
-- EXIST: RUN JOB CREADB21 OF APP-TRANSACTION-TYPE-DB2 FIRST. EACH
-- TABLE GETS ITS OWN TABLE SPACE, SO JOB MODBDRP CAN DROP THEM
-- WITHOUT TOUCHING THE APP-TRANSACTION-TYPE-DB2 TABLES.
-- ------------------------------------------------------------------
  SET CURRENT SQLID = 'SYSADM';

-- ------------------------------------------------------------------
-- CARDDEMO.TRAN_HIST - POSTED TRANSACTION HISTORY
-- ------------------------------------------------------------------
  CREATE TABLESPACE MOTHST01
    IN CARDDEMO
    USING STOGROUP AWST1STG
    SEGSIZE 4
    LOCKSIZE TABLE
    BUFFERPOOL BP0
    CLOSE NO
    CCSID EBCDIC;

  COMMIT;

  GRANT USE OF TABLESPACE CARDDEMO.MOTHST01
        TO PUBLIC;

  CREATE TABLE CARDDEMO.TRAN_HIST
       (TH_TRAN_ID          CHAR(16)       NOT NULL,
        TH_ACCT_ID          DECIMAL(11,0)  NOT NULL,
        TH_CARD_NUM         CHAR(16)       NOT NULL,
        TH_TYPE_CD          CHAR(2)        NOT NULL,
        TH_CAT_CD           CHAR(4)        NOT NULL,
        TH_SOURCE           CHAR(10)       NOT NULL,
        TH_DESC             VARCHAR(100)   NOT NULL,
        TH_AMT              DECIMAL(11,2)  NOT NULL,
        TH_MERCHANT_ID      DECIMAL(9,0),
        TH_MERCHANT_NAME    VARCHAR(50),
        TH_MERCHANT_CITY    VARCHAR(50),
        TH_MERCHANT_ZIP     CHAR(10),
        TH_TRAN_DATE        DATE           NOT NULL,
        TH_ORIG_TS          TIMESTAMP      NOT NULL,
        TH_PROC_TS          TIMESTAMP,
        PRIMARY KEY(TH_TRAN_ID))
     IN CARDDEMO.MOTHST01
     CCSID EBCDIC;

  COMMIT;

  CREATE UNIQUE INDEX CARDDEMO.XTRANH01
     ON CARDDEMO.TRAN_HIST
       (TH_TRAN_ID      ASC)
     USING STOGROUP AWST1STG
     ERASE NO
     BUFFERPOOL BP0
     CLOSE NO;

  CREATE INDEX CARDDEMO.XTRANH02
     ON CARDDEMO.TRAN_HIST
       (TH_TRAN_DATE    ASC,
        TH_ACCT_ID      ASC)
     USING STOGROUP AWST1STG
     ERASE NO
     BUFFERPOOL BP0
     CLOSE NO;

  COMMIT;

  GRANT DELETE, INSERT, SELECT, UPDATE
        ON TABLE CARDDEMO.TRAN_HIST
        TO PUBLIC;

-- ------------------------------------------------------------------
-- CARDDEMO.ACCT_DAILY_BAL - ACCOUNT DAILY BALANCE SNAPSHOTS
-- ------------------------------------------------------------------
  CREATE TABLESPACE MOADBL01
    IN CARDDEMO
    USING STOGROUP AWST1STG
    SEGSIZE 4
    LOCKSIZE TABLE
    BUFFERPOOL BP0
    CLOSE NO
    CCSID EBCDIC;

  COMMIT;

  GRANT USE OF TABLESPACE CARDDEMO.MOADBL01
        TO PUBLIC;

  CREATE TABLE CARDDEMO.ACCT_DAILY_BAL
       (ADB_ACCT_ID         DECIMAL(11,0)  NOT NULL,
        ADB_BAL_DATE        DATE           NOT NULL,
        ADB_OPEN_BAL        DECIMAL(12,2)  NOT NULL,
        ADB_CREDIT_AMT      DECIMAL(12,2)  NOT NULL,
        ADB_DEBIT_AMT       DECIMAL(12,2)  NOT NULL,
        ADB_CLOSE_BAL       DECIMAL(12,2)  NOT NULL,
        ADB_TRAN_CNT        INTEGER        NOT NULL,
        ADB_CREDIT_LIMIT    DECIMAL(12,2)  NOT NULL,
        ADB_OVERLIMIT_FLG   CHAR(1)        NOT NULL WITH DEFAULT 'N',
        ADB_FLAG_DATE       DATE,
        PRIMARY KEY(ADB_ACCT_ID, ADB_BAL_DATE))
     IN CARDDEMO.MOADBL01
     CCSID EBCDIC;

  COMMIT;

  CREATE UNIQUE INDEX CARDDEMO.XACDBL01
     ON CARDDEMO.ACCT_DAILY_BAL
       (ADB_ACCT_ID     ASC,
        ADB_BAL_DATE    ASC)
     USING STOGROUP AWST1STG
     ERASE NO
     BUFFERPOOL BP0
     CLOSE NO;

  COMMIT;

  GRANT DELETE, INSERT, SELECT, UPDATE
        ON TABLE CARDDEMO.ACCT_DAILY_BAL
        TO PUBLIC;

  COMMIT;
