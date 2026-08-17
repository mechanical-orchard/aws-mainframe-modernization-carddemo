# CardDemo CDC Demo Jobs — Design Specification

Author: mainframe batch design engineer
Status: initial design (pre-implementation)
Scope: two new deterministic COBOL batch jobs plus their JCL, copybooks, and
seed data, added into the AWS CardDemo source tree. The jobs read/write
sequential PS datasets, the existing DB2 table `MODATA1.MOCDC`, and a new
demo VSAM KSDS. The jobs are the CardDemo-flavored, primarily-COBOL
equivalent of the SQL-script `demo-acctload.jcl` / `demo-dalypost.jcl`
pair, modelled to feed the same CDC capture stream that watches
`MODATA1.MOCDC`.

---

## 1. Goals and non-goals

### Goals
- Two batch jobs, each written primarily in COBOL, each touching all three
  I/O types: sequential PS, DB2 (`MODATA1.MOCDC`), and VSAM KSDS.
- Setup/load job (`CBDMO01C` + `DEMOLOAD.jcl`): reset-then-load. Byte-
  identical starting state across runs.
- Daily-post job (`CBDMO02C` + `DEMOPOST.jcl`): reads a fixed daily-input
  PS, updates VSAM (READ/REWRITE) and MOCDC (UPDATE / INSERT for new
  accounts), writes three sequential outputs.
- Deterministic: identical starting state + identical inputs produce
  byte-identical final VSAM state, MOCDC state, and sequential outputs.
- Follow CardDemo conventions (copybook-based record layouts,
  `FILE STATUS` handling, `EXEC SQL` with `SQLCODE` handling, IDCAMS
  DELETE/DEFINE/REPRO, standard batch JCL).

### Non-goals
- No modernization to Java (later, separate pipeline).
- No execution, compilation, or submission of the jobs — this is a static
  authoring artifact.
- No DDL against MOCDC. The jobs issue DML only, and the DML surface is
  narrower than "any DML": setup (`CBDMO01C`) uses `DELETE` + `INSERT`
  only, daily-post (`CBDMO02C`) uses `UPDATE` + `INSERT` only. Daily-post
  must NOT issue `DELETE` against MOCDC — closes are expressed as an
  `UPDATE` to a sentinel state (see §4.3 / §6.3 / §8.2). No CREATE /
  ALTER / DROP / RENAME / schema change. The existing CDC capture on
  MOCDC must keep working unchanged.
- No mutation of any existing CardDemo dataset, copybook, or program.
  All new VSAM and sequential datasets use the isolated HLQ
  `AWS.M2.CARDDEMO.DEMO.*`.

---

## 2. Reference material

- `../glasshouse/scripts/demo-acctload.jcl` — the original SQL-script
  setup job. Establishes the reset-then-load contract against MOCDC
  (`DELETE FROM MODATA1.MOCDC; INSERT ... 1..1000; COMMIT`) and the row
  shape (`ID`, `DESCR = 'BAL FWD ' || DIGITS(N)`, `AMOUNT = DEC(N,9,2)`).
- `../glasshouse/scripts/demo-dalypost.jcl` — the original SQL-script
  daily-post job. Defines the daily action mix: close 901-1000, open new
  1001-1200, post-then-charge 1-100, write trial-balance report, write
  control totals.
- `app/cbl/CBTRN02C.cbl` — CardDemo template for a COBOL batch program
  mixing sequential and VSAM (INDEXED) I/O with FILE STATUS + IO-STATUS
  ABEND pattern.
- `app/app-transaction-type-db2/cbl/COBTUPDT.cbl` — CardDemo template
  for embedded SQL (`EXEC SQL INSERT/UPDATE/DELETE`, `SQLCA`, `SQLCODE`
  evaluation, `INCLUDE` of DCLGEN copybook).
- `app/jcl/POSTTRAN.jcl` — CardDemo template for a JCL that runs a
  non-DB2 COBOL program over multiple DDs (VSAM + PS mix). Used here
  for the application-DD conventions only; POSTTRAN runs `CBTRN02C`,
  which is not a DB2 program, so it is NOT the JCL template for the
  DB2 attach.
- `app/app-transaction-type-db2/jcl/MNTTRDB2.jcl` — CardDemo template
  for the DB2 batch attach convention: `EXEC PGM=IKJEFT01,REGION=0M`
  with `STEPLIB` DDs for `OEM.DB2.DAZ1.SDSNEXIT`,
  `OEMA.DB2.VERSIONA.SDSNLOAD`, and `AWS.M2.CARDDEMO.LOADLIB`, plus
  `DBRMLIB` (`AWS.M2.CARDDEMO.DBRMLIB`), `SYSTSPRT`, and `SYSTSIN`
  driving `DSN SYSTEM(DAZ1) / RUN PROGRAM(<prog>) PLAN(CARDDEMO)`.
  This is the JCL template for both DEMOLOAD STEP30 and DEMOPOST
  STEP20, because both `CBDMO01C` and `CBDMO02C` issue `EXEC SQL`
  DML against `MODATA1.MOCDC` and therefore require the DB2 attach.
  (Same pattern is also used by `CREADB21.jcl` in the same folder.)
- `app/jcl/ACCTFILE.jcl` — CardDemo template for IDCAMS
  DELETE/DEFINE/REPRO of a VSAM KSDS.
- `app/cpy/CVACT01Y.cpy`, `app/cpy/CVTRA05Y.cpy` — CardDemo copybook
  record-layout style (`01`, `05`, PIC, USAGE, key at top, FILLER pad).
- `app/app-transaction-type-db2/dcl/DCLTRTYP.dcl` — CardDemo DCLGEN
  host-variable copybook style (`EXEC SQL DECLARE ... TABLE ... END-EXEC`
  followed by host-variable `01`).
- `README.md` — CardDemo dataset / batch job glossary.

---

## 3. Programs and JCL — deliverable file paths

| Artifact               | Path                                     |
| :--------------------- | :--------------------------------------- |
| Setup COBOL program    | `app/cbl/CBDMO01C.cbl`                   |
| Daily-post COBOL prog  | `app/cbl/CBDMO02C.cbl`                   |
| Setup JCL              | `app/jcl/DEMOLOAD.jcl`                   |
| Daily-post JCL         | `app/jcl/DEMOPOST.jcl`                   |
| VSAM record copybook   | `app/cpy/CVDMO01Y.cpy`                   |
| Seed-account PS copy   | `app/cpy/CVDMO02Y.cpy`                   |
| Daily-input PS copy    | `app/cpy/CVDMO03Y.cpy`                   |
| Posted-output PS copy  | `app/cpy/CVDMO04Y.cpy`                   |
| Trial-balance PS copy  | `app/cpy/CVDMO05Y.cpy`                   |
| Control-totals PS copy | `app/cpy/CVDMO06Y.cpy`                   |
| MOCDC DCLGEN copybook  | `app/cpy/DCLMOCDC.cpy`                   |
| Seed account PS data   | `app/data/AWS.M2.CARDDEMO.DEMO.SEEDACCT.PS` |
| Daily-input PS data    | `app/data/AWS.M2.CARDDEMO.DEMO.DALYIN.PS`   |

