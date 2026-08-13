      ******************************************************************
      * Program:  COBDSUPD.CBL                                         *
      * Layer:    Business logic (Batch / Db2)                         *
      * Function: File-driven dispute maintenance.                     *
      *           Reads sequential INPFILE and applies each record to  *
      *           the CARDDEMO.DISPUTE table, logging status changes   *
      *           to CARDDEMO.DISPUTE_HISTORY.                         *
      *                                                                *
      *           INPUT RECORD LAYOUT (LRECL 15):                      *
      *             COL 1       ACTION -                               *
      *                           U = UPDATE STATUS                    *
      *                           D = DELETE DISPUTE                   *
      *                           * = COMMENT (IGNORED)                *
      *             COLS 2-13    DISP_ID          (12 CHARS)           *
      *             COLS 14-15   NEW STATUS CODE  ( 2 CHARS, 'U' ONLY) *
      *                                                                *
      *           'U' updates DISP_STATUS_CD + DISP_LAST_UPD_TS and    *
      *               inserts a DISPUTE_HISTORY row (next sequence,    *
      *               prior status as from-status, user 'BATCH   ').   *
      *           'D' deletes the dispute (history cascades via FK).   *
      *           No explicit COMMIT (implicit at end under the plan). *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBDSUPD.

       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DS-RECORD ASSIGN TO INPFILE
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE IS SEQUENTIAL
                  FILE STATUS IS WS-INF-STATUS.

       DATA DIVISION.

       FILE SECTION.
       FD DS-RECORD RECORDING MODE F.
       01 WS-INPUT-VARS.
          05 INPUT-TYPE                            PIC X(1)
                                                   VALUE SPACES.
          05 INPUT-DISP-ID                         PIC X(12)
                                                   VALUE SPACES.
          05 INPUT-STATUS                          PIC X(2)
                                                   VALUE SPACES.

       WORKING-STORAGE SECTION.

           EXEC SQL
               INCLUDE SQLCA
           END-EXEC

           EXEC SQL INCLUDE DCLDISP END-EXEC

           EXEC SQL INCLUDE DCLDSTS END-EXEC

           EXEC SQL INCLUDE DCLDSHS END-EXEC

       01 FLAGS.
          05 LASTREC                               PIC X(1)
                                                   VALUE SPACES.

       01 WORKING-VARIABLES.
          05 WS-RETURN-MSG                         PIC X(80)
                                                   VALUE SPACES.

       01 WS-MISC-VARS.
          05 WS-VAR-SQLCODE                        PIC ----9.

       01 WS-HOST-VARS.
          05 WS-FROM-STATUS                        PIC X(2).
          05 WS-NEXT-SEQ                           PIC S9(4) USAGE COMP.

       01 WS-INF-STATUS.
          05 WS-INF-STAT1                          PIC X.
          05 WS-INF-STAT2                          PIC X.

       01 WS-INPUT-REC.
          05 INPUT-REC-TYPE                        PIC X(1)
                                                   VALUE SPACES.
          05 INPUT-REC-DISP-ID                     PIC X(12)
                                                   VALUE SPACES.
          05 INPUT-REC-STATUS                      PIC X(2)
                                                   VALUE SPACES.

       PROCEDURE DIVISION.

       0001-OPEN-FILES.
           OPEN INPUT DS-RECORD.
           IF WS-INF-STATUS = '00' THEN
              DISPLAY 'OPEN FILE OK'
           ELSE
              DISPLAY 'OPEN FILE NOT OK'
           END-IF
           EXIT.

       1001-READ-NEXT-RECORDS.
              PERFORM 1002-READ-RECORDS
           PERFORM UNTIL LASTREC = 'Y'
              PERFORM 1003-TREAT-RECORD
              PERFORM 1002-READ-RECORDS
           END-PERFORM.
           PERFORM 2001-CLOSE-STOP
           EXIT.
           STOP RUN.

       1002-READ-RECORDS.
           READ DS-RECORD NEXT RECORD INTO WS-INPUT-REC
           AT END MOVE 'Y' TO LASTREC
           END-READ.
           IF LASTREC NOT EQUAL TO 'Y' THEN
              DISPLAY 'PROCESSING   ' WS-INPUT-REC
           END-IF.
           EXIT.

       1003-TREAT-RECORD.
           EVALUATE INPUT-REC-TYPE
               WHEN 'U'
                   DISPLAY 'UPDATING DISPUTE STATUS'
                   PERFORM 10032-UPDATE-DB
               WHEN 'D'
                   DISPLAY 'DELETING DISPUTE'
                   PERFORM 10033-DELETE-DB
               WHEN '*'
                   DISPLAY 'IGNORING COMMENTED LINE'
               WHEN OTHER
                  STRING
                  'ERROR: TYPE NOT VALID'
                  DELIMITED BY SIZE
                  INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
           END-EVALUATE.
           EXIT.

       10032-UPDATE-DB.
      ******************************************************************
      * SQL TO UPDATE THE DISPUTE STATUS AND LOG THE CHANGE            *
      ******************************************************************
      *
      * STEP 1 - READ THE CURRENT (FROM) STATUS BEFORE UPDATING
           EXEC SQL
                SELECT DISP_STATUS_CD
                  INTO :WS-FROM-STATUS
                  FROM CARDDEMO.DISPUTE
                 WHERE DISP_ID = :INPUT-REC-DISP-ID
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN SQLCODE = +100
                  STRING 'No records found.' DELIMITED BY SIZE
                     INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
               WHEN SQLCODE < 0
                  STRING
                  'Error accessing:'
                  ' DISPUTE table. SQLCODE:'
                  WS-VAR-SQLCODE
                  DELIMITED BY SIZE
                  INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
           END-EVALUATE
      *
      * STEP 2 - UPDATE THE DISPUTE STATUS
           EXEC SQL
                UPDATE CARDDEMO.DISPUTE
                   SET DISP_STATUS_CD = :INPUT-REC-STATUS,
                       DISP_LAST_UPD_TS = CURRENT TIMESTAMP
                 WHERE DISP_ID = :INPUT-REC-DISP-ID
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  DISPLAY 'DISPUTE STATUS UPDATED SUCCESSFULLY'
               WHEN SQLCODE = +100
                  STRING 'No records found.' DELIMITED BY SIZE
                     INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
               WHEN SQLCODE < 0
                  STRING
                  'Error accessing:'
                  ' DISPUTE table. SQLCODE:'
                  WS-VAR-SQLCODE
                  DELIMITED BY SIZE
                  INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
           END-EVALUATE
      *
      * STEP 3 - COMPUTE THE NEXT HISTORY SEQUENCE NUMBER
           EXEC SQL
                SELECT COALESCE(MAX(DSH_SEQ), 0) + 1
                  INTO :WS-NEXT-SEQ
                  FROM CARDDEMO.DISPUTE_HISTORY
                 WHERE DSH_DISP_ID = :INPUT-REC-DISP-ID
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN SQLCODE < 0
                  STRING
                  'Error accessing:'
                  ' DISPUTE_HISTORY table. SQLCODE:'
                  WS-VAR-SQLCODE
                  DELIMITED BY SIZE
                  INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
           END-EVALUATE
      *
      * STEP 4 - INSERT THE DISPUTE HISTORY ROW
           EXEC SQL
                INSERT INTO CARDDEMO.DISPUTE_HISTORY
                (
                DSH_DISP_ID,
                DSH_SEQ,
                DSH_FROM_STATUS,
                DSH_TO_STATUS,
                DSH_CHG_TS,
                DSH_CHG_USER,
                DSH_NOTE
                )
                VALUES
                (
                :INPUT-REC-DISP-ID,
                :WS-NEXT-SEQ,
                :WS-FROM-STATUS,
                :INPUT-REC-STATUS,
                CURRENT TIMESTAMP,
                'BATCH   ',
                'Batch status update'
                )
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  DISPLAY 'DISPUTE HISTORY LOGGED SUCCESSFULLY'
               WHEN SQLCODE < 0
                  STRING
                  'Error accessing:'
                  ' DISPUTE_HISTORY table. SQLCODE:'
                  WS-VAR-SQLCODE
                  DELIMITED BY SIZE
                  INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
           END-EVALUATE
           EXIT.

       10033-DELETE-DB.
      ******************************************************************
      * SQL TO DELETE THE DISPUTE (HISTORY CASCADES VIA FK)           *
      ******************************************************************
      *
           EXEC SQL
                DELETE FROM CARDDEMO.DISPUTE
                 WHERE DISP_ID = :INPUT-REC-DISP-ID
           END-EXEC.
           MOVE SQLCODE TO WS-VAR-SQLCODE

           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  DISPLAY 'DISPUTE DELETED SUCCESSFULLY'
               WHEN SQLCODE = +100
               STRING 'No records found.' DELIMITED BY SIZE
               INTO WS-RETURN-MSG
               END-STRING
               PERFORM 9999-ABEND

               WHEN SQLCODE < 0
                  STRING
                  'Error accessing:'
                  ' DISPUTE table. SQLCODE:'
                  WS-VAR-SQLCODE
                  DELIMITED BY SIZE
                  INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-ABEND
           END-EVALUATE
           EXIT.

       9999-ABEND.
           DISPLAY WS-RETURN-MSG.
           MOVE 4 TO RETURN-CODE
           EXIT.
       2001-CLOSE-STOP.
           CLOSE DS-RECORD.
           EXIT.
