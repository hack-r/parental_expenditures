  /***************************************************************************/
  /* PROGRAM NAME:  CEX INTERVIEW SURVEY SAMPLE PROGRAM (SAS)                */
  /* LOCATION: D:\PROGRAMS                                                   */
  /* FUNCTION: CREATE AN INTERVIEW SURVEY EXPENDITURE TABLE BY INCOME CLASS  */
  /*           USING MICRODATA FROM THE BUREAU OF LABOR STATISTIC'S CONSUMER */
  /*           EXPENDITURE SURVEY.                                           */
  /*                                                                         */
  /* WRITTEN BY:  ERIC KEIL                                                  */
  /* MODIFICATIONS:                                                          */
  /* DATE-      MODIFIED BY-      REASON-                                    */
  /* -----      ------------      -------                                    */
  /* 03/21/02   ERIC KEIL         IMPROVE EFFICIENCY                         */ 
  /* 10/22/03   ERIC KEIL         UPDATE FOR 2002 DATA                       */
  /* 11/20/03   ERIC KEIL         INCLUDE ROUTINE TO AGGREGATE EASIER        */       
  /*                                                                         */
  /*  FOR SAS VERSION 8 OR HIGHER                                            */
  /*                                                                         */
  /***************************************************************************/



%LET YEAR = 2002;  /* DESIGNATE THE CALENDAR YEAR DESIRED */

%LET YR1 = %SUBSTR(&YEAR,3,2);
%LET YR2 = %SUBSTR(%EVAL(&YEAR+1),3,2);
LIBNAME I&YR1 "D:\INTRVW&YR1";


  /***************************************************************************/
  /* STEP1: READ IN THE STUB PARAMETER FILE AND CREATE FORMATS               */
  /* ----------------------------------------------------------------------- */
  /* 1 CONVERTS THE STUB PARAMETER FILE INTO A LABEL FILE FOR OUTPUT         */
  /* 2 CONVERTS THE STUB PARAMETER FILE INTO AN EXPENDITURE AGGREGATION FILE */
  /* 3 CREATES FORMATS FOR USE IN OTHER PROCEDURES                           */
  /***************************************************************************/


DATA STUBFILE (KEEP= COUNT TYPE LEVEL TITLE UCC SURVEY GROUP LINE);
  INFILE "D:\PROGRAMS\ISTUB&YEAR..TXT"
  PAD MISSOVER;
  INPUT @1 TYPE $1. @ 4 LEVEL $1. @7 TITLE $60. @70 UCC $6.
        @80 SURVEY $1. @86 GROUP $7.;
  IF (TYPE = '1');
  IF GROUP IN ('CUCHARS' 'FOOD' 'EXPEND' 'INCOME');

    RETAIN COUNT 9999;
    COUNT + 1;
    LINE = PUT(COUNT, $5.)||LEVEL ;
	/* READS IN THE STUB PARAMETER FILE AND CREATES LINE NUMBERS FOR UCCS */
	/* A UNIQUE LINE NUMBER IS ASSIGNED TO EACH EXPENDITURE LINE ITEM     */
RUN;


DATA AGGFMT1 (KEEP= UCC LINE LINE1-LINE10);
  SET STUBFILE;
  LENGTH LINE1-LINE10 $6.;
    ARRAY LINES(9) LINE1-LINE9;
      IF (UCC > 'A') THEN
        LINES(SUBSTR(LINE, 6, 1)) = LINE;
	  RETAIN LINE1-LINE9;
      IF (UCC < 'A')  THEN 
        LINE10 = LINE;
  IF (LINE10);
RUN;


PROC SORT DATA= AGGFMT1 (RENAME=(LINE= COMPARE));
  BY UCC;
    /* MAPS LINE NUMBERS TO UCCS */
RUN;


PROC TRANSPOSE DATA= AGGFMT1 OUT= AGGFMT2 (RENAME=(COL1= LINE));
  BY UCC COMPARE;
  VAR LINE1-LINE10;
RUN;


