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
-- LIST THE APP-MO-DB2 OBJECTS FROM THE DB2 CATALOG.
-- RUN THROUGH DSNTEP4 BY JOB MODBCRT AFTER THE CREATE STEP.
-- ------------------------------------------------------------------
-- TABLES AND INDEXES IN THE CARDMODB DATABASE.
-- EXPECT TABLES TRAN_HIST AND ACCT_DAILY_BAL, AND INDEXES
-- XTRANH01, XTRANH02 AND XACDBL01.
-- ------------------------------------------------------------------
  SELECT CREATOR, NAME, TSNAME, COLCOUNT
    FROM SYSIBM.SYSTABLES
   WHERE DBNAME = 'CARDMODB'
     AND TYPE = 'T'
   ORDER BY NAME;

  SELECT CREATOR, NAME, TBNAME, UNIQUERULE
    FROM SYSIBM.SYSINDEXES
   WHERE DBNAME = 'CARDMODB'
   ORDER BY NAME;

