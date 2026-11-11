# Transaction History and Daily Balances with DB2 - CardDemo Extension

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)

## Overview

The Transaction History extension is an optional, batch-only module for the CardDemo application. It copies posted transactions from the base VSAM files into DB2, builds daily account balance snapshots from them, prints a transaction history report, and runs daily maintenance over the DB2 tables.

The module runs after the base daily batch and reads the same VSAM files, so it works on the same CardDemo data as the base application. It does not change any base program or write back to any base file.

Every job is deterministic: business dates come from a parameter record instead of the system clock, and every job can be rerun. Running a job twice with the same input and starting data gives the same output.

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

- **Transaction History Load**: Load posted transactions from the TRANSACT VSAM file into a DB2 table, with account numbers from the card cross reference
- **Daily Balances**: Build one balance snapshot per account per day from the loaded transactions
- **Transaction History Report**: Print transactions for a date range with type and category descriptions, subtotals and totals
- **Daily Maintenance**: Flag accounts over their credit limit and purge history past a retention period
- **DB2 Batch Patterns**: Demonstrates DB2 patterns common in batch COBOL programs, including:
  - Static embedded SQL under the TSO attach (`IKJEFT01` / `DSN RUN`)
  - Mixed VSAM and DB2 processing in one program
  - Cursors held across commits (`WITH HOLD`) and commit checkpoints
  - Null indicators and `VARCHAR` host variables
  - Aggregation (`GROUP BY`, `SUM`, `COUNT`, `MAX`) and outer joins
  - Insert-or-update on duplicate key (`SQLCODE -803`)
  - Positioned update (`WHERE CURRENT OF`) and searched delete
  - DB2 date arithmetic
  - Error reporting with `DSNTIAR`

## Components

### Batch Components

| Job      | Program            | Function |
|:---------|:-------------------|:---------|
| MODBCRT  | DSNTIAD / DSNTEP4  | Creates the `CARDMODB` database, tables and indexes, then lists them from the DB2 catalog |
| MODBDRP  | DSNTIAD            | Drops the `CARDMODB` database to reset the extension |
| MODBLOAD | CBMOD01C           | Loads the TRANSACT VSAM file into `CARDDEMO.TRAN_HIST` |
| MODBBAL  | CBMOD02C           | Builds `CARDDEMO.ACCT_DAILY_BAL` for a balance date |
| MODBRPT  | CBMOD03C           | Prints the transaction history report for a date range |
| MODBMNT  | CBMOD04C           | Flags over-limit accounts and purges old transaction history |

### Build Components

| Member                       | Function |
|:-----------------------------|:---------|
| `samples/proc/BLDBTDB2.prc`  | Batch COBOL DB2 build: precompile, compile, link-edit with `DSNELI`, bind package and plan |
| `samples/jcl/BATDBCMP.jcl`   | Runs `BLDBTDB2` for one program |

### Directory Structure

