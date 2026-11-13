# Transaction History and Daily Balances with DB2 - CardDemo Extension

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)

## Overview

The Transaction History module is an optional extension for the CardDemo application that demonstrates DB2 integration patterns in batch COBOL programs using embedded static SQL. This module loads posted transactions from the VSAM-based transaction processing system into DB2 tables, builds daily account balances from them, and reports on and maintains that history, working alongside the existing VSAM files without changing them.

## Table of Contents
- [Features](#features)
- [Components](#components)
- [Installation](#installation)
- [Usage](#usage)
- [Technical Details](#technical-details)
- [Integration with Base Application](#integration-with-base-application)
- [Dependencies](#dependencies)

## Features

This extension provides the following capabilities:

- **Transaction History**: Load posted transactions from the VSAM transaction file into a DB2 table through a batch job
- **Daily Balances**: Build daily account balance snapshots and flag accounts that are over their credit limit
- **Reporting**: Produce a transaction history report from DB2, with each account's closing balance and credit limit
- **Batch Maintenance**: Purge transaction history older than a retention period
- **DB2 Integration**: Demonstrates various DB2 integration patterns in batch, including:
  - Static embedded SQL with host variables and null indicators
  - Cursor processing across commits and positioned updates
  - Aggregation (GROUP BY, SUM, COUNT, MAX) and outer joins
  - Insert, update and delete operations, including insert-or-update on duplicate keys
  - DB2 precompiler integration in a batch (TSO attach) environment
  - Proper error handling with SQLCA and DSNTIAR

## Components

### Batch Components

| Job      | Program  | Function                                                     |
|:---------|:---------|:-------------------------------------------------------------|
| MODBCRT  | DSNTIAD  | Creates the DB2 tables for transaction history               |
| MODBDRP  | DSNTIAD  | Drops the DB2 tables to reset the extension                  |
| MODBLOAD | CBMOD01C | Loads posted transactions from VSAM into DB2                 |
| MODBBAL  | CBMOD02C | Builds daily account balances from transaction history       |
| MODBRPT  | CBMOD03C | Produces the transaction history report                      |
| MODBMNT  | CBMOD04C | Flags over-limit accounts and purges old transaction history |
| MODBUNL  | DSNUTILB | Unloads both DB2 tables to delimited files                   |

### Directory Structure

- **cbl/**: COBOL programs for transaction history processing
- **cpy/**: Copybooks for data structures
- **dcl/**: DB2 declarations
- **ddl/**: DB2 table definitions
- **jcl/**: JCL for batch operations
- **ctl/**: Control files for DB2 operations

## Installation

### Prerequisites
- Base CardDemo application installed and operational
- DB2 subsystem configured and accessible
- A user ID with CREATETS and CREATETAB (or DBADM) on database `CARDMODB` and CREATEIN on schema `CARDDEMO`. If the `CARDMODB` database does not exist yet, MODBCRT creates it, which also needs CREATEDBA (or SYSADM)

### Installation Steps

1. **Create DB2 Objects**
   - Execute the MODBCRT job to create the DB2 tables in the `CARDMODB` database. It creates the database first, with storage group `SYSDEFLT`, if it does not exist yet
   - Each table has its own tablespace (`MOTHST01`, `MOADBL01`) that uses the default storage group of the database, and MODBDRP drops only those two tablespaces

2. **Compile Programs**
   - Compile the COBOL programs with DB2 precompiler support
   - The sample JCL `samples/jcl/BATDBCMP.jcl` and procedure `samples/proc/BLDBTDB2.prc` precompile, compile, link-edit and bind each program into package collection and plan `CARDMODB`

3. **Set Job Parameters**
   - Review the `SET` statements at the top of each job: high-level qualifier, DB2 subsystem, DB2 libraries and plan names. The jobs pass these to their in-stream DB2 commands, which needs z/OS 2.1 or later

4. **Load Initial Data**
   - Run the base daily batch through COMBTRAN, then execute the MODBLOAD job to load the posted transactions into DB2

## Usage

### Batch Transaction History Processing

Run the jobs after the base daily batch has rebuilt the transaction file (COMBTRAN), in this order:

1. Execute the MODBLOAD job to load posted transactions into DB2
   - Transactions that are already loaded are skipped, so the job can be rerun
   - Rejected transactions are written to `MODB.LOADREJS` with a reason code
2. Execute the MODBBAL job to build daily account balances for the date in its PARMFILE
   - Rerunning it for the same date replaces that date's balances
3. Execute the MODBRPT job to produce the transaction history report for the date range in its PARMFILE
   - The report is written to `MODB.TRANRPT`
   - Each account shows its closing balance and credit limit from the MODBBAL run for the last date of the range, or says it has no daily balance
4. Execute the MODBMNT job to flag accounts over their credit limit and purge transaction history older than the retention days in its PARMFILE

TRANBKP empties the transaction file until COMBTRAN reloads it, so MODBLOAD finds no transactions if it runs between those two jobs. As with the base batch jobs, the VSAM files must be closed in CICS (CLOSEFIL). The header of each job describes its parameters and return codes. To start over, run MODBDRP and then MODBCRT.

### Unloading the Tables

The MODBUNL job unloads both tables to delimited files without changing them. Set `LBL` before each run. Each table gets a header dataset holding its column names and a data dataset with one record per row:

- `MODB.UNL.<LBL>.TRANHIST.HDR` and `MODB.UNL.<LBL>.TRANHIST.DATA`
- `MODB.UNL.<LBL>.ACCTDBAL.HDR` and `MODB.UNL.<LBL>.ACCTDBAL.DATA`

The data is in DB2's delimited format, in EBCDIC: fields separated by commas, strings in double quotes, and NULL as an empty field. Downloading a table's header dataset and then its data dataset in text mode gives a CSV file with a header line.

To keep the contents of the tables at each step of a cycle, run MODBUNL before MODBLOAD and after each of the other jobs, with a new label each time (for example `U1` to `U5`). A rerun with the same label replaces that label's datasets. The submitting user needs SELECT, or the UNLOAD privilege, on both tables.

## Technical Details

### DB2 Tables

The extension uses the following DB2 tables:

- **CARDDEMO.TRAN_HIST**: Stores posted transaction history
  - TH_TRAN_ID (CHAR(16)): Transaction ID (Primary Key)
  - TH_ACCT_ID (DECIMAL(11,0)): Account ID from the card cross reference
  - TH_CARD_NUM (CHAR(16)): Card number
  - TH_TYPE_CD (CHAR(2)): Transaction type code
  - TH_CAT_CD (CHAR(4)): Transaction category code
  - TH_SOURCE (CHAR(10)): Transaction source
  - TH_DESC (VARCHAR(100)): Transaction description, without trailing spaces or low-values
  - TH_AMT (DECIMAL(11,2)): Transaction amount
  - TH_MERCHANT_ID (DECIMAL(9,0)): Merchant ID, NULL when there is no merchant
  - TH_MERCHANT_NAME (VARCHAR(50)): Merchant name, NULL when blank
  - TH_MERCHANT_CITY (VARCHAR(50)): Merchant city, NULL when blank
  - TH_MERCHANT_ZIP (CHAR(10)): Merchant zip code, NULL when blank
  - TH_TRAN_DATE (DATE): Transaction date, from the original timestamp
  - TH_ORIG_TS (TIMESTAMP): Original timestamp
  - TH_PROC_TS (TIMESTAMP): Processing timestamp, NULL when blank

- **CARDDEMO.ACCT_DAILY_BAL**: Stores daily account balance snapshots
  - ADB_ACCT_ID (DECIMAL(11,0)): Account ID (Primary Key)
  - ADB_BAL_DATE (DATE): Balance date (Primary Key)
  - ADB_OPEN_BAL (DECIMAL(12,2)): Opening balance: the closing balance of the account's previous snapshot, or for its first snapshot the ACCTDATA balance less the transactions dated on or after the balance date
  - ADB_CREDIT_AMT (DECIMAL(12,2)): Total of the day's amounts that are zero or more
  - ADB_DEBIT_AMT (DECIMAL(12,2)): Total of the day's negative amounts
  - ADB_CLOSE_BAL (DECIMAL(12,2)): Closing balance
  - ADB_TRAN_CNT (INTEGER): Number of transactions
  - ADB_CREDIT_LIMIT (DECIMAL(12,2)): Credit limit from ACCTDATA
  - ADB_OVERLIMIT_FLG (CHAR(1)): Y when the closing balance is above the credit limit
  - ADB_FLAG_DATE (DATE): Date the account was flagged, NULL when not flagged

### Integration Patterns

This extension demonstrates several DB2 integration patterns:

1. **Static Embedded SQL**: All programs use static SQL statements embedded in COBOL code, with host variables declared in the program or in DCLGEN members
2. **Cursor Processing**: The MODBBAL and MODBRPT jobs read DB2 data through cursors, and the MODBMNT job updates rows through a FOR UPDATE cursor (WHERE CURRENT OF)
3. **Commit Processing**: Programs that change data commit every 100 changes, with cursors declared WITH HOLD so they stay open across commits
4. **Null Indicators**: Optional merchant and timestamp columns, aggregate results and outer-join columns use null indicator variables
5. **DB2 Precompiler Integration**: Programs are precompiled with DSNHPC, link-edited with DSNELI and run under the TSO attach (IKJEFT01 and DSN RUN)
6. **Error Handling**: Each SQL statement checks SQLCODE. Unexpected errors are reported with DSNTIAR, rolled back and abended
7. **Deterministic Processing**: Business dates come from the PARMFILE instead of the system clock, and every cursor whose rows are written out has an ORDER BY, so a rerun with the same input gives the same output

## Integration with Base Application

This module integrates with the base CardDemo application in the following ways:

1. **Transaction Data**: The MODBLOAD job reads the base transaction file (TRANSACT) after COMBTRAN, with the card cross reference (CARDXREF) for account numbers
2. **Account Data**: The MODBBAL job reads balances and credit limits from the base account file (ACCTDATA)
3. **Reference Data**: The MODBRPT job looks up transaction type and category names in the base transaction type and category files (TRANTYPE and TRANCATG)
4. **Read-Only Integration**: The module reads the base VSAM files but does not change any base program or file
5. **Separate DB2 Objects**: Its own DB2 database, package collection and plan (all `CARDMODB`), so creating, dropping or rebinding it does not affect the other DB2 extensions

## Dependencies

- Base CardDemo application
- DB2 subsystem
