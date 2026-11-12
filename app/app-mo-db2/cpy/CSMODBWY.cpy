      ******************************************************************
      * Copybook    : CSMODBWY
      * Application : CardDemo - app-mo-db2
      * Function    : Common working storage for the app-mo-db2 batch
      *               programs: file status display, abend, and Db2
      *               error message formatting with DSNTIAR.
      *               Used with procedure copybook CSMODBPY.
      *
      *   Abend codes set in ABCODE before 9999-ABEND-PROGRAM:
      *     997  Invalid run parameters
      *     998  Unexpected SQLCODE
      *     999  File I/O error
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
       01  IO-STATUS.
           05  IO-STAT1                         PIC X.
           05  IO-STAT2                         PIC X.
       01  TWO-BYTES-BINARY                     PIC 9(4) BINARY.
       01  TWO-BYTES-ALPHA                      REDEFINES
           TWO-BYTES-BINARY.
           05  TWO-BYTES-LEFT                   PIC X.
           05  TWO-BYTES-RIGHT                  PIC X.
       01  IO-STATUS-04.
           05  IO-STATUS-0401                   PIC 9   VALUE 0.
           05  IO-STATUS-0403                   PIC 999 VALUE 0.

       01  ABCODE                               PIC S9(9) BINARY.
       01  TIMING                               PIC S9(9) BINARY.

       01  WS-SQL-ERROR-INFO.
           05  WS-SQL-ACTION                    PIC X(40) VALUE SPACES.
           05  WS-SQL-DISP-CODE                 PIC -(9)9.

       01  WS-DSNTIAR-MSG.
           05  WS-DSNTIAR-LEN                   PIC S9(4) COMP
                                                VALUE +720.
           05  WS-DSNTIAR-TEXT                  PIC X(72)
                                                OCCURS 10 TIMES
                                                INDEXED BY
                                                WS-DSNTIAR-IX.
       01  WS-DSNTIAR-LRECL                     PIC S9(9) COMP
                                                VALUE +72.
