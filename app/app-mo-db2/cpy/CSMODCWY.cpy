      ******************************************************************
      * Copybook    : CSMODCWY
      * Application : CardDemo - app-mo-db2
      * Function    : Common working storage for the app-mo-db2 CICS
      *               programs: Db2 error messages for the screen,
      *               date validation and amount formatting.
      *               Used with procedure copybook CSMODCPY.
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
      *    Db2 error message: set WS-DB2-ACTION, then perform
      *    9800-FORMAT-DB2-MESSAGE; the text is in WS-DB2-MESSAGE.
       01  WS-DB2-ERROR-INFO.
           05  WS-DB2-ACTION                    PIC X(30) VALUE SPACES.
           05  WS-DB2-DISP-CODE                 PIC -(4)9.
           05  WS-DB2-CODE-X                    PIC X(5).
           05  WS-DB2-ERRMC                     PIC X(70).
           05  WS-DB2-ERRMC-LEN                 PIC S9(4) COMP.
           05  WS-DB2-MESSAGE                   PIC X(78).

      *    Date check: move YYYY-MM-DD text to WS-DC-DATE, then
      *    perform 9700-VALIDATE-DATE and test WS-DC-VALID.
       01  WS-DATE-CHECK.
           05  WS-DC-DATE                       PIC X(10).
           05  WS-DC-DATE-PARTS REDEFINES WS-DC-DATE.
               10  WS-DC-YYYY                   PIC X(4).
               10  WS-DC-DASH1                  PIC X.
               10  WS-DC-MM                     PIC X(2).
               10  WS-DC-DASH2                  PIC X.
               10  WS-DC-DD                     PIC X(2).
           05  WS-DC-YEAR-N                     PIC 9(4).
           05  WS-DC-MONTH-N                    PIC 9(2).
           05  WS-DC-DAY-N                      PIC 9(2).
           05  WS-DC-MAX-DAY                    PIC 9(2).
           05  WS-DC-FLAG                       PIC X.
               88  WS-DC-VALID                  VALUE 'Y'.
               88  WS-DC-INVALID                VALUE 'N'.
           05  WS-DC-MONTH-DAYS                 PIC X(24)
                                   VALUE '312831303130313130313031'.
           05  WS-DC-DAYS-TABLE REDEFINES WS-DC-MONTH-DAYS.
               10  WS-DC-DAYS-IN-MONTH          PIC 9(2)
                                                OCCURS 12 TIMES.

      *    Account ID check: move the screen text to WS-AC-INPUT, then
      *    perform 9720-PARSE-ACCOUNT. When WS-AC-VALID, WS-AC-NUM
      *    holds the account ID.
       01  WS-ACCOUNT-CHECK.
           05  WS-AC-INPUT                      PIC X(11).
           05  WS-AC-WORK                       PIC X(11).
           05  WS-AC-NUM                        PIC 9(11).
           05  WS-AC-LEN                        PIC S9(4) COMP.
           05  WS-AC-FLAG                       PIC X.
               88  WS-AC-VALID                  VALUE 'Y'.
               88  WS-AC-INVALID                VALUE 'N'.

      *    Amount formatting: move the amount to WS-FMT-AMT, then
      *    perform 9710-FORMAT-AMOUNT. WS-FMT-AMT-SHORT holds up to
      *    9,999,999.99 and shows asterisks for anything larger.
       01  WS-AMOUNT-FORMAT.
           05  WS-FMT-AMT                       PIC S9(13)V99 COMP-3.
           05  WS-FMT-AMT-SHORT                 PIC X(11).
           05  WS-FMT-AMT-LONG                  PIC X(14).
           05  WS-FMT-EDIT-SHORT                PIC -(7)9.99.
           05  WS-FMT-EDIT-LONG                 PIC -(10)9.99.
