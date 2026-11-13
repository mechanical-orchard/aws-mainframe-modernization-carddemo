# Transaction Dispute Management with DB2 - CardDemo Extension

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)

## Overview

The Transaction Dispute Management module is an optional extension for the CardDemo
application that demonstrates richer DB2 integration patterns than the base
`app-transaction-type-db2` module. It lets administrators open, browse, and work
disputes raised against card transactions, keeping the full case data and a
status-change audit trail in DB2.

Where the transaction-type module shows flat reference-data CRUD, this module adds:

- A **multi-table JOIN** between the dispute and the status reference table (online browse
  and batch report).
- **`TIMESTAMP` columns** stamped with `CURRENT TIMESTAMP` for open/last-updated times.
- A parent/child **status-history audit trail** (`ON DELETE CASCADE`).
- A batch **aging report** using `GROUP BY` / `SUM` / `COUNT` and DB2 date arithmetic.
- A single, deliberate **VSAM ↔ DB2** touch-point: opening a dispute reads the real
  `TRANSACT` VSAM record to auto-populate the card number and amount.

## Components

### Online Components

| Transaction | BMS Map  | Program  | Function                                                        |
|:------------|:---------|:---------|:----------------------------------------------------------------|
| CDSL        | CODISLI  | CODISLIC | Dispute list/browse (fwd/back Db2 cursors + JOIN, select-to-open) |
| CDSU        | CODISUP  | CODISUPC | Open a dispute, advance status, add history note                |

### Batch Components

| Job      | Program  | Function                                                             |
|:---------|:---------|:---------------------------------------------------------------------|
| CREADDB2 | DSNTIAD / DSNTEP4 | Create the dispute tables and load status + sample data     |
| RPTDSDB2 | CBDISRPT | Dispute aging report (JOIN + GROUP BY / SUM / COUNT, aging buckets)  |
| MNTDSDB2 | COBDSUPD | File-driven batch status maintenance (update status / delete dispute) |

### Directory Structure

