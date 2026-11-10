      ******************************************************************
      * Copybook    : CVMOD03Y
      * Application : CardDemo - app-mo-db2
      * Function    : Print lines (133 bytes) for the CBMOD03C
      *               transaction history report, DD REPTFILE.
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
       01  MODB-RPT-HEADER-1.
           05  FILLER                           PIC X(10) VALUE
               'MODBRPT'.
           05  FILLER                           PIC X(40) VALUE
               'Transaction History by Account'.
           05  FILLER                           PIC X(12) VALUE
               'Date Range: '.
           05  MODB-RPT-H-START-DATE            PIC X(10).
           05  FILLER                           PIC X(04) VALUE
               ' to '.
           05  MODB-RPT-H-END-DATE              PIC X(10).
           05  FILLER                           PIC X(47) VALUE SPACES.

       01  MODB-RPT-HEADER-2.
           05  FILLER                           PIC X(18) VALUE
               'Transaction ID'.
           05  FILLER                           PIC X(12) VALUE
               'Date'.
           05  FILLER                           PIC X(25) VALUE
               'Type'.
           05  FILLER                           PIC X(33) VALUE
               'Category'.
           05  FILLER                           PIC X(27) VALUE
               'Merchant'.
           05  FILLER                           PIC X(15) VALUE
               '         Amount'.
           05  FILLER                           PIC X(03) VALUE SPACES.

       01  MODB-RPT-HEADER-3                    PIC X(133)
                                                VALUE ALL '-'.

       01  MODB-RPT-BLANK-LINE                  PIC X(133) VALUE SPACES.

       01  MODB-RPT-ACCOUNT-LINE.
           05  FILLER                           PIC X(09) VALUE
               'Account: '.
           05  MODB-RPT-A-ACCT-ID               PIC 9(11).
           05  FILLER                           PIC X(113) VALUE SPACES.

       01  MODB-RPT-DETAIL-LINE.
           05  MODB-RPT-D-TRAN-ID               PIC X(16).
           05  FILLER                           PIC X(02) VALUE SPACES.
           05  MODB-RPT-D-TRAN-DATE             PIC X(10).
           05  FILLER                           PIC X(02) VALUE SPACES.
           05  MODB-RPT-D-TYPE-CD               PIC X(02).
           05  FILLER                           PIC X(01) VALUE '-'.
           05  MODB-RPT-D-TYPE-DESC             PIC X(20).
           05  FILLER                           PIC X(02) VALUE SPACES.
           05  MODB-RPT-D-CAT-CD                PIC X(04).
           05  FILLER                           PIC X(01) VALUE '-'.
           05  MODB-RPT-D-CAT-DESC              PIC X(26).
           05  FILLER                           PIC X(02) VALUE SPACES.
           05  MODB-RPT-D-MERCHANT              PIC X(25).
           05  FILLER                           PIC X(02) VALUE SPACES.
           05  MODB-RPT-D-AMT                   PIC ----,---,--9.99.
           05  FILLER                           PIC X(03) VALUE SPACES.

       01  MODB-RPT-TYPE-TOTAL.
           05  FILLER                           PIC X(04) VALUE SPACES.
           05  FILLER                           PIC X(05) VALUE
               'Type '.
           05  MODB-RPT-T-TYPE-CD               PIC X(02).
           05  FILLER                           PIC X(06) VALUE
               ' total'.
           05  FILLER                           PIC X(02) VALUE ' ('.
           05  MODB-RPT-T-COUNT                 PIC ZZZ,ZZ9.
           05  FILLER                           PIC X(14) VALUE
               ' transactions)'.
           05  FILLER                           PIC X(73) VALUE ALL '.'.
           05  MODB-RPT-T-AMT                   PIC --,---,---,--9.99.
           05  FILLER                           PIC X(03) VALUE SPACES.

       01  MODB-RPT-ACCOUNT-TOTAL.
           05  FILLER                           PIC X(13) VALUE
               'Account total'.
           05  FILLER                           PIC X(02) VALUE ' ('.
           05  MODB-RPT-AT-COUNT                PIC ZZZ,ZZ9.
           05  FILLER                           PIC X(14) VALUE
               ' transactions)'.
           05  FILLER                           PIC X(77) VALUE ALL '.'.
           05  MODB-RPT-AT-AMT                  PIC --,---,---,--9.99.
           05  FILLER                           PIC X(03) VALUE SPACES.

       01  MODB-RPT-GRAND-TOTAL.
           05  FILLER                           PIC X(11) VALUE
               'Grand total'.
           05  FILLER                           PIC X(02) VALUE ' ('.
           05  MODB-RPT-G-ACCT-COUNT            PIC ZZZ,ZZ9.
           05  FILLER                           PIC X(11) VALUE
               ' accounts, '.
           05  MODB-RPT-G-TRAN-COUNT            PIC ZZZ,ZZ9.
           05  FILLER                           PIC X(14) VALUE
               ' transactions)'.
           05  FILLER                           PIC X(61) VALUE ALL '.'.
           05  MODB-RPT-G-AMT                   PIC --,---,---,--9.99.
           05  FILLER                           PIC X(03) VALUE SPACES.

       01  MODB-RPT-NO-DATA-LINE.
           05  FILLER                           PIC X(40) VALUE
               '*** NO TRANSACTIONS IN DATE RANGE ***'.
           05  FILLER                           PIC X(93) VALUE SPACES.
