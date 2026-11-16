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
       01  CMODUPAI.
           02  FILLER PIC X(12).
           02  TRNNAMEL    COMP  PIC  S9(4).
           02  TRNNAMEF    PICTURE X.
           02  FILLER REDEFINES TRNNAMEF.
             03 TRNNAMEA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  TRNNAMEI  PIC X(4).
           02  TITLE01L    COMP  PIC  S9(4).
           02  TITLE01F    PICTURE X.
           02  FILLER REDEFINES TITLE01F.
             03 TITLE01A    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  TITLE01I  PIC X(40).
           02  CURDATEL    COMP  PIC  S9(4).
           02  CURDATEF    PICTURE X.
           02  FILLER REDEFINES CURDATEF.
             03 CURDATEA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  CURDATEI  PIC X(8).
           02  PGMNAMEL    COMP  PIC  S9(4).
           02  PGMNAMEF    PICTURE X.
           02  FILLER REDEFINES PGMNAMEF.
             03 PGMNAMEA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  PGMNAMEI  PIC X(8).
           02  TITLE02L    COMP  PIC  S9(4).
           02  TITLE02F    PICTURE X.
           02  FILLER REDEFINES TITLE02F.
             03 TITLE02A    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  TITLE02I  PIC X(40).
           02  CURTIMEL    COMP  PIC  S9(4).
           02  CURTIMEF    PICTURE X.
           02  FILLER REDEFINES CURTIMEF.
             03 CURTIMEA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  CURTIMEI  PIC X(8).
           02  ACCTIDL    COMP  PIC  S9(4).
           02  ACCTIDF    PICTURE X.
           02  FILLER REDEFINES ACCTIDF.
             03 ACCTIDA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  ACCTIDI  PIC X(11).
           02  BALDATEL    COMP  PIC  S9(4).
           02  BALDATEF    PICTURE X.
           02  FILLER REDEFINES BALDATEF.
             03 BALDATEA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  BALDATEI  PIC X(10).
           02  OPENBALL    COMP  PIC  S9(4).
           02  OPENBALF    PICTURE X.
           02  FILLER REDEFINES OPENBALF.
             03 OPENBALA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  OPENBALI  PIC X(14).
           02  CRLIMITL    COMP  PIC  S9(4).
           02  CRLIMITF    PICTURE X.
           02  FILLER REDEFINES CRLIMITF.
             03 CRLIMITA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  CRLIMITI  PIC X(14).
           02  CREDITSL    COMP  PIC  S9(4).
           02  CREDITSF    PICTURE X.
           02  FILLER REDEFINES CREDITSF.
             03 CREDITSA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  CREDITSI  PIC X(14).
           02  CLOSBALL    COMP  PIC  S9(4).
           02  CLOSBALF    PICTURE X.
           02  FILLER REDEFINES CLOSBALF.
             03 CLOSBALA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  CLOSBALI  PIC X(14).
           02  DEBITSL    COMP  PIC  S9(4).
           02  DEBITSF    PICTURE X.
           02  FILLER REDEFINES DEBITSF.
             03 DEBITSA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DEBITSI  PIC X(14).
           02  TRANCNTL    COMP  PIC  S9(4).
           02  TRANCNTF    PICTURE X.
           02  FILLER REDEFINES TRANCNTF.
             03 TRANCNTA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  TRANCNTI  PIC X(11).
           02  THCOUNTL    COMP  PIC  S9(4).
           02  THCOUNTF    PICTURE X.
           02  FILLER REDEFINES THCOUNTF.
             03 THCOUNTA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  THCOUNTI  PIC X(11).
           02  THNETL    COMP  PIC  S9(4).
           02  THNETF    PICTURE X.
           02  FILLER REDEFINES THNETF.
             03 THNETA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  THNETI  PIC X(14).
           02  THCREDL    COMP  PIC  S9(4).
           02  THCREDF    PICTURE X.
           02  FILLER REDEFINES THCREDF.
             03 THCREDA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  THCREDI  PIC X(14).
           02  THDEBTL    COMP  PIC  S9(4).
           02  THDEBTF    PICTURE X.
           02  FILLER REDEFINES THDEBTF.
             03 THDEBTA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  THDEBTI  PIC X(14).
           02  CURFLGL    COMP  PIC  S9(4).
           02  CURFLGF    PICTURE X.
           02  FILLER REDEFINES CURFLGF.
             03 CURFLGA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  CURFLGI  PIC X(1).
           02  FLGDATEL    COMP  PIC  S9(4).
           02  FLGDATEF    PICTURE X.
           02  FILLER REDEFINES FLGDATEF.
             03 FLGDATEA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  FLGDATEI  PIC X(10).
           02  NEWFLGL    COMP  PIC  S9(4).
           02  NEWFLGF    PICTURE X.
           02  FILLER REDEFINES NEWFLGF.
             03 NEWFLGA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  NEWFLGI  PIC X(1).
           02  INFOMSGL    COMP  PIC  S9(4).
           02  INFOMSGF    PICTURE X.
           02  FILLER REDEFINES INFOMSGF.
             03 INFOMSGA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  INFOMSGI  PIC X(60).
           02  ERRMSGL    COMP  PIC  S9(4).
           02  ERRMSGF    PICTURE X.
           02  FILLER REDEFINES ERRMSGF.
             03 ERRMSGA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  ERRMSGI  PIC X(78).
           02  FKEYSL    COMP  PIC  S9(4).
           02  FKEYSF    PICTURE X.
           02  FILLER REDEFINES FKEYSF.
             03 FKEYSA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  FKEYSI  PIC X(22).
           02  FKEY05L    COMP  PIC  S9(4).
           02  FKEY05F    PICTURE X.
           02  FILLER REDEFINES FKEY05F.
             03 FKEY05A    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  FKEY05I  PIC X(7).
           02  FKEY12L    COMP  PIC  S9(4).
           02  FKEY12F    PICTURE X.
           02  FILLER REDEFINES FKEY12F.
             03 FKEY12A    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  FKEY12I  PIC X(10).
       01  CMODUPAO REDEFINES CMODUPAI.
           02  FILLER PIC X(12).
           02  FILLER PICTURE X(3).
           02  TRNNAMEC    PICTURE X.
           02  TRNNAMEP    PICTURE X.
           02  TRNNAMEH    PICTURE X.
           02  TRNNAMEV    PICTURE X.
           02  TRNNAMEO  PIC X(4).
           02  FILLER PICTURE X(3).
           02  TITLE01C    PICTURE X.
           02  TITLE01P    PICTURE X.
           02  TITLE01H    PICTURE X.
           02  TITLE01V    PICTURE X.
           02  TITLE01O  PIC X(40).
           02  FILLER PICTURE X(3).
           02  CURDATEC    PICTURE X.
           02  CURDATEP    PICTURE X.
           02  CURDATEH    PICTURE X.
           02  CURDATEV    PICTURE X.
           02  CURDATEO  PIC X(8).
           02  FILLER PICTURE X(3).
           02  PGMNAMEC    PICTURE X.
           02  PGMNAMEP    PICTURE X.
           02  PGMNAMEH    PICTURE X.
           02  PGMNAMEV    PICTURE X.
           02  PGMNAMEO  PIC X(8).
           02  FILLER PICTURE X(3).
           02  TITLE02C    PICTURE X.
           02  TITLE02P    PICTURE X.
           02  TITLE02H    PICTURE X.
           02  TITLE02V    PICTURE X.
           02  TITLE02O  PIC X(40).
           02  FILLER PICTURE X(3).
           02  CURTIMEC    PICTURE X.
           02  CURTIMEP    PICTURE X.
           02  CURTIMEH    PICTURE X.
           02  CURTIMEV    PICTURE X.
           02  CURTIMEO  PIC X(8).
           02  FILLER PICTURE X(3).
           02  ACCTIDC    PICTURE X.
           02  ACCTIDP    PICTURE X.
           02  ACCTIDH    PICTURE X.
           02  ACCTIDV    PICTURE X.
           02  ACCTIDO  PIC X(11).
           02  FILLER PICTURE X(3).
           02  BALDATEC    PICTURE X.
           02  BALDATEP    PICTURE X.
           02  BALDATEH    PICTURE X.
           02  BALDATEV    PICTURE X.
           02  BALDATEO  PIC X(10).
           02  FILLER PICTURE X(3).
           02  OPENBALC    PICTURE X.
           02  OPENBALP    PICTURE X.
           02  OPENBALH    PICTURE X.
           02  OPENBALV    PICTURE X.
           02  OPENBALO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  CRLIMITC    PICTURE X.
           02  CRLIMITP    PICTURE X.
           02  CRLIMITH    PICTURE X.
           02  CRLIMITV    PICTURE X.
           02  CRLIMITO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  CREDITSC    PICTURE X.
           02  CREDITSP    PICTURE X.
           02  CREDITSH    PICTURE X.
           02  CREDITSV    PICTURE X.
           02  CREDITSO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  CLOSBALC    PICTURE X.
           02  CLOSBALP    PICTURE X.
           02  CLOSBALH    PICTURE X.
           02  CLOSBALV    PICTURE X.
           02  CLOSBALO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  DEBITSC    PICTURE X.
           02  DEBITSP    PICTURE X.
           02  DEBITSH    PICTURE X.
           02  DEBITSV    PICTURE X.
           02  DEBITSO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  TRANCNTC    PICTURE X.
           02  TRANCNTP    PICTURE X.
           02  TRANCNTH    PICTURE X.
           02  TRANCNTV    PICTURE X.
           02  TRANCNTO  PIC X(11).
           02  FILLER PICTURE X(3).
           02  THCOUNTC    PICTURE X.
           02  THCOUNTP    PICTURE X.
           02  THCOUNTH    PICTURE X.
           02  THCOUNTV    PICTURE X.
           02  THCOUNTO  PIC X(11).
           02  FILLER PICTURE X(3).
           02  THNETC    PICTURE X.
           02  THNETP    PICTURE X.
           02  THNETH    PICTURE X.
           02  THNETV    PICTURE X.
           02  THNETO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  THCREDC    PICTURE X.
           02  THCREDP    PICTURE X.
           02  THCREDH    PICTURE X.
           02  THCREDV    PICTURE X.
           02  THCREDO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  THDEBTC    PICTURE X.
           02  THDEBTP    PICTURE X.
           02  THDEBTH    PICTURE X.
           02  THDEBTV    PICTURE X.
           02  THDEBTO  PIC X(14).
           02  FILLER PICTURE X(3).
           02  CURFLGC    PICTURE X.
           02  CURFLGP    PICTURE X.
           02  CURFLGH    PICTURE X.
           02  CURFLGV    PICTURE X.
           02  CURFLGO  PIC X(1).
           02  FILLER PICTURE X(3).
           02  FLGDATEC    PICTURE X.
           02  FLGDATEP    PICTURE X.
           02  FLGDATEH    PICTURE X.
           02  FLGDATEV    PICTURE X.
           02  FLGDATEO  PIC X(10).
           02  FILLER PICTURE X(3).
           02  NEWFLGC    PICTURE X.
           02  NEWFLGP    PICTURE X.
           02  NEWFLGH    PICTURE X.
           02  NEWFLGV    PICTURE X.
           02  NEWFLGO  PIC X(1).
           02  FILLER PICTURE X(3).
           02  INFOMSGC    PICTURE X.
           02  INFOMSGP    PICTURE X.
           02  INFOMSGH    PICTURE X.
           02  INFOMSGV    PICTURE X.
           02  INFOMSGO  PIC X(60).
           02  FILLER PICTURE X(3).
           02  ERRMSGC    PICTURE X.
           02  ERRMSGP    PICTURE X.
           02  ERRMSGH    PICTURE X.
           02  ERRMSGV    PICTURE X.
           02  ERRMSGO  PIC X(78).
           02  FILLER PICTURE X(3).
           02  FKEYSC    PICTURE X.
           02  FKEYSP    PICTURE X.
           02  FKEYSH    PICTURE X.
           02  FKEYSV    PICTURE X.
           02  FKEYSO  PIC X(22).
           02  FILLER PICTURE X(3).
           02  FKEY05C    PICTURE X.
           02  FKEY05P    PICTURE X.
           02  FKEY05H    PICTURE X.
           02  FKEY05V    PICTURE X.
           02  FKEY05O  PIC X(7).
           02  FILLER PICTURE X(3).
           02  FKEY12C    PICTURE X.
           02  FKEY12P    PICTURE X.
           02  FKEY12H    PICTURE X.
           02  FKEY12V    PICTURE X.
           02  FKEY12O  PIC X(10).