The DCLGEN copybook is placed under `app/cpy/` rather than an
optional-module `dcl/` directory because the two new jobs are core
CardDemo demo jobs, not part of an optional-module tree.

---

## 4. Dataset inventory

All new datasets use the isolated HLQ `AWS.M2.CARDDEMO.DEMO.*`. No
existing CardDemo dataset is touched. The DB2 table `MODATA1.MOCDC` is
the existing CDC-enabled table and is accessed DML-only.

### 4.1 VSAM KSDS

| DSN                                            | Kind      | Key            | RECORDSIZE | Copybook   | Job/step (mode)                         |
| :--------------------------------------------- | :-------- | :------------- | :--------- | :--------- | :--------------------------------------- |
| `AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS`       | VSAM KSDS | `KEYS(11 0)`   | `(100 100)` | CVDMO01Y  | DEMOLOAD STEP20 (IDCAMS DELETE/DEFINE), DEMOLOAD STEP30 CBDMO01C (OUTPUT — WRITE only, sequential-load), DEMOPOST STEP20 CBDMO02C (I-O — READ + REWRITE + WRITE for opens) |

### 4.2 Sequential PS

| DSN                                          | RECFM | LRECL | Copybook   | Job/step (mode)                                                      |
| :-------------------------------------------- | :---- | ----: | :--------- | :-------------------------------------------------------------------- |
| `AWS.M2.CARDDEMO.DEMO.SEEDACCT.PS`           | FB    |   100 | CVDMO02Y   | DEMOLOAD STEP30 CBDMO01C (INPUT)                                      |
| `AWS.M2.CARDDEMO.DEMO.DALYIN.PS`             | FB    |    80 | CVDMO03Y   | DEMOPOST STEP20 CBDMO02C (INPUT)                                      |
| `AWS.M2.CARDDEMO.DEMO.POSTED.PS`             | FB    |    80 | CVDMO04Y   | DEMOPOST STEP10 IDCAMS DELETE, DEMOPOST STEP20 CBDMO02C (OUTPUT)      |
| `AWS.M2.CARDDEMO.DEMO.TRIALBAL.PS`           | FBA   |   133 | CVDMO05Y   | DEMOPOST STEP10 IDCAMS DELETE, DEMOPOST STEP20 CBDMO02C (OUTPUT)      |
| `AWS.M2.CARDDEMO.DEMO.CONTROLS.PS`           | FB    |    80 | CVDMO06Y   | DEMOPOST STEP10 IDCAMS DELETE, DEMOPOST STEP20 CBDMO02C (OUTPUT)      |

The three output PS are `DISP=(NEW,CATLG,DELETE)` in DEMOPOST STEP20;
STEP10 IDCAMS deletes any leftover copy from a prior run so DEMOPOST is
itself idempotent for its output datasets. No GDG is used — a plain
catalog entry is deterministic and does not depend on run count.

### 4.3 DB2 table (existing, DML only)

Table `MODATA1.MOCDC` — existing CDC-enabled table. The jobs assume
the columns and types below (verified against the glasshouse scripts,
which insert `(ID, DESCR, AMOUNT)` values `(N, 'BAL FWD ' || DIGITS(N),
DEC(N, 9, 2))`). If the physical column definitions differ from these
assumed types in a way that changes host-variable widths, that is
flagged for reviewers in §6 as an ASSUMPTION.

| Column    | DB2 type        | Nullability   | Host-variable PIC (in `DCLMOCDC.cpy`)   | Read/write in setup (CBDMO01C)      | Read/write in daily-post (CBDMO02C)                        |
| :-------- | :-------------- | :------------ | :--------------------------------------- | :----------------------------------- | :---------------------------------------------------------- |
| `ID`      | `INTEGER`       | NOT NULL, PK  | `PIC S9(9) USAGE COMP`                   | DELETE all rows, then INSERT one row per seed record | UPDATE (for `P` post, `C` charge, and `X` close), INSERT (for `N` open) |
| `DESCR`   | `VARCHAR(50)`   | NOT NULL      | Group of `S9(4) COMP` length + `X(50)` text (DCLGEN VARCHAR pattern; matches DCLTRTYP.dcl style) | INSERT with 'BAL FWD ' + zero-padded ID | UPDATE to 'POSTED ' / 'CHARGED ' / 'CLOSED ' + zero-padded ID; INSERT with 'NEW ACCT ' + zero-padded ID |
| `AMOUNT`  | `DECIMAL(9,2)`  | NOT NULL      | `PIC S9(7)V99 USAGE COMP-3`              | INSERT with numeric value equal to ID | UPDATE (post/charge to daily-input value; close to sentinel `0`) or INSERT (open to `ID`) |

**Daily-post MOCDC DML surface is `UPDATE` and `INSERT` only.** No
`DELETE` is issued from `CBDMO02C` against `MODATA1.MOCDC`. Closes for
IDs 901..1000 are expressed as an `UPDATE` to a sentinel state
(`DESCR = 'CLOSED ' + zero-padded ID`, `AMOUNT = 0`) rather than a row
removal — the row stays in the table so a downstream CDC consumer sees
a modeled close event, and the operation stays inside the contracted
`UPDATE`/`INSERT` surface. Setup's DML surface is `DELETE` + `INSERT`
only (whole-table reset then row-by-row load). No DDL is issued from
either program. No CREATE / ALTER / DROP / RENAME / index change.
COMMIT is issued at deterministic points as spelled out in §7.2 and §8.2.

---

## 5. Record layouts (copybook field lists)

Level numbers and PIC/USAGE clauses below are the authoritative record
layouts; the implementer copies them verbatim into the listed `.cpy`
files. Total record length in each copybook matches the DCB/RECFM/LRECL
in §4.

### 5.1 `CVDMO01Y.cpy` — VSAM KSDS record (RECLN 100)

```
       01  DEMO-ACCT-RECORD.
           05  DEMO-ACCT-ID              PIC 9(11).
           05  DEMO-ACCT-DESCR           PIC X(50).
           05  DEMO-ACCT-AMOUNT          PIC S9(7)V99 USAGE COMP-3.
           05  DEMO-ACCT-STATUS          PIC X(01).
                88  DEMO-ACCT-OPEN       VALUE 'O'.
                88  DEMO-ACCT-CLOSED     VALUE 'C'.
           05  FILLER                    PIC X(33).
```

Key = `DEMO-ACCT-ID` (11 bytes zoned, offset 0, matches
`KEYS(11 0)`). Fixed length 100. `AMOUNT` is COMP-3 for
deterministic packed-decimal representation.

### 5.2 `CVDMO02Y.cpy` — Seed-account PS record (FB LRECL 100)

Identical layout to `CVDMO01Y.cpy`; the seed file is loaded 1:1 into
VSAM by `CBDMO01C`.