DATA AGGFMT (KEEP= UCC LINE);
  SET AGGFMT2;
    IF LINE;
    IF SUBSTR(COMPARE, 6, 1) > SUBSTR(LINE, 6, 1) OR COMPARE=LINE;
	/* AGGREGATION FILE. EXTRANEOUS MAPPINGS ARE DELETED            */
	/* PROC SQL WILL AGGANGE LINE#/UCC PAIRS FOR USE IN PROC FORMAT */
RUN;


PROC SQL NOPRINT;
  SELECT UCC, LINE, COUNT(*)
  INTO  :UCCS SEPARATED BY " ",
        :LINES SEPARATED BY " ",          
        :CNT
  FROM AGGFMT;
  QUIT;
RUN;


%MACRO MAPPING;
  %DO  I = 1  %TO  &CNT;
    "%SCAN(&UCCS,&I,%STR( ))" = "%SCAN(&LINES,&I,%STR( ))"
  %END;
%MEND MAPPING;


DATA LBLFMT (RENAME=(LINE= START TITLE= LABEL));
  SET STUBFILE (KEEP= LINE TITLE);
  RETAIN FMTNAME 'LBLFMT' TYPE 'C';
  /* LABEL FILE. LINE NUMBERS ARE ASSIGNED A TEXT LABEL */
  /* DATASET CONSTRUCTED TO BE READ INTO A PROC FORMAT  */
RUN;


PROC FORMAT;

  VALUE $AGGFMT (MULTILABEL)
    %MAPPING
    OTHER= 'OTHER';
	/* CREATE AGGREGATION FORMAT */


  VALUE $INC (MULTILABEL)
    '01' = '01'
    '01' = '11'
    '02' = '02'
    '02' = '11'
    '03' = '03'
    '03' = '11'
    '04' = '04'
    '04' = '11'
    '05' = '05'
    '05' = '11'
    '06' = '06'
    '06' = '11'
    '07' = '07'
    '07' = '11'
    '08' = '08'
    '08' = '11'
    '09' = '09'
    '09' = '11'
    '10' = '10';
	/* CREATE INCOME CLASS FORMAT */
RUN;


PROC FORMAT LIBRARY= WORK  CNTLIN= LBLFMT;
  /* CREATE LABEL FILE FORMATS */
RUN;


  /***************************************************************************/
  /* STEP2: READ IN ALL NEEDED DATA FROM THE CD-ROM                          */
  /* ----------------------------------------------------------------------- */
  /* 1 READ IN THE INTERVIEW FMLY FILES & CREATE THE MO_SCOPE VARIABLE       */
  /* 2 READ IN THE INTERVIEW MTAB AND ITAB FILES                             */
  /* 3 MERGE FMLY AND EXPENDITURE FILES TO DERIVE WEIGHTED EXPENDITURES      */
  /***************************************************************************/


DATA FMLY (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 REPWT1-REPWT45);

SET I&YR1..FMLI&YR1.1X (IN = FIRSTQTR)
    I&YR1..FMLI&YR1.2
    I&YR1..FMLI&YR1.3
    I&YR1..FMLI&YR1.4
    I&YR1..FMLI&YR2.1  (IN = LASTQTR);
	BY NEWID;
	/* READ IN FMLY FILE DATA */

    IF FIRSTQTR THEN 
      MO_SCOPE = (QINTRVMO - 1);
    ELSE IF LASTQTR THEN 
      MO_SCOPE = (4 - QINTRVMO);
    ELSE 
      MO_SCOPE = 3;
	/* CREATE MONTH IN SCOPE VARIABLE (MO_SCOPE) */

    ARRAY REPS_A(45) WTREP01-WTREP44 FINLWT21;
    ARRAY REPS_B(45) REPWT1-REPWT45;

      DO i = 1 TO 45;
	  IF REPS_A(i) > 0 THEN
         REPS_B(i) = (REPS_A(i) * MO_SCOPE / 12); 
		 ELSE REPS_B(i) = 0;	
	  END;
	  /* ADJUST WEIGHTS BY MO_SCOPE TO ACCOUNT FOR SAMPLE ROTATION */ 
