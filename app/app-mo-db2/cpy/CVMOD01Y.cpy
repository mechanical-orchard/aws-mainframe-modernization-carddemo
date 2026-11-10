      ******************************************************************
      * Copybook    : CVMOD01Y
      * Application : CardDemo - app-mo-db2
      * Function    : Run parameter record read from DD PARMFILE
      *               (LRECL 80) by the app-mo-db2 batch programs.
      *
      *   Cols  1-10  START-DATE  YYYY-MM-DD
      *               CBMOD02C - balance date
      *               CBMOD03C - first date of the report range
      *               CBMOD04C - as-of date
      *   Cols 12-21  END-DATE    YYYY-MM-DD
      *               CBMOD03C - last date of the report range
      *   Cols 23-26  RETAIN-DAYS NNNN
      *               CBMOD04C - days of TRAN_HIST history to keep
      *
      * The layout of cols 1-21 matches the base DATEPARM record.
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
       01  MODB-PARM-RECORD.
           05  MODB-PARM-START-DATE             PIC X(10).
           05  FILLER                           PIC X(01).
           05  MODB-PARM-END-DATE               PIC X(10).
           05  FILLER                           PIC X(01).
           05  MODB-PARM-RETAIN-DAYS            PIC X(04).
           05  FILLER                           PIC X(54).