```
       01  DEMO-SEEDACCT-RECORD.
           05  SEED-ACCT-ID              PIC 9(11).
           05  SEED-ACCT-DESCR           PIC X(50).
           05  SEED-ACCT-AMOUNT          PIC S9(7)V99 USAGE COMP-3.
           05  SEED-ACCT-STATUS          PIC X(01).
           05  FILLER                    PIC X(33).
```

### 5.3 `CVDMO03Y.cpy` — Daily-input PS record (FB LRECL 80)

```
       01  DEMO-DALYIN-RECORD.
           05  DIN-ACTION                PIC X(01).
                88  DIN-POST             VALUE 'P'.
                88  DIN-CHARGE           VALUE 'C'.
                88  DIN-OPEN             VALUE 'N'.
                88  DIN-CLOSE            VALUE 'X'.
           05  DIN-ACCT-ID               PIC 9(11).
           05  DIN-DESCR                 PIC X(50).
           05  DIN-AMOUNT                PIC S9(7)V99
                                          SIGN IS LEADING SEPARATE.
           05  FILLER                    PIC X(08).
```

Amount is display (SIGN LEADING SEPARATE, 10 bytes) so the file
remains portable FB text and can be diffed byte-for-byte. Total:
1 + 11 + 50 + 10 + 8 = 80.

### 5.4 `CVDMO04Y.cpy` — Posted-output PS record (FB LRECL 80)

```
       01  DEMO-POSTED-RECORD.
           05  POST-ACTION               PIC X(01).
           05  POST-ACCT-ID              PIC 9(11).
           05  POST-DESCR                PIC X(50).
           05  POST-AMOUNT               PIC S9(7)V99
                                          SIGN IS LEADING SEPARATE.
           05  POST-RESULT-CODE          PIC X(02).
                88  POST-OK              VALUE 'OK'.
                88  POST-REJECT          VALUE 'RJ'.
           05  FILLER                    PIC X(06).
```

Total 80. One record per daily-input record processed, in daily-input
order, regardless of outcome.

### 5.5 `CVDMO05Y.cpy` — Trial-balance report record (FBA LRECL 133)

```
       01  DEMO-TRIAL-BAL-LINE.
           05  TB-CC                     PIC X(01).
           05  TB-DETAIL.
              10  TB-ACCT-ID             PIC 9(11).
              10  FILLER                 PIC X(02).
              10  TB-DESCR               PIC X(50).
              10  FILLER                 PIC X(02).
              10  TB-AMOUNT-DISPLAY      PIC -Z(6)9.99.
              10  FILLER                 PIC X(02).
              10  TB-STATUS              PIC X(01).
              10  FILLER                 PIC X(53).
```

`TB-CC` is the carriage-control byte (`'1'` on header, `' '` on
detail, `'-'` on total).

Trial-balance report layout (fixed line order — see §8.2 paragraph
`3000-WRITE-TRIALBAL`):
- Line 1: header (`TB-CC='1'`) — `TB-ACCT-ID` = zeros, `TB-DESCR` =
  literal `'TRIAL BALANCE - DEMO CDC ACCOUNTS'` (33 chars) left-justified
  in 50 bytes with 17 trailing blanks, `TB-AMOUNT-DISPLAY` = zeros,
  `TB-STATUS` = space.
- Lines 2..N-1: detail (`TB-CC=' '`), one per account with `TB-ACCT-ID`
  in the fixed range **1001 through 1200 inclusive**, emitted in
  ascending VSAM key order (guaranteed by `START KEY IS >= 1001` +
  `READ NEXT` — see §8.2). `TB-DESCR` and `TB-STATUS` come from the
  VSAM record; `TB-AMOUNT-DISPLAY` is the account's post-post AMOUNT.
- Line N: total (`TB-CC='-'`), `TB-ACCT-ID` = zeros, `TB-DESCR` = literal
  `'TOTAL'` left-justified in 50 chars (padded with trailing blanks),
  `TB-AMOUNT-DISPLAY` = the sum of the detail lines' amounts, `TB-STATUS`
  = space.

For the fixed daily input in §6.2 this produces exactly 202 records:
1 header + 200 detail (IDs 1001..1200) + 1 total. This range matches the
glasshouse `demo-dalypost.jcl` STEP4 selection (`WHERE ID BETWEEN 1001
AND 1200 ORDER BY ID`).

### 5.6 `CVDMO06Y.cpy` — Control-totals PS record (FB LRECL 80)

```
       01  DEMO-CONTROLS-RECORD.
           05  CTL-LABEL                 PIC X(30).
           05  CTL-VALUE                 PIC 9(15).
           05  FILLER                    PIC X(35).
```

Six records emitted in fixed order (see §8.2 STEP20 paragraph
`3500-WRITE-CONTROLS`): input-read, posted-ok, posted-reject,
opened, closed, unchanged.

### 5.7 `DCLMOCDC.cpy` — DCLGEN host-variable copybook for MOCDC

Modeled on `app/app-transaction-type-db2/dcl/DCLTRTYP.dcl`. This
copybook is DECLARE-only — it does NOT create the table; it declares
the shape of the existing table for host-variable binding.

```
      ******************************************************************
      * DCLGEN-STYLE DECLARATION FOR EXISTING TABLE MODATA1.MOCDC       *
      *   THIS COPYBOOK IS DECLARE-ONLY. NO DDL IS ISSUED.              *
      *   PHYSICAL TYPES ARE ASSUMED (see docs/DEMO-JOBS-SPEC.md §4.3): *
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
```

---

## 6. Fixed starting state and fixed daily input

### 6.1 Fixed starting state (produced by DEMOLOAD)

After DEMOLOAD completes cleanly the following state exists — byte- and
row-identical across every run:

- **VSAM `AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS`**: exactly 1000
  records, keys `00000000001` .. `00000001000`, one record per key,
  each written by loading the corresponding record from
  `SEEDACCT.PS` in file order (file order == key order). Every record
  has `DEMO-ACCT-STATUS = 'O'` (open), `DEMO-ACCT-DESCR = 'BAL FWD '` +
  the 11-digit zero-padded ID (right-padded with spaces to 50), and
  `DEMO-ACCT-AMOUNT = ID` (as `S9(7)V99` COMP-3, so ID=1 → +0000001.00).

- **DB2 `MODATA1.MOCDC`**: exactly 1000 rows, `ID` 1..1000, `DESCR`
  `'BAL FWD ' || RIGHT('00000000000' || DIGITS(ID), 11)` (matching the
  VSAM `DEMO-ACCT-DESCR` byte-for-byte in the ID span), `AMOUNT`
  `DEC(ID, 9, 2)` (i.e. numeric equal to ID).

### 6.2 Fixed daily input (consumed by DEMOPOST)

`AWS.M2.CARDDEMO.DEMO.DALYIN.PS` is checked into `app/data/` and is
FB LRECL 80. It contains, in this exact record order:

1. 100 `P` (POST) records for `DIN-ACCT-ID` = 1..100, in ascending ID
   order, with `DIN-DESCR = 'POSTED '` + zero-padded ID and
   `DIN-AMOUNT = ID + 1000`.
2. 100 `C` (CHARGE) records for `DIN-ACCT-ID` = 1..100, in ascending
   ID order, with `DIN-DESCR = 'CHARGED '` + zero-padded ID and
   `DIN-AMOUNT = ID + 1025`.
3. 100 `X` (CLOSE) records for `DIN-ACCT-ID` = 901..1000, in
   ascending ID order, with `DIN-DESCR = spaces`, `DIN-AMOUNT = 0`.
4. 200 `N` (NEW) records for `DIN-ACCT-ID` = 1001..1200, in ascending
   ID order, with `DIN-DESCR = 'NEW ACCT '` + zero-padded ID and
   `DIN-AMOUNT = ID`.

Total 500 records. This mix reproduces the glasshouse
`demo-dalypost.jcl` semantics (close 901-1000, open 1001-1200, then
post-and-charge 1-100). Order is fixed and part of the input — the
implementer must produce this file byte-for-byte.

### 6.3 Fixed final state (produced by DEMOPOST)

Given the fixed starting state from §6.1 and the fixed daily input
from §6.2, DEMOPOST produces:

- **VSAM**: 1200 records. Keys 1..100 have `DESCR = 'CHARGED ...'` (the
  charge overwrites the post), `AMOUNT = ID + 1025`, `STATUS = 'O'`.
  Keys 101..900 unchanged from starting state. Keys 901..1000 have
  `STATUS = 'C'` and `DESCR`/`AMOUNT` unchanged (VSAM close does not
  need a sentinel — the `STATUS` byte carries the close signal). Keys
  1001..1200 written fresh: `DESCR = 'NEW ACCT ...'`, `AMOUNT = ID`,
  `STATUS = 'O'`.
- **MOCDC**: 1200 rows (row count goes 1000 → 1200 — no deletes). Rows
  1..100 → `DESCR = 'CHARGED ...'`, `AMOUNT = ID + 1025`. Rows 101..900
  → unchanged. Rows 901..1000 → `DESCR = 'CLOSED ' + zero-padded ID`,
  `AMOUNT = 0` (sentinel close via `UPDATE`; the row is retained, not
  deleted, so daily-post's MOCDC DML surface stays `UPDATE`/`INSERT`
  only per §4.3). Rows 1001..1200 → new rows with `DESCR = 'NEW ACCT
  ...'`, `AMOUNT = ID` (`INSERT`).
- **`POSTED.PS`**: 500 records in daily-input order (§6.2), one per
  input record. `POST-RESULT-CODE = 'OK'` for all 500 (no rejects in
  the fixed input).
- **`TRIALBAL.PS`**: 1 header + 200 detail (IDs 1001..1200 in
  ascending order) + 1 total = 202 records, matching the glasshouse
  STEP4 selection.
- **`CONTROLS.PS`**: 6 records in fixed order (see §5.6) with counts
  500 / 500 / 0 / 200 / 100 / 800.

---

## 7. CBDMO01C — Setup/load program

### 7.1 File/DD map

| SELECT (COBOL)   | ASSIGN (DD) | Organization | Access     | Copybook   |
| :--------------- | :---------- | :----------- | :--------- | :--------- |
| `SEEDACCT-FILE`  | `SEEDACCT`  | SEQUENTIAL   | SEQUENTIAL | CVDMO02Y   |
| `CDCACCT-FILE`   | `CDCACCT`   | INDEXED KSDS | SEQUENTIAL (load mode) | CVDMO01Y   |

Embedded SQL uses the existing DB2 plan/bind that CardDemo already
wires for its DB2 batch modules; `DCLMOCDC.cpy` and `SQLCA` are
`INCLUDE`d in WORKING-STORAGE (see §5.7). No file for MOCDC — MOCDC
is accessed only through `EXEC SQL`.

### 7.2 Paragraph flow

```
0000-MAIN.
    PERFORM 0100-OPEN-FILES
    PERFORM 0200-RESET-MOCDC
    PERFORM 1000-LOAD-LOOP UNTIL END-OF-FILE = 'Y'
    PERFORM 8000-COMMIT-MOCDC
    PERFORM 9000-CLOSE-FILES
    PERFORM 9500-DISPLAY-COUNTS
    GOBACK.

0100-OPEN-FILES.
    OPEN INPUT  SEEDACCT-FILE
    OPEN OUTPUT CDCACCT-FILE      *> KSDS load mode
    * FILE STATUS pattern per CBTRN02C — abend on non-'00'.

0200-RESET-MOCDC.
    EXEC SQL DELETE FROM MODATA1.MOCDC END-EXEC
    * Accept SQLCODE 0 (a searched DELETE returns 0 even against an
    * already-empty table; SQLERRD(3) carries the row count). Abend on
    * SQLCODE < 0. No COMMIT here — batched into 8000.
    * DELETE-then-INSERT (no DROP/CREATE) leaves the CDC-enabled
    * table's DDL untouched. This is what makes the job idempotent
    * without breaching the "no DDL" rule.

1000-LOAD-LOOP.
    READ SEEDACCT-FILE INTO DEMO-SEEDACCT-RECORD
       AT END MOVE 'Y' TO END-OF-FILE.
    IF END-OF-FILE = 'N'
       ADD 1 TO WS-READ-COUNT
       PERFORM 1100-WRITE-VSAM
       PERFORM 1200-INSERT-MOCDC
    END-IF.

1100-WRITE-VSAM.
    * Move seed fields to DEMO-ACCT-RECORD, WRITE.
    * File-status abend pattern.

1200-INSERT-MOCDC.
    MOVE SEED-ACCT-ID     TO DCL-MOCDC-ID
    MOVE SEED-ACCT-DESCR  TO DCL-MOCDC-DESCR-TEXT
    MOVE +50              TO DCL-MOCDC-DESCR-LEN
    *> Every MOCDC VARCHAR store uses length 50 with the copybook's
    *> PIC X(50) content (trailing blanks allowed). This is a fixed
    *> contract — see §9 rule (h) — so the stored VARCHAR is
    *> byte-identical to the VSAM DEMO-ACCT-DESCR PIC X(50) field.
    MOVE SEED-ACCT-AMOUNT TO DCL-MOCDC-AMOUNT
    EXEC SQL
        INSERT INTO MODATA1.MOCDC (ID, DESCR, AMOUNT)
        VALUES (:DCL-MOCDC-ID, :DCL-MOCDC-DESCR, :DCL-MOCDC-AMOUNT)
    END-EXEC
    * EVALUATE SQLCODE:
    *   = 0   -> ADD 1 TO WS-INSERT-COUNT
    *   < 0   -> abend with SQLCODE (no SQLCODE -803 possible because
    *            0200-RESET-MOCDC emptied the table).

8000-COMMIT-MOCDC.
    EXEC SQL COMMIT END-EXEC.

9000-CLOSE-FILES.
    CLOSE SEEDACCT-FILE
    CLOSE CDCACCT-FILE.

9500-DISPLAY-COUNTS.
    DISPLAY 'SEED READ    : ' WS-READ-COUNT
    DISPLAY 'MOCDC INSERT : ' WS-INSERT-COUNT.
```