RUN;



DATA EXPEND (KEEP=NEWID UCC COST);

  SET I&YR1..MTBI&YR1.1X
      I&YR1..MTBI&YR1.2
      I&YR1..MTBI&YR1.3
      I&YR1..MTBI&YR1.4
      I&YR1..MTBI&YR2.1

      I&YR1..ITBI&YR1.1X (RENAME=(VALUE=COST))
      I&YR1..ITBI&YR1.2  (RENAME=(VALUE=COST))
      I&YR1..ITBI&YR1.3  (RENAME=(VALUE=COST))
      I&YR1..ITBI&YR1.4  (RENAME=(VALUE=COST))
      I&YR1..ITBI&YR2.1  (RENAME=(VALUE=COST));
      BY NEWID;

   IF REFYR = "&YEAR" OR  REF_YR = "&YEAR";
   IF UCC = '710110'  THEN  
      COST = (COST * 4); 
   /* READ IN MTAB AND ITAB EXPENDITURE AND INCOME DATA */
   /* ADJUST UCC 710110 TO ANNUALIZE                    */
RUN;



DATA PUBFILE (KEEP = NEWID INCLASS UCC RCOST1-RCOST45);

  MERGE FMLY   (IN = INFAM)
        EXPEND (IN = INEXP);
  BY NEWID;
  IF INEXP AND INFAM;

  IF COST = .  THEN 
     COST = 0;
	 
     ARRAY REPS_A(45) WTREP01-WTREP44 FINLWT21;
     ARRAY REPS_B(45) RCOST1-RCOST45;

     DO i = 1 TO 45;
	   IF REPS_A(i)> 0 
         THEN REPS_B(i) = (REPS_A(i) * COST);
	     ELSE REPS_B(i) = 0; 	
	 END; 
	 /* MERGE FMLY FILE WEIGHTS AND CHARACTERISTICS WITH MTAB/ITAB COSTS */
	 /* MULTIPLY COSTS BY WEIGHTS TO DERIVE WEIGHTED COSTS               */
RUN;


  /***************************************************************************/
  /* STEP3: CALCULATE POPULATIONS                                            */
  /* ----------------------------------------------------------------------- */
  /* 1 SUM ALL 45 WEIGHT VARIABLES TO DERIVE REPLICATE POPULATIONS           */
  /* 2 FORMAT FOR CORRECT COLUMN CLASSIFICATIONS                             */
  /* 3 ARRANGE DATA FOR MERGING WITH EXPENDITURES                            */
  /***************************************************************************/


PROC SUMMARY NWAY DATA=FMLY;
  CLASS INCLASS / MLF;
  VAR REPWT1-REPWT45;
  FORMAT INCLASS $INC.;
  OUTPUT OUT = POP1 SUM = RPOP1-RPOP45;
  /* SUMS WEIGHTS TO CREATE POPULATIONS PER REPLICATE */
  /* FORMATS ROWS TO CORRECT COLUMN CLASSIFICATIONS   */
  /* ROWS = CLASS, COLUMNS = REPLICATES               */
RUN;


PROC TRANSPOSE DATA = POP1 
  OUT = POP2 PREFIX = POP;
  VAR RPOP1-RPOP45;
  /* PUTS POPULATIONS INTO 2 DIM FORMAT FOR MERGING */
  /* ROWS = REPLICATES, COLUMNS = CLASS             */
RUN;


DATA POP (KEEP = REP POP1-POP11) 
     CUS (RENAME = (POP1=GROUP1 POP2=GROUP2 POP3=GROUP3 POP4=GROUP4 POP5=GROUP5
                    POP6=GROUP6 POP7=GROUP7 POP8=GROUP8 POP9=GROUP9 POP10=GROUP10
                    POP11=GROUP11) DROP = _NAME_ REP);
  SET POP2;
  REP + 1;
  LINE = '100001';

  OUTPUT POP;
  IF REP = 45  THEN OUTPUT CUS;
  /* CREATES REP VARIABLE FOR MERGING WITH EXPENDITURES                 */
  /* SETS ASIDE THE 45TH REPLICATE POPULATIONS FOR INSERTION INTO TABLE */
