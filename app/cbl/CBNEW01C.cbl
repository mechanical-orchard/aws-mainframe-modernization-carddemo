      ******************************************************************
      * Program     : CBNEW01C.CBL
      * Application : CardDemo
      * Type        : BATCH COBOL Program
      * Function    : Standalone source-addition reference fixture.
      ******************************************************************
      * Copyright (c) 2026 Mechanical Orchard, Inc.
      * All Rights Reserved.
      *
      * Licensed under the Apache License, Version 2.0 (the "License").
      * You may not use this file except in compliance with the License.
      * You may obtain a copy of the License at
      *
      *    http://www.apache.org/licenses/LICENSE-2.0
      *
      * Unless required by applicable law or agreed to in writing,
      * software distributed under the License is distributed on an
      * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
      * either express or implied. See the License for the specific
      * language governing permissions and limitations under the License.
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBNEW01C.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-MESSAGE PIC X(32) VALUE 'MT-1676 ADDED SOURCE FIXTURE'.

       PROCEDURE DIVISION.
           DISPLAY WS-MESSAGE
           GOBACK.