Load-mode WRITE against a KSDS pre-defined with IDCAMS is
deterministic when the seed file is in ascending key order.

### 7.3 DEMOLOAD JCL

```
//DEMOLOAD JOB 'DEMO CDC LOAD',CLASS=A,MSGCLASS=0,
//         NOTIFY=&SYSUID
//*
//* STEP10 : IDCAMS delete of any leftover VSAM cluster.
//* STEP20 : IDCAMS define of AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS
//*          (KEYS(11 0), RECORDSIZE(100 100), INDEXED).
//* STEP30 : run CBDMO01C to load VSAM and reset+load MOCDC.
//*
//STEP10 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
   DELETE AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS CLUSTER
   IF MAXCC LE 08 THEN SET MAXCC = 0
/*
//STEP20 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
   DEFINE CLUSTER (NAME(AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS) -
          CYLINDERS(1 1) -
          KEYS(11 0) -
          RECORDSIZE(100 100) -
          SHAREOPTIONS(2 3) -
          INDEXED) -
          DATA  (NAME(AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS.DATA)) -
          INDEX (NAME(AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS.INDEX))
/*
//STEP30   EXEC PGM=IKJEFT01,REGION=0M
//STEPLIB  DD DISP=SHR,DSN=OEM.DB2.DAZ1.SDSNEXIT
//         DD DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//         DD DISP=SHR,DSN=AWS.M2.CARDDEMO.LOADLIB
//DBRMLIB  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DBRMLIB
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SEEDACCT DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.SEEDACCT.PS
//CDCACCT  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS
//SYSTSIN  DD *
     DSN SYSTEM(DAZ1)
          RUN PROGRAM(CBDMO01C) PLAN(CARDDEMO)
/*
```

STEP30 uses the CardDemo DB2 batch attach convention — `IKJEFT01`
with `SDSNEXIT` + `SDSNLOAD` + application `LOADLIB` on `STEPLIB`,
`DBRMLIB` for the program's DBRM, and `SYSTSIN` driving
`DSN SYSTEM(DAZ1) / RUN PROGRAM(CBDMO01C) PLAN(CARDDEMO)` — matching
`app/app-transaction-type-db2/jcl/MNTTRDB2.jcl`. This is required
because `CBDMO01C` issues `EXEC SQL DELETE` and `EXEC SQL INSERT`
against `MODATA1.MOCDC`; running `EXEC PGM=CBDMO01C` directly (with
only the application LOADLIB on STEPLIB) would fail at OPEN of the
DB2 thread and on every subsequent SQL call. The DB2 subsystem name
(`DAZ1`) and plan name (`CARDDEMO`) are copied verbatim from the
CardDemo reference — the implementer must not change them without
also updating the BIND artifacts. The application DD statements
(`SEEDACCT`, `CDCACCT`, `SYSPRINT`, `SYSOUT`) are unchanged from the
COBOL SELECT/ASSIGN in §7.1 — `IKJEFT01` passes them through to the
program.

STEP10 + STEP20 give reset-then-load for the VSAM. `0200-RESET-MOCDC`
+ the INSERT loop give reset-then-load for MOCDC. Together the job
is idempotent — re-running produces byte-identical state.

---

## 8. CBDMO02C — Daily-post program

### 8.1 File/DD map

| SELECT (COBOL)   | ASSIGN (DD) | Organization | Access     | Copybook |
| :--------------- | :---------- | :----------- | :--------- | :------- |
| `DALYIN-FILE`    | `DALYIN`    | SEQUENTIAL   | SEQUENTIAL | CVDMO03Y |
| `CDCACCT-FILE`   | `CDCACCT`   | INDEXED KSDS | DYNAMIC    | CVDMO01Y |
| `POSTED-FILE`    | `POSTED`    | SEQUENTIAL   | SEQUENTIAL | CVDMO04Y |
| `TRIALBAL-FILE`  | `TRIALBAL`  | SEQUENTIAL   | SEQUENTIAL | CVDMO05Y |
| `CONTROLS-FILE`  | `CONTROLS`  | SEQUENTIAL   | SEQUENTIAL | CVDMO06Y |

`CDCACCT-FILE` is declared `ACCESS MODE IS DYNAMIC` (not `RANDOM`)
because the program mixes random READ/REWRITE/WRITE by key (for
`1100-APPLY-POST` / `1200-APPLY-CHARGE` / `1300-APPLY-OPEN` /
`1400-APPLY-CLOSE`) with sequential `START KEY IS >= ...` +
`READ NEXT` access (for `3000-WRITE-TRIALBAL`). DYNAMIC is the only
COBOL VSAM access mode that legally supports both patterns on the
same OPEN. Reviewers can grep the resulting `CBDMO02C.cbl` for
`ACCESS MODE IS DYNAMIC` on the `CDCACCT-FILE` SELECT — see §9 rule (k).

Embedded SQL against MOCDC as in CBDMO01C; `DCLMOCDC.cpy` and
`SQLCA` INCLUDEd in WORKING-STORAGE. No SELECT cursor is needed for
the trial-balance step — the trial balance is written from a
sequential scan of VSAM (see §8.2 `3000-WRITE-TRIALBAL`), which
guarantees deterministic order and matches the VSAM state that MOCDC
mirrors.

### 8.2 Paragraph flow