RUN;


  /***************************************************************************/
  /* STEP4: CALCULATE WEIGHTED AGGREGATE EXPENDITURES                        */
  /* ----------------------------------------------------------------------- */
  /* 1 SUM THE 45 REPLICATE WEIGHTED EXPENDITURES TO DERIVE AGGREGATES       */
  /* 2 FORMAT FOR CORRECT COLUMN CLASSIFICATIONS AND AGGREGATION SCHEME      */
  /* 3 ARRANGE DATA FOR MERGING WITH POPULATIONS                             */
  /***************************************************************************/


PROC SUMMARY NWAY DATA=PUBFILE SUMSIZE=MAX COMPLETETYPES;
  CLASS UCC INCLASS / MLF;
  VAR RCOST1-RCOST45;
  FORMAT UCC $AGGFMT. INCLASS $INC.;
   OUTPUT OUT=AGG1 (DROP= _TYPE_ _FREQ_  RENAME=(UCC=LINE)) 
   SUM = RCOST1-RCOST45;
  /* SUMS WEIGHTED COSTS PER REPLICATE TO GET AGGREGATES */
  /* SUMS COLUMNS TO CREATE COMPLETE REPORTING COLUMN    */
  /* ROWS = UCC*CLASS, COLUMNS = REPLICATES              */
RUN;


/* PROC SUMMARY WILL NOT OUTPUT MISSINGS FOR LINES THAT       */
/* HAVE NO OBSERVATOINS FOR ANY INCLASS, SO A STUB CONTAINING */
/* EVERY COMBINATION OF INCLASS AND LINE MUST BE GENERATED    */
/* AND MERGED WITH THE SUMS TO PROVIDE ROWS OF MISSINGS.      */


/* GENERATE A DATASET CONTAINING EACH UNIQUE LINE ONLY ONCE */
PROC SORT DATA = AGGFMT OUT = AGG_STUB NODUPKEYS;
  BY LINE;
RUN;


/* GENERATE EVERY COMBINATION OF INCLASS AND LINE */
DATA AGG_STUB (KEEP = LINE INCLASS);
  SET AGG_STUB;
  ATTRIB INCLASS FORMAT=$CHAR2.;
    DO i = 1 TO 11;
	  INCLASS = i;
	  IF INCLASS <= ' 9'  THEN INCLASS = '0'||SUBSTR(INCLASS,2,1);
	  ELSE INCLASS = INCLASS;
      OUTPUT;
    END;
RUN;


/* MERGE STUB AND SUMMARY DATASETS TO PRODUCE COMPLETE SUMMATION */
DATA AGG1;
  MERGE AGG1 
        AGG_STUB;
  BY LINE INCLASS;
RUN;


PROC TRANSPOSE DATA=AGG1
  OUT=AGG2 (DROP = _NAME_) PREFIX = AGG;
  BY LINE;
  WHERE LINE NE 'OTHER';
  VAR RCOST1-RCOST45;
  /* TRANSPOSES TO PUT AGGREGATED COSTS IN 2 DIM FORMAT */
  /* ROWS = REPLICATES, COLUMNS = CLASS                 */
RUN;



DATA AGG;
  SET AGG2;
  BY LINE;

  RETAIN REP 0;
  IF FIRST.LINE  THEN
    DO;
        REP = 0;
    END;

  ARRAY AGGS(11) AGG1-AGG11;
	DO i = 1 TO 11;
	  IF AGGS(i) = .  
      THEN AGGS(i) = 0;
	END;
  REP + 1;
  /* CREATES VARIABLES TO USE LATER IN MERGES */
  /* SETS MISSING AGGREGATED COSTS TO ZERO    */
RUN; 


PROC SORT DATA=AGG;
  BY REP LINE;
RUN;


  /***************************************************************************/
  /* STEP5: CALCULATE MEAN EXPENDITURES AND STANDARD ERRORS                  */
  /* ----------------------------------------------------------------------- */
  /* 1 MERGE POPULATIONS WITH AGGREGATE EXPENDITURES AND CALCULATE MEANS     */
  /* 2 CALCULATE STANDARD ERRORS                                             */
  /***************************************************************************/