- **cbl/**: Batch COBOL DB2 programs
- **cpy/**: Copybooks for the parameter, reject and report records, and common error handling
- **ctl/**: SQL input for the DB2 utilities (create, drop, catalog listing)
- **dcl/**: DB2 declarations (DCLGEN)
- **ddl/**: DB2 table and index definitions
- **jcl/**: JCL for the batch jobs

## Installation

### Prerequisites
- Base CardDemo application installed, with its VSAM files loaded
- DB2 subsystem configured and accessible from batch
- The Transaction Type Management extension (`app-transaction-type-db2`) tables, created by job `CREADB21`. Only the report job `MODBRPT` uses them
- z/OS 2.1 or later (the JCL uses `SYMBOLS=JCLONLY` in-stream data) and DB2 10 or later (partition-by-growth table spaces)

### Installation Steps

1. **Upload the Source**
   - `cbl/` to `CARDDEMO.CBL`, `cpy/` to `CARDDEMO.CPY`, `dcl/` to `CARDDEMO.DCL`, `ctl/` to `CARDDEMO.CNTL` and `jcl/` to `CARDDEMO.JCL`
   - `samples/proc/BLDBTDB2.prc` to `CARDDEMO.PROC.UTIL`
   - Create `CARDDEMO.DCL` and `CARDDEMO.DBRMLIB` (FB 80) if they do not exist yet

2. **Set Up for Your Environment**
   - Change the storage group `AWST1STG` in `ctl/MODBCRT.ctl` to one that exists in your DB2 subsystem
   - Review the `SET` statements at the top of each job: `HLQ`, `DB2S` (subsystem id), the DB2 `SDSNEXIT`, `SDSNLOAD` and `RUNLIB.LOAD` libraries, and the utility and application plan names

3. **Create DB2 Objects**
   - Run `MODBCRT`. Step `STEP20` lists the new tables and indexes, and checks that the `app-transaction-type-db2` tables exist

4. **Compile and Bind the Programs**
   - Run `samples/jcl/BATDBCMP.jcl` once for each of `CBMOD01C`, `CBMOD02C`, `CBMOD03C` and `CBMOD04C`, setting `MEMNAME` each time
   - The programs are bound into package collection `CARDMODB` and plan `CARDMODB`

## Usage

### Daily Run Order

Run the jobs after the base daily batch has posted transactions (`POSTTRAN`):

```
MODBLOAD -> MODBBAL -> MODBRPT -> MODBMNT
```

Like the base batch jobs, the jobs that read VSAM files (`MODBLOAD`, `MODBBAL`) need the files closed in CICS (base job `CLOSEFIL`).

### Run Parameters

`MODBBAL`, `MODBRPT` and `MODBMNT` read an 80-byte parameter record from DD `PARMFILE`, in-stream in each job. Columns 1-21 have the same layout as the base `DATEPARM` record.

| Columns | Field        | Used by | Meaning |
|:--------|:-------------|:--------|:--------|
| 1-10    | Start date   | MODBBAL, MODBRPT, MODBMNT | `YYYY-MM-DD`. Balance date, first report date, or as-of date |
| 12-21   | End date     | MODBRPT | `YYYY-MM-DD`. Last report date |
| 23-26   | Retain days  | MODBMNT | 4 digits, for example `0030`. Days of transaction history to keep |

The sample jobs use `2022-06-10`, the date of the CardDemo sample daily transactions.

### Rerunning and Resetting

- `MODBLOAD` skips transactions that are already loaded, so it can be rerun after a failure
- `MODBBAL` replaces the snapshots of its balance date when rerun, and clears their over-limit flags for `MODBMNT` to set again
- `MODBRPT` and `MODBMNT` can be rerun at any time
- To start over, run `MODBDRP` and then `MODBCRT`. `MODBDRP` drops both tables and all of their data

### Outputs

| Job      | DD       | Dataset              | Format | Content |
|:---------|:---------|:---------------------|:-------|:--------|
| MODBLOAD | REJFILE  | `&HLQ..MODB.LOADREJS`| FB 430 | Rejected transactions: the 350-byte TRANSACT record and an 80-byte reason trailer |
| MODBRPT  | REPTFILE | `&HLQ..MODB.TRANRPT` | FB 133 | Transaction history report |

Each job deletes its output dataset from the previous run before writing a new one. Every program writes run totals to `SYSOUT`.

### Return and Abend Codes

| Job      | RC 4 means |
|:---------|:-----------|
| MODBLOAD | Some transactions were rejected (see `REJFILE`) |
| MODBBAL  | An account was not found in ACCTDATA. Its snapshot gets a credit limit of 0 |
| MODBMNT  | The number of rows purged differs from the number counted before the purge |

| Abend | Meaning |
|:------|:--------|
| U0997 | Invalid run parameters |
| U0998 | Unexpected SQLCODE. The program displays the `DSNTIAR` message and rolls back first |
| U0999 | File I/O error |

### Reject Reason Codes (MODBLOAD)

| Code | Reason |
|:-----|:-------|
| 0100 | Card number not found in the card cross reference |
| 0101 | Original timestamp is not a valid timestamp |
| 0102 | Processing timestamp is not a valid timestamp |
| 0103 | DB2 rejected a date or timestamp value (`SQLCODE -180` or `-181`) |

## Technical Details

### DB2 Tables

The extension creates database `CARDMODB` with one table space per table. Tables are qualified with `CARDDEMO`, the same schema as the Transaction Type Management extension.

- **CARDDEMO.TRAN_HIST**: Posted transaction history, one row per transaction
  - TH_TRAN_ID (CHAR(16)): Transaction id (Primary Key)
  - TH_ACCT_ID (DECIMAL(11,0)): Account id, from the card cross reference
  - TH_CARD_NUM (CHAR(16)): Card number
  - TH_TYPE_CD (CHAR(2)): Transaction type code
  - TH_CAT_CD (CHAR(4)): Transaction category code
  - TH_SOURCE (CHAR(10)): Transaction source
  - TH_DESC (VARCHAR(100)): Description
  - TH_AMT (DECIMAL(11,2)): Amount
  - TH_MERCHANT_ID (DECIMAL(9,0), nullable): Merchant id. NULL when zero
  - TH_MERCHANT_NAME (VARCHAR(50), nullable): Merchant name. NULL when blank
  - TH_MERCHANT_CITY (VARCHAR(50), nullable): Merchant city. NULL when blank
  - TH_MERCHANT_ZIP (CHAR(10), nullable): Merchant zip. NULL when blank
  - TH_TRAN_DATE (DATE): Date of the original timestamp
  - TH_ORIG_TS (TIMESTAMP): Original timestamp
  - TH_PROC_TS (TIMESTAMP, nullable): Processing timestamp. NULL when blank
  - Indexes: `XTRANH01` (unique, TH_TRAN_ID) and `XTRANH02` (TH_TRAN_DATE, TH_ACCT_ID)

- **CARDDEMO.ACCT_DAILY_BAL**: Account balance snapshot, one row per account per day with activity
  - ADB_ACCT_ID (DECIMAL(11,0)): Account id (Primary Key)
  - ADB_BAL_DATE (DATE): Balance date (Primary Key)
  - ADB_OPEN_BAL (DECIMAL(12,2)): Opening balance
  - ADB_CREDIT_AMT (DECIMAL(12,2)): Total of the day's amounts that are zero or more
  - ADB_DEBIT_AMT (DECIMAL(12,2)): Total of the day's negative amounts
  - ADB_CLOSE_BAL (DECIMAL(12,2)): Opening balance plus the day's amounts
  - ADB_TRAN_CNT (INTEGER): Number of transactions
  - ADB_CREDIT_LIMIT (DECIMAL(12,2)): Credit limit from ACCTDATA
  - ADB_OVERLIMIT_FLG (CHAR(1)): `Y` when the closing balance is above a non-zero credit limit
  - ADB_FLAG_DATE (DATE, nullable): Date the account was flagged. NULL when not flagged
  - Index: `XACDBL01` (unique, ADB_ACCT_ID, ADB_BAL_DATE)

### Program Logic

- **CBMOD01C (load)**: Reads TRANSACT in key order and looks up each card in CARDXREF. It accepts timestamps in DB2 format and in the `YYYY-MM-DD HH:MM:SS.NNNNNN` form of the daily transaction input, rewriting the second into the first. Commits every 100 inserted rows.
- **CBMOD02C (daily balances)**: A `GROUP BY` cursor totals each account's transactions for the balance date, in account order. The opening balance is the closing balance of the account's latest earlier snapshot. For an account's first snapshot it is the ACCTDATA current balance less the day's net amount, because the base posting job has already added the day's transactions to that balance. Commits every 100 accounts.
- **CBMOD03C (report)**: Outer joins `TRAN_HIST` to `CARDDEMO.TRANSACTION_TYPE` and `CARDDEMO.TRANSACTION_TYPE_CATEGORY`, so a transaction with an unknown type or category is printed as `UNKNOWN` rather than left out. Ordered by account, type, category and transaction id, with a subtotal per type, a total per account and a grand total. Read only.
- **CBMOD04C (maintenance)**: Updates the over-limit flag through a `FOR UPDATE` cursor only when it changes, committing every 100 updates. DB2 computes the purge cutoff as the as-of date minus the retention days, and the program checks the deleted row count (`SQLERRD(3)`) against a count taken first.

### Integration Patterns

1. **TSO Attach**: Programs run under `IKJEFT01` with `DSN RUN PROGRAM(...) PLAN(CARDMODB)` and are link-edited with `DSNELI`
2. **Host Variables Visible to the Precompiler**: Host variables are declared in the program or in DCLGEN members included with `EXEC SQL INCLUDE`, never in COBOL `COPY` members, so the separate DB2 precompiler (`DSNHPC`) can see them. The shared copybooks contain no SQL
3. **Commit Checkpoints**: Programs that change data commit every 100 changes, and their cursors are declared `WITH HOLD` to stay open across commits
4. **Error Handling**: Each SQL statement checks `SQLCODE`. Expected conditions (`+100`, `-803`, `-180`, `-181`) are handled in line. Anything else displays the `DSNTIAR` message, rolls back and abends
5. **Deterministic Output**: Dates come from the parameter record, and every cursor whose rows are written out has an `ORDER BY`. The `FOR UPDATE` cursor of CBMOD04C cannot have one, so CBMOD04C writes only totals

## Integration with Base Application

This module integrates with the base CardDemo application in the following ways:

1. **Reads Base VSAM Files**: TRANSACT (posted transactions), CARDXREF (card to account) and ACCTDATA (balances and credit limits), the same files the base batch jobs use
2. **Runs After the Base Posting Job**: `MODBLOAD` loads what `POSTTRAN` has posted
3. **Uses the Transaction Type Tables**: The report joins to the tables of the Transaction Type Management extension
4. **Separate DB2 Objects**: Its own database (`CARDMODB`), package collection and plan, so creating, dropping or rebinding it does not affect the other DB2 extensions
5. **No Base Changes**: No base program, copybook or file is changed, and nothing is written back to the VSAM files

## Dependencies

- Base CardDemo application and its VSAM files
- DB2 subsystem
- Transaction Type Management extension (`app-transaction-type-db2`) tables, for `MODBRPT`