```
0000-MAIN.
    PERFORM 0100-OPEN-FILES
    PERFORM 1000-PROCESS-DAILY UNTIL END-OF-FILE = 'Y'
    PERFORM 2500-COMMIT-MOCDC
    PERFORM 2700-COUNT-UNCHANGED
    PERFORM 3000-WRITE-TRIALBAL
    PERFORM 3500-WRITE-CONTROLS
    PERFORM 9000-CLOSE-FILES
    PERFORM 9500-DISPLAY-COUNTS
    GOBACK.

0100-OPEN-FILES.
    OPEN INPUT  DALYIN-FILE
    OPEN I-O    CDCACCT-FILE
    OPEN OUTPUT POSTED-FILE
    OPEN OUTPUT TRIALBAL-FILE
    OPEN OUTPUT CONTROLS-FILE.

1000-PROCESS-DAILY.
    READ DALYIN-FILE INTO DEMO-DALYIN-RECORD AT END MOVE 'Y' TO END-OF-FILE.
    IF END-OF-FILE = 'N'
       ADD 1 TO WS-READ-COUNT
       EVALUATE TRUE
           WHEN DIN-POST   PERFORM 1100-APPLY-POST
           WHEN DIN-CHARGE PERFORM 1200-APPLY-CHARGE
           WHEN DIN-OPEN   PERFORM 1300-APPLY-OPEN
           WHEN DIN-CLOSE  PERFORM 1400-APPLY-CLOSE
           WHEN OTHER      PERFORM 1900-WRITE-POSTED-REJECT
       END-EVALUATE
    END-IF.

1100-APPLY-POST.
    * READ VSAM (random) by DIN-ACCT-ID; if not found, reject.
    * If found: MOVE DIN-DESCR + DIN-AMOUNT into VSAM record, REWRITE.
    * Bind MOCDC host variables:
    *     MOVE DIN-ACCT-ID     TO DCL-MOCDC-ID
    *     MOVE DIN-DESCR       TO DCL-MOCDC-DESCR-TEXT
    *     MOVE +50             TO DCL-MOCDC-DESCR-LEN
    *     MOVE DIN-AMOUNT      TO DCL-MOCDC-AMOUNT
    * EXEC SQL UPDATE MODATA1.MOCDC
    *          SET DESCR = :DCL-MOCDC-DESCR,
    *              AMOUNT = :DCL-MOCDC-AMOUNT
    *          WHERE ID = :DCL-MOCDC-ID END-EXEC.
    * SQLCODE 0 -> counted OK; SQLCODE +100 -> reject.
    * ADD 1 TO WS-P-COUNT on any P record read (before OK/reject test).
    * Write POSTED record with POST-RESULT-CODE = 'OK' / 'RJ'.

1200-APPLY-CHARGE.
    * Same as 1100 with DIN-DESCR = 'CHARGED ...' and
    * DIN-AMOUNT = ID + 1025 (already in the input record).
    * DCL-MOCDC-DESCR-LEN = +50 (fixed contract, §5.7 / §9 rule (h)).
    * ADD 1 TO WS-C-COUNT.

1300-APPLY-OPEN.
    * WRITE new VSAM record (STATUS 'O') by key (DYNAMIC access
    * supports keyed WRITE outside of load mode).
    * Bind MOCDC host variables with DCL-MOCDC-DESCR-LEN = +50.
    * EXEC SQL INSERT INTO MODATA1.MOCDC (ID, DESCR, AMOUNT)
    *          VALUES (:DCL-MOCDC-ID, :DCL-MOCDC-DESCR,
    *                  :DCL-MOCDC-AMOUNT) END-EXEC.
    * SQLCODE 0 expected — the seed load committed only IDs 1..1000,
    * and 1300 only fires for 1001..1200.
    * ADD 1 TO WS-N-COUNT.
    * Write POSTED OK.

1400-APPLY-CLOSE.
    * READ VSAM (random), set STATUS = 'C', REWRITE.
    * Bind MOCDC host variables for sentinel close:
    *     MOVE DIN-ACCT-ID     TO DCL-MOCDC-ID
    *     MOVE 'CLOSED '       TO WS-DESCR-PREFIX     *> 7 bytes 'CLOSED '
    *     MOVE SPACES          TO DCL-MOCDC-DESCR-TEXT
    *     *> Blank-fill the full 50-byte host-variable text area FIRST.
    *     *> Standard COBOL STRING writes only the bytes it emits (here
    *     *> the 7-byte prefix + 11-byte zero-padded ID = 18 bytes) and
    *     *> does NOT touch positions 19..50. Pre-blanking guarantees
    *     *> positions 19..50 are spaces, so the stored VARCHAR bytes
    *     *> match §6.3's stated final MOCDC state exactly.
    *     STRING WS-DESCR-PREFIX DELIMITED BY SIZE
    *            DIN-ACCT-ID    DELIMITED BY SIZE
    *            INTO DCL-MOCDC-DESCR-TEXT
    *     *> Result: 'CLOSED ' + 11-digit zero-padded ID = 18 bytes,
    *     *> right-padded with blanks (from the MOVE SPACES above)
    *     *> to 50. Byte-deterministic.
    *     MOVE +50             TO DCL-MOCDC-DESCR-LEN
    *     MOVE ZERO            TO DCL-MOCDC-AMOUNT
    * EXEC SQL UPDATE MODATA1.MOCDC
    *          SET DESCR = :DCL-MOCDC-DESCR,
    *              AMOUNT = :DCL-MOCDC-AMOUNT
    *          WHERE ID = :DCL-MOCDC-ID END-EXEC.
    * NO DELETE against MOCDC — see §4.3 and §9 rule (i).
    * SQLCODE 0 -> OK; SQLCODE +100 -> reject (row missing).
    * ADD 1 TO WS-X-COUNT.
    * Write POSTED OK.

1900-WRITE-POSTED-REJECT.
    * Fill POSTED-RECORD with input echo + POST-RESULT-CODE = 'RJ'.
    * WRITE. Add 1 to WS-REJECT-COUNT.

2500-COMMIT-MOCDC.
    EXEC SQL COMMIT END-EXEC.
    * One COMMIT per run, at end of DALYIN. Chosen (rather than one
    * per record or one per action-class) because a single unit of
    * work is the smallest, most deterministic contract to review:
    * either the whole run's MOCDC delta is captured by CDC or none
    * of it is.

2700-COUNT-UNCHANGED.
    * Before the trial-balance scan, compute WS-UNCHANGED-COUNT as the
    * number of accounts still in "brought-forward" shape after posting.
    * Scan VSAM by key range [00000000001 .. 00000001000] (the
    * pre-existing account range from §6.1):
    *     MOVE 00000000001 TO DEMO-ACCT-ID
    *     START CDCACCT-FILE KEY IS NOT LESS THAN DEMO-ACCT-ID
    *     PERFORM UNTIL EOF OR DEMO-ACCT-ID > 00000001000
    *         READ CDCACCT-FILE NEXT
    *         IF DEMO-ACCT-ID <= 00000001000
    *            AND DEMO-ACCT-STATUS = 'O'
    *            AND DEMO-ACCT-DESCR (1:8) = 'BAL FWD '
    *            ADD 1 TO WS-UNCHANGED-COUNT
    *         END-IF
    *     END-PERFORM.
    * This makes UNCHANGED an observed fact about final VSAM state
    * rather than a derived formula — deterministic and unambiguous.

3000-WRITE-TRIALBAL.
    * Sequential scan of VSAM in ascending-key order. CDCACCT-FILE is
    * OPEN I-O with ACCESS MODE IS DYNAMIC (§8.1), which supports
    * both random ops (used earlier by 1100..1400) and sequential
    * navigation via START / READ NEXT.
    *     WRITE header line.
    *     MOVE 00000001001 TO DEMO-ACCT-ID
    *     START CDCACCT-FILE KEY IS NOT LESS THAN DEMO-ACCT-ID
    *     PERFORM UNTIL EOF OR DEMO-ACCT-ID > 00000001200
    *         READ CDCACCT-FILE NEXT
    *         IF DEMO-ACCT-ID <= 00000001200
    *            build detail line from VSAM record,
    *            ADD DEMO-ACCT-AMOUNT TO WS-TB-TOTAL,
    *            WRITE detail
    *         END-IF
    *     END-PERFORM.
    *     WRITE total line (TB-CC = '-', TB-DESCR = 'TOTAL', amount
    *     = WS-TB-TOTAL, other columns per §5.5).

3500-WRITE-CONTROLS.
    * WRITE six control-total records in fixed order (matches §5.6):
    *   INPUT-READ    : WS-READ-COUNT       (expected 500)
    *   POSTED-OK     : WS-POSTED-OK-COUNT  (expected 500)
    *   POSTED-REJECT : WS-REJECT-COUNT     (expected 0)
    *   OPENED        : WS-N-COUNT          (expected 200)
    *   CLOSED        : WS-X-COUNT          (expected 100)
    *   UNCHANGED     : WS-UNCHANGED-COUNT  (expected 800; observed —
    *                    NOT a derived formula. See 2700-COUNT-UNCHANGED.)

9000-CLOSE-FILES.  CLOSE all five.
9500-DISPLAY-COUNTS.  DISPLAY same six counts.
```

