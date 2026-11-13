      ******************************************************************
      * Copybook    : CSMODBPY
      * Application : CardDemo - app-mo-db2
      * Function    : Common procedures for the app-mo-db2 batch
      *               programs. COPY at the end of the PROCEDURE
      *               DIVISION, with CSMODBWY in WORKING-STORAGE and
      *               the SQLCA included.
      *               Contains no SQL, so the Db2 precompiler does not
      *               need to see it.
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
      *---------------------------------------------------------------*
      * Display the failing SQLCODE and the DSNTIAR formatted message.
      * Run before ROLLBACK, which resets the SQLCA.
      *---------------------------------------------------------------*
       9810-DISPLAY-SQL-ERROR.
           MOVE SQLCODE TO WS-SQL-DISP-CODE
           DISPLAY 'DB2 ERROR DURING: ' WS-SQL-ACTION
           DISPLAY 'SQLCODE : ' WS-SQL-DISP-CODE
           DISPLAY 'SQLSTATE: ' SQLSTATE
           CALL 'DSNTIAR' USING SQLCA
                                WS-DSNTIAR-MSG
                                WS-DSNTIAR-LRECL
           IF RETURN-CODE = ZERO
              PERFORM VARYING WS-DSNTIAR-IX FROM 1 BY 1
                        UNTIL WS-DSNTIAR-IX > 10
                 IF WS-DSNTIAR-TEXT(WS-DSNTIAR-IX) NOT = SPACES
                    DISPLAY WS-DSNTIAR-TEXT(WS-DSNTIAR-IX)
                 END-IF
              END-PERFORM
           ELSE
              DISPLAY 'DSNTIAR RETURN CODE: ' RETURN-CODE
           END-IF.
      *---------------------------------------------------------------*
       9910-DISPLAY-IO-STATUS.
           IF  IO-STATUS NOT NUMERIC
           OR  IO-STAT1 = '9'
               MOVE IO-STAT1 TO IO-STATUS-04(1:1)
               MOVE 0        TO TWO-BYTES-BINARY
               MOVE IO-STAT2 TO TWO-BYTES-RIGHT
               MOVE TWO-BYTES-BINARY TO IO-STATUS-0403
               DISPLAY 'FILE STATUS IS: NNNN' IO-STATUS-04
           ELSE
               MOVE '0000' TO IO-STATUS-04
               MOVE IO-STATUS TO IO-STATUS-04(3:2)
               DISPLAY 'FILE STATUS IS: NNNN' IO-STATUS-04
           END-IF.
      *---------------------------------------------------------------*
      * Set ABCODE before performing this paragraph.
      *---------------------------------------------------------------*
       9999-ABEND-PROGRAM.
           DISPLAY 'ABENDING PROGRAM WITH CODE ' ABCODE
           MOVE 0 TO TIMING
           CALL 'CEE3ABD' USING ABCODE, TIMING.
