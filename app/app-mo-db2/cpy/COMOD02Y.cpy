      ******************************************************************
      * Copybook    : COMOD02Y
      * Application : CardDemo - app-mo-db2
      * Function    : COMMAREA of COMODUPC (transaction CMDU): the
      *               request a caller passes on EXEC CICS LINK and the
      *               daily balance COMODUPC returns in it.
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
      *    Request. R reads the row for RQ-ACCT-ID and RQ-BAL-DATE. S
      *    sets its over-limit flag and C clears it; both apply only
      *    if the row still equals RQ-ROW, the row as the caller last
      *    read it (pass CMDU-RS-ROW of an R response).
           05  CMDU-REQUEST.
               10  CMDU-RQ-ACTION               PIC X.
                   88  CMDU-RQ-READ                       VALUE 'R'.
                   88  CMDU-RQ-SET-FLAG                   VALUE 'S'.
                   88  CMDU-RQ-CLEAR-FLAG                 VALUE 'C'.
               10  CMDU-RQ-ACCT-ID              PIC X(11).
               10  CMDU-RQ-BAL-DATE             PIC X(10).
               10  CMDU-RQ-ROW.
                   15  CMDU-RQ-OPEN-BAL         PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RQ-CREDIT-AMT       PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RQ-DEBIT-AMT        PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RQ-CLOSE-BAL        PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RQ-TRAN-CNT         PIC 9(9).
                   15  CMDU-RQ-CREDIT-LIMIT     PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RQ-OVERLIMIT-FLG    PIC X.
      *            Spaces when ADB_FLAG_DATE is NULL
                   15  CMDU-RQ-FLAG-DATE        PIC X(10).
      *    Response. Status 00 is the row (after S or C, as saved); 04
      *    is a notice in the message (no such row, or the row changed
      *    since RQ-ROW and nothing was saved; the current row is
      *    returned when there is one); 08 is a request that is not
      *    valid, and RS-ERR-FIELD names the field (A account, D date,
      *    F flag, R action); 12 is a Db2 error.
           05  CMDU-RESPONSE.
               10  CMDU-RS-STATUS               PIC X(2).
                   88  CMDU-RS-OK                         VALUE '00'.
                   88  CMDU-RS-NOTICE                     VALUE '04'.
                   88  CMDU-RS-BAD-REQUEST                VALUE '08'.
                   88  CMDU-RS-DB2-ERROR                  VALUE '12'.
               10  CMDU-RS-ERR-FIELD            PIC X.
               10  CMDU-RS-MESSAGE              PIC X(78).
               10  CMDU-RS-FOUND-FLG            PIC X.
                   88  CMDU-RS-ROW-FOUND                  VALUE 'Y'.
                   88  CMDU-RS-ROW-NOT-FOUND              VALUE 'N'.
               10  CMDU-RS-ACCT-ID              PIC 9(11).
               10  CMDU-RS-BAL-DATE             PIC X(10).
               10  CMDU-RS-ROW.
                   15  CMDU-RS-OPEN-BAL         PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RS-CREDIT-AMT       PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RS-DEBIT-AMT        PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RS-CLOSE-BAL        PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RS-TRAN-CNT         PIC 9(9).
                   15  CMDU-RS-CREDIT-LIMIT     PIC S9(10)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RS-OVERLIMIT-FLG    PIC X.
      *            Spaces when ADB_FLAG_DATE is NULL
                   15  CMDU-RS-FLAG-DATE        PIC X(10).
      *        That day's CARDDEMO.TRAN_HIST rows for the account
               10  CMDU-RS-HISTORY.
                   15  CMDU-RS-TH-COUNT         PIC 9(9).
                   15  CMDU-RS-TH-CREDITS       PIC S9(13)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RS-TH-DEBITS        PIC S9(13)V99
                                                SIGN LEADING SEPARATE.
                   15  CMDU-RS-TH-NET           PIC S9(13)V99
                                                SIGN LEADING SEPARATE.