### 8.3 DEMOPOST JCL

```
//DEMOPOST JOB 'DEMO CDC POST',CLASS=A,MSGCLASS=0,
//         NOTIFY=&SYSUID
//*
//* STEP10 : IDCAMS delete of leftover output PS from prior run.
//* STEP20 : run CBDMO02C to post DALYIN.
//*
//STEP10 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
   DELETE AWS.M2.CARDDEMO.DEMO.POSTED.PS
   DELETE AWS.M2.CARDDEMO.DEMO.TRIALBAL.PS
   DELETE AWS.M2.CARDDEMO.DEMO.CONTROLS.PS
   IF MAXCC LE 08 THEN SET MAXCC = 0
/*
//STEP20   EXEC PGM=IKJEFT01,REGION=0M
//STEPLIB  DD DISP=SHR,DSN=OEM.DB2.DAZ1.SDSNEXIT
//         DD DISP=SHR,DSN=OEMA.DB2.VERSIONA.SDSNLOAD
//         DD DISP=SHR,DSN=AWS.M2.CARDDEMO.LOADLIB
//DBRMLIB  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DBRMLIB
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//DALYIN   DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.DALYIN.PS
//CDCACCT  DD DISP=SHR,DSN=AWS.M2.CARDDEMO.DEMO.CDCACCT.VSAM.KSDS
//POSTED   DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=AWS.M2.CARDDEMO.DEMO.POSTED.PS
//TRIALBAL DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=AWS.M2.CARDDEMO.DEMO.TRIALBAL.PS
//CONTROLS DD DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=0),
//            SPACE=(CYL,(1,1),RLSE),
//            DSN=AWS.M2.CARDDEMO.DEMO.CONTROLS.PS
//SYSTSIN  DD *
     DSN SYSTEM(DAZ1)
          RUN PROGRAM(CBDMO02C) PLAN(CARDDEMO)
/*
```

STEP20 uses the CardDemo DB2 batch attach convention — `IKJEFT01`
with `SDSNEXIT` + `SDSNLOAD` + application `LOADLIB` on `STEPLIB`,
`DBRMLIB` for the program's DBRM, and `SYSTSIN` driving
`DSN SYSTEM(DAZ1) / RUN PROGRAM(CBDMO02C) PLAN(CARDDEMO)` — matching
`app/app-transaction-type-db2/jcl/MNTTRDB2.jcl` (the same template
used by DEMOLOAD STEP30 in §7.3). This is required because
`CBDMO02C` issues `EXEC SQL UPDATE` and `EXEC SQL INSERT` against
`MODATA1.MOCDC`; running `EXEC PGM=CBDMO02C` directly (with only the
application LOADLIB on STEPLIB) would fail at OPEN of the DB2 thread
and on every subsequent SQL call. The DB2 subsystem name (`DAZ1`)
and plan name (`CARDDEMO`) are copied verbatim from the CardDemo
reference and match DEMOLOAD STEP30 — the implementer must not
change them without also updating the BIND artifacts. The
application DD statements (`DALYIN`, `CDCACCT`, `POSTED`, `TRIALBAL`,
`CONTROLS`, `SYSPRINT`, `SYSOUT`) are unchanged from the COBOL
SELECT/ASSIGN in §8.1 — `IKJEFT01` passes them through to the
program.

`BLKSIZE=0` lets the system pick a deterministic optimal block size
for the volume — the record content is unaffected. No GDG.

---

## 9. Deterministic contract (verifiable rules)

Every rule below is either a syntactic constraint (a reviewer can grep
the source), or a semantic invariant (a reviewer can point at the
paragraph that enforces it).

