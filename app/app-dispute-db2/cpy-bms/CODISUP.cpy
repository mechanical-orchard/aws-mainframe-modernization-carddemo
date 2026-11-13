      ******************************************************************
      * Symbolic map for CODISUP / CDISUPA
      * Transaction Dispute Maintain screen
      ******************************************************************
       01  CDISUPAI.
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
           02  DISPIDFL    COMP  PIC  S9(4).
           02  DISPIDFF    PICTURE X.
           02  FILLER REDEFINES DISPIDFF.
             03 DISPIDFA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DISPIDFI  PIC X(12).
           02  DTRANIDL    COMP  PIC  S9(4).
           02  DTRANIDF    PICTURE X.
           02  FILLER REDEFINES DTRANIDF.
             03 DTRANIDA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DTRANIDI  PIC X(16).
           02  DCARDNOL    COMP  PIC  S9(4).
           02  DCARDNOF    PICTURE X.
           02  FILLER REDEFINES DCARDNOF.
             03 DCARDNOA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DCARDNOI  PIC X(16).
           02  DAMTL    COMP  PIC  S9(4).
           02  DAMTF    PICTURE X.
           02  FILLER REDEFINES DAMTF.
             03 DAMTA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DAMTI  PIC X(13).
           02  DREASONL    COMP  PIC  S9(4).
           02  DREASONF    PICTURE X.
           02  FILLER REDEFINES DREASONF.
             03 DREASONA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DREASONI  PIC X(4).
           02  DSTATUSL    COMP  PIC  S9(4).
           02  DSTATUSF    PICTURE X.
           02  FILLER REDEFINES DSTATUSF.
             03 DSTATUSA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DSTATUSI  PIC X(2).
           02  DSTSDSCL    COMP  PIC  S9(4).
           02  DSTSDSCF    PICTURE X.
           02  FILLER REDEFINES DSTSDSCF.
             03 DSTSDSCA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DSTSDSCI  PIC X(30).
           02  DNEWSTSL    COMP  PIC  S9(4).
           02  DNEWSTSF    PICTURE X.
           02  FILLER REDEFINES DNEWSTSF.
             03 DNEWSTSA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DNEWSTSI  PIC X(2).
           02  DOPENTSL    COMP  PIC  S9(4).
           02  DOPENTSF    PICTURE X.
           02  FILLER REDEFINES DOPENTSF.
             03 DOPENTSA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DOPENTSI  PIC X(26).
           02  DUPDTSL    COMP  PIC  S9(4).
           02  DUPDTSF    PICTURE X.
           02  FILLER REDEFINES DUPDTSF.
             03 DUPDTSA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DUPDTSI  PIC X(26).
           02  DDESCL    COMP  PIC  S9(4).
           02  DDESCF    PICTURE X.
           02  FILLER REDEFINES DDESCF.
             03 DDESCA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DDESCI  PIC X(50).
           02  DNOTEL    COMP  PIC  S9(4).
           02  DNOTEF    PICTURE X.
           02  FILLER REDEFINES DNOTEF.
             03 DNOTEA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  DNOTEI  PIC X(50).
           02  INFOMSGL    COMP  PIC  S9(4).
           02  INFOMSGF    PICTURE X.
           02  FILLER REDEFINES INFOMSGF.
             03 INFOMSGA    PICTURE X.
           02  FILLER   PICTURE X(4).
           02  INFOMSGI  PIC X(45).
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
           02  FKEYSI  PIC X(41).
       01  CDISUPAO REDEFINES CDISUPAI.
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
           02  DISPIDFC    PICTURE X.
           02  DISPIDFP    PICTURE X.
           02  DISPIDFH    PICTURE X.
           02  DISPIDFV    PICTURE X.
           02  DISPIDFO  PIC X(12).
           02  FILLER PICTURE X(3).
           02  DTRANIDC    PICTURE X.
           02  DTRANIDP    PICTURE X.
           02  DTRANIDH    PICTURE X.
           02  DTRANIDV    PICTURE X.
           02  DTRANIDO  PIC X(16).
           02  FILLER PICTURE X(3).
           02  DCARDNOC    PICTURE X.
           02  DCARDNOP    PICTURE X.
           02  DCARDNOH    PICTURE X.
           02  DCARDNOV    PICTURE X.
           02  DCARDNOO  PIC X(16).
           02  FILLER PICTURE X(3).
           02  DAMTC    PICTURE X.
           02  DAMTP    PICTURE X.
           02  DAMTH    PICTURE X.
           02  DAMTV    PICTURE X.
           02  DAMTO  PIC X(13).
           02  FILLER PICTURE X(3).
           02  DREASONC    PICTURE X.
           02  DREASONP    PICTURE X.
           02  DREASONH    PICTURE X.
           02  DREASONV    PICTURE X.
           02  DREASONO  PIC X(4).
           02  FILLER PICTURE X(3).
           02  DSTATUSC    PICTURE X.
           02  DSTATUSP    PICTURE X.
           02  DSTATUSH    PICTURE X.
           02  DSTATUSV    PICTURE X.
           02  DSTATUSO  PIC X(2).
           02  FILLER PICTURE X(3).
           02  DSTSDSCC    PICTURE X.
           02  DSTSDSCP    PICTURE X.
           02  DSTSDSCH    PICTURE X.
           02  DSTSDSCV    PICTURE X.
           02  DSTSDSCO  PIC X(30).
           02  FILLER PICTURE X(3).
           02  DNEWSTSC    PICTURE X.
           02  DNEWSTSP    PICTURE X.
           02  DNEWSTSH    PICTURE X.
           02  DNEWSTSV    PICTURE X.
           02  DNEWSTSO  PIC X(2).
           02  FILLER PICTURE X(3).
           02  DOPENTSC    PICTURE X.
           02  DOPENTSP    PICTURE X.
           02  DOPENTSH    PICTURE X.
           02  DOPENTSV    PICTURE X.
           02  DOPENTSO  PIC X(26).
           02  FILLER PICTURE X(3).
           02  DUPDTSC    PICTURE X.
           02  DUPDTSP    PICTURE X.
           02  DUPDTSH    PICTURE X.
           02  DUPDTSV    PICTURE X.
           02  DUPDTSO  PIC X(26).
           02  FILLER PICTURE X(3).
           02  DDESCC    PICTURE X.
           02  DDESCP    PICTURE X.
           02  DDESCH    PICTURE X.
           02  DDESCV    PICTURE X.
           02  DDESCO  PIC X(50).
           02  FILLER PICTURE X(3).
           02  DNOTEC    PICTURE X.
           02  DNOTEP    PICTURE X.
           02  DNOTEH    PICTURE X.
           02  DNOTEV    PICTURE X.
           02  DNOTEO  PIC X(50).
           02  FILLER PICTURE X(3).
           02  INFOMSGC    PICTURE X.
           02  INFOMSGP    PICTURE X.
           02  INFOMSGH    PICTURE X.
           02  INFOMSGV    PICTURE X.
           02  INFOMSGO  PIC X(45).
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
           02  FKEYSO  PIC X(41).
