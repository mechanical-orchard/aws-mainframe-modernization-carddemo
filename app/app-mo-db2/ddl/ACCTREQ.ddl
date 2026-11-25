CREATE TABLE CARDDEMO.ACCT_REQUEST
(   REQ_ID                         CHAR(12) NOT NULL,
    REQ_ACTION                     CHAR(1) NOT NULL,
    REQ_ACCT_ID                    DECIMAL(11,0) NOT NULL,
    REQ_BAL_DATE                   DATE NOT NULL,
    REQ_CARD_NUM                   CHAR(16),
    REQ_AMT                        DECIMAL(11,2),
    REQ_DESC                       VARCHAR(100),
    REQ_STATUS                     CHAR(1) NOT NULL WITH DEFAULT 'P',
    REQ_REASON                     CHAR(8),
    REQ_TRAN_ID                    CHAR(16),
    PRIMARY KEY(REQ_ID));