| # | Rule                                                                                                                    | Enforcement / verification                                                                                                                              |
| :-| :---------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- |
| a | No `FUNCTION CURRENT-DATE`, no `ACCEPT ... FROM DATE`, `FROM TIME`, `FROM DAY`, `FROM DAY-OF-WEEK`, `FROM TIMESTAMP`.    | Reviewer greps `CBDMO01C.cbl` and `CBDMO02C.cbl` for `CURRENT-DATE`, `ACCEPT`, `TIME`. Zero matches required.                                             |
| b | No randomness. No `FUNCTION RANDOM`. No UUID / GUID. No clock-derived seed or clock-derived value anywhere.             | Reviewer greps for `RANDOM`, `UUID`, `GUID`. Zero matches required.                                                                                     |
| c | Records are processed in deterministic order everywhere. Sequential PS is read in file order. VSAM sequential reads are ascending-key.                                | `SELECT ... ACCESS MODE IS SEQUENTIAL` on `DALYIN-FILE` and `SEEDACCT-FILE`. VSAM SEQUENTIAL scan in `3000-WRITE-TRIALBAL` uses `START KEY IS >=` + `READ NEXT`. |
| d | Final VSAM state, final MOCDC state, and all sequential outputs are a pure function of (`SEEDACCT.PS` seed contents + `DALYIN.PS` daily input + prior state after DEMOLOAD). | All inputs and starting state are checked in; no environment lookups. §6.3 gives the deterministic expected final state.                                 |
| e | Setup is idempotent (both VSAM and MOCDC reset-then-load).                                                              | DEMOLOAD STEP10 IDCAMS DELETE + STEP20 IDCAMS DEFINE (VSAM), CBDMO01C `0200-RESET-MOCDC` `DELETE FROM MODATA1.MOCDC` + row-by-row INSERT (MOCDC).        |
| f | No dependence on run time, `&SYSUID`, spool, or JES-generated values. GDG not used.                                     | JCL uses `&SYSUID` only in the JES `NOTIFY=` card (does not affect dataset content). All DSNs are static — no `+1` / `-1` GDG suffix.                    |
| g | Seed input is fixed and checked in.                                                                                     | `app/data/AWS.M2.CARDDEMO.DEMO.SEEDACCT.PS` and `app/data/AWS.M2.CARDDEMO.DEMO.DALYIN.PS` are committed. Bytes are the input contract.                    |
| h | Numeric and rounding fully specified. No locale-dependent decimal formatting. COMP-3 for stored packed decimals; `SIGN LEADING SEPARATE` for text-file numerics. | See §5. All numeric fields have explicit PIC and USAGE. All arithmetic is integer / fixed-point with defined precision.                                  |
| i | No DDL against MOCDC — DML only. Furthermore, the DML surface is narrower than "any DML": `CBDMO01C` uses `DELETE` + `INSERT` only (whole-table reset then row-by-row load); `CBDMO02C` uses `UPDATE` + `INSERT` only (`DELETE` against MOCDC is forbidden in daily-post — closes are expressed via an `UPDATE` to a sentinel state per §4.3, §6.3, and §8.2 `1400-APPLY-CLOSE`). | Reviewer greps `CBDMO01C.cbl` and `CBDMO02C.cbl` for `CREATE`, `ALTER`, `DROP`, `RENAME` (zero matches required — this covers the no-DDL constraint). Reviewer greps `CBDMO02C.cbl` for `EXEC SQL DELETE` and for `DELETE FROM MODATA1.MOCDC` (zero matches required — this covers the daily-post DML narrowing; the setup file `CBDMO01C.cbl` is the only place a `DELETE FROM MODATA1.MOCDC` may appear). `DCLMOCDC.cpy` contains a `DECLARE`, not a DDL statement — that is DCLGEN metadata, not an SQL DDL statement that gets executed. |
| j | No mutation of existing CardDemo artifacts.                                                                             | All new files live in the DEMO namespace: programs `CBDMO0*`, JCL `DEMO*.jcl`, copybooks `CVDMO*Y.cpy` + `DCLMOCDC.cpy`, DSNs `AWS.M2.CARDDEMO.DEMO.*`.  |
| k | VSAM access modes are the specific COBOL modes required to make each program's I/O pattern legal AND deterministic.    | Reviewer greps `CBDMO01C.cbl` for `ACCESS MODE IS SEQUENTIAL` on the `CDCACCT-FILE` SELECT (load mode — required for `OPEN OUTPUT` KSDS load with ascending-key `WRITE`). Reviewer greps `CBDMO02C.cbl` for `ACCESS MODE IS DYNAMIC` on the `CDCACCT-FILE` SELECT (required because the program mixes random `READ`/`REWRITE`/`WRITE` with sequential `START` + `READ NEXT`; `RANDOM` would make the trial-balance scan illegal, `SEQUENTIAL` would make the random posts illegal). |
| l | MOCDC `VARCHAR(50)` binding is a fixed contract: every host-variable store to `MODATA1.MOCDC.DESCR` sets `DCL-MOCDC-DESCR-LEN = +50` with the copybook `PIC X(50)` content (trailing blanks padding the semantic content). Byte-identical to VSAM `DEMO-ACCT-DESCR`. | Reviewer greps `CBDMO01C.cbl` and `CBDMO02C.cbl` for `MOVE +50 TO DCL-MOCDC-DESCR-LEN` and for the absence of any other value moved into `DCL-MOCDC-DESCR-LEN`. |

---

## 10. Idempotency argument

**DEMOLOAD idempotent:** STEP10 removes any leftover VSAM cluster.
STEP20 defines a fresh one. STEP30 opens it OUTPUT (load mode) and
writes 1000 records in a single deterministic order.
`0200-RESET-MOCDC` empties the MOCDC table before the row loop
INSERTs 1000 rows in seed-file order. Running DEMOLOAD twice therefore
produces byte-identical VSAM contents and row-identical MOCDC contents
(same rows, same values). No SQLCODE -803 is possible because the
DELETE fires before every INSERT.

**DEMOPOST idempotent (given the same starting state):** STEP10
deletes any leftover output PS. STEP20 recreates them
`DISP=(NEW,CATLG,DELETE)`. Provided DEMOLOAD is re-run first to
restore starting state, DEMOPOST produces byte-identical output PS,
byte-identical VSAM final state, and row-identical MOCDC final state.
DEMOPOST is NOT idempotent when run twice without an intervening
DEMOLOAD — the second run's `1300-APPLY-OPEN` would hit MOCDC
SQLCODE -803 on the primary key, exactly as flagged in the glasshouse
`demo-acctload.jcl` header comment. The idempotency contract for the
pair is therefore: **run DEMOLOAD, then DEMOPOST**.

---

## 11. Reviewer checklist

Two independent reviewers must be able to answer YES to each of:

1. Do both jobs read and write across all three I/O types (sequential
   PS + `MODATA1.MOCDC` + VSAM KSDS)?
2. Is the dataset inventory (§4) exhaustive — every DSN accounted for,
   with DCB / RECFM / LRECL / KEYS / RECORDSIZE spelled out, and
   read/write attribution to a specific job/step?
3. Are the record layouts (§5) copyable — level numbers, PIC, USAGE,
   lengths, key fields all present, and totals matching the LRECL /
   RECORDSIZE in §4?
4. Is the MOCDC access strictly DML — with `CBDMO01C` restricted to
   `DELETE` + `INSERT` and `CBDMO02C` restricted to `UPDATE` + `INSERT`
   (no `DELETE` anywhere in `CBDMO02C`) — and with `DCLMOCDC.cpy` as
   DECLARE-only and no CREATE/ALTER/DROP anywhere?
5. Are the deterministic rules in §9 (a..l) individually verifiable
   by inspection of the deliverables? In particular:
   - (a) grep for clock/date primitives returns zero.
   - (b) grep for randomness primitives returns zero.
   - (i) grep of both programs for CREATE/ALTER/DROP/RENAME returns
     zero, AND grep of `CBDMO02C.cbl` for `EXEC SQL DELETE` and
     `DELETE FROM MODATA1.MOCDC` returns zero.
   - (k) `CBDMO01C` declares `ACCESS MODE IS SEQUENTIAL` on `CDCACCT-FILE`;
     `CBDMO02C` declares `ACCESS MODE IS DYNAMIC` on `CDCACCT-FILE`.
   - (l) both programs move `+50` (and only `+50`) into
     `DCL-MOCDC-DESCR-LEN` before every MOCDC write.
6. Is DEMOLOAD reset-then-load for both VSAM and MOCDC (§10)?
7. Do the deliverable paths in §3 place all new artifacts under
   `app/cbl/`, `app/cpy/`, `app/jcl/`, `app/data/`, and use the
   `CBDMO0*` / `DEMO*` / `CVDMO*Y` / `DCLMOCDC` naming and the
   `AWS.M2.CARDDEMO.DEMO.*` DSN namespace?
8. Are `AWS.M2.CARDDEMO.DEMO.SEEDACCT.PS` and
   `AWS.M2.CARDDEMO.DEMO.DALYIN.PS` fully specified byte-for-byte in
   §6?

If any answer is NO, this document is not ready — resolve before
implementation.