DATA ALL (KEEP = LINE REP GRP1-GRP11);
  MERGE POP AGG;
  BY REP;

  ARRAY AGGS(11)  AGG1-AGG11;
  ARRAY POPS(11)  POP1-POP11;
  ARRAY MEANS(11) GRP1-GRP11;

  DO i = 1 TO 11;
    MEANS(i) = AGGS(i) / POPS(i);
  END;
  /* MERGES POPS AND AGGREGATED COSTS TOGETHER   */
  /* CALCULATES MEAN EXPENDITURES                */
  /* ROWS = LINE*REPLICATE MEANS, COLUMN = CLASS */
RUN;


PROC SORT DATA=ALL;
  BY LINE REP;
RUN;


PROC TRANSPOSE DATA=ALL (DROP=REP) 
  OUT = TAB1 PREFIX = MEAN;
  BY LINE;
  /* TRANSPOSES TO PUT REPLICATE MEANS INTO ONE LINE */
  /* ROWS = LINE*CLASS, COLUMNS = REPLICATE MEANS    */
RUN;


DATA TAB2 (DROP = _NAME_ i);
  SET TAB1;

  ARRAY REPS(44) MEAN1-MEAN44;
  ARRAY DIFF(44) DIFF1-DIFF44;

  DO i = 1 TO 44;
    DIFF(i) = (REPS(i) - MEAN45)**2;
  END;
  
  MEAN = MEAN45;
  SE = SQRT((1/44)*SUM(OF DIFF(*)));
  /* CALCULATES STANDARD ERRORS */
RUN;


  /***************************************************************************/
  /* STEP6: TABULATE MEAN EXPENDITURES AND STANDARD ERRORS                   */
  /* ----------------------------------------------------------------------- */
  /* 1 ARRANGE THE DATA INTO A FORM SUITABLE FOR TABULATION                  */
  /* 2 TABULATE                                                              */
  /***************************************************************************/


PROC TRANSPOSE DATA=TAB2 OUT=TAB3 (RENAME=(_NAME_=ESTIMATE)) PREFIX = GROUP;
  BY LINE;
  VAR MEAN SE;
  /* TRANSPOSES MEANS BACK INTO COLUMN FORMAT        */
  /* ROWS = LINE, COLUMNS = CLASS, VAR = MEAN AND SE */
RUN;


DATA TAB;
  SET TAB3 CUS;
  BY LINE;
  IF LINE = '100001'  THEN ESTIMATE = 'N';
RUN;


PROC TABULATE DATA=TAB;
  CLASS LINE / GROUPINTERNAL ORDER=DATA;
  CLASS ESTIMATE;
  VAR GROUP1-GROUP11;
  FORMAT LINE $LBLFMT.;
  /* TABULATES MEANS AND SE                        */
  /* CONDITIONAL MACRO EXECUTION FOR COLUMN TITLES */

    TABLE (LINE * ESTIMATE), (GROUP11 GROUP1 GROUP2 GROUP3 GROUP4 
                              GROUP5  GROUP6 GROUP7 GROUP8 GROUP9) 
    *SUM='' / RTS=25;
    LABEL ESTIMATE=ESTIMATE GROUP1='LESS THAN $5,000'   GROUP2='$5,000 TO $9,999' 
                            GROUP3='$10,000 TO $14,999' GROUP4='$15,000 TO $19,999'
                            GROUP5='$20,000 TO $29,999' GROUP6='$30,000 TO $39,999'
                            GROUP7='$40,000 TO $49,999' GROUP8='$50,000 TO $69,999'
                            GROUP9='$70,000 AND OVER'   GROUP11='TOTAL COMPLETE REPORTING';
	OPTIONS NODATE NOCENTER NONUMBER LS=167;
    TITLE "INTERVIEW EXPENDITURES FOR INCOME BEFORE TAXES";

RUN;

