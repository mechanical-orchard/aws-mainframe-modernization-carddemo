      ******************************************************************
      * Copybook    : CVMOD02Y
      * Application : CardDemo - app-mo-db2
      * Function    : Reject record written by CBMOD01C to DD REJFILE
      *               (LRECL 430): the transaction record as read
      *               from TRANSACT, followed by an 80 byte trailer.
      *               Same shape as the base DALYREJS record.
      *
      *   Reason codes:
      *     0100  Card number not found in CARDXREF
      *     0101  Original timestamp is not a valid timestamp
      *     0102  Processing timestamp is not a valid timestamp
      *     0103  Db2 rejected a date or timestamp (SQLCODE set)
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
       01  MODB-REJECT-RECORD.
           05  MODB-REJ-TRAN-DATA               PIC X(350).
           05  MODB-REJ-TRAILER.
               10  MODB-REJ-REASON-CD           PIC 9(04).
               10  MODB-REJ-REASON-DESC         PIC X(60).
               10  MODB-REJ-SQLCODE             PIC -(9)9.
               10  FILLER                       PIC X(06).