- **bms/**       BMS map definitions (`CODISLI.bms`, `CODISUP.bms`)
- **cbl/**       COBOL programs (`CODISLIC`, `CODISUPC`, `CBDISRPT`, `COBDSUPD`)
- **cpy-bms/**   Symbolic maps for the BMS maps
- **csd/**       CICS resource definitions (`CRDDEMOP.csd`)
- **ctl/**       DB2 control decks (create + seed + DSN runners)
- **dcl/**       DCLGEN copybooks (`DCLDISP`, `DCLDSTS`, `DCLDSHS`)
- **ddl/**       Standalone DDL for the tables and indexes
- **jcl/**       JCL for create/load, report, and maintenance jobs

## DB2 Tables (schema `CARDDEMO`)

- **DISPUTE_STATUS** — status reference / lookup
  - `DST_STATUS_CD CHAR(2)` (PK), `DST_STATUS_DESC VARCHAR(30)`, `DST_OPEN_FLAG CHAR(1)`
- **DISPUTE** — dispute case record
  - `DISP_ID CHAR(12)` (PK), `DISP_TRAN_ID CHAR(16)`, `DISP_CARD_NUM CHAR(16)`,
    `DISP_AMT DECIMAL(11,2)`, `DISP_REASON_CD CHAR(4)`, `DISP_STATUS_CD CHAR(2)`,
    `DISP_OPEN_TS TIMESTAMP`, `DISP_LAST_UPD_TS TIMESTAMP`, `DISP_DESC VARCHAR(100)`
  - FK `DISP_STATUS_CD` → `DISPUTE_STATUS(DST_STATUS_CD)` `ON DELETE RESTRICT`
- **DISPUTE_HISTORY** — status-change audit trail
  - `DSH_DISP_ID CHAR(12)`, `DSH_SEQ SMALLINT` (composite PK), `DSH_FROM_STATUS CHAR(2)`,
    `DSH_TO_STATUS CHAR(2)`, `DSH_CHG_TS TIMESTAMP`, `DSH_CHG_USER CHAR(8)`,
    `DSH_NOTE VARCHAR(100)`
  - FK `DSH_DISP_ID` → `DISPUTE(DISP_ID)` `ON DELETE CASCADE`

## Installation

### Prerequisites

- Base CardDemo application installed and operational (VSAM `TRANSACT` file available).
- The `CARDDEMO` DB2 database already created — the `app-transaction-type-db2` module's
  `CREADB21` job creates it (database, `STOGROUP AWST1STG`, bufferpool `BP0`). The dispute
  `CREADDB2` job only adds new tablespaces/tables into that database.
- CICS with DB2 attachment configured (reuses `DB2ENTRY(CARDDEMO)` / `PLAN(CARDDEMO)`).

### Steps

1. **Create DB2 objects and load data** — run `CREADDB2` (`jcl/CREADDB2.jcl`). It runs the
   `DB2DCRT` create deck, then loads `DISPUTE_STATUS` (`DB2DSTS`) and sample disputes/history
   (`DB2DSMP`). (The job card has `TYPRUN=SCAN` for safety — remove it to actually run.)
2. **Compile** the four COBOL programs with the DB2 precompiler; assemble the two BMS maps.
3. **Define CICS resources** — install `csd/CRDDEMOP.csd` into the CICS region:
   ```
   DEFINE TRANSACTION(CDSL) GROUP(CARDDEMO) PROGRAM(CODISLIC)
   DEFINE TRANSACTION(CDSU) GROUP(CARDDEMO) PROGRAM(CODISUPC)
   ```
4. **Bind** the dispute programs into `PLAN(CARDDEMO)`.
5. The **Admin Menu (CA00)** now shows option **7 – Transaction Dispute Mgmt (Db2)**, which
   launches the dispute list (CDSL).

## Usage

### Online

1. Log in with an admin account and open the Admin Menu (CA00).
2. Select option **7** to reach the dispute list (CDSL):
   - Browse disputes with **F7 / F8** paging; each row shows dispute id, card, amount and the
     joined status description.
   - Filter by status code and/or card number.
   - Type `S` beside a dispute and press **Enter** to open it (CDSU); or press **F2** to open a
     brand-new dispute.
3. On the maintain screen (CDSU):
   - **Open new**: enter a Transaction ID, reason code and description, press **F5**. The
     program reads the `TRANSACT` VSAM record for card/amount, inserts the dispute (status
     `01`) and the first history row under one unit of work.
   - **Advance status**: with a dispute shown, enter a new status code and a note, press
     **F5** — the dispute is updated and a new history row is appended.

### Batch

- **RPTDSDB2** runs `CBDISRPT` to print the aging report (open disputes bucketed 0-30 / 31-60 /
  61+ days, escalation candidates flagged, plus a status summary with counts and summed
  amounts).
- **MNTDSDB2** runs `COBDSUPD` to apply status updates / deletions from an `INPFILE` dataset.

## Integration with the Base Application

- **Admin menu**: adds option 7 in `app/cpy/COADM02Y.cpy` (count bumped to 7). No change to
  `COADM01C.cbl` is required.
- **Shared commarea**: `app/cpy/COCOM01Y.cpy` gains a `CDEMO-DISPUTE-INFO` group with
  `CDEMO-DISP-ID` so the list can hand a selected dispute to the maintain program (append-only,
  backward compatible).
- **VSAM coexistence**: disputes live entirely in DB2 but reference real VSAM transactions by
  `TRAN-ID`, reinforcing CardDemo's dual-storage theme without changing any base flow.

## Dependencies

- Base CardDemo application and its VSAM `TRANSACT` file
- `app-transaction-type-db2` module (creates the shared `CARDDEMO` DB2 database)
- DB2 subsystem `DAZ1`, CICS with DB2 support
