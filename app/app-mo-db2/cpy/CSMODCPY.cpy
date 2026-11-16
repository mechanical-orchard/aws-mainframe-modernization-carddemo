      ******************************************************************
      * Copybook    : CSMODCPY
      * Application : CardDemo - app-mo-db2
      * Function    : Common procedures for the app-mo-db2 CICS
      *               programs. Needs working storage copybook
      *               CSMODCWY and the SQLCA.
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
      * Check that WS-DC-DATE is a real date in YYYY-MM-DD form.
      *---------------------------------------------------------------*
       9700-VALIDATE-DATE.
           SET WS-DC-INVALID TO TRUE
           IF  WS-DC-DASH1 = '-'
           AND WS-DC-DASH2 = '-'
           AND WS-DC-YYYY IS NUMERIC
           AND WS-DC-MM   IS NUMERIC
           AND WS-DC-DD   IS NUMERIC
               MOVE WS-DC-YYYY TO WS-DC-YEAR-N
               MOVE WS-DC-MM   TO WS-DC-MONTH-N
               MOVE WS-DC-DD   TO WS-DC-DAY-N
               IF  WS-DC-YEAR-N  > 0
               AND WS-DC-MONTH-N > 0
               AND WS-DC-MONTH-N < 13
                   MOVE WS-DC-DAYS-IN-MONTH(WS-DC-MONTH-N)
                     TO WS-DC-MAX-DAY
                   IF  WS-DC-MONTH-N = 2
                   AND (FUNCTION MOD(WS-DC-YEAR-N, 400) = 0
                    OR (FUNCTION MOD(WS-DC-YEAR-N, 4) = 0
                    AND FUNCTION MOD(WS-DC-YEAR-N, 100) NOT = 0))
                       MOVE 29 TO WS-DC-MAX-DAY
                   END-IF
                   IF  WS-DC-DAY-N > 0
                   AND WS-DC-DAY-N NOT > WS-DC-MAX-DAY
                       SET WS-DC-VALID TO TRUE
                   END-IF
               END-IF
           END-IF.
      *---------------------------------------------------------------*
      * Check that WS-AC-INPUT is an account ID of 1 to 11 digits,
      * with nothing but spaces around it.
      *---------------------------------------------------------------*
       9720-PARSE-ACCOUNT.
           SET WS-AC-INVALID TO TRUE
           MOVE 0 TO WS-AC-NUM
                     WS-AC-LEN
           INSPECT WS-AC-INPUT REPLACING ALL LOW-VALUE BY SPACE
           IF WS-AC-INPUT NOT = SPACES
               MOVE FUNCTION TRIM(WS-AC-INPUT) TO WS-AC-WORK
               INSPECT WS-AC-WORK TALLYING WS-AC-LEN
                       FOR CHARACTERS BEFORE INITIAL SPACE
               IF WS-AC-LEN < 11
                   IF WS-AC-WORK(WS-AC-LEN + 1:) NOT = SPACES
                       MOVE 0 TO WS-AC-LEN
                   END-IF
               END-IF
               IF WS-AC-LEN > 0
                   IF WS-AC-WORK(1:WS-AC-LEN) IS NUMERIC
                       MOVE WS-AC-WORK(1:WS-AC-LEN) TO WS-AC-NUM
                       SET WS-AC-VALID TO TRUE
                   END-IF
               END-IF
           END-IF.
      *---------------------------------------------------------------*
      * Format WS-FMT-AMT for an 11 and a 14 character screen field.
      *---------------------------------------------------------------*
       9710-FORMAT-AMOUNT.
           MOVE WS-FMT-AMT TO WS-FMT-EDIT-LONG
           MOVE WS-FMT-EDIT-LONG TO WS-FMT-AMT-LONG
           IF  WS-FMT-AMT NOT > 9999999.99
           AND WS-FMT-AMT NOT < -9999999.99
               MOVE WS-FMT-AMT TO WS-FMT-EDIT-SHORT
               MOVE WS-FMT-EDIT-SHORT TO WS-FMT-AMT-SHORT
           ELSE
               MOVE ALL '*' TO WS-FMT-AMT-SHORT
           END-IF.
      *---------------------------------------------------------------*
      * Put the failing SQLCODE and its message tokens in
      * WS-DB2-MESSAGE, prefixed by WS-DB2-ACTION. Run it before
      * SYNCPOINT ROLLBACK, which resets the SQLCA. It reads SQLERRMC
      * rather than calling DSNTIAC, so the CICS region needs no
      * extra program definitions for it.
      *---------------------------------------------------------------*
       9800-FORMAT-DB2-MESSAGE.
           MOVE SQLCODE          TO WS-DB2-DISP-CODE
           MOVE WS-DB2-DISP-CODE TO WS-DB2-CODE-X
           MOVE SPACES           TO WS-DB2-ERRMC
                                    WS-DB2-MESSAGE
           MOVE SQLERRML         TO WS-DB2-ERRMC-LEN
           IF WS-DB2-ERRMC-LEN > 70
              MOVE 70 TO WS-DB2-ERRMC-LEN
           END-IF
           IF WS-DB2-ERRMC-LEN > 0
              MOVE SQLERRMC(1:WS-DB2-ERRMC-LEN) TO WS-DB2-ERRMC
              INSPECT WS-DB2-ERRMC REPLACING ALL X'FF' BY SPACE
           END-IF
           STRING FUNCTION TRIM(WS-DB2-ACTION) DELIMITED BY SIZE
                  ' failed. SQLCODE '          DELIMITED BY SIZE
                  FUNCTION TRIM(WS-DB2-CODE-X) DELIMITED BY SIZE
                  ' '                          DELIMITED BY SIZE
                  WS-DB2-ERRMC                 DELIMITED BY SIZE
             INTO WS-DB2-MESSAGE
           END-STRING.
