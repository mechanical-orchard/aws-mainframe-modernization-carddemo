      ******************************************************************
      * Copybook    : COMOD01Y
      * Application : CardDemo - app-mo-db2
      * Function    : COMMAREA of COMODLIC (transaction CMDL): the
      *               request a caller passes on EXEC CICS LINK and the
      *               page of daily balances COMODLIC returns in it.
      *               Every field is text, so a request can be typed
      *               (for example in CECI) and a response read as is.
      ******************************************************************
      * Copyright (c) 2026 Mechanical Orchard, Inc.                    *
      * All Rights Reserved.                                           *
      *                                                                *
      * Licensed under the Apache License, Version 2.0 (the "License").*
      * You may not use this file except in compliance with the        *
      * License. You may obtain a copy of the License at               *
      *                                                                *
      *    http://www.apache.org/licenses/LICENSE-2.0                  *
      *                                                                *
      * Unless required by applicable law or agreed to in writing,     *
      * software distributed under the License is distributed on an    *
      * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,   *
      * either express or implied. See the License for the specific    *
      * language governing permissions and limitations under the       *
      * License.                                                       *
      ******************************************************************
      *    Request. F reads the first page that matches the filters;
      *    N the page after RQ-LAST-ACCT/RQ-LAST-DATE; P the page
      *    before RQ-FIRST-ACCT/RQ-FIRST-DATE; C the page starting at
      *    RQ-FIRST-ACCT/RQ-FIRST-DATE again. For N, P and C, pass the
      *    keys and page number of the previous response.
           05  CMDL-REQUEST.
               10  CMDL-RQ-ACTION               PIC X.
                   88  CMDL-RQ-FIRST-PAGE                 VALUE 'F'.
                   88  CMDL-RQ-NEXT-PAGE                  VALUE 'N'.
                   88  CMDL-RQ-PREV-PAGE                  VALUE 'P'.
                   88  CMDL-RQ-SAME-PAGE                  VALUE 'C'.
      *        Filters: spaces mean all accounts or all dates
               10  CMDL-RQ-FILTER-ACCT          PIC X(11).
               10  CMDL-RQ-FILTER-DATE          PIC X(10).
               10  CMDL-RQ-PAGE-NUM             PIC 9(3).
               10  CMDL-RQ-FIRST-ACCT           PIC 9(11).
               10  CMDL-RQ-FIRST-DATE           PIC X(10).
               10  CMDL-RQ-LAST-ACCT            PIC 9(11).
               10  CMDL-RQ-LAST-DATE            PIC X(10).
      *    Response. Status 00 is a page; 04 is a page with a notice in
      *    the message (top or bottom of the list, no rows); 08 is a
      *    request that is not valid, and RS-ERR-FIELD names the field
      *    (A account, D date, R action); 12 is a Db2 error.
           05  CMDL-RESPONSE.
               10  CMDL-RS-STATUS               PIC X(2).
                   88  CMDL-RS-OK                         VALUE '00'.
                   88  CMDL-RS-NOTICE                     VALUE '04'.
                   88  CMDL-RS-BAD-REQUEST                VALUE '08'.
                   88  CMDL-RS-DB2-ERROR                  VALUE '12'.
               10  CMDL-RS-ERR-FIELD            PIC X.
               10  CMDL-RS-MESSAGE              PIC X(78).
               10  CMDL-RS-PAGE-NUM             PIC 9(3).
               10  CMDL-RS-NEXT-PAGE-FLG        PIC X.
                   88  CMDL-RS-NEXT-PAGE-EXISTS           VALUE 'Y'.
                   88  CMDL-RS-NEXT-PAGE-NOT-EXISTS       VALUE 'N'.
               10  CMDL-RS-FIRST-ACCT           PIC 9(11).
               10  CMDL-RS-FIRST-DATE           PIC X(10).
               10  CMDL-RS-LAST-ACCT            PIC 9(11).
               10  CMDL-RS-LAST-DATE            PIC X(10).
               10  CMDL-RS-ROW-COUNT            PIC 9(2).
               10  CMDL-RS-ROW OCCURS 10 TIMES.
                   15  CMDL-RS-ACCT-ID          PIC 9(11).
                   15  CMDL-RS-BAL-DATE         PIC X(10).
                   15  CMDL-RS-OPEN-BAL         PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDL-RS-CREDIT-AMT       PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDL-RS-DEBIT-AMT        PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDL-RS-CLOSE-BAL        PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDL-RS-TRAN-CNT         PIC 9(9).
                   15  CMDL-RS-OVERLIMIT-FLG    PIC X.
