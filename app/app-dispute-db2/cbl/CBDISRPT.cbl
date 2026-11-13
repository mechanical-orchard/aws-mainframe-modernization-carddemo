      ******************************************************************
      * Program:  CBDISRPT.CBL                                         *
      * Layer:    Business logic (Batch / Db2)                         *
      * Function: Dispute Aging Report.                                *
      *           Reads all OPEN disputes (joined to DISPUTE_STATUS    *
      *           where DST_OPEN_FLAG = 'Y'), prints one detail line   *
      *           per dispute with its age in days, flags rows aged    *
      *           over 60 days as ESCALATION CANDIDATE, tallies aging  *
      *           buckets (0-30 / 31-60 / 61+) and prints a per-status *
      *           summary (count and summed amount).                   *
      *           Read-only; no COMMIT required.                       *
      *           Report is written to DD REPORT (SYSOUT, 132 col).    *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBDISRPT.

       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REPORT-FILE ASSIGN TO REPORT
                  ORGANIZATION IS SEQUENTIAL
                  ACCESS MODE IS SEQUENTIAL
                  FILE STATUS IS WS-RPT-STATUS.

       DATA DIVISION.

       FILE SECTION.
       FD REPORT-FILE RECORDING MODE F.
       01 REPORT-REC                             PIC X(132).

       WORKING-STORAGE SECTION.

           EXEC SQL
               INCLUDE SQLCA
           END-EXEC

           EXEC SQL INCLUDE DCLDISP END-EXEC

           EXEC SQL INCLUDE DCLDSTS END-EXEC

      ******************************************************************
      * DETAIL CURSOR - OPEN DISPUTES WITH COMPUTED AGE IN DAYS        *
      ******************************************************************
           EXEC SQL
               DECLARE C-AGING CURSOR FOR
               SELECT A.DISP_ID, A.DISP_CARD_NUM, A.DISP_AMT,
                      A.DISP_STATUS_CD, B.DST_STATUS_DESC,
                      DAYS(CURRENT DATE) - DAYS(DATE(A.DISP_OPEN_TS))
                      AS AGE_DAYS
                 FROM CARDDEMO.DISPUTE A, CARDDEMO.DISPUTE_STATUS B
                WHERE A.DISP_STATUS_CD = B.DST_STATUS_CD
                  AND B.DST_OPEN_FLAG = 'Y'
                ORDER BY AGE_DAYS DESC, A.DISP_ID
           END-EXEC

      ******************************************************************
      * SUMMARY CURSOR - COUNT AND SUMMED AMOUNT PER STATUS           *
      ******************************************************************
           EXEC SQL
               DECLARE C-SUMMARY CURSOR FOR
               SELECT A.DISP_STATUS_CD, B.DST_STATUS_DESC,
                      COUNT(*), SUM(A.DISP_AMT)
                 FROM CARDDEMO.DISPUTE A, CARDDEMO.DISPUTE_STATUS B
                WHERE A.DISP_STATUS_CD = B.DST_STATUS_CD
                GROUP BY A.DISP_STATUS_CD, B.DST_STATUS_DESC
                ORDER BY A.DISP_STATUS_CD
           END-EXEC

       01 WS-HOST-VARS.
          05 WS-AGE-DAYS                          PIC S9(5) COMP-3.
          05 WS-SUM-COUNT                         PIC S9(9) COMP-3.
          05 WS-SUM-AMT                           PIC S9(13)V99 COMP-3.

       01 WS-RPT-STATUS.
          05 WS-RPT-STAT1                         PIC X.
          05 WS-RPT-STAT2                         PIC X.

       01 WS-FLAGS.
          05 WS-END-CURSOR                        PIC X VALUE 'N'.
          05 WS-END-SUMMARY                       PIC X VALUE 'N'.

       01 WS-MISC-VARS.
          05 WS-VAR-SQLCODE                       PIC ----9.
          05 WS-RETURN-MSG                        PIC X(80).

       01 WS-COUNTERS.
          05 WS-TOT-OPEN                          PIC 9(7) VALUE 0.
          05 WS-BKT-0-30                          PIC 9(7) VALUE 0.
          05 WS-BKT-31-60                         PIC 9(7) VALUE 0.
          05 WS-BKT-61                            PIC 9(7) VALUE 0.

       01 WS-CURRENT-DATE-DATA.
          05 WS-CURR-DATE.
             10 WS-CURR-YYYY                       PIC 9(4).
             10 WS-CURR-MM                         PIC 9(2).
             10 WS-CURR-DD                         PIC 9(2).
          05 FILLER                               PIC X(13).

       01 WS-DATE-EDIT.
          05 WDE-MM                               PIC 99.
          05 FILLER                               PIC X VALUE '/'.
          05 WDE-DD                               PIC 99.
          05 FILLER                               PIC X VALUE '/'.
          05 WDE-YYYY                             PIC 9999.

       01 WS-BLANK-LINE                           PIC X(132)
                                                  VALUE SPACES.

       01 WS-TITLE-LINE.
          05 FILLER                    PIC X(45) VALUE SPACES.
          05 FILLER                    PIC X(29)
                            VALUE 'CARDDEMO DISPUTE AGING REPORT'.
          05 FILLER                    PIC X(58) VALUE SPACES.

       01 WS-DATE-LINE.
          05 FILLER                    PIC X(10) VALUE 'RUN DATE: '.
          05 WDL-DATE                   PIC X(10) VALUE SPACES.
          05 FILLER                    PIC X(112) VALUE SPACES.

       01 WS-COLHDR-LINE.
          05 FILLER                    PIC X(12) VALUE 'DISPUTE ID'.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 FILLER                    PIC X(16) VALUE 'CARD NUMBER'.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 FILLER                    PIC X(17)
                                       VALUE '           AMOUNT'.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 FILLER                    PIC X(2)  VALUE 'ST'.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 FILLER                    PIC X(30)
                                       VALUE 'STATUS DESCRIPTION'.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 FILLER                    PIC X(5)  VALUE '  AGE'.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 FILLER                    PIC X(22) VALUE 'FLAG'.
          05 FILLER                    PIC X(16) VALUE SPACES.

       01 WS-DETAIL-LINE.
          05 DL-DISP-ID                PIC X(12).
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 DL-CARD-NUM               PIC X(16).
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 DL-AMT                    PIC -Z,ZZZ,ZZZ,ZZ9.99.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 DL-STATUS-CD              PIC X(2).
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 DL-STATUS-DESC            PIC X(30).
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 DL-AGE                    PIC ZZZZ9.
          05 FILLER                    PIC X(2)  VALUE SPACES.
          05 DL-FLAG                   PIC X(22).
          05 FILLER                    PIC X(16) VALUE SPACES.

       01 WS-SUMHDR-LINE.
          05 FILLER                    PIC X(132)
                                       VALUE 'SUMMARY BY STATUS'.

       01 WS-SUMCOL-LINE.
          05 FILLER                    PIC X(2)  VALUE 'ST'.
          05 FILLER                    PIC X(4)  VALUE SPACES.
          05 FILLER                    PIC X(30)
                                       VALUE 'STATUS DESCRIPTION'.
          05 FILLER                    PIC X(4)  VALUE SPACES.
          05 FILLER                    PIC X(8)  VALUE '   COUNT'.
          05 FILLER                    PIC X(4)  VALUE SPACES.
          05 FILLER                    PIC X(21)
                                       VALUE '         TOTAL AMOUNT'.
          05 FILLER                    PIC X(59) VALUE SPACES.

       01 WS-SUMMARY-LINE.
          05 SL-STATUS-CD              PIC X(2).
          05 FILLER                    PIC X(4)  VALUE SPACES.
          05 SL-STATUS-DESC            PIC X(30).
          05 FILLER                    PIC X(4)  VALUE SPACES.
          05 SL-COUNT                  PIC ZZZZZZZ9.
          05 FILLER                    PIC X(4)  VALUE SPACES.
          05 SL-AMT                    PIC -Z,ZZZ,ZZZ,ZZZ,ZZ9.99.
          05 FILLER                    PIC X(59) VALUE SPACES.

       01 WS-BUCKET-LINE.
          05 BL-LABEL                  PIC X(30).
          05 BL-COUNT                  PIC ZZZZZZZ9.
          05 FILLER                    PIC X(94) VALUE SPACES.

       PROCEDURE DIVISION.

       0000-MAIN.
           PERFORM 0100-INIT
           PERFORM 0200-PRINT-HEADINGS
           PERFORM 1000-PROCESS-DETAIL
           PERFORM 2000-PROCESS-SUMMARY
           PERFORM 3000-PRINT-BUCKETS
           PERFORM 9000-CLOSE-STOP
           STOP RUN.

       0100-INIT.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE-DATA
           MOVE WS-CURR-MM   TO WDE-MM
           MOVE WS-CURR-DD   TO WDE-DD
           MOVE WS-CURR-YYYY TO WDE-YYYY
           MOVE WS-DATE-EDIT TO WDL-DATE
           OPEN OUTPUT REPORT-FILE
           IF WS-RPT-STATUS = '00'
              DISPLAY 'OPEN REPORT FILE OK'
           ELSE
              DISPLAY 'OPEN REPORT FILE NOT OK - STATUS: '
                      WS-RPT-STATUS
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF
           EXIT.

       0200-PRINT-HEADINGS.
           WRITE REPORT-REC FROM WS-TITLE-LINE
           WRITE REPORT-REC FROM WS-DATE-LINE
           WRITE REPORT-REC FROM WS-BLANK-LINE
           WRITE REPORT-REC FROM WS-COLHDR-LINE
           WRITE REPORT-REC FROM WS-BLANK-LINE
           EXIT.

       1000-PROCESS-DETAIL.
           EXEC SQL OPEN C-AGING END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN OTHER
                  STRING 'Error opening C-AGING cursor. SQLCODE:'
                         WS-VAR-SQLCODE
                     DELIMITED BY SIZE INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-SQL-ERROR
           END-EVALUATE
           PERFORM 1100-FETCH-DETAIL
           PERFORM UNTIL WS-END-CURSOR = 'Y'
               PERFORM 1200-WRITE-DETAIL
               PERFORM 1100-FETCH-DETAIL
           END-PERFORM
           EXEC SQL CLOSE C-AGING END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           IF SQLCODE < 0
              STRING 'Error closing C-AGING cursor. SQLCODE:'
                     WS-VAR-SQLCODE
                 DELIMITED BY SIZE INTO WS-RETURN-MSG
              END-STRING
              PERFORM 9999-SQL-ERROR
           END-IF
           EXIT.

       1100-FETCH-DETAIL.
           EXEC SQL
               FETCH C-AGING
                INTO :DCL-DISP-ID,
                     :DCL-DISP-CARD-NUM,
                     :DCL-DISP-AMT,
                     :DCL-DISP-STATUS-CD,
                     :DCL-DST-STATUS-DESC,
                     :WS-AGE-DAYS
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN SQLCODE = +100
                  MOVE 'Y' TO WS-END-CURSOR
               WHEN OTHER
                  STRING 'Error fetching DISPUTE aging. SQLCODE:'
                         WS-VAR-SQLCODE
                     DELIMITED BY SIZE INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-SQL-ERROR
           END-EVALUATE
           EXIT.

       1200-WRITE-DETAIL.
           ADD 1 TO WS-TOT-OPEN
           EVALUATE TRUE
               WHEN WS-AGE-DAYS <= 30
                  ADD 1 TO WS-BKT-0-30
               WHEN WS-AGE-DAYS <= 60
                  ADD 1 TO WS-BKT-31-60
               WHEN OTHER
                  ADD 1 TO WS-BKT-61
           END-EVALUATE
           MOVE DCL-DISP-ID              TO DL-DISP-ID
           MOVE DCL-DISP-CARD-NUM        TO DL-CARD-NUM
           MOVE DCL-DISP-AMT             TO DL-AMT
           MOVE DCL-DISP-STATUS-CD       TO DL-STATUS-CD
           MOVE DCL-DST-STATUS-DESC-TEXT TO DL-STATUS-DESC
           MOVE WS-AGE-DAYS              TO DL-AGE
           IF WS-AGE-DAYS > 60
              MOVE 'ESCALATION CANDIDATE' TO DL-FLAG
           ELSE
              MOVE SPACES                 TO DL-FLAG
           END-IF
           WRITE REPORT-REC FROM WS-DETAIL-LINE
           EXIT.

       2000-PROCESS-SUMMARY.
           WRITE REPORT-REC FROM WS-BLANK-LINE
           WRITE REPORT-REC FROM WS-SUMHDR-LINE
           WRITE REPORT-REC FROM WS-BLANK-LINE
           WRITE REPORT-REC FROM WS-SUMCOL-LINE
           WRITE REPORT-REC FROM WS-BLANK-LINE
           EXEC SQL OPEN C-SUMMARY END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN OTHER
                  STRING 'Error opening C-SUMMARY cursor. SQLCODE:'
                         WS-VAR-SQLCODE
                     DELIMITED BY SIZE INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-SQL-ERROR
           END-EVALUATE
           PERFORM 2100-FETCH-SUMMARY
           PERFORM UNTIL WS-END-SUMMARY = 'Y'
               PERFORM 2200-WRITE-SUMMARY
               PERFORM 2100-FETCH-SUMMARY
           END-PERFORM
           EXEC SQL CLOSE C-SUMMARY END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           IF SQLCODE < 0
              STRING 'Error closing C-SUMMARY cursor. SQLCODE:'
                     WS-VAR-SQLCODE
                 DELIMITED BY SIZE INTO WS-RETURN-MSG
              END-STRING
              PERFORM 9999-SQL-ERROR
           END-IF
           EXIT.

       2100-FETCH-SUMMARY.
           EXEC SQL
               FETCH C-SUMMARY
                INTO :DCL-DISP-STATUS-CD,
                     :DCL-DST-STATUS-DESC,
                     :WS-SUM-COUNT,
                     :WS-SUM-AMT
           END-EXEC
           MOVE SQLCODE TO WS-VAR-SQLCODE
           EVALUATE TRUE
               WHEN SQLCODE = ZERO
                  CONTINUE
               WHEN SQLCODE = +100
                  MOVE 'Y' TO WS-END-SUMMARY
               WHEN OTHER
                  STRING 'Error fetching DISPUTE summary. SQLCODE:'
                         WS-VAR-SQLCODE
                     DELIMITED BY SIZE INTO WS-RETURN-MSG
                  END-STRING
                  PERFORM 9999-SQL-ERROR
           END-EVALUATE
           EXIT.

       2200-WRITE-SUMMARY.
           MOVE DCL-DISP-STATUS-CD       TO SL-STATUS-CD
           MOVE DCL-DST-STATUS-DESC-TEXT TO SL-STATUS-DESC
           MOVE WS-SUM-COUNT             TO SL-COUNT
           MOVE WS-SUM-AMT               TO SL-AMT
           WRITE REPORT-REC FROM WS-SUMMARY-LINE
           EXIT.

       3000-PRINT-BUCKETS.
           WRITE REPORT-REC FROM WS-BLANK-LINE
           MOVE 'DISPUTES AGED 0-30 DAYS:'   TO BL-LABEL
           MOVE WS-BKT-0-30                  TO BL-COUNT
           WRITE REPORT-REC FROM WS-BUCKET-LINE
           MOVE 'DISPUTES AGED 31-60 DAYS:'  TO BL-LABEL
           MOVE WS-BKT-31-60                 TO BL-COUNT
           WRITE REPORT-REC FROM WS-BUCKET-LINE
           MOVE 'DISPUTES AGED 61+ DAYS:'    TO BL-LABEL
           MOVE WS-BKT-61                    TO BL-COUNT
           WRITE REPORT-REC FROM WS-BUCKET-LINE
           MOVE 'TOTAL OPEN DISPUTES:'       TO BL-LABEL
           MOVE WS-TOT-OPEN                  TO BL-COUNT
           WRITE REPORT-REC FROM WS-BUCKET-LINE
           EXIT.

       9000-CLOSE-STOP.
           CLOSE REPORT-FILE
           EXIT.

       9999-SQL-ERROR.
           DISPLAY WS-RETURN-MSG
           MOVE 8 TO RETURN-CODE
           CLOSE REPORT-FILE
           STOP RUN.
