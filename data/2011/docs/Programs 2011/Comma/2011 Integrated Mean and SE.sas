  /***************************************************************************/
  /* PROGRAM NAME:  CEX INTEGRATED SURVEYS SAMPLE PROGRAM (SAS)              */
  /* FUNCTION: CREATE AN INTEGRATED SURVEY EXPENDITURE TABLE BY INCOME CLASS */
  /*           USING MICRODATA FROM THE BUREAU OF LABOR STATISTICS' CONSUMER */
  /*           EXPENDITURE SURVEY.                                           */
  /*                                                                         */
  /* WRITTEN BY: BUREAU OF LABOR STATISTICS         APRIL 7 2003             */
  /*             CONSUMER EXPENDITURE SURVEY                                 */
  /* MODIFICATIONS:                                                          */
  /* DATE-      MODIFIED BY-        REASON-                                  */
  /* -----      ------------        -------                                  */
  /*                                                                         */
  /*                                                                         */
  /*                                                                         */
  /*  NOTE:  FOR SAS VERSION 8 OR HIGHER                                     */
  /*                                                                         */
  /*  DATA AND INPUT FILES USED IN THIS SAMPLE PROGRAM WERE UNZIPPED         */
  /*  OR COPIED TO THE LOCATIONS BELOW:                                      */
  /*                                                                         */
  /*  INTERVIEW DATA -- C:\2011_CEX\INTRVW11                                 */
  /*  DIARY DATA -- C:\2011_CEX\DIARY11                                      */
  /*  INTSTUB2011.TXT -- C:\2011_CEX\Programs                                */
  /*                                                                         */
  /***************************************************************************/


  /*Enter Data Year*/
  %LET YEAR = 2011;


  /***************************************************************************/
  /* STEP1: READ IN THE STUB PARAMETER FILE AND CREATE FORMATS               */
  /* ----------------------------------------------------------------------- */
  /* 1 CONVERTS THE STUB PARAMETER FILE INTO A LABEL FILE FOR OUTPUT         */
  /* 2 CONVERTS THE STUB PARAMETER FILE INTO AN EXPENDITURE AGGREGATION FILE */
  /* 3 CREATES FORMATS FOR USE IN OTHER PROCEDURES                           */
  /***************************************************************************/


%LET YR1 = %SUBSTR(&YEAR, 3, 2);
%LET YR2 = %SUBSTR(%EVAL(&YEAR + 1), 3, 2);

DATA STUBFILE (KEEP= COUNT TYPE LEVEL TITLE UCC SURVEY GROUP LINE);
  INFILE "C:\&YEAR._CEX\Programs\INTSTUB&YEAR..TXT"
  PAD MISSOVER;
  INPUT @1 TYPE $1. @ 4 LEVEL $1. @7 TITLE $60. @70 UCC $6.
        @80 SURVEY $1. @86 GROUP $7.;
  IF (TYPE = "1");
  IF GROUP IN ("CUCHARS" "FOOD" "EXPEND" "INCOME");
  IF SURVEY = "T" THEN DELETE;

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
      IF (UCC > "A") THEN
        LINES(SUBSTR(LINE,6,1)) = LINE;
	  RETAIN LINE1-LINE9;
      IF (UCC < "A")  THEN 
        LINE10 = LINE;
  IF (LINE10);
  /* MAPS LINE NUMBERS TO UCCS */
RUN;


PROC SORT DATA= AGGFMT1 (RENAME=(LINE= COMPARE));
  BY UCC;
RUN;


PROC TRANSPOSE DATA= AGGFMT1 OUT= AGGFMT2 (RENAME=(COL1= LINE));
  BY UCC COMPARE;
  VAR LINE1-LINE10;
RUN;


DATA AGGFMT (KEEP= UCC LINE);
  SET AGGFMT2;
    IF LINE;
    IF SUBSTR(COMPARE,6,1) > SUBSTR(LINE,6,1) OR COMPARE=LINE;
	/* AGGREGATION FILE. EXTRANEOUS MAPPINGS ARE DELETED */
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
  %DO  i = 1  %TO  &CNT;
    "%SCAN(&UCCS,&i,%STR( ))" = "%SCAN(&LINES,&i,%STR( ))"
  %END;
%MEND MAPPING;


DATA LBLFMT (RENAME=(LINE= START TITLE= LABEL));
  SET STUBFILE (KEEP= LINE TITLE);
  RETAIN FMTNAME "LBLFMT" TYPE "C";
  /* LABEL FILE. LINE NUMBERS ARE ASSIGNED A TEXT LABEL */
  /* DATASET CONSTRUCTED TO BE READ INTO A PROC FORMAT  */
RUN;


PROC FORMAT;

  VALUE $AGGFMT (MULTILABEL)
    %MAPPING
    OTHER= 'OTHER'
    ;

  VALUE $INC (MULTILABEL)
    '01' = '01'
    '01' = '10'
    '02' = '02'
    '02' = '10'
    '03' = '03'
    '03' = '10'
    '04' = '04'
    '04' = '10'
    '05' = '05'
    '05' = '10'
    '06' = '06'
    '06' = '10'
    '07' = '07'
    '07' = '10'
    '08' = '08'
    '08' = '10'
    '09' = '09'
    '09' = '10';
	/* CREATE INCOME CLASS FORMAT */
RUN;


PROC FORMAT LIBRARY=WORK  CNTLIN=LBLFMT;
RUN;


  /***************************************************************************/
  /* STEP2: READ IN ALL NEEDED DATA                                          */
  /* ----------------------------------------------------------------------- */
  /* 1 READ IN THE INTERVIEW AND DIARY FMLY FILES & CREATE MO_SCOPE VARIABLE */
  /* 2 READ IN THE INTERVIEW MTAB/ITAB AND DIARY EXPN/DTAB FILES             */
  /* 3 MERGE FMLY AND EXPENDITURE FILES TO DERIVE WEIGHTED EXPENDITURES      */
  /***************************************************************************/
/***********************************************************************************************
 ** PROC IMPORT was removed and replaced by the internal SAS code produced via PROC IMPORT.   **
 ** This was done because SAS assigned incorrect formats to QINTRVYR and QINTRVMO             **
 ***********************************************************************************************

PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\FMLI&YR1.1x.CSV"
            OUT=FMLYI&YR1.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
*************************************************************************************************/

data WORK.FMLYI111                                ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile 'C:\2011_CEX\Intrvw11\FMLI111x.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat NEWID best32. ;
informat DIRACC $3. ;
informat DIRACC_ $3. ;
informat AGE_REF best32. ;
informat AGE_REF_ $3. ;
informat AGE2 best32. ;
informat AGE2_ $3. ;
informat AS_COMP1 best32. ;
informat AS_C_MP1 $3. ;
informat AS_COMP2 best32. ;
informat AS_C_MP2 $3. ;
informat AS_COMP3 best32. ;
informat AS_C_MP3 $3. ;
informat AS_COMP4 best32. ;
informat AS_C_MP4 $3. ;
informat AS_COMP5 best32. ;
informat AS_C_MP5 $3. ;
informat BATHRMQ best32. ;
informat BATHRMQ_ $3. ;
informat BEDROOMQ best32. ;
informat BEDR_OMQ $3. ;
informat BLS_URBN $3. ;
informat BSINVSTX best32. ;
informat BSIN_STX $3. ;
informat BUILDING $4. ;
informat BUIL_ING $3. ;
informat CKBKACTX best32. ;
informat CKBK_CTX $3. ;
informat COMPBND $4. ;
informat COMPBND_ $3. ;
informat COMPBNDX best32. ;
informat COMP_NDX $3. ;
informat COMPCKG $4. ;
informat COMPCKG_ $3. ;
informat COMPCKGX best32. ;
informat COMP_KGX $3. ;
informat COMPENSX best32. ;
informat COMP_NSX $3. ;
informat COMPOWD $1. ;
informat COMPOWD_ $3. ;
informat COMPOWDX best32. ;
informat COMP_WDX $3. ;
informat COMPSAV $4. ;
informat COMPSAV_ $3. ;
informat COMPSAVX best32. ;
informat COMP_AVX $3. ;
informat COMPSEC $4. ;
informat COMPSEC_ $3. ;
informat COMPSECX best32. ;
informat COMP_ECX $3. ;
informat CUTENURE $3. ;
informat CUTE_URE $3. ;
informat EARNCOMP $3. ;
informat EARN_OMP $3. ;
informat EDUC_REF $4. ;
informat EDUC0REF $3. ;
informat EDUCA2 $5. ;
informat EDUCA2_ $3. ;
informat FAM_SIZE best32. ;
informat FAM__IZE $3. ;
informat FAM_TYPE $3. ;
informat FAM__YPE $3. ;
informat FAMTFEDX best32. ;
informat FAMT_EDX $3. ;
informat FEDRFNDX best32. ;
informat FEDR_NDX $3. ;
informat FEDTAXX best32. ;
informat FEDTAXX_ $3. ;
informat FFRMINCX best32. ;
informat FFRM_NCX $3. ;
informat FGOVRETX best32. ;
informat FGOV_ETX $3. ;
informat FINCATAX best32. ;
informat FINCAT_X $3. ;
informat FINCBTAX best32. ;
informat FINCBT_X $3. ;
informat FINDRETX best32. ;
informat FIND_ETX $3. ;
informat FININCX best32. ;
informat FININCX_ $3. ;
informat FINLWT21 best32. ;
informat FJSSDEDX best32. ;
informat FJSS_EDX $3. ;
informat FNONFRMX best32. ;
informat FNON_RMX $3. ;
informat FPRIPENX best32. ;
informat FPRI_ENX $3. ;
informat FRRDEDX best32. ;
informat FRRDEDX_ $3. ;
informat FRRETIRX best32. ;
informat FRRE_IRX $3. ;
informat FSALARYX best32. ;
informat FSAL_RYX $3. ;
informat FSLTAXX best32. ;
informat FSLTAXX_ $3. ;
informat FSSIX best32. ;
informat FSSIX_ $3. ;
informat GOVTCOST $3. ;
informat GOVT_OST $3. ;
informat HLFBATHQ best32. ;
informat HLFB_THQ $3. ;
informat INC_HRS1 best32. ;
informat INC__RS1 $3. ;
informat INC_HRS2 best32. ;
informat INC__RS2 $3. ;
informat INC_RANK best32. ;
informat INC__ANK $3. ;
informat INCLOSSA best32. ;
informat INCL_SSA $3. ;
informat INCLOSSB best32. ;
informat INCL_SSB $3. ;
informat INCNONW1 $3. ;
informat INCN_NW1 $3. ;
informat INCNONW2 $4. ;
informat INCN_NW2 $3. ;
informat INCOMEY1 $4. ;
informat INCO_EY1 $3. ;
informat INCOMEY2 $4. ;
informat INCO_EY2 $3. ;
informat INCWEEK1 best32. ;
informat INCW_EK1 $3. ;
informat INCWEEK2 best32. ;
informat INCW_EK2 $3. ;
informat INSRFNDX best32. ;
informat INSR_NDX $3. ;
informat INTEARNX best32. ;
informat INTE_RNX $3. ;
informat MISCTAXX best32. ;
informat MISC_AXX $3. ;
informat LUMPSUMX best32. ;
informat LUMP_UMX $3. ;
informat MARITAL1 $3. ;
informat MARI_AL1 $3. ;
informat MONYOWDX best32. ;
informat MONY_WDX $3. ;
informat NO_EARNR best32. ;
informat NO_E_RNR $3. ;
informat NONINCMX best32. ;
informat NONI_CMX $3. ;
informat NUM_AUTO best32. ;
informat NUM__UTO $3. ;
informat OCCUCOD1 $5. ;
informat OCCU_OD1 $3. ;
informat OCCUCOD2 $5. ;
informat OCCU_OD2 $3. ;
informat OTHRFNDX best32. ;
informat OTHR_NDX $3. ;
informat OTHRINCX best32. ;
informat OTHR_NCX $3. ;
informat PENSIONX best32. ;
informat PENS_ONX $3. ;
informat PERSLT18 best32. ;
informat PERS_T18 $3. ;
informat PERSOT64 best32. ;
informat PERS_T64 $3. ;
informat POPSIZE $3. ;
informat PRINEARN $4. ;
informat PRIN_ARN $3. ;
informat PTAXRFDX best32. ;
informat PTAX_FDX $3. ;
informat PUBLHOUS $3. ;
informat PUBL_OUS $3. ;
informat PURSSECX best32. ;
informat PURS_ECX $3. ;
informat QINTRVMO $2. ;
informat QINTRVYR 4. ;
informat RACE2 $4. ;
informat RACE2_ $3. ;
informat REF_RACE $3. ;
informat REF__ACE $3. ;
informat REGION $3. ;
informat RENTEQVX best32. ;
informat RENT_QVX $3. ;
informat RESPSTAT $3. ;
informat RESP_TAT $3. ;
informat ROOMSQ best32. ;
informat ROOMSQ_ $3. ;
informat SALEINCX best32. ;
informat SALE_NCX $3. ;
informat SAVACCTX best32. ;
informat SAVA_CTX $3. ;
informat SECESTX best32. ;
informat SECESTX_ $3. ;
informat SELLSECX best32. ;
informat SELL_ECX $3. ;
informat SETLINSX best32. ;
informat SETL_NSX $3. ;
informat SEX_REF $3. ;
informat SEX_REF_ $3. ;
informat SEX2 $4. ;
informat SEX2_ $3. ;
informat SLOCTAXX best32. ;
informat SLOC_AXX $3. ;
informat SLRFUNDX best32. ;
informat SLRF_NDX $3. ;
informat SMSASTAT $3. ;
informat SSOVERPX best32. ;
informat SSOV_RPX $3. ;
informat ST_HOUS $3. ;
informat ST_HOUS_ $3. ;
informat TAXPROPX best32. ;
informat TAXP_OPX $3. ;
informat TOTTXPDX best32. ;
informat TOTT_PDX $3. ;
informat UNEMPLX best32. ;
informat UNEMPLX_ $3. ;
informat USBNDX best32. ;
informat USBNDX_ $3. ;
informat VEHQ best32. ;
informat VEHQ_ $3. ;
informat WDBSASTX best32. ;
informat WDBS_STX $3. ;
informat WDBSGDSX best32. ;
informat WDBS_DSX $3. ;
informat WELFAREX best32. ;
informat WELF_REX $3. ;
informat WTREP01 best32. ;
informat WTREP02 best32. ;
informat WTREP03 best32. ;
informat WTREP04 best32. ;
informat WTREP05 best32. ;
informat WTREP06 best32. ;
informat WTREP07 best32. ;
informat WTREP08 best32. ;
informat WTREP09 best32. ;
informat WTREP10 best32. ;
informat WTREP11 best32. ;
informat WTREP12 best32. ;
informat WTREP13 best32. ;
informat WTREP14 best32. ;
informat WTREP15 best32. ;
informat WTREP16 best32. ;
informat WTREP17 best32. ;
informat WTREP18 best32. ;
informat WTREP19 best32. ;
informat WTREP20 best32. ;
informat WTREP21 best32. ;
informat WTREP22 best32. ;
informat WTREP23 best32. ;
informat WTREP24 best32. ;
informat WTREP25 best32. ;
informat WTREP26 best32. ;
informat WTREP27 best32. ;
informat WTREP28 best32. ;
informat WTREP29 best32. ;
informat WTREP30 best32. ;
informat WTREP31 best32. ;
informat WTREP32 best32. ;
informat WTREP33 best32. ;
informat WTREP34 best32. ;
informat WTREP35 best32. ;
informat WTREP36 best32. ;
informat WTREP37 best32. ;
informat WTREP38 best32. ;
informat WTREP39 best32. ;
informat WTREP40 best32. ;
informat WTREP41 best32. ;
informat WTREP42 best32. ;
informat WTREP43 best32. ;
informat WTREP44 best32. ;
informat TOTEXPPQ best32. ;
informat TOTEXPCQ best32. ;
informat FOODPQ best32. ;
informat FOODCQ best32. ;
informat FDHOMEPQ best32. ;
informat FDHOMECQ best32. ;
informat FDAWAYPQ best32. ;
informat FDAWAYCQ best32. ;
informat FDXMAPPQ best32. ;
informat FDXMAPCQ best32. ;
informat FDMAPPQ best32. ;
informat FDMAPCQ best32. ;
informat ALCBEVPQ best32. ;
informat ALCBEVCQ best32. ;
informat HOUSPQ best32. ;
informat HOUSCQ best32. ;
informat SHELTPQ best32. ;
informat SHELTCQ best32. ;
informat OWNDWEPQ best32. ;
informat OWNDWECQ best32. ;
informat MRTINTPQ best32. ;
informat MRTINTCQ best32. ;
informat PROPTXPQ best32. ;
informat PROPTXCQ best32. ;
informat MRPINSPQ best32. ;
informat MRPINSCQ best32. ;
informat RENDWEPQ best32. ;
informat RENDWECQ best32. ;
informat RNTXRPPQ best32. ;
informat RNTXRPCQ best32. ;
informat RNTAPYPQ best32. ;
informat RNTAPYCQ best32. ;
informat OTHLODPQ best32. ;
informat OTHLODCQ best32. ;
informat UTILPQ best32. ;
informat UTILCQ best32. ;
informat NTLGASPQ best32. ;
informat NTLGASCQ best32. ;
informat ELCTRCPQ best32. ;
informat ELCTRCCQ best32. ;
informat ALLFULPQ best32. ;
informat ALLFULCQ best32. ;
informat FULOILPQ best32. ;
informat FULOILCQ best32. ;
informat OTHFLSPQ best32. ;
informat OTHFLSCQ best32. ;
informat TELEPHPQ best32. ;
informat TELEPHCQ best32. ;
informat WATRPSPQ best32. ;
informat WATRPSCQ best32. ;
informat HOUSOPPQ best32. ;
informat HOUSOPCQ best32. ;
informat DOMSRVPQ best32. ;
informat DOMSRVCQ best32. ;
informat DMSXCCPQ best32. ;
informat DMSXCCCQ best32. ;
informat BBYDAYPQ best32. ;
informat BBYDAYCQ best32. ;
informat OTHHEXPQ best32. ;
informat OTHHEXCQ best32. ;
informat HOUSEQPQ best32. ;
informat HOUSEQCQ best32. ;
informat TEXTILPQ best32. ;
informat TEXTILCQ best32. ;
informat FURNTRPQ best32. ;
informat FURNTRCQ best32. ;
informat FLRCVRPQ best32. ;
informat FLRCVRCQ best32. ;
informat MAJAPPPQ best32. ;
informat MAJAPPCQ best32. ;
informat SMLAPPPQ best32. ;
informat SMLAPPCQ best32. ;
informat MISCEQPQ best32. ;
informat MISCEQCQ best32. ;
informat APPARPQ best32. ;
informat APPARCQ best32. ;
informat MENBOYPQ best32. ;
informat MENBOYCQ best32. ;
informat MENSIXPQ best32. ;
informat MENSIXCQ best32. ;
informat BOYFIFPQ best32. ;
informat BOYFIFCQ best32. ;
informat WOMGRLPQ best32. ;
informat WOMGRLCQ best32. ;
informat WOMSIXPQ best32. ;
informat WOMSIXCQ best32. ;
informat GRLFIFPQ best32. ;
informat GRLFIFCQ best32. ;
informat CHLDRNPQ best32. ;
informat CHLDRNCQ best32. ;
informat FOOTWRPQ best32. ;
informat FOOTWRCQ best32. ;
informat OTHAPLPQ best32. ;
informat OTHAPLCQ best32. ;
informat TRANSPQ best32. ;
informat TRANSCQ best32. ;
informat CARTKNPQ best32. ;
informat CARTKNCQ best32. ;
informat CARTKUPQ best32. ;
informat CARTKUCQ best32. ;
informat OTHVEHPQ best32. ;
informat OTHVEHCQ best32. ;
informat GASMOPQ best32. ;
informat GASMOCQ best32. ;
informat VEHFINPQ best32. ;
informat VEHFINCQ best32. ;
informat MAINRPPQ best32. ;
informat MAINRPCQ best32. ;
informat VEHINSPQ best32. ;
informat VEHINSCQ best32. ;
informat VRNTLOPQ best32. ;
informat VRNTLOCQ best32. ;
informat PUBTRAPQ best32. ;
informat PUBTRACQ best32. ;
informat TRNTRPPQ best32. ;
informat TRNTRPCQ best32. ;
informat TRNOTHPQ best32. ;
informat TRNOTHCQ best32. ;
informat HEALTHPQ best32. ;
informat HEALTHCQ best32. ;
informat HLTHINPQ best32. ;
informat HLTHINCQ best32. ;
informat MEDSRVPQ best32. ;
informat MEDSRVCQ best32. ;
informat PREDRGPQ best32. ;
informat PREDRGCQ best32. ;
informat MEDSUPPQ best32. ;
informat MEDSUPCQ best32. ;
informat ENTERTPQ best32. ;
informat ENTERTCQ best32. ;
informat FEEADMPQ best32. ;
informat FEEADMCQ best32. ;
informat TVRDIOPQ best32. ;
informat TVRDIOCQ best32. ;
informat OTHEQPPQ best32. ;
informat OTHEQPCQ best32. ;
informat PETTOYPQ best32. ;
informat PETTOYCQ best32. ;
informat OTHENTPQ best32. ;
informat OTHENTCQ best32. ;
informat PERSCAPQ best32. ;
informat PERSCACQ best32. ;
informat READPQ best32. ;
informat READCQ best32. ;
informat EDUCAPQ best32. ;
informat EDUCACQ best32. ;
informat TOBACCPQ best32. ;
informat TOBACCCQ best32. ;
informat MISCPQ best32. ;
informat MISCCQ best32. ;
informat MISC1PQ best32. ;
informat MISC1CQ best32. ;
informat MISC2PQ best32. ;
informat MISC2CQ best32. ;
informat CASHCOPQ best32. ;
informat CASHCOCQ best32. ;
informat PERINSPQ best32. ;
informat PERINSCQ best32. ;
informat LIFINSPQ best32. ;
informat LIFINSCQ best32. ;
informat RETPENPQ best32. ;
informat RETPENCQ best32. ;
informat HH_CU_Q best32. ;
informat HH_CU_Q_ $3. ;
informat HHID best32. ;
informat HHID_ $3. ;
informat POV_CY $3. ;
informat POV_CY_ $3. ;
informat POV_PY $3. ;
informat POV_PY_ $3. ;
informat HEATFUEL $4. ;
informat HEAT_UEL $3. ;
informat SWIMPOOL $5. ;
informat SWIM_OOL $3. ;
informat WATERHT $4. ;
informat WATERHT_ $3. ;
informat APTMENT $1. ;
informat APTMENT_ $3. ;
informat OFSTPARK $4. ;
informat OFST_ARK $3. ;
informat WINDOWAC $5. ;
informat WIND_WAC $3. ;
informat CNTRALAC $4. ;
informat CNTR_LAC $3. ;
informat CHILDAGE $3. ;
informat CHIL_AGE $3. ;
informat INCLASS $4. ;
informat STATE $4. ;
informat CHDOTHX best32. ;
informat CHDOTHX_ $3. ;
informat ALIOTHX best32. ;
informat ALIOTHX_ $3. ;
informat CHDLMPX best32. ;
informat CHDLMPX_ $3. ;
informat ERANKH best32. ;
informat ERANKH_ $3. ;
informat TOTEX4PQ best32. ;
informat TOTEX4CQ best32. ;
informat MISCX4PQ best32. ;
informat MISCX4CQ best32. ;
informat VEHQL best32. ;
informat VEHQL_ $3. ;
informat NUM_TVAN best32. ;
informat NUM__VAN $3. ;
informat TTOTALP best32. ;
informat TTOTALC best32. ;
informat TFOODTOP best32. ;
informat TFOODTOC best32. ;
informat TFOODAWP best32. ;
informat TFOODAWC best32. ;
informat TFOODHOP best32. ;
informat TFOODHOC best32. ;
informat TALCBEVP best32. ;
informat TALCBEVC best32. ;
informat TOTHRLOP best32. ;
informat TOTHRLOC best32. ;
informat TTRANPRP best32. ;
informat TTRANPRC best32. ;
informat TGASMOTP best32. ;
informat TGASMOTC best32. ;
informat TVRENTLP best32. ;
informat TVRENTLC best32. ;
informat TCARTRKP best32. ;
informat TCARTRKC best32. ;
informat TOTHVHRP best32. ;
informat TOTHVHRC best32. ;
informat TOTHTREP best32. ;
informat TOTHTREC best32. ;
informat TTRNTRIP best32. ;
informat TTRNTRIC best32. ;
informat TFAREP best32. ;
informat TFAREC best32. ;
informat TAIRFARP best32. ;
informat TAIRFARC best32. ;
informat TOTHFARP best32. ;
informat TOTHFARC best32. ;
informat TLOCALTP best32. ;
informat TLOCALTC best32. ;
informat TENTRMNP best32. ;
informat TENTRMNC best32. ;
informat TFEESADP best32. ;
informat TFEESADC best32. ;
informat TOTHENTP best32. ;
informat TOTHENTC best32. ;
informat OWNVACP best32. ;
informat OWNVACC best32. ;
informat VOTHRLOP best32. ;
informat VOTHRLOC best32. ;
informat VMISCHEP best32. ;
informat VMISCHEC best32. ;
informat UTILOWNP best32. ;
informat UTILOWNC best32. ;
informat VFUELOIP best32. ;
informat VFUELOIC best32. ;
informat VOTHRFLP best32. ;
informat VOTHRFLC best32. ;
informat VELECTRP best32. ;
informat VELECTRC best32. ;
informat VNATLGAP best32. ;
informat VNATLGAC best32. ;
informat VWATERPP best32. ;
informat VWATERPC best32. ;
informat MRTPRNOP best32. ;
informat MRTPRNOC best32. ;
informat UTILRNTP best32. ;
informat UTILRNTC best32. ;
informat RFUELOIP best32. ;
informat RFUELOIC best32. ;
informat ROTHRFLP best32. ;
informat ROTHRFLC best32. ;
informat RELECTRP best32. ;
informat RELECTRC best32. ;
informat RNATLGAP best32. ;
informat RNATLGAC best32. ;
informat RWATERPP best32. ;
informat RWATERPC best32. ;
informat POVLEVCY best32. ;
informat POVL_VCY $3. ;
informat POVLEVPY best32. ;
informat POVL_VPY $3. ;
informat COOKING $4. ;
informat COOKING_ $3. ;
informat PORCH $4. ;
informat PORCH_ $3. ;
informat ETOTALP best32. ;
informat ETOTALC best32. ;
informat ETOTAPX4 best32. ;
informat ETOTACX4 best32. ;
informat EHOUSNGP best32. ;
informat EHOUSNGC best32. ;
informat ESHELTRP best32. ;
informat ESHELTRC best32. ;
informat EOWNDWLP best32. ;
informat EOWNDWLC best32. ;
informat EOTHLODP best32. ;
informat EOTHLODC best32. ;
informat EMRTPNOP best32. ;
informat EMRTPNOC best32. ;
informat EMRTPNVP best32. ;
informat EMRTPNVC best32. ;
informat ETRANPTP best32. ;
informat ETRANPTC best32. ;
informat EVEHPURP best32. ;
informat EVEHPURC best32. ;
informat ECARTKNP best32. ;
informat ECARTKNC best32. ;
informat ECARTKUP best32. ;
informat ECARTKUC best32. ;
informat EOTHVEHP best32. ;
informat EOTHVEHC best32. ;
informat EENTRMTP best32. ;
informat EENTRMTC best32. ;
informat EOTHENTP best32. ;
informat EOTHENTC best32. ;
informat ENOMOTRP best32. ;
informat ENOMOTRC best32. ;
informat EMOTRVHP best32. ;
informat EMOTRVHC best32. ;
informat EENTMSCP best32. ;
informat EENTMSCC best32. ;
informat EMISCELP best32. ;
informat EMISCELC best32. ;
informat EMISCMTP best32. ;
informat EMISCMTC best32. ;
informat UNISTRQ $4. ;
informat UNISTRQ_ $3. ;
informat INTEARNB $5. ;
informat INTE_RNB $3. ;
informat INTERNBX best32. ;
informat INTE_NBX $3. ;
informat FININCB $1. ;
informat FININCB_ $3. ;
informat FININCBX best32. ;
informat FINI_CBX $3. ;
informat PENSIONB $5. ;
informat PENS_ONB $3. ;
informat PNSIONBX best32. ;
informat PNSI_NBX $3. ;
informat UNEMPLB $1. ;
informat UNEMPLB_ $3. ;
informat UNEMPLBX best32. ;
informat UNEM_LBX $3. ;
informat COMPENSB $1. ;
informat COMP_NSB $3. ;
informat COMPNSBX best32. ;
informat COMP_SBX $3. ;
informat WELFAREB $1. ;
informat WELF_REB $3. ;
informat WELFREBX best32. ;
informat WELF_EBX $3. ;
informat FOODSMPX best32. ;
informat FOOD_MPX $3. ;
informat FOODSMPB $1. ;
informat FOOD_MPB $3. ;
informat FOODSPBX best32. ;
informat FOOD_PBX $3. ;
informat INCLOSAB $1. ;
informat INCL_SAB $3. ;
informat INCLSABX best32. ;
informat INCL_ABX $3. ;
informat INCLOSBB $1. ;
informat INCL_SBB $3. ;
informat INCLSBBX best32. ;
informat INCL_BBX $3. ;
informat CHDLMPB $1. ;
informat CHDLMPB_ $3. ;
informat CHDLMPBX best32. ;
informat CHDL_PBX $3. ;
informat CHDOTHB $1. ;
informat CHDOTHB_ $3. ;
informat CHDOTHBX best32. ;
informat CHDO_HBX $3. ;
informat ALIOTHB $1. ;
informat ALIOTHB_ $3. ;
informat ALIOTHBX best32. ;
informat ALIO_HBX $3. ;
informat LUMPSUMB $1. ;
informat LUMP_UMB $3. ;
informat LMPSUMBX best32. ;
informat LMPS_MBX $3. ;
informat SALEINCB $1. ;
informat SALE_NCB $3. ;
informat SALINCBX best32. ;
informat SALI_CBX $3. ;
informat OTHRINCB $1. ;
informat OTHR_NCB $3. ;
informat OTRINCBX best32. ;
informat OTRI_CBX $3. ;
informat INCLASS2 $3. ;
informat INCL_SS2 $3. ;
informat CUID best32. ;
informat INTERI best32. ;
informat HORREF1 $4. ;
informat HORREF1_ $3. ;
informat HORREF2 $4. ;
informat HORREF2_ $3. ;
informat ALIOTHXM best32. ;
informat ALIO_HXM $3. ;
informat ALIOTHX1 best32. ;
informat ALIOTHX2 best32. ;
informat ALIOTHX3 best32. ;
informat ALIOTHX4 best32. ;
informat ALIOTHX5 best32. ;
informat ALIOTHXI best32. ;
informat CHDOTHXM best32. ;
informat CHDO_HXM $3. ;
informat CHDOTHX1 best32. ;
informat CHDOTHX2 best32. ;
informat CHDOTHX3 best32. ;
informat CHDOTHX4 best32. ;
informat CHDOTHX5 best32. ;
informat CHDOTHXI best32. ;
informat COMPENSM best32. ;
informat COMP_NSM $3. ;
informat COMPENS1 best32. ;
informat COMPENS2 best32. ;
informat COMPENS3 best32. ;
informat COMPENS4 best32. ;
informat COMPENS5 best32. ;
informat COMPENSI best32. ;
informat ERANKHM best32. ;
informat ERANKHM_ $3. ;
informat FAMTFEDM best32. ;
informat FAMT_EDM $3. ;
informat FAMTFED1 best32. ;
informat FAMTFED2 best32. ;
informat FAMTFED3 best32. ;
informat FAMTFED4 best32. ;
informat FAMTFED5 best32. ;
informat FFRMINCM best32. ;
informat FFRM_NCM $3. ;
informat FFRMINC1 best32. ;
informat FFRMINC2 best32. ;
informat FFRMINC3 best32. ;
informat FFRMINC4 best32. ;
informat FFRMINC5 best32. ;
informat FFRMINCI best32. ;
informat FGOVRETM best32. ;
informat FGOV_ETM $3. ;
informat FINCATXM best32. ;
informat FINCA_XM $3. ;
informat FINCATX1 best32. ;
informat FINCATX2 best32. ;
informat FINCATX3 best32. ;
informat FINCATX4 best32. ;
informat FINCATX5 best32. ;
informat FINCBTXM best32. ;
informat FINCB_XM $3. ;
informat FINCBTX1 best32. ;
informat FINCBTX2 best32. ;
informat FINCBTX3 best32. ;
informat FINCBTX4 best32. ;
informat FINCBTX5 best32. ;
informat FINCBTXI best32. ;
informat FININCXM best32. ;
informat FINI_CXM $3. ;
informat FININCX1 best32. ;
informat FININCX2 best32. ;
informat FININCX3 best32. ;
informat FININCX4 best32. ;
informat FININCX5 best32. ;
informat FININCXI best32. ;
informat FJSSDEDM best32. ;
informat FJSS_EDM $3. ;
informat FJSSDED1 best32. ;
informat FJSSDED2 best32. ;
informat FJSSDED3 best32. ;
informat FJSSDED4 best32. ;
informat FJSSDED5 best32. ;
informat FNONFRMM best32. ;
informat FNON_RMM $3. ;
informat FNONFRM1 best32. ;
informat FNONFRM2 best32. ;
informat FNONFRM3 best32. ;
informat FNONFRM4 best32. ;
informat FNONFRM5 best32. ;
informat FNONFRMI best32. ;
informat FOODSMPM best32. ;
informat FOOD_MPM $3. ;
informat FOODSMP1 best32. ;
informat FOODSMP2 best32. ;
informat FOODSMP3 best32. ;
informat FOODSMP4 best32. ;
informat FOODSMP5 best32. ;
informat FOODSMPI best32. ;
informat FPRIPENM best32. ;
informat FPRI_ENM $3. ;
informat FRRDEDM best32. ;
informat FRRDEDM_ $3. ;
informat FRRETIRM best32. ;
informat FRRE_IRM $3. ;
informat FRRETIR1 best32. ;
informat FRRETIR2 best32. ;
informat FRRETIR3 best32. ;
informat FRRETIR4 best32. ;
informat FRRETIR5 best32. ;
informat FRRETIRI best32. ;
informat FSALARYM best32. ;
informat FSAL_RYM $3. ;
informat FSALARY1 best32. ;
informat FSALARY2 best32. ;
informat FSALARY3 best32. ;
informat FSALARY4 best32. ;
informat FSALARY5 best32. ;
informat FSALARYI best32. ;
informat FSLTAXXM best32. ;
informat FSLT_XXM $3. ;
informat FSLTAXX1 best32. ;
informat FSLTAXX2 best32. ;
informat FSLTAXX3 best32. ;
informat FSLTAXX4 best32. ;
informat FSLTAXX5 best32. ;
informat FSSIXM best32. ;
informat FSSIXM_ $3. ;
informat FSSIX1 best32. ;
informat FSSIX2 best32. ;
informat FSSIX3 best32. ;
informat FSSIX4 best32. ;
informat FSSIX5 best32. ;
informat FSSIXI best32. ;
informat INC_RNKM best32. ;
informat INC__NKM $3. ;
informat INC_RNK1 best32. ;
informat INC_RNK2 best32. ;
informat INC_RNK3 best32. ;
informat INC_RNK4 best32. ;
informat INC_RNK5 best32. ;
informat INCLOSAM best32. ;
informat INCL_SAM $3. ;
informat INCLOSA1 best32. ;
informat INCLOSA2 best32. ;
informat INCLOSA3 best32. ;
informat INCLOSA4 best32. ;
informat INCLOSA5 best32. ;
informat INCLOSAI best32. ;
informat INCLOSBM best32. ;
informat INCL_SBM $3. ;
informat INCLOSB1 best32. ;
informat INCLOSB2 best32. ;
informat INCLOSB3 best32. ;
informat INCLOSB4 best32. ;
informat INCLOSB5 best32. ;
informat INCLOSBI best32. ;
informat INTEARNM best32. ;
informat INTE_RNM $3. ;
informat INTEARN1 best32. ;
informat INTEARN2 best32. ;
informat INTEARN3 best32. ;
informat INTEARN4 best32. ;
informat INTEARN5 best32. ;
informat INTEARNI best32. ;
informat OTHRINCM best32. ;
informat OTHR_NCM $3. ;
informat OTHRINC1 best32. ;
informat OTHRINC2 best32. ;
informat OTHRINC3 best32. ;
informat OTHRINC4 best32. ;
informat OTHRINC5 best32. ;
informat OTHRINCI best32. ;
informat PENSIONM best32. ;
informat PENS_ONM $3. ;
informat PENSION1 best32. ;
informat PENSION2 best32. ;
informat PENSION3 best32. ;
informat PENSION4 best32. ;
informat PENSION5 best32. ;
informat PENSIONI best32. ;
informat POV_CYM $3. ;
informat POV_CYM_ $3. ;
informat POV_CY1 $3. ;
informat POV_CY2 $3. ;
informat POV_CY3 $3. ;
informat POV_CY4 $3. ;
informat POV_CY5 $3. ;
informat POV_PYM $3. ;
informat POV_PYM_ $3. ;
informat POV_PY1 $3. ;
informat POV_PY2 $3. ;
informat POV_PY3 $3. ;
informat POV_PY4 $3. ;
informat POV_PY5 $3. ;
informat PRINERNM $4. ;
informat PRIN_RNM $3. ;
informat PRINERN1 $4. ;
informat PRINERN2 $4. ;
informat PRINERN3 $4. ;
informat PRINERN4 $4. ;
informat PRINERN5 $4. ;
informat TOTTXPDM best32. ;
informat TOTT_PDM $3. ;
informat TOTTXPD1 best32. ;
informat TOTTXPD2 best32. ;
informat TOTTXPD3 best32. ;
informat TOTTXPD4 best32. ;
informat TOTTXPD5 best32. ;
informat UNEMPLXM best32. ;
informat UNEM_LXM $3. ;
informat UNEMPLX1 best32. ;
informat UNEMPLX2 best32. ;
informat UNEMPLX3 best32. ;
informat UNEMPLX4 best32. ;
informat UNEMPLX5 best32. ;
informat UNEMPLXI best32. ;
informat WELFAREM best32. ;
informat WELF_REM $3. ;
informat WELFARE1 best32. ;
informat WELFARE2 best32. ;
informat WELFARE3 best32. ;
informat WELFARE4 best32. ;
informat WELFARE5 best32. ;
informat WELFAREI best32. ;
informat COLPLAN $4. ;
informat COLPLAN_ $3. ;
informat COLPLANX best32. ;
informat COLP_ANX $3. ;
informat PSU $8. ;
informat REVSMORT $4. ;
informat REVS_ORT $3. ;
informat RVSLUMP $1. ;
informat RVSLUMP_ $3. ;
informat RVSREGMO $1. ;
informat RVSR_GMO $3. ;
informat RVSLOC $1. ;
informat RVSLOC_ $3. ;
informat RVSOTHPY $1. ;
informat RVSO_HPY $3. ;
informat TYPEPYX best32. ;
informat TYPEPYX_ $3. ;
informat HISP_REF $3. ;
informat HISP2 $4. ;
informat BUILT $8. ;
informat BUILT_ $3. ;
input
NEWID
DIRACC $
DIRACC_ $
AGE_REF
AGE_REF_ $
AGE2
AGE2_ $
AS_COMP1
AS_C_MP1 $
AS_COMP2
AS_C_MP2 $
AS_COMP3
AS_C_MP3 $
AS_COMP4
AS_C_MP4 $
AS_COMP5
AS_C_MP5 $
BATHRMQ
BATHRMQ_ $
BEDROOMQ
BEDR_OMQ $
BLS_URBN $
BSINVSTX
BSIN_STX $
BUILDING $
BUIL_ING $
CKBKACTX
CKBK_CTX $
COMPBND $
COMPBND_ $
COMPBNDX
COMP_NDX $
COMPCKG $
COMPCKG_ $
COMPCKGX
COMP_KGX $
COMPENSX
COMP_NSX $
COMPOWD $
COMPOWD_ $
COMPOWDX
COMP_WDX $
COMPSAV $
COMPSAV_ $
COMPSAVX
COMP_AVX $
COMPSEC $
COMPSEC_ $
COMPSECX
COMP_ECX $
CUTENURE $
CUTE_URE $
EARNCOMP $
EARN_OMP $
EDUC_REF $
EDUC0REF $
EDUCA2 $
EDUCA2_ $
FAM_SIZE
FAM__IZE $
FAM_TYPE $
FAM__YPE $
FAMTFEDX
FAMT_EDX $
FEDRFNDX
FEDR_NDX $
FEDTAXX
FEDTAXX_ $
FFRMINCX
FFRM_NCX $
FGOVRETX
FGOV_ETX $
FINCATAX
FINCAT_X $
FINCBTAX
FINCBT_X $
FINDRETX
FIND_ETX $
FININCX
FININCX_ $
FINLWT21
FJSSDEDX
FJSS_EDX $
FNONFRMX
FNON_RMX $
FPRIPENX
FPRI_ENX $
FRRDEDX
FRRDEDX_ $
FRRETIRX
FRRE_IRX $
FSALARYX
FSAL_RYX $
FSLTAXX
FSLTAXX_ $
FSSIX
FSSIX_ $
GOVTCOST $
GOVT_OST $
HLFBATHQ
HLFB_THQ $
INC_HRS1
INC__RS1 $
INC_HRS2
INC__RS2 $
INC_RANK
INC__ANK $
INCLOSSA
INCL_SSA $
INCLOSSB
INCL_SSB $
INCNONW1 $
INCN_NW1 $
INCNONW2 $
INCN_NW2 $
INCOMEY1 $
INCO_EY1 $
INCOMEY2 $
INCO_EY2 $
INCWEEK1
INCW_EK1 $
INCWEEK2
INCW_EK2 $
INSRFNDX
INSR_NDX $
INTEARNX
INTE_RNX $
MISCTAXX
MISC_AXX $
LUMPSUMX
LUMP_UMX $
MARITAL1 $
MARI_AL1 $
MONYOWDX
MONY_WDX $
NO_EARNR
NO_E_RNR $
NONINCMX
NONI_CMX $
NUM_AUTO
NUM__UTO $
OCCUCOD1 $
OCCU_OD1 $
OCCUCOD2 $
OCCU_OD2 $
OTHRFNDX
OTHR_NDX $
OTHRINCX
OTHR_NCX $
PENSIONX
PENS_ONX $
PERSLT18
PERS_T18 $
PERSOT64
PERS_T64 $
POPSIZE $
PRINEARN $
PRIN_ARN $
PTAXRFDX
PTAX_FDX $
PUBLHOUS $
PUBL_OUS $
PURSSECX
PURS_ECX $
QINTRVMO $
QINTRVYR
RACE2 $
RACE2_ $
REF_RACE $
REF__ACE $
REGION $
RENTEQVX
RENT_QVX $
RESPSTAT $
RESP_TAT $
ROOMSQ
ROOMSQ_ $
SALEINCX
SALE_NCX $
SAVACCTX
SAVA_CTX $
SECESTX
SECESTX_ $
SELLSECX
SELL_ECX $
SETLINSX
SETL_NSX $
SEX_REF $
SEX_REF_ $
SEX2 $
SEX2_ $
SLOCTAXX
SLOC_AXX $
SLRFUNDX
SLRF_NDX $
SMSASTAT $
SSOVERPX
SSOV_RPX $
ST_HOUS $
ST_HOUS_ $
TAXPROPX
TAXP_OPX $
TOTTXPDX
TOTT_PDX $
UNEMPLX
UNEMPLX_ $
USBNDX
USBNDX_ $
VEHQ
VEHQ_ $
WDBSASTX
WDBS_STX $
WDBSGDSX
WDBS_DSX $
WELFAREX
WELF_REX $
WTREP01
WTREP02
WTREP03
WTREP04
WTREP05
WTREP06
WTREP07
WTREP08
WTREP09
WTREP10
WTREP11
WTREP12
WTREP13
WTREP14
WTREP15
WTREP16
WTREP17
WTREP18
WTREP19
WTREP20
WTREP21
WTREP22
WTREP23
WTREP24
WTREP25
WTREP26
WTREP27
WTREP28
WTREP29
WTREP30
WTREP31
WTREP32
WTREP33
WTREP34
WTREP35
WTREP36
WTREP37
WTREP38
WTREP39
WTREP40
WTREP41
WTREP42
WTREP43
WTREP44
TOTEXPPQ
TOTEXPCQ
FOODPQ
FOODCQ
FDHOMEPQ
FDHOMECQ
FDAWAYPQ
FDAWAYCQ
FDXMAPPQ
FDXMAPCQ
FDMAPPQ
FDMAPCQ
ALCBEVPQ
ALCBEVCQ
HOUSPQ
HOUSCQ
SHELTPQ
SHELTCQ
OWNDWEPQ
OWNDWECQ
MRTINTPQ
MRTINTCQ
PROPTXPQ
PROPTXCQ
MRPINSPQ
MRPINSCQ
RENDWEPQ
RENDWECQ
RNTXRPPQ
RNTXRPCQ
RNTAPYPQ
RNTAPYCQ
OTHLODPQ
OTHLODCQ
UTILPQ
UTILCQ
NTLGASPQ
NTLGASCQ
ELCTRCPQ
ELCTRCCQ
ALLFULPQ
ALLFULCQ
FULOILPQ
FULOILCQ
OTHFLSPQ
OTHFLSCQ
TELEPHPQ
TELEPHCQ
WATRPSPQ
WATRPSCQ
HOUSOPPQ
HOUSOPCQ
DOMSRVPQ
DOMSRVCQ
DMSXCCPQ
DMSXCCCQ
BBYDAYPQ
BBYDAYCQ
OTHHEXPQ
OTHHEXCQ
HOUSEQPQ
HOUSEQCQ
TEXTILPQ
TEXTILCQ
FURNTRPQ
FURNTRCQ
FLRCVRPQ
FLRCVRCQ
MAJAPPPQ
MAJAPPCQ
SMLAPPPQ
SMLAPPCQ
MISCEQPQ
MISCEQCQ
APPARPQ
APPARCQ
MENBOYPQ
MENBOYCQ
MENSIXPQ
MENSIXCQ
BOYFIFPQ
BOYFIFCQ
WOMGRLPQ
WOMGRLCQ
WOMSIXPQ
WOMSIXCQ
GRLFIFPQ
GRLFIFCQ
CHLDRNPQ
CHLDRNCQ
FOOTWRPQ
FOOTWRCQ
OTHAPLPQ
OTHAPLCQ
TRANSPQ
TRANSCQ
CARTKNPQ
CARTKNCQ
CARTKUPQ
CARTKUCQ
OTHVEHPQ
OTHVEHCQ
GASMOPQ
GASMOCQ
VEHFINPQ
VEHFINCQ
MAINRPPQ
MAINRPCQ
VEHINSPQ
VEHINSCQ
VRNTLOPQ
VRNTLOCQ
PUBTRAPQ
PUBTRACQ
TRNTRPPQ
TRNTRPCQ
TRNOTHPQ
TRNOTHCQ
HEALTHPQ
HEALTHCQ
HLTHINPQ
HLTHINCQ
MEDSRVPQ
MEDSRVCQ
PREDRGPQ
PREDRGCQ
MEDSUPPQ
MEDSUPCQ
ENTERTPQ
ENTERTCQ
FEEADMPQ
FEEADMCQ
TVRDIOPQ
TVRDIOCQ
OTHEQPPQ
OTHEQPCQ
PETTOYPQ
PETTOYCQ
OTHENTPQ
OTHENTCQ
PERSCAPQ
PERSCACQ
READPQ
READCQ
EDUCAPQ
EDUCACQ
TOBACCPQ
TOBACCCQ
MISCPQ
MISCCQ
MISC1PQ
MISC1CQ
MISC2PQ
MISC2CQ
CASHCOPQ
CASHCOCQ
PERINSPQ
PERINSCQ
LIFINSPQ
LIFINSCQ
RETPENPQ
RETPENCQ
HH_CU_Q
HH_CU_Q_ $
HHID
HHID_ $
POV_CY $
POV_CY_ $
POV_PY $
POV_PY_ $
HEATFUEL $
HEAT_UEL $
SWIMPOOL $
SWIM_OOL $
WATERHT $
WATERHT_ $
APTMENT $
APTMENT_ $
OFSTPARK $
OFST_ARK $
WINDOWAC $
WIND_WAC $
CNTRALAC $
CNTR_LAC $
CHILDAGE $
CHIL_AGE $
INCLASS $
STATE $
CHDOTHX
CHDOTHX_ $
ALIOTHX
ALIOTHX_ $
CHDLMPX
CHDLMPX_ $
ERANKH
ERANKH_ $
TOTEX4PQ
TOTEX4CQ
MISCX4PQ
MISCX4CQ
VEHQL
VEHQL_ $
NUM_TVAN
NUM__VAN $
TTOTALP
TTOTALC
TFOODTOP
TFOODTOC
TFOODAWP
TFOODAWC
TFOODHOP
TFOODHOC
TALCBEVP
TALCBEVC
TOTHRLOP
TOTHRLOC
TTRANPRP
TTRANPRC
TGASMOTP
TGASMOTC
TVRENTLP
TVRENTLC
TCARTRKP
TCARTRKC
TOTHVHRP
TOTHVHRC
TOTHTREP
TOTHTREC
TTRNTRIP
TTRNTRIC
TFAREP
TFAREC
TAIRFARP
TAIRFARC
TOTHFARP
TOTHFARC
TLOCALTP
TLOCALTC
TENTRMNP
TENTRMNC
TFEESADP
TFEESADC
TOTHENTP
TOTHENTC
OWNVACP
OWNVACC
VOTHRLOP
VOTHRLOC
VMISCHEP
VMISCHEC
UTILOWNP
UTILOWNC
VFUELOIP
VFUELOIC
VOTHRFLP
VOTHRFLC
VELECTRP
VELECTRC
VNATLGAP
VNATLGAC
VWATERPP
VWATERPC
MRTPRNOP
MRTPRNOC
UTILRNTP
UTILRNTC
RFUELOIP
RFUELOIC
ROTHRFLP
ROTHRFLC
RELECTRP
RELECTRC
RNATLGAP
RNATLGAC
RWATERPP
RWATERPC
POVLEVCY
POVL_VCY $
POVLEVPY
POVL_VPY $
COOKING $
COOKING_ $
PORCH $
PORCH_ $
ETOTALP
ETOTALC
ETOTAPX4
ETOTACX4
EHOUSNGP
EHOUSNGC
ESHELTRP
ESHELTRC
EOWNDWLP
EOWNDWLC
EOTHLODP
EOTHLODC
EMRTPNOP
EMRTPNOC
EMRTPNVP
EMRTPNVC
ETRANPTP
ETRANPTC
EVEHPURP
EVEHPURC
ECARTKNP
ECARTKNC
ECARTKUP
ECARTKUC
EOTHVEHP
EOTHVEHC
EENTRMTP
EENTRMTC
EOTHENTP
EOTHENTC
ENOMOTRP
ENOMOTRC
EMOTRVHP
EMOTRVHC
EENTMSCP
EENTMSCC
EMISCELP
EMISCELC
EMISCMTP
EMISCMTC
UNISTRQ $
UNISTRQ_ $
INTEARNB $
INTE_RNB $
INTERNBX
INTE_NBX $
FININCB $
FININCB_ $
FININCBX
FINI_CBX $
PENSIONB $
PENS_ONB $
PNSIONBX
PNSI_NBX $
UNEMPLB $
UNEMPLB_ $
UNEMPLBX
UNEM_LBX $
COMPENSB $
COMP_NSB $
COMPNSBX
COMP_SBX $
WELFAREB $
WELF_REB $
WELFREBX
WELF_EBX $
FOODSMPX
FOOD_MPX $
FOODSMPB $
FOOD_MPB $
FOODSPBX
FOOD_PBX $
INCLOSAB $
INCL_SAB $
INCLSABX
INCL_ABX $
INCLOSBB $
INCL_SBB $
INCLSBBX
INCL_BBX $
CHDLMPB $
CHDLMPB_ $
CHDLMPBX
CHDL_PBX $
CHDOTHB $
CHDOTHB_ $
CHDOTHBX
CHDO_HBX $
ALIOTHB $
ALIOTHB_ $
ALIOTHBX
ALIO_HBX $
LUMPSUMB $
LUMP_UMB $
LMPSUMBX
LMPS_MBX $
SALEINCB $
SALE_NCB $
SALINCBX
SALI_CBX $
OTHRINCB $
OTHR_NCB $
OTRINCBX
OTRI_CBX $
INCLASS2 $
INCL_SS2 $
CUID
INTERI
HORREF1 $
HORREF1_ $
HORREF2 $
HORREF2_ $
ALIOTHXM
ALIO_HXM $
ALIOTHX1
ALIOTHX2
ALIOTHX3
ALIOTHX4
ALIOTHX5
ALIOTHXI
CHDOTHXM
CHDO_HXM $
CHDOTHX1
CHDOTHX2
CHDOTHX3
CHDOTHX4
CHDOTHX5
CHDOTHXI
COMPENSM
COMP_NSM $
COMPENS1
COMPENS2
COMPENS3
COMPENS4
COMPENS5
COMPENSI
ERANKHM
ERANKHM_ $
FAMTFEDM
FAMT_EDM $
FAMTFED1
FAMTFED2
FAMTFED3
FAMTFED4
FAMTFED5
FFRMINCM
FFRM_NCM $
FFRMINC1
FFRMINC2
FFRMINC3
FFRMINC4
FFRMINC5
FFRMINCI
FGOVRETM
FGOV_ETM $
FINCATXM
FINCA_XM $
FINCATX1
FINCATX2
FINCATX3
FINCATX4
FINCATX5
FINCBTXM
FINCB_XM $
FINCBTX1
FINCBTX2
FINCBTX3
FINCBTX4
FINCBTX5
FINCBTXI
FININCXM
FINI_CXM $
FININCX1
FININCX2
FININCX3
FININCX4
FININCX5
FININCXI
FJSSDEDM
FJSS_EDM $
FJSSDED1
FJSSDED2
FJSSDED3
FJSSDED4
FJSSDED5
FNONFRMM
FNON_RMM $
FNONFRM1
FNONFRM2
FNONFRM3
FNONFRM4
FNONFRM5
FNONFRMI
FOODSMPM
FOOD_MPM $
FOODSMP1
FOODSMP2
FOODSMP3
FOODSMP4
FOODSMP5
FOODSMPI
FPRIPENM
FPRI_ENM $
FRRDEDM
FRRDEDM_ $
FRRETIRM
FRRE_IRM $
FRRETIR1
FRRETIR2
FRRETIR3
FRRETIR4
FRRETIR5
FRRETIRI
FSALARYM
FSAL_RYM $
FSALARY1
FSALARY2
FSALARY3
FSALARY4
FSALARY5
FSALARYI
FSLTAXXM
FSLT_XXM $
FSLTAXX1
FSLTAXX2
FSLTAXX3
FSLTAXX4
FSLTAXX5
FSSIXM
FSSIXM_ $
FSSIX1
FSSIX2
FSSIX3
FSSIX4
FSSIX5
FSSIXI
INC_RNKM
INC__NKM $
INC_RNK1
INC_RNK2
INC_RNK3
INC_RNK4
INC_RNK5
INCLOSAM
INCL_SAM $
INCLOSA1
INCLOSA2
INCLOSA3
INCLOSA4
INCLOSA5
INCLOSAI
INCLOSBM
INCL_SBM $
INCLOSB1
INCLOSB2
INCLOSB3
INCLOSB4
INCLOSB5
INCLOSBI
INTEARNM
INTE_RNM $
INTEARN1
INTEARN2
INTEARN3
INTEARN4
INTEARN5
INTEARNI
OTHRINCM
OTHR_NCM $
OTHRINC1
OTHRINC2
OTHRINC3
OTHRINC4
OTHRINC5
OTHRINCI
PENSIONM
PENS_ONM $
PENSION1
PENSION2
PENSION3
PENSION4
PENSION5
PENSIONI
POV_CYM $
POV_CYM_ $
POV_CY1 $
POV_CY2 $
POV_CY3 $
POV_CY4 $
POV_CY5 $
POV_PYM $
POV_PYM_ $
POV_PY1 $
POV_PY2 $
POV_PY3 $
POV_PY4 $
POV_PY5 $
PRINERNM $
PRIN_RNM $
PRINERN1 $
PRINERN2 $
PRINERN3 $
PRINERN4 $
PRINERN5 $
TOTTXPDM
TOTT_PDM $
TOTTXPD1
TOTTXPD2
TOTTXPD3
TOTTXPD4
TOTTXPD5
UNEMPLXM
UNEM_LXM $
UNEMPLX1
UNEMPLX2
UNEMPLX3
UNEMPLX4
UNEMPLX5
UNEMPLXI
WELFAREM
WELF_REM $
WELFARE1
WELFARE2
WELFARE3
WELFARE4
WELFARE5
WELFAREI
COLPLAN $
COLPLAN_ $
COLPLANX
COLP_ANX $
PSU $
REVSMORT $
REVS_ORT $
RVSLUMP $
RVSLUMP_ $
RVSREGMO $
RVSR_GMO $
RVSLOC $
RVSLOC_ $
RVSOTHPY $
RVSO_HPY $
TYPEPYX
TYPEPYX_ $
HISP_REF $
HISP2 $
BUILT $
BUILT_ $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;


/**********************************************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\FMLI&YR1.2.CSV"
            OUT=FMLYI&YR1.2
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
************************************************************************************************/

data WORK.FMLYI112                                ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile 'C:\2011_CEX\Intrvw11\FMLI112.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat NEWID best32. ;
informat DIRACC $3. ;
informat DIRACC_ $3. ;
informat AGE_REF best32. ;
informat AGE_REF_ $3. ;
informat AGE2 best32. ;
informat AGE2_ $3. ;
informat AS_COMP1 best32. ;
informat AS_C_MP1 $3. ;
informat AS_COMP2 best32. ;
informat AS_C_MP2 $3. ;
informat AS_COMP3 best32. ;
informat AS_C_MP3 $3. ;
informat AS_COMP4 best32. ;
informat AS_C_MP4 $3. ;
informat AS_COMP5 best32. ;
informat AS_C_MP5 $3. ;
informat BATHRMQ best32. ;
informat BATHRMQ_ $3. ;
informat BEDROOMQ best32. ;
informat BEDR_OMQ $3. ;
informat BLS_URBN $3. ;
informat BSINVSTX best32. ;
informat BSIN_STX $3. ;
informat BUILDING $4. ;
informat BUIL_ING $3. ;
informat CKBKACTX best32. ;
informat CKBK_CTX $3. ;
informat COMPBND $4. ;
informat COMPBND_ $3. ;
informat COMPBNDX best32. ;
informat COMP_NDX $3. ;
informat COMPCKG $4. ;
informat COMPCKG_ $3. ;
informat COMPCKGX best32. ;
informat COMP_KGX $3. ;
informat COMPENSX best32. ;
informat COMP_NSX $3. ;
informat COMPOWD $1. ;
informat COMPOWD_ $3. ;
informat COMPOWDX best32. ;
informat COMP_WDX $3. ;
informat COMPSAV $4. ;
informat COMPSAV_ $3. ;
informat COMPSAVX best32. ;
informat COMP_AVX $3. ;
informat COMPSEC $4. ;
informat COMPSEC_ $3. ;
informat COMPSECX best32. ;
informat COMP_ECX $3. ;
informat CUTENURE $3. ;
informat CUTE_URE $3. ;
informat EARNCOMP $3. ;
informat EARN_OMP $3. ;
informat EDUC_REF $4. ;
informat EDUC0REF $3. ;
informat EDUCA2 $5. ;
informat EDUCA2_ $3. ;
informat FAM_SIZE best32. ;
informat FAM__IZE $3. ;
informat FAM_TYPE $3. ;
informat FAM__YPE $3. ;
informat FAMTFEDX best32. ;
informat FAMT_EDX $3. ;
informat FEDRFNDX best32. ;
informat FEDR_NDX $3. ;
informat FEDTAXX best32. ;
informat FEDTAXX_ $3. ;
informat FFRMINCX best32. ;
informat FFRM_NCX $3. ;
informat FGOVRETX best32. ;
informat FGOV_ETX $3. ;
informat FINCATAX best32. ;
informat FINCAT_X $3. ;
informat FINCBTAX best32. ;
informat FINCBT_X $3. ;
informat FINDRETX best32. ;
informat FIND_ETX $3. ;
informat FININCX best32. ;
informat FININCX_ $3. ;
informat FINLWT21 best32. ;
informat FJSSDEDX best32. ;
informat FJSS_EDX $3. ;
informat FNONFRMX best32. ;
informat FNON_RMX $3. ;
informat FPRIPENX best32. ;
informat FPRI_ENX $3. ;
informat FRRDEDX best32. ;
informat FRRDEDX_ $3. ;
informat FRRETIRX best32. ;
informat FRRE_IRX $3. ;
informat FSALARYX best32. ;
informat FSAL_RYX $3. ;
informat FSLTAXX best32. ;
informat FSLTAXX_ $3. ;
informat FSSIX best32. ;
informat FSSIX_ $3. ;
informat GOVTCOST $3. ;
informat GOVT_OST $3. ;
informat HLFBATHQ best32. ;
informat HLFB_THQ $3. ;
informat INC_HRS1 best32. ;
informat INC__RS1 $3. ;
informat INC_HRS2 best32. ;
informat INC__RS2 $3. ;
informat INC_RANK best32. ;
informat INC__ANK $3. ;
informat INCLOSSA best32. ;
informat INCL_SSA $3. ;
informat INCLOSSB best32. ;
informat INCL_SSB $3. ;
informat INCNONW1 $3. ;
informat INCN_NW1 $3. ;
informat INCNONW2 $4. ;
informat INCN_NW2 $3. ;
informat INCOMEY1 $4. ;
informat INCO_EY1 $3. ;
informat INCOMEY2 $4. ;
informat INCO_EY2 $3. ;
informat INCWEEK1 best32. ;
informat INCW_EK1 $3. ;
informat INCWEEK2 best32. ;
informat INCW_EK2 $3. ;
informat INSRFNDX best32. ;
informat INSR_NDX $3. ;
informat INTEARNX best32. ;
informat INTE_RNX $3. ;
informat MISCTAXX best32. ;
informat MISC_AXX $3. ;
informat LUMPSUMX best32. ;
informat LUMP_UMX $3. ;
informat MARITAL1 $3. ;
informat MARI_AL1 $3. ;
informat MONYOWDX best32. ;
informat MONY_WDX $3. ;
informat NO_EARNR best32. ;
informat NO_E_RNR $3. ;
informat NONINCMX best32. ;
informat NONI_CMX $3. ;
informat NUM_AUTO best32. ;
informat NUM__UTO $3. ;
informat OCCUCOD1 $5. ;
informat OCCU_OD1 $3. ;
informat OCCUCOD2 $5. ;
informat OCCU_OD2 $3. ;
informat OTHRFNDX best32. ;
informat OTHR_NDX $3. ;
informat OTHRINCX best32. ;
informat OTHR_NCX $3. ;
informat PENSIONX best32. ;
informat PENS_ONX $3. ;
informat PERSLT18 best32. ;
informat PERS_T18 $3. ;
informat PERSOT64 best32. ;
informat PERS_T64 $3. ;
informat POPSIZE $3. ;
informat PRINEARN $4. ;
informat PRIN_ARN $3. ;
informat PTAXRFDX best32. ;
informat PTAX_FDX $3. ;
informat PUBLHOUS $3. ;
informat PUBL_OUS $3. ;
informat PURSSECX best32. ;
informat PURS_ECX $3. ;
informat QINTRVMO $2. ;
informat QINTRVYR 4. ;
informat RACE2 $4. ;
informat RACE2_ $3. ;
informat REF_RACE $3. ;
informat REF__ACE $3. ;
informat REGION $3. ;
informat RENTEQVX best32. ;
informat RENT_QVX $3. ;
informat RESPSTAT $3. ;
informat RESP_TAT $3. ;
informat ROOMSQ best32. ;
informat ROOMSQ_ $3. ;
informat SALEINCX best32. ;
informat SALE_NCX $3. ;
informat SAVACCTX best32. ;
informat SAVA_CTX $3. ;
informat SECESTX best32. ;
informat SECESTX_ $3. ;
informat SELLSECX best32. ;
informat SELL_ECX $3. ;
informat SETLINSX best32. ;
informat SETL_NSX $3. ;
informat SEX_REF $3. ;
informat SEX_REF_ $3. ;
informat SEX2 $4. ;
informat SEX2_ $3. ;
informat SLOCTAXX best32. ;
informat SLOC_AXX $3. ;
informat SLRFUNDX best32. ;
informat SLRF_NDX $3. ;
informat SMSASTAT $3. ;
informat SSOVERPX best32. ;
informat SSOV_RPX $3. ;
informat ST_HOUS $3. ;
informat ST_HOUS_ $3. ;
informat TAXPROPX best32. ;
informat TAXP_OPX $3. ;
informat TOTTXPDX best32. ;
informat TOTT_PDX $3. ;
informat UNEMPLX best32. ;
informat UNEMPLX_ $3. ;
informat USBNDX best32. ;
informat USBNDX_ $3. ;
informat VEHQ best32. ;
informat VEHQ_ $3. ;
informat WDBSASTX best32. ;
informat WDBS_STX $3. ;
informat WDBSGDSX best32. ;
informat WDBS_DSX $3. ;
informat WELFAREX best32. ;
informat WELF_REX $3. ;
informat WTREP01 best32. ;
informat WTREP02 best32. ;
informat WTREP03 best32. ;
informat WTREP04 best32. ;
informat WTREP05 best32. ;
informat WTREP06 best32. ;
informat WTREP07 best32. ;
informat WTREP08 best32. ;
informat WTREP09 best32. ;
informat WTREP10 best32. ;
informat WTREP11 best32. ;
informat WTREP12 best32. ;
informat WTREP13 best32. ;
informat WTREP14 best32. ;
informat WTREP15 best32. ;
informat WTREP16 best32. ;
informat WTREP17 best32. ;
informat WTREP18 best32. ;
informat WTREP19 best32. ;
informat WTREP20 best32. ;
informat WTREP21 best32. ;
informat WTREP22 best32. ;
informat WTREP23 best32. ;
informat WTREP24 best32. ;
informat WTREP25 best32. ;
informat WTREP26 best32. ;
informat WTREP27 best32. ;
informat WTREP28 best32. ;
informat WTREP29 best32. ;
informat WTREP30 best32. ;
informat WTREP31 best32. ;
informat WTREP32 best32. ;
informat WTREP33 best32. ;
informat WTREP34 best32. ;
informat WTREP35 best32. ;
informat WTREP36 best32. ;
informat WTREP37 best32. ;
informat WTREP38 best32. ;
informat WTREP39 best32. ;
informat WTREP40 best32. ;
informat WTREP41 best32. ;
informat WTREP42 best32. ;
informat WTREP43 best32. ;
informat WTREP44 best32. ;
informat TOTEXPPQ best32. ;
informat TOTEXPCQ best32. ;
informat FOODPQ best32. ;
informat FOODCQ best32. ;
informat FDHOMEPQ best32. ;
informat FDHOMECQ best32. ;
informat FDAWAYPQ best32. ;
informat FDAWAYCQ best32. ;
informat FDXMAPPQ best32. ;
informat FDXMAPCQ best32. ;
informat FDMAPPQ best32. ;
informat FDMAPCQ best32. ;
informat ALCBEVPQ best32. ;
informat ALCBEVCQ best32. ;
informat HOUSPQ best32. ;
informat HOUSCQ best32. ;
informat SHELTPQ best32. ;
informat SHELTCQ best32. ;
informat OWNDWEPQ best32. ;
informat OWNDWECQ best32. ;
informat MRTINTPQ best32. ;
informat MRTINTCQ best32. ;
informat PROPTXPQ best32. ;
informat PROPTXCQ best32. ;
informat MRPINSPQ best32. ;
informat MRPINSCQ best32. ;
informat RENDWEPQ best32. ;
informat RENDWECQ best32. ;
informat RNTXRPPQ best32. ;
informat RNTXRPCQ best32. ;
informat RNTAPYPQ best32. ;
informat RNTAPYCQ best32. ;
informat OTHLODPQ best32. ;
informat OTHLODCQ best32. ;
informat UTILPQ best32. ;
informat UTILCQ best32. ;
informat NTLGASPQ best32. ;
informat NTLGASCQ best32. ;
informat ELCTRCPQ best32. ;
informat ELCTRCCQ best32. ;
informat ALLFULPQ best32. ;
informat ALLFULCQ best32. ;
informat FULOILPQ best32. ;
informat FULOILCQ best32. ;
informat OTHFLSPQ best32. ;
informat OTHFLSCQ best32. ;
informat TELEPHPQ best32. ;
informat TELEPHCQ best32. ;
informat WATRPSPQ best32. ;
informat WATRPSCQ best32. ;
informat HOUSOPPQ best32. ;
informat HOUSOPCQ best32. ;
informat DOMSRVPQ best32. ;
informat DOMSRVCQ best32. ;
informat DMSXCCPQ best32. ;
informat DMSXCCCQ best32. ;
informat BBYDAYPQ best32. ;
informat BBYDAYCQ best32. ;
informat OTHHEXPQ best32. ;
informat OTHHEXCQ best32. ;
informat HOUSEQPQ best32. ;
informat HOUSEQCQ best32. ;
informat TEXTILPQ best32. ;
informat TEXTILCQ best32. ;
informat FURNTRPQ best32. ;
informat FURNTRCQ best32. ;
informat FLRCVRPQ best32. ;
informat FLRCVRCQ best32. ;
informat MAJAPPPQ best32. ;
informat MAJAPPCQ best32. ;
informat SMLAPPPQ best32. ;
informat SMLAPPCQ best32. ;
informat MISCEQPQ best32. ;
informat MISCEQCQ best32. ;
informat APPARPQ best32. ;
informat APPARCQ best32. ;
informat MENBOYPQ best32. ;
informat MENBOYCQ best32. ;
informat MENSIXPQ best32. ;
informat MENSIXCQ best32. ;
informat BOYFIFPQ best32. ;
informat BOYFIFCQ best32. ;
informat WOMGRLPQ best32. ;
informat WOMGRLCQ best32. ;
informat WOMSIXPQ best32. ;
informat WOMSIXCQ best32. ;
informat GRLFIFPQ best32. ;
informat GRLFIFCQ best32. ;
informat CHLDRNPQ best32. ;
informat CHLDRNCQ best32. ;
informat FOOTWRPQ best32. ;
informat FOOTWRCQ best32. ;
informat OTHAPLPQ best32. ;
informat OTHAPLCQ best32. ;
informat TRANSPQ best32. ;
informat TRANSCQ best32. ;
informat CARTKNPQ best32. ;
informat CARTKNCQ best32. ;
informat CARTKUPQ best32. ;
informat CARTKUCQ best32. ;
informat OTHVEHPQ best32. ;
informat OTHVEHCQ best32. ;
informat GASMOPQ best32. ;
informat GASMOCQ best32. ;
informat VEHFINPQ best32. ;
informat VEHFINCQ best32. ;
informat MAINRPPQ best32. ;
informat MAINRPCQ best32. ;
informat VEHINSPQ best32. ;
informat VEHINSCQ best32. ;
informat VRNTLOPQ best32. ;
informat VRNTLOCQ best32. ;
informat PUBTRAPQ best32. ;
informat PUBTRACQ best32. ;
informat TRNTRPPQ best32. ;
informat TRNTRPCQ best32. ;
informat TRNOTHPQ best32. ;
informat TRNOTHCQ best32. ;
informat HEALTHPQ best32. ;
informat HEALTHCQ best32. ;
informat HLTHINPQ best32. ;
informat HLTHINCQ best32. ;
informat MEDSRVPQ best32. ;
informat MEDSRVCQ best32. ;
informat PREDRGPQ best32. ;
informat PREDRGCQ best32. ;
informat MEDSUPPQ best32. ;
informat MEDSUPCQ best32. ;
informat ENTERTPQ best32. ;
informat ENTERTCQ best32. ;
informat FEEADMPQ best32. ;
informat FEEADMCQ best32. ;
informat TVRDIOPQ best32. ;
informat TVRDIOCQ best32. ;
informat OTHEQPPQ best32. ;
informat OTHEQPCQ best32. ;
informat PETTOYPQ best32. ;
informat PETTOYCQ best32. ;
informat OTHENTPQ best32. ;
informat OTHENTCQ best32. ;
informat PERSCAPQ best32. ;
informat PERSCACQ best32. ;
informat READPQ best32. ;
informat READCQ best32. ;
informat EDUCAPQ best32. ;
informat EDUCACQ best32. ;
informat TOBACCPQ best32. ;
informat TOBACCCQ best32. ;
informat MISCPQ best32. ;
informat MISCCQ best32. ;
informat MISC1PQ best32. ;
informat MISC1CQ best32. ;
informat MISC2PQ best32. ;
informat MISC2CQ best32. ;
informat CASHCOPQ best32. ;
informat CASHCOCQ best32. ;
informat PERINSPQ best32. ;
informat PERINSCQ best32. ;
informat LIFINSPQ best32. ;
informat LIFINSCQ best32. ;
informat RETPENPQ best32. ;
informat RETPENCQ best32. ;
informat HH_CU_Q best32. ;
informat HH_CU_Q_ $3. ;
informat HHID best32. ;
informat HHID_ $3. ;
informat POV_CY $3. ;
informat POV_CY_ $3. ;
informat POV_PY $3. ;
informat POV_PY_ $3. ;
informat HEATFUEL $4. ;
informat HEAT_UEL $3. ;
informat SWIMPOOL $5. ;
informat SWIM_OOL $3. ;
informat WATERHT $4. ;
informat WATERHT_ $3. ;
informat APTMENT $1. ;
informat APTMENT_ $3. ;
informat OFSTPARK $4. ;
informat OFST_ARK $3. ;
informat WINDOWAC $5. ;
informat WIND_WAC $3. ;
informat CNTRALAC $4. ;
informat CNTR_LAC $3. ;
informat CHILDAGE $3. ;
informat CHIL_AGE $3. ;
informat INCLASS $4. ;
informat STATE $4. ;
informat CHDOTHX best32. ;
informat CHDOTHX_ $3. ;
informat ALIOTHX best32. ;
informat ALIOTHX_ $3. ;
informat CHDLMPX best32. ;
informat CHDLMPX_ $3. ;
informat ERANKH best32. ;
informat ERANKH_ $3. ;
informat TOTEX4PQ best32. ;
informat TOTEX4CQ best32. ;
informat MISCX4PQ best32. ;
informat MISCX4CQ best32. ;
informat VEHQL best32. ;
informat VEHQL_ $3. ;
informat NUM_TVAN best32. ;
informat NUM__VAN $3. ;
informat TTOTALP best32. ;
informat TTOTALC best32. ;
informat TFOODTOP best32. ;
informat TFOODTOC best32. ;
informat TFOODAWP best32. ;
informat TFOODAWC best32. ;
informat TFOODHOP best32. ;
informat TFOODHOC best32. ;
informat TALCBEVP best32. ;
informat TALCBEVC best32. ;
informat TOTHRLOP best32. ;
informat TOTHRLOC best32. ;
informat TTRANPRP best32. ;
informat TTRANPRC best32. ;
informat TGASMOTP best32. ;
informat TGASMOTC best32. ;
informat TVRENTLP best32. ;
informat TVRENTLC best32. ;
informat TCARTRKP best32. ;
informat TCARTRKC best32. ;
informat TOTHVHRP best32. ;
informat TOTHVHRC best32. ;
informat TOTHTREP best32. ;
informat TOTHTREC best32. ;
informat TTRNTRIP best32. ;
informat TTRNTRIC best32. ;
informat TFAREP best32. ;
informat TFAREC best32. ;
informat TAIRFARP best32. ;
informat TAIRFARC best32. ;
informat TOTHFARP best32. ;
informat TOTHFARC best32. ;
informat TLOCALTP best32. ;
informat TLOCALTC best32. ;
informat TENTRMNP best32. ;
informat TENTRMNC best32. ;
informat TFEESADP best32. ;
informat TFEESADC best32. ;
informat TOTHENTP best32. ;
informat TOTHENTC best32. ;
informat OWNVACP best32. ;
informat OWNVACC best32. ;
informat VOTHRLOP best32. ;
informat VOTHRLOC best32. ;
informat VMISCHEP best32. ;
informat VMISCHEC best32. ;
informat UTILOWNP best32. ;
informat UTILOWNC best32. ;
informat VFUELOIP best32. ;
informat VFUELOIC best32. ;
informat VOTHRFLP best32. ;
informat VOTHRFLC best32. ;
informat VELECTRP best32. ;
informat VELECTRC best32. ;
informat VNATLGAP best32. ;
informat VNATLGAC best32. ;
informat VWATERPP best32. ;
informat VWATERPC best32. ;
informat MRTPRNOP best32. ;
informat MRTPRNOC best32. ;
informat UTILRNTP best32. ;
informat UTILRNTC best32. ;
informat RFUELOIP best32. ;
informat RFUELOIC best32. ;
informat ROTHRFLP best32. ;
informat ROTHRFLC best32. ;
informat RELECTRP best32. ;
informat RELECTRC best32. ;
informat RNATLGAP best32. ;
informat RNATLGAC best32. ;
informat RWATERPP best32. ;
informat RWATERPC best32. ;
informat POVLEVCY best32. ;
informat POVL_VCY $3. ;
informat POVLEVPY best32. ;
informat POVL_VPY $3. ;
informat COOKING $4. ;
informat COOKING_ $3. ;
informat PORCH $4. ;
informat PORCH_ $3. ;
informat ETOTALP best32. ;
informat ETOTALC best32. ;
informat ETOTAPX4 best32. ;
informat ETOTACX4 best32. ;
informat EHOUSNGP best32. ;
informat EHOUSNGC best32. ;
informat ESHELTRP best32. ;
informat ESHELTRC best32. ;
informat EOWNDWLP best32. ;
informat EOWNDWLC best32. ;
informat EOTHLODP best32. ;
informat EOTHLODC best32. ;
informat EMRTPNOP best32. ;
informat EMRTPNOC best32. ;
informat EMRTPNVP best32. ;
informat EMRTPNVC best32. ;
informat ETRANPTP best32. ;
informat ETRANPTC best32. ;
informat EVEHPURP best32. ;
informat EVEHPURC best32. ;
informat ECARTKNP best32. ;
informat ECARTKNC best32. ;
informat ECARTKUP best32. ;
informat ECARTKUC best32. ;
informat EOTHVEHP best32. ;
informat EOTHVEHC best32. ;
informat EENTRMTP best32. ;
informat EENTRMTC best32. ;
informat EOTHENTP best32. ;
informat EOTHENTC best32. ;
informat ENOMOTRP best32. ;
informat ENOMOTRC best32. ;
informat EMOTRVHP best32. ;
informat EMOTRVHC best32. ;
informat EENTMSCP best32. ;
informat EENTMSCC best32. ;
informat EMISCELP best32. ;
informat EMISCELC best32. ;
informat EMISCMTP best32. ;
informat EMISCMTC best32. ;
informat UNISTRQ $4. ;
informat UNISTRQ_ $3. ;
informat INTEARNB $5. ;
informat INTE_RNB $3. ;
informat INTERNBX best32. ;
informat INTE_NBX $3. ;
informat FININCB $1. ;
informat FININCB_ $3. ;
informat FININCBX best32. ;
informat FINI_CBX $3. ;
informat PENSIONB $5. ;
informat PENS_ONB $3. ;
informat PNSIONBX best32. ;
informat PNSI_NBX $3. ;
informat UNEMPLB $1. ;
informat UNEMPLB_ $3. ;
informat UNEMPLBX best32. ;
informat UNEM_LBX $3. ;
informat COMPENSB $1. ;
informat COMP_NSB $3. ;
informat COMPNSBX best32. ;
informat COMP_SBX $3. ;
informat WELFAREB $1. ;
informat WELF_REB $3. ;
informat WELFREBX best32. ;
informat WELF_EBX $3. ;
informat FOODSMPX best32. ;
informat FOOD_MPX $3. ;
informat FOODSMPB $1. ;
informat FOOD_MPB $3. ;
informat FOODSPBX best32. ;
informat FOOD_PBX $3. ;
informat INCLOSAB $1. ;
informat INCL_SAB $3. ;
informat INCLSABX best32. ;
informat INCL_ABX $3. ;
informat INCLOSBB $1. ;
informat INCL_SBB $3. ;
informat INCLSBBX best32. ;
informat INCL_BBX $3. ;
informat CHDLMPB $1. ;
informat CHDLMPB_ $3. ;
informat CHDLMPBX best32. ;
informat CHDL_PBX $3. ;
informat CHDOTHB $1. ;
informat CHDOTHB_ $3. ;
informat CHDOTHBX best32. ;
informat CHDO_HBX $3. ;
informat ALIOTHB $1. ;
informat ALIOTHB_ $3. ;
informat ALIOTHBX best32. ;
informat ALIO_HBX $3. ;
informat LUMPSUMB $1. ;
informat LUMP_UMB $3. ;
informat LMPSUMBX best32. ;
informat LMPS_MBX $3. ;
informat SALEINCB $1. ;
informat SALE_NCB $3. ;
informat SALINCBX best32. ;
informat SALI_CBX $3. ;
informat OTHRINCB $1. ;
informat OTHR_NCB $3. ;
informat OTRINCBX best32. ;
informat OTRI_CBX $3. ;
informat INCLASS2 $3. ;
informat INCL_SS2 $3. ;
informat CUID best32. ;
informat INTERI best32. ;
informat HORREF1 $4. ;
informat HORREF1_ $3. ;
informat HORREF2 $4. ;
informat HORREF2_ $3. ;
informat ALIOTHXM best32. ;
informat ALIO_HXM $3. ;
informat ALIOTHX1 best32. ;
informat ALIOTHX2 best32. ;
informat ALIOTHX3 best32. ;
informat ALIOTHX4 best32. ;
informat ALIOTHX5 best32. ;
informat ALIOTHXI best32. ;
informat CHDOTHXM best32. ;
informat CHDO_HXM $3. ;
informat CHDOTHX1 best32. ;
informat CHDOTHX2 best32. ;
informat CHDOTHX3 best32. ;
informat CHDOTHX4 best32. ;
informat CHDOTHX5 best32. ;
informat CHDOTHXI best32. ;
informat COMPENSM best32. ;
informat COMP_NSM $3. ;
informat COMPENS1 best32. ;
informat COMPENS2 best32. ;
informat COMPENS3 best32. ;
informat COMPENS4 best32. ;
informat COMPENS5 best32. ;
informat COMPENSI best32. ;
informat ERANKHM best32. ;
informat ERANKHM_ $3. ;
informat FAMTFEDM best32. ;
informat FAMT_EDM $3. ;
informat FAMTFED1 best32. ;
informat FAMTFED2 best32. ;
informat FAMTFED3 best32. ;
informat FAMTFED4 best32. ;
informat FAMTFED5 best32. ;
informat FFRMINCM best32. ;
informat FFRM_NCM $3. ;
informat FFRMINC1 best32. ;
informat FFRMINC2 best32. ;
informat FFRMINC3 best32. ;
informat FFRMINC4 best32. ;
informat FFRMINC5 best32. ;
informat FFRMINCI best32. ;
informat FGOVRETM best32. ;
informat FGOV_ETM $3. ;
informat FINCATXM best32. ;
informat FINCA_XM $3. ;
informat FINCATX1 best32. ;
informat FINCATX2 best32. ;
informat FINCATX3 best32. ;
informat FINCATX4 best32. ;
informat FINCATX5 best32. ;
informat FINCBTXM best32. ;
informat FINCB_XM $3. ;
informat FINCBTX1 best32. ;
informat FINCBTX2 best32. ;
informat FINCBTX3 best32. ;
informat FINCBTX4 best32. ;
informat FINCBTX5 best32. ;
informat FINCBTXI best32. ;
informat FININCXM best32. ;
informat FINI_CXM $3. ;
informat FININCX1 best32. ;
informat FININCX2 best32. ;
informat FININCX3 best32. ;
informat FININCX4 best32. ;
informat FININCX5 best32. ;
informat FININCXI best32. ;
informat FJSSDEDM best32. ;
informat FJSS_EDM $3. ;
informat FJSSDED1 best32. ;
informat FJSSDED2 best32. ;
informat FJSSDED3 best32. ;
informat FJSSDED4 best32. ;
informat FJSSDED5 best32. ;
informat FNONFRMM best32. ;
informat FNON_RMM $3. ;
informat FNONFRM1 best32. ;
informat FNONFRM2 best32. ;
informat FNONFRM3 best32. ;
informat FNONFRM4 best32. ;
informat FNONFRM5 best32. ;
informat FNONFRMI best32. ;
informat FOODSMPM best32. ;
informat FOOD_MPM $3. ;
informat FOODSMP1 best32. ;
informat FOODSMP2 best32. ;
informat FOODSMP3 best32. ;
informat FOODSMP4 best32. ;
informat FOODSMP5 best32. ;
informat FOODSMPI best32. ;
informat FPRIPENM best32. ;
informat FPRI_ENM $3. ;
informat FRRDEDM best32. ;
informat FRRDEDM_ $3. ;
informat FRRETIRM best32. ;
informat FRRE_IRM $3. ;
informat FRRETIR1 best32. ;
informat FRRETIR2 best32. ;
informat FRRETIR3 best32. ;
informat FRRETIR4 best32. ;
informat FRRETIR5 best32. ;
informat FRRETIRI best32. ;
informat FSALARYM best32. ;
informat FSAL_RYM $3. ;
informat FSALARY1 best32. ;
informat FSALARY2 best32. ;
informat FSALARY3 best32. ;
informat FSALARY4 best32. ;
informat FSALARY5 best32. ;
informat FSALARYI best32. ;
informat FSLTAXXM best32. ;
informat FSLT_XXM $3. ;
informat FSLTAXX1 best32. ;
informat FSLTAXX2 best32. ;
informat FSLTAXX3 best32. ;
informat FSLTAXX4 best32. ;
informat FSLTAXX5 best32. ;
informat FSSIXM best32. ;
informat FSSIXM_ $3. ;
informat FSSIX1 best32. ;
informat FSSIX2 best32. ;
informat FSSIX3 best32. ;
informat FSSIX4 best32. ;
informat FSSIX5 best32. ;
informat FSSIXI best32. ;
informat INC_RNKM best32. ;
informat INC__NKM $3. ;
informat INC_RNK1 best32. ;
informat INC_RNK2 best32. ;
informat INC_RNK3 best32. ;
informat INC_RNK4 best32. ;
informat INC_RNK5 best32. ;
informat INCLOSAM best32. ;
informat INCL_SAM $3. ;
informat INCLOSA1 best32. ;
informat INCLOSA2 best32. ;
informat INCLOSA3 best32. ;
informat INCLOSA4 best32. ;
informat INCLOSA5 best32. ;
informat INCLOSAI best32. ;
informat INCLOSBM best32. ;
informat INCL_SBM $3. ;
informat INCLOSB1 best32. ;
informat INCLOSB2 best32. ;
informat INCLOSB3 best32. ;
informat INCLOSB4 best32. ;
informat INCLOSB5 best32. ;
informat INCLOSBI best32. ;
informat INTEARNM best32. ;
informat INTE_RNM $3. ;
informat INTEARN1 best32. ;
informat INTEARN2 best32. ;
informat INTEARN3 best32. ;
informat INTEARN4 best32. ;
informat INTEARN5 best32. ;
informat INTEARNI best32. ;
informat OTHRINCM best32. ;
informat OTHR_NCM $3. ;
informat OTHRINC1 best32. ;
informat OTHRINC2 best32. ;
informat OTHRINC3 best32. ;
informat OTHRINC4 best32. ;
informat OTHRINC5 best32. ;
informat OTHRINCI best32. ;
informat PENSIONM best32. ;
informat PENS_ONM $3. ;
informat PENSION1 best32. ;
informat PENSION2 best32. ;
informat PENSION3 best32. ;
informat PENSION4 best32. ;
informat PENSION5 best32. ;
informat PENSIONI best32. ;
informat POV_CYM $3. ;
informat POV_CYM_ $3. ;
informat POV_CY1 $3. ;
informat POV_CY2 $3. ;
informat POV_CY3 $3. ;
informat POV_CY4 $3. ;
informat POV_CY5 $3. ;
informat POV_PYM $3. ;
informat POV_PYM_ $3. ;
informat POV_PY1 $3. ;
informat POV_PY2 $3. ;
informat POV_PY3 $3. ;
informat POV_PY4 $3. ;
informat POV_PY5 $3. ;
informat PRINERNM $4. ;
informat PRIN_RNM $3. ;
informat PRINERN1 $4. ;
informat PRINERN2 $4. ;
informat PRINERN3 $4. ;
informat PRINERN4 $4. ;
informat PRINERN5 $4. ;
informat TOTTXPDM best32. ;
informat TOTT_PDM $3. ;
informat TOTTXPD1 best32. ;
informat TOTTXPD2 best32. ;
informat TOTTXPD3 best32. ;
informat TOTTXPD4 best32. ;
informat TOTTXPD5 best32. ;
informat UNEMPLXM best32. ;
informat UNEM_LXM $3. ;
informat UNEMPLX1 best32. ;
informat UNEMPLX2 best32. ;
informat UNEMPLX3 best32. ;
informat UNEMPLX4 best32. ;
informat UNEMPLX5 best32. ;
informat UNEMPLXI best32. ;
informat WELFAREM best32. ;
informat WELF_REM $3. ;
informat WELFARE1 best32. ;
informat WELFARE2 best32. ;
informat WELFARE3 best32. ;
informat WELFARE4 best32. ;
informat WELFARE5 best32. ;
informat WELFAREI best32. ;
informat COLPLAN $4. ;
informat COLPLAN_ $3. ;
informat COLPLANX best32. ;
informat COLP_ANX $3. ;
informat PSU $8. ;
informat REVSMORT $4. ;
informat REVS_ORT $3. ;
informat RVSLUMP $1. ;
informat RVSLUMP_ $3. ;
informat RVSREGMO $1. ;
informat RVSR_GMO $3. ;
informat RVSLOC $1. ;
informat RVSLOC_ $3. ;
informat RVSOTHPY $1. ;
informat RVSO_HPY $3. ;
informat TYPEPYX best32. ;
informat TYPEPYX_ $3. ;
informat HISP_REF $3. ;
informat HISP2 $4. ;
informat BUILT $8. ;
informat BUILT_ $3. ;
input
NEWID
DIRACC $
DIRACC_ $
AGE_REF
AGE_REF_ $
AGE2
AGE2_ $
AS_COMP1
AS_C_MP1 $
AS_COMP2
AS_C_MP2 $
AS_COMP3
AS_C_MP3 $
AS_COMP4
AS_C_MP4 $
AS_COMP5
AS_C_MP5 $
BATHRMQ
BATHRMQ_ $
BEDROOMQ
BEDR_OMQ $
BLS_URBN $
BSINVSTX
BSIN_STX $
BUILDING $
BUIL_ING $
CKBKACTX
CKBK_CTX $
COMPBND $
COMPBND_ $
COMPBNDX
COMP_NDX $
COMPCKG $
COMPCKG_ $
COMPCKGX
COMP_KGX $
COMPENSX
COMP_NSX $
COMPOWD $
COMPOWD_ $
COMPOWDX
COMP_WDX $
COMPSAV $
COMPSAV_ $
COMPSAVX
COMP_AVX $
COMPSEC $
COMPSEC_ $
COMPSECX
COMP_ECX $
CUTENURE $
CUTE_URE $
EARNCOMP $
EARN_OMP $
EDUC_REF $
EDUC0REF $
EDUCA2 $
EDUCA2_ $
FAM_SIZE
FAM__IZE $
FAM_TYPE $
FAM__YPE $
FAMTFEDX
FAMT_EDX $
FEDRFNDX
FEDR_NDX $
FEDTAXX
FEDTAXX_ $
FFRMINCX
FFRM_NCX $
FGOVRETX
FGOV_ETX $
FINCATAX
FINCAT_X $
FINCBTAX
FINCBT_X $
FINDRETX
FIND_ETX $
FININCX
FININCX_ $
FINLWT21
FJSSDEDX
FJSS_EDX $
FNONFRMX
FNON_RMX $
FPRIPENX
FPRI_ENX $
FRRDEDX
FRRDEDX_ $
FRRETIRX
FRRE_IRX $
FSALARYX
FSAL_RYX $
FSLTAXX
FSLTAXX_ $
FSSIX
FSSIX_ $
GOVTCOST $
GOVT_OST $
HLFBATHQ
HLFB_THQ $
INC_HRS1
INC__RS1 $
INC_HRS2
INC__RS2 $
INC_RANK
INC__ANK $
INCLOSSA
INCL_SSA $
INCLOSSB
INCL_SSB $
INCNONW1 $
INCN_NW1 $
INCNONW2 $
INCN_NW2 $
INCOMEY1 $
INCO_EY1 $
INCOMEY2 $
INCO_EY2 $
INCWEEK1
INCW_EK1 $
INCWEEK2
INCW_EK2 $
INSRFNDX
INSR_NDX $
INTEARNX
INTE_RNX $
MISCTAXX
MISC_AXX $
LUMPSUMX
LUMP_UMX $
MARITAL1 $
MARI_AL1 $
MONYOWDX
MONY_WDX $
NO_EARNR
NO_E_RNR $
NONINCMX
NONI_CMX $
NUM_AUTO
NUM__UTO $
OCCUCOD1 $
OCCU_OD1 $
OCCUCOD2 $
OCCU_OD2 $
OTHRFNDX
OTHR_NDX $
OTHRINCX
OTHR_NCX $
PENSIONX
PENS_ONX $
PERSLT18
PERS_T18 $
PERSOT64
PERS_T64 $
POPSIZE $
PRINEARN $
PRIN_ARN $
PTAXRFDX
PTAX_FDX $
PUBLHOUS $
PUBL_OUS $
PURSSECX
PURS_ECX $
QINTRVMO $
QINTRVYR
RACE2 $
RACE2_ $
REF_RACE $
REF__ACE $
REGION $
RENTEQVX
RENT_QVX $
RESPSTAT $
RESP_TAT $
ROOMSQ
ROOMSQ_ $
SALEINCX
SALE_NCX $
SAVACCTX
SAVA_CTX $
SECESTX
SECESTX_ $
SELLSECX
SELL_ECX $
SETLINSX
SETL_NSX $
SEX_REF $
SEX_REF_ $
SEX2 $
SEX2_ $
SLOCTAXX
SLOC_AXX $
SLRFUNDX
SLRF_NDX $
SMSASTAT $
SSOVERPX
SSOV_RPX $
ST_HOUS $
ST_HOUS_ $
TAXPROPX
TAXP_OPX $
TOTTXPDX
TOTT_PDX $
UNEMPLX
UNEMPLX_ $
USBNDX
USBNDX_ $
VEHQ
VEHQ_ $
WDBSASTX
WDBS_STX $
WDBSGDSX
WDBS_DSX $
WELFAREX
WELF_REX $
WTREP01
WTREP02
WTREP03
WTREP04
WTREP05
WTREP06
WTREP07
WTREP08
WTREP09
WTREP10
WTREP11
WTREP12
WTREP13
WTREP14
WTREP15
WTREP16
WTREP17
WTREP18
WTREP19
WTREP20
WTREP21
WTREP22
WTREP23
WTREP24
WTREP25
WTREP26
WTREP27
WTREP28
WTREP29
WTREP30
WTREP31
WTREP32
WTREP33
WTREP34
WTREP35
WTREP36
WTREP37
WTREP38
WTREP39
WTREP40
WTREP41
WTREP42
WTREP43
WTREP44
TOTEXPPQ
TOTEXPCQ
FOODPQ
FOODCQ
FDHOMEPQ
FDHOMECQ
FDAWAYPQ
FDAWAYCQ
FDXMAPPQ
FDXMAPCQ
FDMAPPQ
FDMAPCQ
ALCBEVPQ
ALCBEVCQ
HOUSPQ
HOUSCQ
SHELTPQ
SHELTCQ
OWNDWEPQ
OWNDWECQ
MRTINTPQ
MRTINTCQ
PROPTXPQ
PROPTXCQ
MRPINSPQ
MRPINSCQ
RENDWEPQ
RENDWECQ
RNTXRPPQ
RNTXRPCQ
RNTAPYPQ
RNTAPYCQ
OTHLODPQ
OTHLODCQ
UTILPQ
UTILCQ
NTLGASPQ
NTLGASCQ
ELCTRCPQ
ELCTRCCQ
ALLFULPQ
ALLFULCQ
FULOILPQ
FULOILCQ
OTHFLSPQ
OTHFLSCQ
TELEPHPQ
TELEPHCQ
WATRPSPQ
WATRPSCQ
HOUSOPPQ
HOUSOPCQ
DOMSRVPQ
DOMSRVCQ
DMSXCCPQ
DMSXCCCQ
BBYDAYPQ
BBYDAYCQ
OTHHEXPQ
OTHHEXCQ
HOUSEQPQ
HOUSEQCQ
TEXTILPQ
TEXTILCQ
FURNTRPQ
FURNTRCQ
FLRCVRPQ
FLRCVRCQ
MAJAPPPQ
MAJAPPCQ
SMLAPPPQ
SMLAPPCQ
MISCEQPQ
MISCEQCQ
APPARPQ
APPARCQ
MENBOYPQ
MENBOYCQ
MENSIXPQ
MENSIXCQ
BOYFIFPQ
BOYFIFCQ
WOMGRLPQ
WOMGRLCQ
WOMSIXPQ
WOMSIXCQ
GRLFIFPQ
GRLFIFCQ
CHLDRNPQ
CHLDRNCQ
FOOTWRPQ
FOOTWRCQ
OTHAPLPQ
OTHAPLCQ
TRANSPQ
TRANSCQ
CARTKNPQ
CARTKNCQ
CARTKUPQ
CARTKUCQ
OTHVEHPQ
OTHVEHCQ
GASMOPQ
GASMOCQ
VEHFINPQ
VEHFINCQ
MAINRPPQ
MAINRPCQ
VEHINSPQ
VEHINSCQ
VRNTLOPQ
VRNTLOCQ
PUBTRAPQ
PUBTRACQ
TRNTRPPQ
TRNTRPCQ
TRNOTHPQ
TRNOTHCQ
HEALTHPQ
HEALTHCQ
HLTHINPQ
HLTHINCQ
MEDSRVPQ
MEDSRVCQ
PREDRGPQ
PREDRGCQ
MEDSUPPQ
MEDSUPCQ
ENTERTPQ
ENTERTCQ
FEEADMPQ
FEEADMCQ
TVRDIOPQ
TVRDIOCQ
OTHEQPPQ
OTHEQPCQ
PETTOYPQ
PETTOYCQ
OTHENTPQ
OTHENTCQ
PERSCAPQ
PERSCACQ
READPQ
READCQ
EDUCAPQ
EDUCACQ
TOBACCPQ
TOBACCCQ
MISCPQ
MISCCQ
MISC1PQ
MISC1CQ
MISC2PQ
MISC2CQ
CASHCOPQ
CASHCOCQ
PERINSPQ
PERINSCQ
LIFINSPQ
LIFINSCQ
RETPENPQ
RETPENCQ
HH_CU_Q
HH_CU_Q_ $
HHID
HHID_ $
POV_CY $
POV_CY_ $
POV_PY $
POV_PY_ $
HEATFUEL $
HEAT_UEL $
SWIMPOOL $
SWIM_OOL $
WATERHT $
WATERHT_ $
APTMENT $
APTMENT_ $
OFSTPARK $
OFST_ARK $
WINDOWAC $
WIND_WAC $
CNTRALAC $
CNTR_LAC $
CHILDAGE $
CHIL_AGE $
INCLASS $
STATE $
CHDOTHX
CHDOTHX_ $
ALIOTHX
ALIOTHX_ $
CHDLMPX
CHDLMPX_ $
ERANKH
ERANKH_ $
TOTEX4PQ
TOTEX4CQ
MISCX4PQ
MISCX4CQ
VEHQL
VEHQL_ $
NUM_TVAN
NUM__VAN $
TTOTALP
TTOTALC
TFOODTOP
TFOODTOC
TFOODAWP
TFOODAWC
TFOODHOP
TFOODHOC
TALCBEVP
TALCBEVC
TOTHRLOP
TOTHRLOC
TTRANPRP
TTRANPRC
TGASMOTP
TGASMOTC
TVRENTLP
TVRENTLC
TCARTRKP
TCARTRKC
TOTHVHRP
TOTHVHRC
TOTHTREP
TOTHTREC
TTRNTRIP
TTRNTRIC
TFAREP
TFAREC
TAIRFARP
TAIRFARC
TOTHFARP
TOTHFARC
TLOCALTP
TLOCALTC
TENTRMNP
TENTRMNC
TFEESADP
TFEESADC
TOTHENTP
TOTHENTC
OWNVACP
OWNVACC
VOTHRLOP
VOTHRLOC
VMISCHEP
VMISCHEC
UTILOWNP
UTILOWNC
VFUELOIP
VFUELOIC
VOTHRFLP
VOTHRFLC
VELECTRP
VELECTRC
VNATLGAP
VNATLGAC
VWATERPP
VWATERPC
MRTPRNOP
MRTPRNOC
UTILRNTP
UTILRNTC
RFUELOIP
RFUELOIC
ROTHRFLP
ROTHRFLC
RELECTRP
RELECTRC
RNATLGAP
RNATLGAC
RWATERPP
RWATERPC
POVLEVCY
POVL_VCY $
POVLEVPY
POVL_VPY $
COOKING $
COOKING_ $
PORCH $
PORCH_ $
ETOTALP
ETOTALC
ETOTAPX4
ETOTACX4
EHOUSNGP
EHOUSNGC
ESHELTRP
ESHELTRC
EOWNDWLP
EOWNDWLC
EOTHLODP
EOTHLODC
EMRTPNOP
EMRTPNOC
EMRTPNVP
EMRTPNVC
ETRANPTP
ETRANPTC
EVEHPURP
EVEHPURC
ECARTKNP
ECARTKNC
ECARTKUP
ECARTKUC
EOTHVEHP
EOTHVEHC
EENTRMTP
EENTRMTC
EOTHENTP
EOTHENTC
ENOMOTRP
ENOMOTRC
EMOTRVHP
EMOTRVHC
EENTMSCP
EENTMSCC
EMISCELP
EMISCELC
EMISCMTP
EMISCMTC
UNISTRQ $
UNISTRQ_ $
INTEARNB $
INTE_RNB $
INTERNBX
INTE_NBX $
FININCB $
FININCB_ $
FININCBX
FINI_CBX $
PENSIONB $
PENS_ONB $
PNSIONBX
PNSI_NBX $
UNEMPLB $
UNEMPLB_ $
UNEMPLBX
UNEM_LBX $
COMPENSB $
COMP_NSB $
COMPNSBX
COMP_SBX $
WELFAREB $
WELF_REB $
WELFREBX
WELF_EBX $
FOODSMPX
FOOD_MPX $
FOODSMPB $
FOOD_MPB $
FOODSPBX
FOOD_PBX $
INCLOSAB $
INCL_SAB $
INCLSABX
INCL_ABX $
INCLOSBB $
INCL_SBB $
INCLSBBX
INCL_BBX $
CHDLMPB $
CHDLMPB_ $
CHDLMPBX
CHDL_PBX $
CHDOTHB $
CHDOTHB_ $
CHDOTHBX
CHDO_HBX $
ALIOTHB $
ALIOTHB_ $
ALIOTHBX
ALIO_HBX $
LUMPSUMB $
LUMP_UMB $
LMPSUMBX
LMPS_MBX $
SALEINCB $
SALE_NCB $
SALINCBX
SALI_CBX $
OTHRINCB $
OTHR_NCB $
OTRINCBX
OTRI_CBX $
INCLASS2 $
INCL_SS2 $
CUID
INTERI
HORREF1 $
HORREF1_ $
HORREF2 $
HORREF2_ $
ALIOTHXM
ALIO_HXM $
ALIOTHX1
ALIOTHX2
ALIOTHX3
ALIOTHX4
ALIOTHX5
ALIOTHXI
CHDOTHXM
CHDO_HXM $
CHDOTHX1
CHDOTHX2
CHDOTHX3
CHDOTHX4
CHDOTHX5
CHDOTHXI
COMPENSM
COMP_NSM $
COMPENS1
COMPENS2
COMPENS3
COMPENS4
COMPENS5
COMPENSI
ERANKHM
ERANKHM_ $
FAMTFEDM
FAMT_EDM $
FAMTFED1
FAMTFED2
FAMTFED3
FAMTFED4
FAMTFED5
FFRMINCM
FFRM_NCM $
FFRMINC1
FFRMINC2
FFRMINC3
FFRMINC4
FFRMINC5
FFRMINCI
FGOVRETM
FGOV_ETM $
FINCATXM
FINCA_XM $
FINCATX1
FINCATX2
FINCATX3
FINCATX4
FINCATX5
FINCBTXM
FINCB_XM $
FINCBTX1
FINCBTX2
FINCBTX3
FINCBTX4
FINCBTX5
FINCBTXI
FININCXM
FINI_CXM $
FININCX1
FININCX2
FININCX3
FININCX4
FININCX5
FININCXI
FJSSDEDM
FJSS_EDM $
FJSSDED1
FJSSDED2
FJSSDED3
FJSSDED4
FJSSDED5
FNONFRMM
FNON_RMM $
FNONFRM1
FNONFRM2
FNONFRM3
FNONFRM4
FNONFRM5
FNONFRMI
FOODSMPM
FOOD_MPM $
FOODSMP1
FOODSMP2
FOODSMP3
FOODSMP4
FOODSMP5
FOODSMPI
FPRIPENM
FPRI_ENM $
FRRDEDM
FRRDEDM_ $
FRRETIRM
FRRE_IRM $
FRRETIR1
FRRETIR2
FRRETIR3
FRRETIR4
FRRETIR5
FRRETIRI
FSALARYM
FSAL_RYM $
FSALARY1
FSALARY2
FSALARY3
FSALARY4
FSALARY5
FSALARYI
FSLTAXXM
FSLT_XXM $
FSLTAXX1
FSLTAXX2
FSLTAXX3
FSLTAXX4
FSLTAXX5
FSSIXM
FSSIXM_ $
FSSIX1
FSSIX2
FSSIX3
FSSIX4
FSSIX5
FSSIXI
INC_RNKM
INC__NKM $
INC_RNK1
INC_RNK2
INC_RNK3
INC_RNK4
INC_RNK5
INCLOSAM
INCL_SAM $
INCLOSA1
INCLOSA2
INCLOSA3
INCLOSA4
INCLOSA5
INCLOSAI
INCLOSBM
INCL_SBM $
INCLOSB1
INCLOSB2
INCLOSB3
INCLOSB4
INCLOSB5
INCLOSBI
INTEARNM
INTE_RNM $
INTEARN1
INTEARN2
INTEARN3
INTEARN4
INTEARN5
INTEARNI
OTHRINCM
OTHR_NCM $
OTHRINC1
OTHRINC2
OTHRINC3
OTHRINC4
OTHRINC5
OTHRINCI
PENSIONM
PENS_ONM $
PENSION1
PENSION2
PENSION3
PENSION4
PENSION5
PENSIONI
POV_CYM $
POV_CYM_ $
POV_CY1 $
POV_CY2 $
POV_CY3 $
POV_CY4 $
POV_CY5 $
POV_PYM $
POV_PYM_ $
POV_PY1 $
POV_PY2 $
POV_PY3 $
POV_PY4 $
POV_PY5 $
PRINERNM $
PRIN_RNM $
PRINERN1 $
PRINERN2 $
PRINERN3 $
PRINERN4 $
PRINERN5 $
TOTTXPDM
TOTT_PDM $
TOTTXPD1
TOTTXPD2
TOTTXPD3
TOTTXPD4
TOTTXPD5
UNEMPLXM
UNEM_LXM $
UNEMPLX1
UNEMPLX2
UNEMPLX3
UNEMPLX4
UNEMPLX5
UNEMPLXI
WELFAREM
WELF_REM $
WELFARE1
WELFARE2
WELFARE3
WELFARE4
WELFARE5
WELFAREI
COLPLAN $
COLPLAN_ $
COLPLANX
COLP_ANX $
PSU $
REVSMORT $
REVS_ORT $
RVSLUMP $
RVSLUMP_ $
RVSREGMO $
RVSR_GMO $
RVSLOC $
RVSLOC_ $
RVSOTHPY $
RVSO_HPY $
TYPEPYX
TYPEPYX_ $
HISP_REF $
HISP2 $
BUILT $
BUILT_ $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/**********************************************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\FMLI&YR1.3.CSV"
            OUT=FMLYI&YR1.3
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
***********************************************************************************************/

data WORK.FMLYI113                                ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile 'C:\2011_CEX\Intrvw11\FMLI113.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat NEWID best32. ;
informat DIRACC $3. ;
informat DIRACC_ $3. ;
informat AGE_REF best32. ;
informat AGE_REF_ $3. ;
informat AGE2 best32. ;
informat AGE2_ $3. ;
informat AS_COMP1 best32. ;
informat AS_C_MP1 $3. ;
informat AS_COMP2 best32. ;
informat AS_C_MP2 $3. ;
informat AS_COMP3 best32. ;
informat AS_C_MP3 $3. ;
informat AS_COMP4 best32. ;
informat AS_C_MP4 $3. ;
informat AS_COMP5 best32. ;
informat AS_C_MP5 $3. ;
informat BATHRMQ best32. ;
informat BATHRMQ_ $3. ;
informat BEDROOMQ best32. ;
informat BEDR_OMQ $3. ;
informat BLS_URBN $3. ;
informat BSINVSTX best32. ;
informat BSIN_STX $3. ;
informat BUILDING $4. ;
informat BUIL_ING $3. ;
informat CKBKACTX best32. ;
informat CKBK_CTX $3. ;
informat COMPBND $4. ;
informat COMPBND_ $3. ;
informat COMPBNDX best32. ;
informat COMP_NDX $3. ;
informat COMPCKG $4. ;
informat COMPCKG_ $3. ;
informat COMPCKGX best32. ;
informat COMP_KGX $3. ;
informat COMPENSX best32. ;
informat COMP_NSX $3. ;
informat COMPOWD $1. ;
informat COMPOWD_ $3. ;
informat COMPOWDX best32. ;
informat COMP_WDX $3. ;
informat COMPSAV $4. ;
informat COMPSAV_ $3. ;
informat COMPSAVX best32. ;
informat COMP_AVX $3. ;
informat COMPSEC $4. ;
informat COMPSEC_ $3. ;
informat COMPSECX best32. ;
informat COMP_ECX $3. ;
informat CUTENURE $3. ;
informat CUTE_URE $3. ;
informat EARNCOMP $3. ;
informat EARN_OMP $3. ;
informat EDUC_REF $4. ;
informat EDUC0REF $3. ;
informat EDUCA2 $5. ;
informat EDUCA2_ $3. ;
informat FAM_SIZE best32. ;
informat FAM__IZE $3. ;
informat FAM_TYPE $3. ;
informat FAM__YPE $3. ;
informat FAMTFEDX best32. ;
informat FAMT_EDX $3. ;
informat FEDRFNDX best32. ;
informat FEDR_NDX $3. ;
informat FEDTAXX best32. ;
informat FEDTAXX_ $3. ;
informat FFRMINCX best32. ;
informat FFRM_NCX $3. ;
informat FGOVRETX best32. ;
informat FGOV_ETX $3. ;
informat FINCATAX best32. ;
informat FINCAT_X $3. ;
informat FINCBTAX best32. ;
informat FINCBT_X $3. ;
informat FINDRETX best32. ;
informat FIND_ETX $3. ;
informat FININCX best32. ;
informat FININCX_ $3. ;
informat FINLWT21 best32. ;
informat FJSSDEDX best32. ;
informat FJSS_EDX $3. ;
informat FNONFRMX best32. ;
informat FNON_RMX $3. ;
informat FPRIPENX best32. ;
informat FPRI_ENX $3. ;
informat FRRDEDX best32. ;
informat FRRDEDX_ $3. ;
informat FRRETIRX best32. ;
informat FRRE_IRX $3. ;
informat FSALARYX best32. ;
informat FSAL_RYX $3. ;
informat FSLTAXX best32. ;
informat FSLTAXX_ $3. ;
informat FSSIX best32. ;
informat FSSIX_ $3. ;
informat GOVTCOST $3. ;
informat GOVT_OST $3. ;
informat HLFBATHQ best32. ;
informat HLFB_THQ $3. ;
informat INC_HRS1 best32. ;
informat INC__RS1 $3. ;
informat INC_HRS2 best32. ;
informat INC__RS2 $3. ;
informat INC_RANK best32. ;
informat INC__ANK $3. ;
informat INCLOSSA best32. ;
informat INCL_SSA $3. ;
informat INCLOSSB best32. ;
informat INCL_SSB $3. ;
informat INCNONW1 $3. ;
informat INCN_NW1 $3. ;
informat INCNONW2 $4. ;
informat INCN_NW2 $3. ;
informat INCOMEY1 $4. ;
informat INCO_EY1 $3. ;
informat INCOMEY2 $4. ;
informat INCO_EY2 $3. ;
informat INCWEEK1 best32. ;
informat INCW_EK1 $3. ;
informat INCWEEK2 best32. ;
informat INCW_EK2 $3. ;
informat INSRFNDX best32. ;
informat INSR_NDX $3. ;
informat INTEARNX best32. ;
informat INTE_RNX $3. ;
informat MISCTAXX best32. ;
informat MISC_AXX $3. ;
informat LUMPSUMX best32. ;
informat LUMP_UMX $3. ;
informat MARITAL1 $3. ;
informat MARI_AL1 $3. ;
informat MONYOWDX best32. ;
informat MONY_WDX $3. ;
informat NO_EARNR best32. ;
informat NO_E_RNR $3. ;
informat NONINCMX best32. ;
informat NONI_CMX $3. ;
informat NUM_AUTO best32. ;
informat NUM__UTO $3. ;
informat OCCUCOD1 $5. ;
informat OCCU_OD1 $3. ;
informat OCCUCOD2 $5. ;
informat OCCU_OD2 $3. ;
informat OTHRFNDX best32. ;
informat OTHR_NDX $3. ;
informat OTHRINCX best32. ;
informat OTHR_NCX $3. ;
informat PENSIONX best32. ;
informat PENS_ONX $3. ;
informat PERSLT18 best32. ;
informat PERS_T18 $3. ;
informat PERSOT64 best32. ;
informat PERS_T64 $3. ;
informat POPSIZE $3. ;
informat PRINEARN $4. ;
informat PRIN_ARN $3. ;
informat PTAXRFDX best32. ;
informat PTAX_FDX $3. ;
informat PUBLHOUS $3. ;
informat PUBL_OUS $3. ;
informat PURSSECX best32. ;
informat PURS_ECX $3. ;
informat QINTRVMO $2. ;
informat QINTRVYR 4. ;
informat RACE2 $4. ;
informat RACE2_ $3. ;
informat REF_RACE $3. ;
informat REF__ACE $3. ;
informat REGION $3. ;
informat RENTEQVX best32. ;
informat RENT_QVX $3. ;
informat RESPSTAT $3. ;
informat RESP_TAT $3. ;
informat ROOMSQ best32. ;
informat ROOMSQ_ $3. ;
informat SALEINCX best32. ;
informat SALE_NCX $3. ;
informat SAVACCTX best32. ;
informat SAVA_CTX $3. ;
informat SECESTX best32. ;
informat SECESTX_ $3. ;
informat SELLSECX best32. ;
informat SELL_ECX $3. ;
informat SETLINSX best32. ;
informat SETL_NSX $3. ;
informat SEX_REF $3. ;
informat SEX_REF_ $3. ;
informat SEX2 $4. ;
informat SEX2_ $3. ;
informat SLOCTAXX best32. ;
informat SLOC_AXX $3. ;
informat SLRFUNDX best32. ;
informat SLRF_NDX $3. ;
informat SMSASTAT $3. ;
informat SSOVERPX best32. ;
informat SSOV_RPX $3. ;
informat ST_HOUS $3. ;
informat ST_HOUS_ $3. ;
informat TAXPROPX best32. ;
informat TAXP_OPX $3. ;
informat TOTTXPDX best32. ;
informat TOTT_PDX $3. ;
informat UNEMPLX best32. ;
informat UNEMPLX_ $3. ;
informat USBNDX best32. ;
informat USBNDX_ $3. ;
informat VEHQ best32. ;
informat VEHQ_ $3. ;
informat WDBSASTX best32. ;
informat WDBS_STX $3. ;
informat WDBSGDSX best32. ;
informat WDBS_DSX $3. ;
informat WELFAREX best32. ;
informat WELF_REX $3. ;
informat WTREP01 best32. ;
informat WTREP02 best32. ;
informat WTREP03 best32. ;
informat WTREP04 best32. ;
informat WTREP05 best32. ;
informat WTREP06 best32. ;
informat WTREP07 best32. ;
informat WTREP08 best32. ;
informat WTREP09 best32. ;
informat WTREP10 best32. ;
informat WTREP11 best32. ;
informat WTREP12 best32. ;
informat WTREP13 best32. ;
informat WTREP14 best32. ;
informat WTREP15 best32. ;
informat WTREP16 best32. ;
informat WTREP17 best32. ;
informat WTREP18 best32. ;
informat WTREP19 best32. ;
informat WTREP20 best32. ;
informat WTREP21 best32. ;
informat WTREP22 best32. ;
informat WTREP23 best32. ;
informat WTREP24 best32. ;
informat WTREP25 best32. ;
informat WTREP26 best32. ;
informat WTREP27 best32. ;
informat WTREP28 best32. ;
informat WTREP29 best32. ;
informat WTREP30 best32. ;
informat WTREP31 best32. ;
informat WTREP32 best32. ;
informat WTREP33 best32. ;
informat WTREP34 best32. ;
informat WTREP35 best32. ;
informat WTREP36 best32. ;
informat WTREP37 best32. ;
informat WTREP38 best32. ;
informat WTREP39 best32. ;
informat WTREP40 best32. ;
informat WTREP41 best32. ;
informat WTREP42 best32. ;
informat WTREP43 best32. ;
informat WTREP44 best32. ;
informat TOTEXPPQ best32. ;
informat TOTEXPCQ best32. ;
informat FOODPQ best32. ;
informat FOODCQ best32. ;
informat FDHOMEPQ best32. ;
informat FDHOMECQ best32. ;
informat FDAWAYPQ best32. ;
informat FDAWAYCQ best32. ;
informat FDXMAPPQ best32. ;
informat FDXMAPCQ best32. ;
informat FDMAPPQ best32. ;
informat FDMAPCQ best32. ;
informat ALCBEVPQ best32. ;
informat ALCBEVCQ best32. ;
informat HOUSPQ best32. ;
informat HOUSCQ best32. ;
informat SHELTPQ best32. ;
informat SHELTCQ best32. ;
informat OWNDWEPQ best32. ;
informat OWNDWECQ best32. ;
informat MRTINTPQ best32. ;
informat MRTINTCQ best32. ;
informat PROPTXPQ best32. ;
informat PROPTXCQ best32. ;
informat MRPINSPQ best32. ;
informat MRPINSCQ best32. ;
informat RENDWEPQ best32. ;
informat RENDWECQ best32. ;
informat RNTXRPPQ best32. ;
informat RNTXRPCQ best32. ;
informat RNTAPYPQ best32. ;
informat RNTAPYCQ best32. ;
informat OTHLODPQ best32. ;
informat OTHLODCQ best32. ;
informat UTILPQ best32. ;
informat UTILCQ best32. ;
informat NTLGASPQ best32. ;
informat NTLGASCQ best32. ;
informat ELCTRCPQ best32. ;
informat ELCTRCCQ best32. ;
informat ALLFULPQ best32. ;
informat ALLFULCQ best32. ;
informat FULOILPQ best32. ;
informat FULOILCQ best32. ;
informat OTHFLSPQ best32. ;
informat OTHFLSCQ best32. ;
informat TELEPHPQ best32. ;
informat TELEPHCQ best32. ;
informat WATRPSPQ best32. ;
informat WATRPSCQ best32. ;
informat HOUSOPPQ best32. ;
informat HOUSOPCQ best32. ;
informat DOMSRVPQ best32. ;
informat DOMSRVCQ best32. ;
informat DMSXCCPQ best32. ;
informat DMSXCCCQ best32. ;
informat BBYDAYPQ best32. ;
informat BBYDAYCQ best32. ;
informat OTHHEXPQ best32. ;
informat OTHHEXCQ best32. ;
informat HOUSEQPQ best32. ;
informat HOUSEQCQ best32. ;
informat TEXTILPQ best32. ;
informat TEXTILCQ best32. ;
informat FURNTRPQ best32. ;
informat FURNTRCQ best32. ;
informat FLRCVRPQ best32. ;
informat FLRCVRCQ best32. ;
informat MAJAPPPQ best32. ;
informat MAJAPPCQ best32. ;
informat SMLAPPPQ best32. ;
informat SMLAPPCQ best32. ;
informat MISCEQPQ best32. ;
informat MISCEQCQ best32. ;
informat APPARPQ best32. ;
informat APPARCQ best32. ;
informat MENBOYPQ best32. ;
informat MENBOYCQ best32. ;
informat MENSIXPQ best32. ;
informat MENSIXCQ best32. ;
informat BOYFIFPQ best32. ;
informat BOYFIFCQ best32. ;
informat WOMGRLPQ best32. ;
informat WOMGRLCQ best32. ;
informat WOMSIXPQ best32. ;
informat WOMSIXCQ best32. ;
informat GRLFIFPQ best32. ;
informat GRLFIFCQ best32. ;
informat CHLDRNPQ best32. ;
informat CHLDRNCQ best32. ;
informat FOOTWRPQ best32. ;
informat FOOTWRCQ best32. ;
informat OTHAPLPQ best32. ;
informat OTHAPLCQ best32. ;
informat TRANSPQ best32. ;
informat TRANSCQ best32. ;
informat CARTKNPQ best32. ;
informat CARTKNCQ best32. ;
informat CARTKUPQ best32. ;
informat CARTKUCQ best32. ;
informat OTHVEHPQ best32. ;
informat OTHVEHCQ best32. ;
informat GASMOPQ best32. ;
informat GASMOCQ best32. ;
informat VEHFINPQ best32. ;
informat VEHFINCQ best32. ;
informat MAINRPPQ best32. ;
informat MAINRPCQ best32. ;
informat VEHINSPQ best32. ;
informat VEHINSCQ best32. ;
informat VRNTLOPQ best32. ;
informat VRNTLOCQ best32. ;
informat PUBTRAPQ best32. ;
informat PUBTRACQ best32. ;
informat TRNTRPPQ best32. ;
informat TRNTRPCQ best32. ;
informat TRNOTHPQ best32. ;
informat TRNOTHCQ best32. ;
informat HEALTHPQ best32. ;
informat HEALTHCQ best32. ;
informat HLTHINPQ best32. ;
informat HLTHINCQ best32. ;
informat MEDSRVPQ best32. ;
informat MEDSRVCQ best32. ;
informat PREDRGPQ best32. ;
informat PREDRGCQ best32. ;
informat MEDSUPPQ best32. ;
informat MEDSUPCQ best32. ;
informat ENTERTPQ best32. ;
informat ENTERTCQ best32. ;
informat FEEADMPQ best32. ;
informat FEEADMCQ best32. ;
informat TVRDIOPQ best32. ;
informat TVRDIOCQ best32. ;
informat OTHEQPPQ best32. ;
informat OTHEQPCQ best32. ;
informat PETTOYPQ best32. ;
informat PETTOYCQ best32. ;
informat OTHENTPQ best32. ;
informat OTHENTCQ best32. ;
informat PERSCAPQ best32. ;
informat PERSCACQ best32. ;
informat READPQ best32. ;
informat READCQ best32. ;
informat EDUCAPQ best32. ;
informat EDUCACQ best32. ;
informat TOBACCPQ best32. ;
informat TOBACCCQ best32. ;
informat MISCPQ best32. ;
informat MISCCQ best32. ;
informat MISC1PQ best32. ;
informat MISC1CQ best32. ;
informat MISC2PQ best32. ;
informat MISC2CQ best32. ;
informat CASHCOPQ best32. ;
informat CASHCOCQ best32. ;
informat PERINSPQ best32. ;
informat PERINSCQ best32. ;
informat LIFINSPQ best32. ;
informat LIFINSCQ best32. ;
informat RETPENPQ best32. ;
informat RETPENCQ best32. ;
informat HH_CU_Q best32. ;
informat HH_CU_Q_ $3. ;
informat HHID best32. ;
informat HHID_ $3. ;
informat POV_CY $3. ;
informat POV_CY_ $3. ;
informat POV_PY $3. ;
informat POV_PY_ $3. ;
informat HEATFUEL $4. ;
informat HEAT_UEL $3. ;
informat SWIMPOOL $5. ;
informat SWIM_OOL $3. ;
informat WATERHT $4. ;
informat WATERHT_ $3. ;
informat APTMENT $1. ;
informat APTMENT_ $3. ;
informat OFSTPARK $4. ;
informat OFST_ARK $3. ;
informat WINDOWAC $5. ;
informat WIND_WAC $3. ;
informat CNTRALAC $4. ;
informat CNTR_LAC $3. ;
informat CHILDAGE $3. ;
informat CHIL_AGE $3. ;
informat INCLASS $4. ;
informat STATE $4. ;
informat CHDOTHX best32. ;
informat CHDOTHX_ $3. ;
informat ALIOTHX best32. ;
informat ALIOTHX_ $3. ;
informat CHDLMPX best32. ;
informat CHDLMPX_ $3. ;
informat ERANKH best32. ;
informat ERANKH_ $3. ;
informat TOTEX4PQ best32. ;
informat TOTEX4CQ best32. ;
informat MISCX4PQ best32. ;
informat MISCX4CQ best32. ;
informat VEHQL best32. ;
informat VEHQL_ $3. ;
informat NUM_TVAN best32. ;
informat NUM__VAN $3. ;
informat TTOTALP best32. ;
informat TTOTALC best32. ;
informat TFOODTOP best32. ;
informat TFOODTOC best32. ;
informat TFOODAWP best32. ;
informat TFOODAWC best32. ;
informat TFOODHOP best32. ;
informat TFOODHOC best32. ;
informat TALCBEVP best32. ;
informat TALCBEVC best32. ;
informat TOTHRLOP best32. ;
informat TOTHRLOC best32. ;
informat TTRANPRP best32. ;
informat TTRANPRC best32. ;
informat TGASMOTP best32. ;
informat TGASMOTC best32. ;
informat TVRENTLP best32. ;
informat TVRENTLC best32. ;
informat TCARTRKP best32. ;
informat TCARTRKC best32. ;
informat TOTHVHRP best32. ;
informat TOTHVHRC best32. ;
informat TOTHTREP best32. ;
informat TOTHTREC best32. ;
informat TTRNTRIP best32. ;
informat TTRNTRIC best32. ;
informat TFAREP best32. ;
informat TFAREC best32. ;
informat TAIRFARP best32. ;
informat TAIRFARC best32. ;
informat TOTHFARP best32. ;
informat TOTHFARC best32. ;
informat TLOCALTP best32. ;
informat TLOCALTC best32. ;
informat TENTRMNP best32. ;
informat TENTRMNC best32. ;
informat TFEESADP best32. ;
informat TFEESADC best32. ;
informat TOTHENTP best32. ;
informat TOTHENTC best32. ;
informat OWNVACP best32. ;
informat OWNVACC best32. ;
informat VOTHRLOP best32. ;
informat VOTHRLOC best32. ;
informat VMISCHEP best32. ;
informat VMISCHEC best32. ;
informat UTILOWNP best32. ;
informat UTILOWNC best32. ;
informat VFUELOIP best32. ;
informat VFUELOIC best32. ;
informat VOTHRFLP best32. ;
informat VOTHRFLC best32. ;
informat VELECTRP best32. ;
informat VELECTRC best32. ;
informat VNATLGAP best32. ;
informat VNATLGAC best32. ;
informat VWATERPP best32. ;
informat VWATERPC best32. ;
informat MRTPRNOP best32. ;
informat MRTPRNOC best32. ;
informat UTILRNTP best32. ;
informat UTILRNTC best32. ;
informat RFUELOIP best32. ;
informat RFUELOIC best32. ;
informat ROTHRFLP best32. ;
informat ROTHRFLC best32. ;
informat RELECTRP best32. ;
informat RELECTRC best32. ;
informat RNATLGAP best32. ;
informat RNATLGAC best32. ;
informat RWATERPP best32. ;
informat RWATERPC best32. ;
informat POVLEVCY best32. ;
informat POVL_VCY $3. ;
informat POVLEVPY best32. ;
informat POVL_VPY $3. ;
informat COOKING $4. ;
informat COOKING_ $3. ;
informat PORCH $4. ;
informat PORCH_ $3. ;
informat ETOTALP best32. ;
informat ETOTALC best32. ;
informat ETOTAPX4 best32. ;
informat ETOTACX4 best32. ;
informat EHOUSNGP best32. ;
informat EHOUSNGC best32. ;
informat ESHELTRP best32. ;
informat ESHELTRC best32. ;
informat EOWNDWLP best32. ;
informat EOWNDWLC best32. ;
informat EOTHLODP best32. ;
informat EOTHLODC best32. ;
informat EMRTPNOP best32. ;
informat EMRTPNOC best32. ;
informat EMRTPNVP best32. ;
informat EMRTPNVC best32. ;
informat ETRANPTP best32. ;
informat ETRANPTC best32. ;
informat EVEHPURP best32. ;
informat EVEHPURC best32. ;
informat ECARTKNP best32. ;
informat ECARTKNC best32. ;
informat ECARTKUP best32. ;
informat ECARTKUC best32. ;
informat EOTHVEHP best32. ;
informat EOTHVEHC best32. ;
informat EENTRMTP best32. ;
informat EENTRMTC best32. ;
informat EOTHENTP best32. ;
informat EOTHENTC best32. ;
informat ENOMOTRP best32. ;
informat ENOMOTRC best32. ;
informat EMOTRVHP best32. ;
informat EMOTRVHC best32. ;
informat EENTMSCP best32. ;
informat EENTMSCC best32. ;
informat EMISCELP best32. ;
informat EMISCELC best32. ;
informat EMISCMTP best32. ;
informat EMISCMTC best32. ;
informat UNISTRQ $4. ;
informat UNISTRQ_ $3. ;
informat INTEARNB $5. ;
informat INTE_RNB $3. ;
informat INTERNBX best32. ;
informat INTE_NBX $3. ;
informat FININCB $1. ;
informat FININCB_ $3. ;
informat FININCBX best32. ;
informat FINI_CBX $3. ;
informat PENSIONB $5. ;
informat PENS_ONB $3. ;
informat PNSIONBX best32. ;
informat PNSI_NBX $3. ;
informat UNEMPLB $1. ;
informat UNEMPLB_ $3. ;
informat UNEMPLBX best32. ;
informat UNEM_LBX $3. ;
informat COMPENSB $1. ;
informat COMP_NSB $3. ;
informat COMPNSBX best32. ;
informat COMP_SBX $3. ;
informat WELFAREB $1. ;
informat WELF_REB $3. ;
informat WELFREBX best32. ;
informat WELF_EBX $3. ;
informat FOODSMPX best32. ;
informat FOOD_MPX $3. ;
informat FOODSMPB $1. ;
informat FOOD_MPB $3. ;
informat FOODSPBX best32. ;
informat FOOD_PBX $3. ;
informat INCLOSAB $1. ;
informat INCL_SAB $3. ;
informat INCLSABX best32. ;
informat INCL_ABX $3. ;
informat INCLOSBB $1. ;
informat INCL_SBB $3. ;
informat INCLSBBX best32. ;
informat INCL_BBX $3. ;
informat CHDLMPB $1. ;
informat CHDLMPB_ $3. ;
informat CHDLMPBX best32. ;
informat CHDL_PBX $3. ;
informat CHDOTHB $1. ;
informat CHDOTHB_ $3. ;
informat CHDOTHBX best32. ;
informat CHDO_HBX $3. ;
informat ALIOTHB $1. ;
informat ALIOTHB_ $3. ;
informat ALIOTHBX best32. ;
informat ALIO_HBX $3. ;
informat LUMPSUMB $1. ;
informat LUMP_UMB $3. ;
informat LMPSUMBX best32. ;
informat LMPS_MBX $3. ;
informat SALEINCB $1. ;
informat SALE_NCB $3. ;
informat SALINCBX best32. ;
informat SALI_CBX $3. ;
informat OTHRINCB $1. ;
informat OTHR_NCB $3. ;
informat OTRINCBX best32. ;
informat OTRI_CBX $3. ;
informat INCLASS2 $3. ;
informat INCL_SS2 $3. ;
informat CUID best32. ;
informat INTERI best32. ;
informat HORREF1 $4. ;
informat HORREF1_ $3. ;
informat HORREF2 $4. ;
informat HORREF2_ $3. ;
informat ALIOTHXM best32. ;
informat ALIO_HXM $3. ;
informat ALIOTHX1 best32. ;
informat ALIOTHX2 best32. ;
informat ALIOTHX3 best32. ;
informat ALIOTHX4 best32. ;
informat ALIOTHX5 best32. ;
informat ALIOTHXI best32. ;
informat CHDOTHXM best32. ;
informat CHDO_HXM $3. ;
informat CHDOTHX1 best32. ;
informat CHDOTHX2 best32. ;
informat CHDOTHX3 best32. ;
informat CHDOTHX4 best32. ;
informat CHDOTHX5 best32. ;
informat CHDOTHXI best32. ;
informat COMPENSM best32. ;
informat COMP_NSM $3. ;
informat COMPENS1 best32. ;
informat COMPENS2 best32. ;
informat COMPENS3 best32. ;
informat COMPENS4 best32. ;
informat COMPENS5 best32. ;
informat COMPENSI best32. ;
informat ERANKHM best32. ;
informat ERANKHM_ $3. ;
informat FAMTFEDM best32. ;
informat FAMT_EDM $3. ;
informat FAMTFED1 best32. ;
informat FAMTFED2 best32. ;
informat FAMTFED3 best32. ;
informat FAMTFED4 best32. ;
informat FAMTFED5 best32. ;
informat FFRMINCM best32. ;
informat FFRM_NCM $3. ;
informat FFRMINC1 best32. ;
informat FFRMINC2 best32. ;
informat FFRMINC3 best32. ;
informat FFRMINC4 best32. ;
informat FFRMINC5 best32. ;
informat FFRMINCI best32. ;
informat FGOVRETM best32. ;
informat FGOV_ETM $3. ;
informat FINCATXM best32. ;
informat FINCA_XM $3. ;
informat FINCATX1 best32. ;
informat FINCATX2 best32. ;
informat FINCATX3 best32. ;
informat FINCATX4 best32. ;
informat FINCATX5 best32. ;
informat FINCBTXM best32. ;
informat FINCB_XM $3. ;
informat FINCBTX1 best32. ;
informat FINCBTX2 best32. ;
informat FINCBTX3 best32. ;
informat FINCBTX4 best32. ;
informat FINCBTX5 best32. ;
informat FINCBTXI best32. ;
informat FININCXM best32. ;
informat FINI_CXM $3. ;
informat FININCX1 best32. ;
informat FININCX2 best32. ;
informat FININCX3 best32. ;
informat FININCX4 best32. ;
informat FININCX5 best32. ;
informat FININCXI best32. ;
informat FJSSDEDM best32. ;
informat FJSS_EDM $3. ;
informat FJSSDED1 best32. ;
informat FJSSDED2 best32. ;
informat FJSSDED3 best32. ;
informat FJSSDED4 best32. ;
informat FJSSDED5 best32. ;
informat FNONFRMM best32. ;
informat FNON_RMM $3. ;
informat FNONFRM1 best32. ;
informat FNONFRM2 best32. ;
informat FNONFRM3 best32. ;
informat FNONFRM4 best32. ;
informat FNONFRM5 best32. ;
informat FNONFRMI best32. ;
informat FOODSMPM best32. ;
informat FOOD_MPM $3. ;
informat FOODSMP1 best32. ;
informat FOODSMP2 best32. ;
informat FOODSMP3 best32. ;
informat FOODSMP4 best32. ;
informat FOODSMP5 best32. ;
informat FOODSMPI best32. ;
informat FPRIPENM best32. ;
informat FPRI_ENM $3. ;
informat FRRDEDM best32. ;
informat FRRDEDM_ $3. ;
informat FRRETIRM best32. ;
informat FRRE_IRM $3. ;
informat FRRETIR1 best32. ;
informat FRRETIR2 best32. ;
informat FRRETIR3 best32. ;
informat FRRETIR4 best32. ;
informat FRRETIR5 best32. ;
informat FRRETIRI best32. ;
informat FSALARYM best32. ;
informat FSAL_RYM $3. ;
informat FSALARY1 best32. ;
informat FSALARY2 best32. ;
informat FSALARY3 best32. ;
informat FSALARY4 best32. ;
informat FSALARY5 best32. ;
informat FSALARYI best32. ;
informat FSLTAXXM best32. ;
informat FSLT_XXM $3. ;
informat FSLTAXX1 best32. ;
informat FSLTAXX2 best32. ;
informat FSLTAXX3 best32. ;
informat FSLTAXX4 best32. ;
informat FSLTAXX5 best32. ;
informat FSSIXM best32. ;
informat FSSIXM_ $3. ;
informat FSSIX1 best32. ;
informat FSSIX2 best32. ;
informat FSSIX3 best32. ;
informat FSSIX4 best32. ;
informat FSSIX5 best32. ;
informat FSSIXI best32. ;
informat INC_RNKM best32. ;
informat INC__NKM $3. ;
informat INC_RNK1 best32. ;
informat INC_RNK2 best32. ;
informat INC_RNK3 best32. ;
informat INC_RNK4 best32. ;
informat INC_RNK5 best32. ;
informat INCLOSAM best32. ;
informat INCL_SAM $3. ;
informat INCLOSA1 best32. ;
informat INCLOSA2 best32. ;
informat INCLOSA3 best32. ;
informat INCLOSA4 best32. ;
informat INCLOSA5 best32. ;
informat INCLOSAI best32. ;
informat INCLOSBM best32. ;
informat INCL_SBM $3. ;
informat INCLOSB1 best32. ;
informat INCLOSB2 best32. ;
informat INCLOSB3 best32. ;
informat INCLOSB4 best32. ;
informat INCLOSB5 best32. ;
informat INCLOSBI best32. ;
informat INTEARNM best32. ;
informat INTE_RNM $3. ;
informat INTEARN1 best32. ;
informat INTEARN2 best32. ;
informat INTEARN3 best32. ;
informat INTEARN4 best32. ;
informat INTEARN5 best32. ;
informat INTEARNI best32. ;
informat OTHRINCM best32. ;
informat OTHR_NCM $3. ;
informat OTHRINC1 best32. ;
informat OTHRINC2 best32. ;
informat OTHRINC3 best32. ;
informat OTHRINC4 best32. ;
informat OTHRINC5 best32. ;
informat OTHRINCI best32. ;
informat PENSIONM best32. ;
informat PENS_ONM $3. ;
informat PENSION1 best32. ;
informat PENSION2 best32. ;
informat PENSION3 best32. ;
informat PENSION4 best32. ;
informat PENSION5 best32. ;
informat PENSIONI best32. ;
informat POV_CYM $3. ;
informat POV_CYM_ $3. ;
informat POV_CY1 $3. ;
informat POV_CY2 $3. ;
informat POV_CY3 $3. ;
informat POV_CY4 $3. ;
informat POV_CY5 $3. ;
informat POV_PYM $3. ;
informat POV_PYM_ $3. ;
informat POV_PY1 $3. ;
informat POV_PY2 $3. ;
informat POV_PY3 $3. ;
informat POV_PY4 $3. ;
informat POV_PY5 $3. ;
informat PRINERNM $4. ;
informat PRIN_RNM $3. ;
informat PRINERN1 $4. ;
informat PRINERN2 $4. ;
informat PRINERN3 $4. ;
informat PRINERN4 $4. ;
informat PRINERN5 $4. ;
informat TOTTXPDM best32. ;
informat TOTT_PDM $3. ;
informat TOTTXPD1 best32. ;
informat TOTTXPD2 best32. ;
informat TOTTXPD3 best32. ;
informat TOTTXPD4 best32. ;
informat TOTTXPD5 best32. ;
informat UNEMPLXM best32. ;
informat UNEM_LXM $3. ;
informat UNEMPLX1 best32. ;
informat UNEMPLX2 best32. ;
informat UNEMPLX3 best32. ;
informat UNEMPLX4 best32. ;
informat UNEMPLX5 best32. ;
informat UNEMPLXI best32. ;
informat WELFAREM best32. ;
informat WELF_REM $3. ;
informat WELFARE1 best32. ;
informat WELFARE2 best32. ;
informat WELFARE3 best32. ;
informat WELFARE4 best32. ;
informat WELFARE5 best32. ;
informat WELFAREI best32. ;
informat COLPLAN $4. ;
informat COLPLAN_ $3. ;
informat COLPLANX best32. ;
informat COLP_ANX $3. ;
informat PSU $8. ;
informat REVSMORT $4. ;
informat REVS_ORT $3. ;
informat RVSLUMP $1. ;
informat RVSLUMP_ $3. ;
informat RVSREGMO $1. ;
informat RVSR_GMO $3. ;
informat RVSLOC $1. ;
informat RVSLOC_ $3. ;
informat RVSOTHPY $1. ;
informat RVSO_HPY $3. ;
informat TYPEPYX best32. ;
informat TYPEPYX_ $3. ;
informat HISP_REF $3. ;
informat HISP2 $4. ;
informat BUILT $8. ;
informat BUILT_ $3. ;
input
NEWID
DIRACC $
DIRACC_ $
AGE_REF
AGE_REF_ $
AGE2
AGE2_ $
AS_COMP1
AS_C_MP1 $
AS_COMP2
AS_C_MP2 $
AS_COMP3
AS_C_MP3 $
AS_COMP4
AS_C_MP4 $
AS_COMP5
AS_C_MP5 $
BATHRMQ
BATHRMQ_ $
BEDROOMQ
BEDR_OMQ $
BLS_URBN $
BSINVSTX
BSIN_STX $
BUILDING $
BUIL_ING $
CKBKACTX
CKBK_CTX $
COMPBND $
COMPBND_ $
COMPBNDX
COMP_NDX $
COMPCKG $
COMPCKG_ $
COMPCKGX
COMP_KGX $
COMPENSX
COMP_NSX $
COMPOWD $
COMPOWD_ $
COMPOWDX
COMP_WDX $
COMPSAV $
COMPSAV_ $
COMPSAVX
COMP_AVX $
COMPSEC $
COMPSEC_ $
COMPSECX
COMP_ECX $
CUTENURE $
CUTE_URE $
EARNCOMP $
EARN_OMP $
EDUC_REF $
EDUC0REF $
EDUCA2 $
EDUCA2_ $
FAM_SIZE
FAM__IZE $
FAM_TYPE $
FAM__YPE $
FAMTFEDX
FAMT_EDX $
FEDRFNDX
FEDR_NDX $
FEDTAXX
FEDTAXX_ $
FFRMINCX
FFRM_NCX $
FGOVRETX
FGOV_ETX $
FINCATAX
FINCAT_X $
FINCBTAX
FINCBT_X $
FINDRETX
FIND_ETX $
FININCX
FININCX_ $
FINLWT21
FJSSDEDX
FJSS_EDX $
FNONFRMX
FNON_RMX $
FPRIPENX
FPRI_ENX $
FRRDEDX
FRRDEDX_ $
FRRETIRX
FRRE_IRX $
FSALARYX
FSAL_RYX $
FSLTAXX
FSLTAXX_ $
FSSIX
FSSIX_ $
GOVTCOST $
GOVT_OST $
HLFBATHQ
HLFB_THQ $
INC_HRS1
INC__RS1 $
INC_HRS2
INC__RS2 $
INC_RANK
INC__ANK $
INCLOSSA
INCL_SSA $
INCLOSSB
INCL_SSB $
INCNONW1 $
INCN_NW1 $
INCNONW2 $
INCN_NW2 $
INCOMEY1 $
INCO_EY1 $
INCOMEY2 $
INCO_EY2 $
INCWEEK1
INCW_EK1 $
INCWEEK2
INCW_EK2 $
INSRFNDX
INSR_NDX $
INTEARNX
INTE_RNX $
MISCTAXX
MISC_AXX $
LUMPSUMX
LUMP_UMX $
MARITAL1 $
MARI_AL1 $
MONYOWDX
MONY_WDX $
NO_EARNR
NO_E_RNR $
NONINCMX
NONI_CMX $
NUM_AUTO
NUM__UTO $
OCCUCOD1 $
OCCU_OD1 $
OCCUCOD2 $
OCCU_OD2 $
OTHRFNDX
OTHR_NDX $
OTHRINCX
OTHR_NCX $
PENSIONX
PENS_ONX $
PERSLT18
PERS_T18 $
PERSOT64
PERS_T64 $
POPSIZE $
PRINEARN $
PRIN_ARN $
PTAXRFDX
PTAX_FDX $
PUBLHOUS $
PUBL_OUS $
PURSSECX
PURS_ECX $
QINTRVMO $
QINTRVYR
RACE2 $
RACE2_ $
REF_RACE $
REF__ACE $
REGION $
RENTEQVX
RENT_QVX $
RESPSTAT $
RESP_TAT $
ROOMSQ
ROOMSQ_ $
SALEINCX
SALE_NCX $
SAVACCTX
SAVA_CTX $
SECESTX
SECESTX_ $
SELLSECX
SELL_ECX $
SETLINSX
SETL_NSX $
SEX_REF $
SEX_REF_ $
SEX2 $
SEX2_ $
SLOCTAXX
SLOC_AXX $
SLRFUNDX
SLRF_NDX $
SMSASTAT $
SSOVERPX
SSOV_RPX $
ST_HOUS $
ST_HOUS_ $
TAXPROPX
TAXP_OPX $
TOTTXPDX
TOTT_PDX $
UNEMPLX
UNEMPLX_ $
USBNDX
USBNDX_ $
VEHQ
VEHQ_ $
WDBSASTX
WDBS_STX $
WDBSGDSX
WDBS_DSX $
WELFAREX
WELF_REX $
WTREP01
WTREP02
WTREP03
WTREP04
WTREP05
WTREP06
WTREP07
WTREP08
WTREP09
WTREP10
WTREP11
WTREP12
WTREP13
WTREP14
WTREP15
WTREP16
WTREP17
WTREP18
WTREP19
WTREP20
WTREP21
WTREP22
WTREP23
WTREP24
WTREP25
WTREP26
WTREP27
WTREP28
WTREP29
WTREP30
WTREP31
WTREP32
WTREP33
WTREP34
WTREP35
WTREP36
WTREP37
WTREP38
WTREP39
WTREP40
WTREP41
WTREP42
WTREP43
WTREP44
TOTEXPPQ
TOTEXPCQ
FOODPQ
FOODCQ
FDHOMEPQ
FDHOMECQ
FDAWAYPQ
FDAWAYCQ
FDXMAPPQ
FDXMAPCQ
FDMAPPQ
FDMAPCQ
ALCBEVPQ
ALCBEVCQ
HOUSPQ
HOUSCQ
SHELTPQ
SHELTCQ
OWNDWEPQ
OWNDWECQ
MRTINTPQ
MRTINTCQ
PROPTXPQ
PROPTXCQ
MRPINSPQ
MRPINSCQ
RENDWEPQ
RENDWECQ
RNTXRPPQ
RNTXRPCQ
RNTAPYPQ
RNTAPYCQ
OTHLODPQ
OTHLODCQ
UTILPQ
UTILCQ
NTLGASPQ
NTLGASCQ
ELCTRCPQ
ELCTRCCQ
ALLFULPQ
ALLFULCQ
FULOILPQ
FULOILCQ
OTHFLSPQ
OTHFLSCQ
TELEPHPQ
TELEPHCQ
WATRPSPQ
WATRPSCQ
HOUSOPPQ
HOUSOPCQ
DOMSRVPQ
DOMSRVCQ
DMSXCCPQ
DMSXCCCQ
BBYDAYPQ
BBYDAYCQ
OTHHEXPQ
OTHHEXCQ
HOUSEQPQ
HOUSEQCQ
TEXTILPQ
TEXTILCQ
FURNTRPQ
FURNTRCQ
FLRCVRPQ
FLRCVRCQ
MAJAPPPQ
MAJAPPCQ
SMLAPPPQ
SMLAPPCQ
MISCEQPQ
MISCEQCQ
APPARPQ
APPARCQ
MENBOYPQ
MENBOYCQ
MENSIXPQ
MENSIXCQ
BOYFIFPQ
BOYFIFCQ
WOMGRLPQ
WOMGRLCQ
WOMSIXPQ
WOMSIXCQ
GRLFIFPQ
GRLFIFCQ
CHLDRNPQ
CHLDRNCQ
FOOTWRPQ
FOOTWRCQ
OTHAPLPQ
OTHAPLCQ
TRANSPQ
TRANSCQ
CARTKNPQ
CARTKNCQ
CARTKUPQ
CARTKUCQ
OTHVEHPQ
OTHVEHCQ
GASMOPQ
GASMOCQ
VEHFINPQ
VEHFINCQ
MAINRPPQ
MAINRPCQ
VEHINSPQ
VEHINSCQ
VRNTLOPQ
VRNTLOCQ
PUBTRAPQ
PUBTRACQ
TRNTRPPQ
TRNTRPCQ
TRNOTHPQ
TRNOTHCQ
HEALTHPQ
HEALTHCQ
HLTHINPQ
HLTHINCQ
MEDSRVPQ
MEDSRVCQ
PREDRGPQ
PREDRGCQ
MEDSUPPQ
MEDSUPCQ
ENTERTPQ
ENTERTCQ
FEEADMPQ
FEEADMCQ
TVRDIOPQ
TVRDIOCQ
OTHEQPPQ
OTHEQPCQ
PETTOYPQ
PETTOYCQ
OTHENTPQ
OTHENTCQ
PERSCAPQ
PERSCACQ
READPQ
READCQ
EDUCAPQ
EDUCACQ
TOBACCPQ
TOBACCCQ
MISCPQ
MISCCQ
MISC1PQ
MISC1CQ
MISC2PQ
MISC2CQ
CASHCOPQ
CASHCOCQ
PERINSPQ
PERINSCQ
LIFINSPQ
LIFINSCQ
RETPENPQ
RETPENCQ
HH_CU_Q
HH_CU_Q_ $
HHID
HHID_ $
POV_CY $
POV_CY_ $
POV_PY $
POV_PY_ $
HEATFUEL $
HEAT_UEL $
SWIMPOOL $
SWIM_OOL $
WATERHT $
WATERHT_ $
APTMENT $
APTMENT_ $
OFSTPARK $
OFST_ARK $
WINDOWAC $
WIND_WAC $
CNTRALAC $
CNTR_LAC $
CHILDAGE $
CHIL_AGE $
INCLASS $
STATE $
CHDOTHX
CHDOTHX_ $
ALIOTHX
ALIOTHX_ $
CHDLMPX
CHDLMPX_ $
ERANKH
ERANKH_ $
TOTEX4PQ
TOTEX4CQ
MISCX4PQ
MISCX4CQ
VEHQL
VEHQL_ $
NUM_TVAN
NUM__VAN $
TTOTALP
TTOTALC
TFOODTOP
TFOODTOC
TFOODAWP
TFOODAWC
TFOODHOP
TFOODHOC
TALCBEVP
TALCBEVC
TOTHRLOP
TOTHRLOC
TTRANPRP
TTRANPRC
TGASMOTP
TGASMOTC
TVRENTLP
TVRENTLC
TCARTRKP
TCARTRKC
TOTHVHRP
TOTHVHRC
TOTHTREP
TOTHTREC
TTRNTRIP
TTRNTRIC
TFAREP
TFAREC
TAIRFARP
TAIRFARC
TOTHFARP
TOTHFARC
TLOCALTP
TLOCALTC
TENTRMNP
TENTRMNC
TFEESADP
TFEESADC
TOTHENTP
TOTHENTC
OWNVACP
OWNVACC
VOTHRLOP
VOTHRLOC
VMISCHEP
VMISCHEC
UTILOWNP
UTILOWNC
VFUELOIP
VFUELOIC
VOTHRFLP
VOTHRFLC
VELECTRP
VELECTRC
VNATLGAP
VNATLGAC
VWATERPP
VWATERPC
MRTPRNOP
MRTPRNOC
UTILRNTP
UTILRNTC
RFUELOIP
RFUELOIC
ROTHRFLP
ROTHRFLC
RELECTRP
RELECTRC
RNATLGAP
RNATLGAC
RWATERPP
RWATERPC
POVLEVCY
POVL_VCY $
POVLEVPY
POVL_VPY $
COOKING $
COOKING_ $
PORCH $
PORCH_ $
ETOTALP
ETOTALC
ETOTAPX4
ETOTACX4
EHOUSNGP
EHOUSNGC
ESHELTRP
ESHELTRC
EOWNDWLP
EOWNDWLC
EOTHLODP
EOTHLODC
EMRTPNOP
EMRTPNOC
EMRTPNVP
EMRTPNVC
ETRANPTP
ETRANPTC
EVEHPURP
EVEHPURC
ECARTKNP
ECARTKNC
ECARTKUP
ECARTKUC
EOTHVEHP
EOTHVEHC
EENTRMTP
EENTRMTC
EOTHENTP
EOTHENTC
ENOMOTRP
ENOMOTRC
EMOTRVHP
EMOTRVHC
EENTMSCP
EENTMSCC
EMISCELP
EMISCELC
EMISCMTP
EMISCMTC
UNISTRQ $
UNISTRQ_ $
INTEARNB $
INTE_RNB $
INTERNBX
INTE_NBX $
FININCB $
FININCB_ $
FININCBX
FINI_CBX $
PENSIONB $
PENS_ONB $
PNSIONBX
PNSI_NBX $
UNEMPLB $
UNEMPLB_ $
UNEMPLBX
UNEM_LBX $
COMPENSB $
COMP_NSB $
COMPNSBX
COMP_SBX $
WELFAREB $
WELF_REB $
WELFREBX
WELF_EBX $
FOODSMPX
FOOD_MPX $
FOODSMPB $
FOOD_MPB $
FOODSPBX
FOOD_PBX $
INCLOSAB $
INCL_SAB $
INCLSABX
INCL_ABX $
INCLOSBB $
INCL_SBB $
INCLSBBX
INCL_BBX $
CHDLMPB $
CHDLMPB_ $
CHDLMPBX
CHDL_PBX $
CHDOTHB $
CHDOTHB_ $
CHDOTHBX
CHDO_HBX $
ALIOTHB $
ALIOTHB_ $
ALIOTHBX
ALIO_HBX $
LUMPSUMB $
LUMP_UMB $
LMPSUMBX
LMPS_MBX $
SALEINCB $
SALE_NCB $
SALINCBX
SALI_CBX $
OTHRINCB $
OTHR_NCB $
OTRINCBX
OTRI_CBX $
INCLASS2 $
INCL_SS2 $
CUID
INTERI
HORREF1 $
HORREF1_ $
HORREF2 $
HORREF2_ $
ALIOTHXM
ALIO_HXM $
ALIOTHX1
ALIOTHX2
ALIOTHX3
ALIOTHX4
ALIOTHX5
ALIOTHXI
CHDOTHXM
CHDO_HXM $
CHDOTHX1
CHDOTHX2
CHDOTHX3
CHDOTHX4
CHDOTHX5
CHDOTHXI
COMPENSM
COMP_NSM $
COMPENS1
COMPENS2
COMPENS3
COMPENS4
COMPENS5
COMPENSI
ERANKHM
ERANKHM_ $
FAMTFEDM
FAMT_EDM $
FAMTFED1
FAMTFED2
FAMTFED3
FAMTFED4
FAMTFED5
FFRMINCM
FFRM_NCM $
FFRMINC1
FFRMINC2
FFRMINC3
FFRMINC4
FFRMINC5
FFRMINCI
FGOVRETM
FGOV_ETM $
FINCATXM
FINCA_XM $
FINCATX1
FINCATX2
FINCATX3
FINCATX4
FINCATX5
FINCBTXM
FINCB_XM $
FINCBTX1
FINCBTX2
FINCBTX3
FINCBTX4
FINCBTX5
FINCBTXI
FININCXM
FINI_CXM $
FININCX1
FININCX2
FININCX3
FININCX4
FININCX5
FININCXI
FJSSDEDM
FJSS_EDM $
FJSSDED1
FJSSDED2
FJSSDED3
FJSSDED4
FJSSDED5
FNONFRMM
FNON_RMM $
FNONFRM1
FNONFRM2
FNONFRM3
FNONFRM4
FNONFRM5
FNONFRMI
FOODSMPM
FOOD_MPM $
FOODSMP1
FOODSMP2
FOODSMP3
FOODSMP4
FOODSMP5
FOODSMPI
FPRIPENM
FPRI_ENM $
FRRDEDM
FRRDEDM_ $
FRRETIRM
FRRE_IRM $
FRRETIR1
FRRETIR2
FRRETIR3
FRRETIR4
FRRETIR5
FRRETIRI
FSALARYM
FSAL_RYM $
FSALARY1
FSALARY2
FSALARY3
FSALARY4
FSALARY5
FSALARYI
FSLTAXXM
FSLT_XXM $
FSLTAXX1
FSLTAXX2
FSLTAXX3
FSLTAXX4
FSLTAXX5
FSSIXM
FSSIXM_ $
FSSIX1
FSSIX2
FSSIX3
FSSIX4
FSSIX5
FSSIXI
INC_RNKM
INC__NKM $
INC_RNK1
INC_RNK2
INC_RNK3
INC_RNK4
INC_RNK5
INCLOSAM
INCL_SAM $
INCLOSA1
INCLOSA2
INCLOSA3
INCLOSA4
INCLOSA5
INCLOSAI
INCLOSBM
INCL_SBM $
INCLOSB1
INCLOSB2
INCLOSB3
INCLOSB4
INCLOSB5
INCLOSBI
INTEARNM
INTE_RNM $
INTEARN1
INTEARN2
INTEARN3
INTEARN4
INTEARN5
INTEARNI
OTHRINCM
OTHR_NCM $
OTHRINC1
OTHRINC2
OTHRINC3
OTHRINC4
OTHRINC5
OTHRINCI
PENSIONM
PENS_ONM $
PENSION1
PENSION2
PENSION3
PENSION4
PENSION5
PENSIONI
POV_CYM $
POV_CYM_ $
POV_CY1 $
POV_CY2 $
POV_CY3 $
POV_CY4 $
POV_CY5 $
POV_PYM $
POV_PYM_ $
POV_PY1 $
POV_PY2 $
POV_PY3 $
POV_PY4 $
POV_PY5 $
PRINERNM $
PRIN_RNM $
PRINERN1 $
PRINERN2 $
PRINERN3 $
PRINERN4 $
PRINERN5 $
TOTTXPDM
TOTT_PDM $
TOTTXPD1
TOTTXPD2
TOTTXPD3
TOTTXPD4
TOTTXPD5
UNEMPLXM
UNEM_LXM $
UNEMPLX1
UNEMPLX2
UNEMPLX3
UNEMPLX4
UNEMPLX5
UNEMPLXI
WELFAREM
WELF_REM $
WELFARE1
WELFARE2
WELFARE3
WELFARE4
WELFARE5
WELFAREI
COLPLAN $
COLPLAN_ $
COLPLANX
COLP_ANX $
PSU $
REVSMORT $
REVS_ORT $
RVSLUMP $
RVSLUMP_ $
RVSREGMO $
RVSR_GMO $
RVSLOC $
RVSLOC_ $
RVSOTHPY $
RVSO_HPY $
TYPEPYX
TYPEPYX_ $
HISP_REF $
HISP2 $
BUILT $
BUILT_ $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/***********************************************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\FMLI&YR1.4.CSV"
            OUT=FMLYI&YR1.4
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
************************************************************************************************/

data WORK.FMLYI114                                ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile 'C:\2011_CEX\Intrvw11\FMLI114.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat NEWID best32. ;
informat DIRACC $3. ;
informat DIRACC_ $3. ;
informat AGE_REF best32. ;
informat AGE_REF_ $3. ;
informat AGE2 best32. ;
informat AGE2_ $3. ;
informat AS_COMP1 best32. ;
informat AS_C_MP1 $3. ;
informat AS_COMP2 best32. ;
informat AS_C_MP2 $3. ;
informat AS_COMP3 best32. ;
informat AS_C_MP3 $3. ;
informat AS_COMP4 best32. ;
informat AS_C_MP4 $3. ;
informat AS_COMP5 best32. ;
informat AS_C_MP5 $3. ;
informat BATHRMQ best32. ;
informat BATHRMQ_ $3. ;
informat BEDROOMQ best32. ;
informat BEDR_OMQ $3. ;
informat BLS_URBN $3. ;
informat BSINVSTX best32. ;
informat BSIN_STX $3. ;
informat BUILDING $4. ;
informat BUIL_ING $3. ;
informat CKBKACTX best32. ;
informat CKBK_CTX $3. ;
informat COMPBND $4. ;
informat COMPBND_ $3. ;
informat COMPBNDX best32. ;
informat COMP_NDX $3. ;
informat COMPCKG $4. ;
informat COMPCKG_ $3. ;
informat COMPCKGX best32. ;
informat COMP_KGX $3. ;
informat COMPENSX best32. ;
informat COMP_NSX $3. ;
informat COMPOWD $1. ;
informat COMPOWD_ $3. ;
informat COMPOWDX best32. ;
informat COMP_WDX $3. ;
informat COMPSAV $4. ;
informat COMPSAV_ $3. ;
informat COMPSAVX best32. ;
informat COMP_AVX $3. ;
informat COMPSEC $4. ;
informat COMPSEC_ $3. ;
informat COMPSECX best32. ;
informat COMP_ECX $3. ;
informat CUTENURE $3. ;
informat CUTE_URE $3. ;
informat EARNCOMP $3. ;
informat EARN_OMP $3. ;
informat EDUC_REF $4. ;
informat EDUC0REF $3. ;
informat EDUCA2 $5. ;
informat EDUCA2_ $3. ;
informat FAM_SIZE best32. ;
informat FAM__IZE $3. ;
informat FAM_TYPE $3. ;
informat FAM__YPE $3. ;
informat FAMTFEDX best32. ;
informat FAMT_EDX $3. ;
informat FEDRFNDX best32. ;
informat FEDR_NDX $3. ;
informat FEDTAXX best32. ;
informat FEDTAXX_ $3. ;
informat FFRMINCX best32. ;
informat FFRM_NCX $3. ;
informat FGOVRETX best32. ;
informat FGOV_ETX $3. ;
informat FINCATAX best32. ;
informat FINCAT_X $3. ;
informat FINCBTAX best32. ;
informat FINCBT_X $3. ;
informat FINDRETX best32. ;
informat FIND_ETX $3. ;
informat FININCX best32. ;
informat FININCX_ $3. ;
informat FINLWT21 best32. ;
informat FJSSDEDX best32. ;
informat FJSS_EDX $3. ;
informat FNONFRMX best32. ;
informat FNON_RMX $3. ;
informat FPRIPENX best32. ;
informat FPRI_ENX $3. ;
informat FRRDEDX best32. ;
informat FRRDEDX_ $3. ;
informat FRRETIRX best32. ;
informat FRRE_IRX $3. ;
informat FSALARYX best32. ;
informat FSAL_RYX $3. ;
informat FSLTAXX best32. ;
informat FSLTAXX_ $3. ;
informat FSSIX best32. ;
informat FSSIX_ $3. ;
informat GOVTCOST $3. ;
informat GOVT_OST $3. ;
informat HLFBATHQ best32. ;
informat HLFB_THQ $3. ;
informat INC_HRS1 best32. ;
informat INC__RS1 $3. ;
informat INC_HRS2 best32. ;
informat INC__RS2 $3. ;
informat INC_RANK best32. ;
informat INC__ANK $3. ;
informat INCLOSSA best32. ;
informat INCL_SSA $3. ;
informat INCLOSSB best32. ;
informat INCL_SSB $3. ;
informat INCNONW1 $3. ;
informat INCN_NW1 $3. ;
informat INCNONW2 $4. ;
informat INCN_NW2 $3. ;
informat INCOMEY1 $4. ;
informat INCO_EY1 $3. ;
informat INCOMEY2 $4. ;
informat INCO_EY2 $3. ;
informat INCWEEK1 best32. ;
informat INCW_EK1 $3. ;
informat INCWEEK2 best32. ;
informat INCW_EK2 $3. ;
informat INSRFNDX best32. ;
informat INSR_NDX $3. ;
informat INTEARNX best32. ;
informat INTE_RNX $3. ;
informat MISCTAXX best32. ;
informat MISC_AXX $3. ;
informat LUMPSUMX best32. ;
informat LUMP_UMX $3. ;
informat MARITAL1 $3. ;
informat MARI_AL1 $3. ;
informat MONYOWDX best32. ;
informat MONY_WDX $3. ;
informat NO_EARNR best32. ;
informat NO_E_RNR $3. ;
informat NONINCMX best32. ;
informat NONI_CMX $3. ;
informat NUM_AUTO best32. ;
informat NUM__UTO $3. ;
informat OCCUCOD1 $5. ;
informat OCCU_OD1 $3. ;
informat OCCUCOD2 $5. ;
informat OCCU_OD2 $3. ;
informat OTHRFNDX best32. ;
informat OTHR_NDX $3. ;
informat OTHRINCX best32. ;
informat OTHR_NCX $3. ;
informat PENSIONX best32. ;
informat PENS_ONX $3. ;
informat PERSLT18 best32. ;
informat PERS_T18 $3. ;
informat PERSOT64 best32. ;
informat PERS_T64 $3. ;
informat POPSIZE $3. ;
informat PRINEARN $4. ;
informat PRIN_ARN $3. ;
informat PTAXRFDX best32. ;
informat PTAX_FDX $3. ;
informat PUBLHOUS $3. ;
informat PUBL_OUS $3. ;
informat PURSSECX best32. ;
informat PURS_ECX $3. ;
informat QINTRVMO $2. ;
informat QINTRVYR 4. ;
informat RACE2 $4. ;
informat RACE2_ $3. ;
informat REF_RACE $3. ;
informat REF__ACE $3. ;
informat REGION $3. ;
informat RENTEQVX best32. ;
informat RENT_QVX $3. ;
informat RESPSTAT $3. ;
informat RESP_TAT $3. ;
informat ROOMSQ best32. ;
informat ROOMSQ_ $3. ;
informat SALEINCX best32. ;
informat SALE_NCX $3. ;
informat SAVACCTX best32. ;
informat SAVA_CTX $3. ;
informat SECESTX best32. ;
informat SECESTX_ $3. ;
informat SELLSECX best32. ;
informat SELL_ECX $3. ;
informat SETLINSX best32. ;
informat SETL_NSX $3. ;
informat SEX_REF $3. ;
informat SEX_REF_ $3. ;
informat SEX2 $4. ;
informat SEX2_ $3. ;
informat SLOCTAXX best32. ;
informat SLOC_AXX $3. ;
informat SLRFUNDX best32. ;
informat SLRF_NDX $3. ;
informat SMSASTAT $3. ;
informat SSOVERPX best32. ;
informat SSOV_RPX $3. ;
informat ST_HOUS $3. ;
informat ST_HOUS_ $3. ;
informat TAXPROPX best32. ;
informat TAXP_OPX $3. ;
informat TOTTXPDX best32. ;
informat TOTT_PDX $3. ;
informat UNEMPLX best32. ;
informat UNEMPLX_ $3. ;
informat USBNDX best32. ;
informat USBNDX_ $3. ;
informat VEHQ best32. ;
informat VEHQ_ $3. ;
informat WDBSASTX best32. ;
informat WDBS_STX $3. ;
informat WDBSGDSX best32. ;
informat WDBS_DSX $3. ;
informat WELFAREX best32. ;
informat WELF_REX $3. ;
informat WTREP01 best32. ;
informat WTREP02 best32. ;
informat WTREP03 best32. ;
informat WTREP04 best32. ;
informat WTREP05 best32. ;
informat WTREP06 best32. ;
informat WTREP07 best32. ;
informat WTREP08 best32. ;
informat WTREP09 best32. ;
informat WTREP10 best32. ;
informat WTREP11 best32. ;
informat WTREP12 best32. ;
informat WTREP13 best32. ;
informat WTREP14 best32. ;
informat WTREP15 best32. ;
informat WTREP16 best32. ;
informat WTREP17 best32. ;
informat WTREP18 best32. ;
informat WTREP19 best32. ;
informat WTREP20 best32. ;
informat WTREP21 best32. ;
informat WTREP22 best32. ;
informat WTREP23 best32. ;
informat WTREP24 best32. ;
informat WTREP25 best32. ;
informat WTREP26 best32. ;
informat WTREP27 best32. ;
informat WTREP28 best32. ;
informat WTREP29 best32. ;
informat WTREP30 best32. ;
informat WTREP31 best32. ;
informat WTREP32 best32. ;
informat WTREP33 best32. ;
informat WTREP34 best32. ;
informat WTREP35 best32. ;
informat WTREP36 best32. ;
informat WTREP37 best32. ;
informat WTREP38 best32. ;
informat WTREP39 best32. ;
informat WTREP40 best32. ;
informat WTREP41 best32. ;
informat WTREP42 best32. ;
informat WTREP43 best32. ;
informat WTREP44 best32. ;
informat TOTEXPPQ best32. ;
informat TOTEXPCQ best32. ;
informat FOODPQ best32. ;
informat FOODCQ best32. ;
informat FDHOMEPQ best32. ;
informat FDHOMECQ best32. ;
informat FDAWAYPQ best32. ;
informat FDAWAYCQ best32. ;
informat FDXMAPPQ best32. ;
informat FDXMAPCQ best32. ;
informat FDMAPPQ best32. ;
informat FDMAPCQ best32. ;
informat ALCBEVPQ best32. ;
informat ALCBEVCQ best32. ;
informat HOUSPQ best32. ;
informat HOUSCQ best32. ;
informat SHELTPQ best32. ;
informat SHELTCQ best32. ;
informat OWNDWEPQ best32. ;
informat OWNDWECQ best32. ;
informat MRTINTPQ best32. ;
informat MRTINTCQ best32. ;
informat PROPTXPQ best32. ;
informat PROPTXCQ best32. ;
informat MRPINSPQ best32. ;
informat MRPINSCQ best32. ;
informat RENDWEPQ best32. ;
informat RENDWECQ best32. ;
informat RNTXRPPQ best32. ;
informat RNTXRPCQ best32. ;
informat RNTAPYPQ best32. ;
informat RNTAPYCQ best32. ;
informat OTHLODPQ best32. ;
informat OTHLODCQ best32. ;
informat UTILPQ best32. ;
informat UTILCQ best32. ;
informat NTLGASPQ best32. ;
informat NTLGASCQ best32. ;
informat ELCTRCPQ best32. ;
informat ELCTRCCQ best32. ;
informat ALLFULPQ best32. ;
informat ALLFULCQ best32. ;
informat FULOILPQ best32. ;
informat FULOILCQ best32. ;
informat OTHFLSPQ best32. ;
informat OTHFLSCQ best32. ;
informat TELEPHPQ best32. ;
informat TELEPHCQ best32. ;
informat WATRPSPQ best32. ;
informat WATRPSCQ best32. ;
informat HOUSOPPQ best32. ;
informat HOUSOPCQ best32. ;
informat DOMSRVPQ best32. ;
informat DOMSRVCQ best32. ;
informat DMSXCCPQ best32. ;
informat DMSXCCCQ best32. ;
informat BBYDAYPQ best32. ;
informat BBYDAYCQ best32. ;
informat OTHHEXPQ best32. ;
informat OTHHEXCQ best32. ;
informat HOUSEQPQ best32. ;
informat HOUSEQCQ best32. ;
informat TEXTILPQ best32. ;
informat TEXTILCQ best32. ;
informat FURNTRPQ best32. ;
informat FURNTRCQ best32. ;
informat FLRCVRPQ best32. ;
informat FLRCVRCQ best32. ;
informat MAJAPPPQ best32. ;
informat MAJAPPCQ best32. ;
informat SMLAPPPQ best32. ;
informat SMLAPPCQ best32. ;
informat MISCEQPQ best32. ;
informat MISCEQCQ best32. ;
informat APPARPQ best32. ;
informat APPARCQ best32. ;
informat MENBOYPQ best32. ;
informat MENBOYCQ best32. ;
informat MENSIXPQ best32. ;
informat MENSIXCQ best32. ;
informat BOYFIFPQ best32. ;
informat BOYFIFCQ best32. ;
informat WOMGRLPQ best32. ;
informat WOMGRLCQ best32. ;
informat WOMSIXPQ best32. ;
informat WOMSIXCQ best32. ;
informat GRLFIFPQ best32. ;
informat GRLFIFCQ best32. ;
informat CHLDRNPQ best32. ;
informat CHLDRNCQ best32. ;
informat FOOTWRPQ best32. ;
informat FOOTWRCQ best32. ;
informat OTHAPLPQ best32. ;
informat OTHAPLCQ best32. ;
informat TRANSPQ best32. ;
informat TRANSCQ best32. ;
informat CARTKNPQ best32. ;
informat CARTKNCQ best32. ;
informat CARTKUPQ best32. ;
informat CARTKUCQ best32. ;
informat OTHVEHPQ best32. ;
informat OTHVEHCQ best32. ;
informat GASMOPQ best32. ;
informat GASMOCQ best32. ;
informat VEHFINPQ best32. ;
informat VEHFINCQ best32. ;
informat MAINRPPQ best32. ;
informat MAINRPCQ best32. ;
informat VEHINSPQ best32. ;
informat VEHINSCQ best32. ;
informat VRNTLOPQ best32. ;
informat VRNTLOCQ best32. ;
informat PUBTRAPQ best32. ;
informat PUBTRACQ best32. ;
informat TRNTRPPQ best32. ;
informat TRNTRPCQ best32. ;
informat TRNOTHPQ best32. ;
informat TRNOTHCQ best32. ;
informat HEALTHPQ best32. ;
informat HEALTHCQ best32. ;
informat HLTHINPQ best32. ;
informat HLTHINCQ best32. ;
informat MEDSRVPQ best32. ;
informat MEDSRVCQ best32. ;
informat PREDRGPQ best32. ;
informat PREDRGCQ best32. ;
informat MEDSUPPQ best32. ;
informat MEDSUPCQ best32. ;
informat ENTERTPQ best32. ;
informat ENTERTCQ best32. ;
informat FEEADMPQ best32. ;
informat FEEADMCQ best32. ;
informat TVRDIOPQ best32. ;
informat TVRDIOCQ best32. ;
informat OTHEQPPQ best32. ;
informat OTHEQPCQ best32. ;
informat PETTOYPQ best32. ;
informat PETTOYCQ best32. ;
informat OTHENTPQ best32. ;
informat OTHENTCQ best32. ;
informat PERSCAPQ best32. ;
informat PERSCACQ best32. ;
informat READPQ best32. ;
informat READCQ best32. ;
informat EDUCAPQ best32. ;
informat EDUCACQ best32. ;
informat TOBACCPQ best32. ;
informat TOBACCCQ best32. ;
informat MISCPQ best32. ;
informat MISCCQ best32. ;
informat MISC1PQ best32. ;
informat MISC1CQ best32. ;
informat MISC2PQ best32. ;
informat MISC2CQ best32. ;
informat CASHCOPQ best32. ;
informat CASHCOCQ best32. ;
informat PERINSPQ best32. ;
informat PERINSCQ best32. ;
informat LIFINSPQ best32. ;
informat LIFINSCQ best32. ;
informat RETPENPQ best32. ;
informat RETPENCQ best32. ;
informat HH_CU_Q best32. ;
informat HH_CU_Q_ $3. ;
informat HHID best32. ;
informat HHID_ $3. ;
informat POV_CY $3. ;
informat POV_CY_ $3. ;
informat POV_PY $3. ;
informat POV_PY_ $3. ;
informat HEATFUEL $4. ;
informat HEAT_UEL $3. ;
informat SWIMPOOL $5. ;
informat SWIM_OOL $3. ;
informat WATERHT $4. ;
informat WATERHT_ $3. ;
informat APTMENT $1. ;
informat APTMENT_ $3. ;
informat OFSTPARK $4. ;
informat OFST_ARK $3. ;
informat WINDOWAC $5. ;
informat WIND_WAC $3. ;
informat CNTRALAC $4. ;
informat CNTR_LAC $3. ;
informat CHILDAGE $3. ;
informat CHIL_AGE $3. ;
informat INCLASS $4. ;
informat STATE $4. ;
informat CHDOTHX best32. ;
informat CHDOTHX_ $3. ;
informat ALIOTHX best32. ;
informat ALIOTHX_ $3. ;
informat CHDLMPX best32. ;
informat CHDLMPX_ $3. ;
informat ERANKH best32. ;
informat ERANKH_ $3. ;
informat TOTEX4PQ best32. ;
informat TOTEX4CQ best32. ;
informat MISCX4PQ best32. ;
informat MISCX4CQ best32. ;
informat VEHQL best32. ;
informat VEHQL_ $3. ;
informat NUM_TVAN best32. ;
informat NUM__VAN $3. ;
informat TTOTALP best32. ;
informat TTOTALC best32. ;
informat TFOODTOP best32. ;
informat TFOODTOC best32. ;
informat TFOODAWP best32. ;
informat TFOODAWC best32. ;
informat TFOODHOP best32. ;
informat TFOODHOC best32. ;
informat TALCBEVP best32. ;
informat TALCBEVC best32. ;
informat TOTHRLOP best32. ;
informat TOTHRLOC best32. ;
informat TTRANPRP best32. ;
informat TTRANPRC best32. ;
informat TGASMOTP best32. ;
informat TGASMOTC best32. ;
informat TVRENTLP best32. ;
informat TVRENTLC best32. ;
informat TCARTRKP best32. ;
informat TCARTRKC best32. ;
informat TOTHVHRP best32. ;
informat TOTHVHRC best32. ;
informat TOTHTREP best32. ;
informat TOTHTREC best32. ;
informat TTRNTRIP best32. ;
informat TTRNTRIC best32. ;
informat TFAREP best32. ;
informat TFAREC best32. ;
informat TAIRFARP best32. ;
informat TAIRFARC best32. ;
informat TOTHFARP best32. ;
informat TOTHFARC best32. ;
informat TLOCALTP best32. ;
informat TLOCALTC best32. ;
informat TENTRMNP best32. ;
informat TENTRMNC best32. ;
informat TFEESADP best32. ;
informat TFEESADC best32. ;
informat TOTHENTP best32. ;
informat TOTHENTC best32. ;
informat OWNVACP best32. ;
informat OWNVACC best32. ;
informat VOTHRLOP best32. ;
informat VOTHRLOC best32. ;
informat VMISCHEP best32. ;
informat VMISCHEC best32. ;
informat UTILOWNP best32. ;
informat UTILOWNC best32. ;
informat VFUELOIP best32. ;
informat VFUELOIC best32. ;
informat VOTHRFLP best32. ;
informat VOTHRFLC best32. ;
informat VELECTRP best32. ;
informat VELECTRC best32. ;
informat VNATLGAP best32. ;
informat VNATLGAC best32. ;
informat VWATERPP best32. ;
informat VWATERPC best32. ;
informat MRTPRNOP best32. ;
informat MRTPRNOC best32. ;
informat UTILRNTP best32. ;
informat UTILRNTC best32. ;
informat RFUELOIP best32. ;
informat RFUELOIC best32. ;
informat ROTHRFLP best32. ;
informat ROTHRFLC best32. ;
informat RELECTRP best32. ;
informat RELECTRC best32. ;
informat RNATLGAP best32. ;
informat RNATLGAC best32. ;
informat RWATERPP best32. ;
informat RWATERPC best32. ;
informat POVLEVCY best32. ;
informat POVL_VCY $3. ;
informat POVLEVPY best32. ;
informat POVL_VPY $3. ;
informat COOKING $4. ;
informat COOKING_ $3. ;
informat PORCH $4. ;
informat PORCH_ $3. ;
informat ETOTALP best32. ;
informat ETOTALC best32. ;
informat ETOTAPX4 best32. ;
informat ETOTACX4 best32. ;
informat EHOUSNGP best32. ;
informat EHOUSNGC best32. ;
informat ESHELTRP best32. ;
informat ESHELTRC best32. ;
informat EOWNDWLP best32. ;
informat EOWNDWLC best32. ;
informat EOTHLODP best32. ;
informat EOTHLODC best32. ;
informat EMRTPNOP best32. ;
informat EMRTPNOC best32. ;
informat EMRTPNVP best32. ;
informat EMRTPNVC best32. ;
informat ETRANPTP best32. ;
informat ETRANPTC best32. ;
informat EVEHPURP best32. ;
informat EVEHPURC best32. ;
informat ECARTKNP best32. ;
informat ECARTKNC best32. ;
informat ECARTKUP best32. ;
informat ECARTKUC best32. ;
informat EOTHVEHP best32. ;
informat EOTHVEHC best32. ;
informat EENTRMTP best32. ;
informat EENTRMTC best32. ;
informat EOTHENTP best32. ;
informat EOTHENTC best32. ;
informat ENOMOTRP best32. ;
informat ENOMOTRC best32. ;
informat EMOTRVHP best32. ;
informat EMOTRVHC best32. ;
informat EENTMSCP best32. ;
informat EENTMSCC best32. ;
informat EMISCELP best32. ;
informat EMISCELC best32. ;
informat EMISCMTP best32. ;
informat EMISCMTC best32. ;
informat UNISTRQ $4. ;
informat UNISTRQ_ $3. ;
informat INTEARNB $5. ;
informat INTE_RNB $3. ;
informat INTERNBX best32. ;
informat INTE_NBX $3. ;
informat FININCB $1. ;
informat FININCB_ $3. ;
informat FININCBX best32. ;
informat FINI_CBX $3. ;
informat PENSIONB $5. ;
informat PENS_ONB $3. ;
informat PNSIONBX best32. ;
informat PNSI_NBX $3. ;
informat UNEMPLB $1. ;
informat UNEMPLB_ $3. ;
informat UNEMPLBX best32. ;
informat UNEM_LBX $3. ;
informat COMPENSB $1. ;
informat COMP_NSB $3. ;
informat COMPNSBX best32. ;
informat COMP_SBX $3. ;
informat WELFAREB $1. ;
informat WELF_REB $3. ;
informat WELFREBX best32. ;
informat WELF_EBX $3. ;
informat FOODSMPX best32. ;
informat FOOD_MPX $3. ;
informat FOODSMPB $1. ;
informat FOOD_MPB $3. ;
informat FOODSPBX best32. ;
informat FOOD_PBX $3. ;
informat INCLOSAB $1. ;
informat INCL_SAB $3. ;
informat INCLSABX best32. ;
informat INCL_ABX $3. ;
informat INCLOSBB $1. ;
informat INCL_SBB $3. ;
informat INCLSBBX best32. ;
informat INCL_BBX $3. ;
informat CHDLMPB $1. ;
informat CHDLMPB_ $3. ;
informat CHDLMPBX best32. ;
informat CHDL_PBX $3. ;
informat CHDOTHB $1. ;
informat CHDOTHB_ $3. ;
informat CHDOTHBX best32. ;
informat CHDO_HBX $3. ;
informat ALIOTHB $1. ;
informat ALIOTHB_ $3. ;
informat ALIOTHBX best32. ;
informat ALIO_HBX $3. ;
informat LUMPSUMB $1. ;
informat LUMP_UMB $3. ;
informat LMPSUMBX best32. ;
informat LMPS_MBX $3. ;
informat SALEINCB $1. ;
informat SALE_NCB $3. ;
informat SALINCBX best32. ;
informat SALI_CBX $3. ;
informat OTHRINCB $1. ;
informat OTHR_NCB $3. ;
informat OTRINCBX best32. ;
informat OTRI_CBX $3. ;
informat INCLASS2 $3. ;
informat INCL_SS2 $3. ;
informat CUID best32. ;
informat INTERI best32. ;
informat HORREF1 $4. ;
informat HORREF1_ $3. ;
informat HORREF2 $4. ;
informat HORREF2_ $3. ;
informat ALIOTHXM best32. ;
informat ALIO_HXM $3. ;
informat ALIOTHX1 best32. ;
informat ALIOTHX2 best32. ;
informat ALIOTHX3 best32. ;
informat ALIOTHX4 best32. ;
informat ALIOTHX5 best32. ;
informat ALIOTHXI best32. ;
informat CHDOTHXM best32. ;
informat CHDO_HXM $3. ;
informat CHDOTHX1 best32. ;
informat CHDOTHX2 best32. ;
informat CHDOTHX3 best32. ;
informat CHDOTHX4 best32. ;
informat CHDOTHX5 best32. ;
informat CHDOTHXI best32. ;
informat COMPENSM best32. ;
informat COMP_NSM $3. ;
informat COMPENS1 best32. ;
informat COMPENS2 best32. ;
informat COMPENS3 best32. ;
informat COMPENS4 best32. ;
informat COMPENS5 best32. ;
informat COMPENSI best32. ;
informat ERANKHM best32. ;
informat ERANKHM_ $3. ;
informat FAMTFEDM best32. ;
informat FAMT_EDM $3. ;
informat FAMTFED1 best32. ;
informat FAMTFED2 best32. ;
informat FAMTFED3 best32. ;
informat FAMTFED4 best32. ;
informat FAMTFED5 best32. ;
informat FFRMINCM best32. ;
informat FFRM_NCM $3. ;
informat FFRMINC1 best32. ;
informat FFRMINC2 best32. ;
informat FFRMINC3 best32. ;
informat FFRMINC4 best32. ;
informat FFRMINC5 best32. ;
informat FFRMINCI best32. ;
informat FGOVRETM best32. ;
informat FGOV_ETM $3. ;
informat FINCATXM best32. ;
informat FINCA_XM $3. ;
informat FINCATX1 best32. ;
informat FINCATX2 best32. ;
informat FINCATX3 best32. ;
informat FINCATX4 best32. ;
informat FINCATX5 best32. ;
informat FINCBTXM best32. ;
informat FINCB_XM $3. ;
informat FINCBTX1 best32. ;
informat FINCBTX2 best32. ;
informat FINCBTX3 best32. ;
informat FINCBTX4 best32. ;
informat FINCBTX5 best32. ;
informat FINCBTXI best32. ;
informat FININCXM best32. ;
informat FINI_CXM $3. ;
informat FININCX1 best32. ;
informat FININCX2 best32. ;
informat FININCX3 best32. ;
informat FININCX4 best32. ;
informat FININCX5 best32. ;
informat FININCXI best32. ;
informat FJSSDEDM best32. ;
informat FJSS_EDM $3. ;
informat FJSSDED1 best32. ;
informat FJSSDED2 best32. ;
informat FJSSDED3 best32. ;
informat FJSSDED4 best32. ;
informat FJSSDED5 best32. ;
informat FNONFRMM best32. ;
informat FNON_RMM $3. ;
informat FNONFRM1 best32. ;
informat FNONFRM2 best32. ;
informat FNONFRM3 best32. ;
informat FNONFRM4 best32. ;
informat FNONFRM5 best32. ;
informat FNONFRMI best32. ;
informat FOODSMPM best32. ;
informat FOOD_MPM $3. ;
informat FOODSMP1 best32. ;
informat FOODSMP2 best32. ;
informat FOODSMP3 best32. ;
informat FOODSMP4 best32. ;
informat FOODSMP5 best32. ;
informat FOODSMPI best32. ;
informat FPRIPENM best32. ;
informat FPRI_ENM $3. ;
informat FRRDEDM best32. ;
informat FRRDEDM_ $3. ;
informat FRRETIRM best32. ;
informat FRRE_IRM $3. ;
informat FRRETIR1 best32. ;
informat FRRETIR2 best32. ;
informat FRRETIR3 best32. ;
informat FRRETIR4 best32. ;
informat FRRETIR5 best32. ;
informat FRRETIRI best32. ;
informat FSALARYM best32. ;
informat FSAL_RYM $3. ;
informat FSALARY1 best32. ;
informat FSALARY2 best32. ;
informat FSALARY3 best32. ;
informat FSALARY4 best32. ;
informat FSALARY5 best32. ;
informat FSALARYI best32. ;
informat FSLTAXXM best32. ;
informat FSLT_XXM $3. ;
informat FSLTAXX1 best32. ;
informat FSLTAXX2 best32. ;
informat FSLTAXX3 best32. ;
informat FSLTAXX4 best32. ;
informat FSLTAXX5 best32. ;
informat FSSIXM best32. ;
informat FSSIXM_ $3. ;
informat FSSIX1 best32. ;
informat FSSIX2 best32. ;
informat FSSIX3 best32. ;
informat FSSIX4 best32. ;
informat FSSIX5 best32. ;
informat FSSIXI best32. ;
informat INC_RNKM best32. ;
informat INC__NKM $3. ;
informat INC_RNK1 best32. ;
informat INC_RNK2 best32. ;
informat INC_RNK3 best32. ;
informat INC_RNK4 best32. ;
informat INC_RNK5 best32. ;
informat INCLOSAM best32. ;
informat INCL_SAM $3. ;
informat INCLOSA1 best32. ;
informat INCLOSA2 best32. ;
informat INCLOSA3 best32. ;
informat INCLOSA4 best32. ;
informat INCLOSA5 best32. ;
informat INCLOSAI best32. ;
informat INCLOSBM best32. ;
informat INCL_SBM $3. ;
informat INCLOSB1 best32. ;
informat INCLOSB2 best32. ;
informat INCLOSB3 best32. ;
informat INCLOSB4 best32. ;
informat INCLOSB5 best32. ;
informat INCLOSBI best32. ;
informat INTEARNM best32. ;
informat INTE_RNM $3. ;
informat INTEARN1 best32. ;
informat INTEARN2 best32. ;
informat INTEARN3 best32. ;
informat INTEARN4 best32. ;
informat INTEARN5 best32. ;
informat INTEARNI best32. ;
informat OTHRINCM best32. ;
informat OTHR_NCM $3. ;
informat OTHRINC1 best32. ;
informat OTHRINC2 best32. ;
informat OTHRINC3 best32. ;
informat OTHRINC4 best32. ;
informat OTHRINC5 best32. ;
informat OTHRINCI best32. ;
informat PENSIONM best32. ;
informat PENS_ONM $3. ;
informat PENSION1 best32. ;
informat PENSION2 best32. ;
informat PENSION3 best32. ;
informat PENSION4 best32. ;
informat PENSION5 best32. ;
informat PENSIONI best32. ;
informat POV_CYM $3. ;
informat POV_CYM_ $3. ;
informat POV_CY1 $3. ;
informat POV_CY2 $3. ;
informat POV_CY3 $3. ;
informat POV_CY4 $3. ;
informat POV_CY5 $3. ;
informat POV_PYM $3. ;
informat POV_PYM_ $3. ;
informat POV_PY1 $3. ;
informat POV_PY2 $3. ;
informat POV_PY3 $3. ;
informat POV_PY4 $3. ;
informat POV_PY5 $3. ;
informat PRINERNM $4. ;
informat PRIN_RNM $3. ;
informat PRINERN1 $4. ;
informat PRINERN2 $4. ;
informat PRINERN3 $4. ;
informat PRINERN4 $4. ;
informat PRINERN5 $4. ;
informat TOTTXPDM best32. ;
informat TOTT_PDM $3. ;
informat TOTTXPD1 best32. ;
informat TOTTXPD2 best32. ;
informat TOTTXPD3 best32. ;
informat TOTTXPD4 best32. ;
informat TOTTXPD5 best32. ;
informat UNEMPLXM best32. ;
informat UNEM_LXM $3. ;
informat UNEMPLX1 best32. ;
informat UNEMPLX2 best32. ;
informat UNEMPLX3 best32. ;
informat UNEMPLX4 best32. ;
informat UNEMPLX5 best32. ;
informat UNEMPLXI best32. ;
informat WELFAREM best32. ;
informat WELF_REM $3. ;
informat WELFARE1 best32. ;
informat WELFARE2 best32. ;
informat WELFARE3 best32. ;
informat WELFARE4 best32. ;
informat WELFARE5 best32. ;
informat WELFAREI best32. ;
informat COLPLAN $4. ;
informat COLPLAN_ $3. ;
informat COLPLANX best32. ;
informat COLP_ANX $3. ;
informat PSU $8. ;
informat REVSMORT $4. ;
informat REVS_ORT $3. ;
informat RVSLUMP $1. ;
informat RVSLUMP_ $3. ;
informat RVSREGMO $1. ;
informat RVSR_GMO $3. ;
informat RVSLOC $1. ;
informat RVSLOC_ $3. ;
informat RVSOTHPY $1. ;
informat RVSO_HPY $3. ;
informat TYPEPYX best32. ;
informat TYPEPYX_ $3. ;
informat HISP_REF $3. ;
informat HISP2 $4. ;
informat BUILT $8. ;
informat BUILT_ $3. ;
input
NEWID
DIRACC $
DIRACC_ $
AGE_REF
AGE_REF_ $
AGE2
AGE2_ $
AS_COMP1
AS_C_MP1 $
AS_COMP2
AS_C_MP2 $
AS_COMP3
AS_C_MP3 $
AS_COMP4
AS_C_MP4 $
AS_COMP5
AS_C_MP5 $
BATHRMQ
BATHRMQ_ $
BEDROOMQ
BEDR_OMQ $
BLS_URBN $
BSINVSTX
BSIN_STX $
BUILDING $
BUIL_ING $
CKBKACTX
CKBK_CTX $
COMPBND $
COMPBND_ $
COMPBNDX
COMP_NDX $
COMPCKG $
COMPCKG_ $
COMPCKGX
COMP_KGX $
COMPENSX
COMP_NSX $
COMPOWD $
COMPOWD_ $
COMPOWDX
COMP_WDX $
COMPSAV $
COMPSAV_ $
COMPSAVX
COMP_AVX $
COMPSEC $
COMPSEC_ $
COMPSECX
COMP_ECX $
CUTENURE $
CUTE_URE $
EARNCOMP $
EARN_OMP $
EDUC_REF $
EDUC0REF $
EDUCA2 $
EDUCA2_ $
FAM_SIZE
FAM__IZE $
FAM_TYPE $
FAM__YPE $
FAMTFEDX
FAMT_EDX $
FEDRFNDX
FEDR_NDX $
FEDTAXX
FEDTAXX_ $
FFRMINCX
FFRM_NCX $
FGOVRETX
FGOV_ETX $
FINCATAX
FINCAT_X $
FINCBTAX
FINCBT_X $
FINDRETX
FIND_ETX $
FININCX
FININCX_ $
FINLWT21
FJSSDEDX
FJSS_EDX $
FNONFRMX
FNON_RMX $
FPRIPENX
FPRI_ENX $
FRRDEDX
FRRDEDX_ $
FRRETIRX
FRRE_IRX $
FSALARYX
FSAL_RYX $
FSLTAXX
FSLTAXX_ $
FSSIX
FSSIX_ $
GOVTCOST $
GOVT_OST $
HLFBATHQ
HLFB_THQ $
INC_HRS1
INC__RS1 $
INC_HRS2
INC__RS2 $
INC_RANK
INC__ANK $
INCLOSSA
INCL_SSA $
INCLOSSB
INCL_SSB $
INCNONW1 $
INCN_NW1 $
INCNONW2 $
INCN_NW2 $
INCOMEY1 $
INCO_EY1 $
INCOMEY2 $
INCO_EY2 $
INCWEEK1
INCW_EK1 $
INCWEEK2
INCW_EK2 $
INSRFNDX
INSR_NDX $
INTEARNX
INTE_RNX $
MISCTAXX
MISC_AXX $
LUMPSUMX
LUMP_UMX $
MARITAL1 $
MARI_AL1 $
MONYOWDX
MONY_WDX $
NO_EARNR
NO_E_RNR $
NONINCMX
NONI_CMX $
NUM_AUTO
NUM__UTO $
OCCUCOD1 $
OCCU_OD1 $
OCCUCOD2 $
OCCU_OD2 $
OTHRFNDX
OTHR_NDX $
OTHRINCX
OTHR_NCX $
PENSIONX
PENS_ONX $
PERSLT18
PERS_T18 $
PERSOT64
PERS_T64 $
POPSIZE $
PRINEARN $
PRIN_ARN $
PTAXRFDX
PTAX_FDX $
PUBLHOUS $
PUBL_OUS $
PURSSECX
PURS_ECX $
QINTRVMO $
QINTRVYR
RACE2 $
RACE2_ $
REF_RACE $
REF__ACE $
REGION $
RENTEQVX
RENT_QVX $
RESPSTAT $
RESP_TAT $
ROOMSQ
ROOMSQ_ $
SALEINCX
SALE_NCX $
SAVACCTX
SAVA_CTX $
SECESTX
SECESTX_ $
SELLSECX
SELL_ECX $
SETLINSX
SETL_NSX $
SEX_REF $
SEX_REF_ $
SEX2 $
SEX2_ $
SLOCTAXX
SLOC_AXX $
SLRFUNDX
SLRF_NDX $
SMSASTAT $
SSOVERPX
SSOV_RPX $
ST_HOUS $
ST_HOUS_ $
TAXPROPX
TAXP_OPX $
TOTTXPDX
TOTT_PDX $
UNEMPLX
UNEMPLX_ $
USBNDX
USBNDX_ $
VEHQ
VEHQ_ $
WDBSASTX
WDBS_STX $
WDBSGDSX
WDBS_DSX $
WELFAREX
WELF_REX $
WTREP01
WTREP02
WTREP03
WTREP04
WTREP05
WTREP06
WTREP07
WTREP08
WTREP09
WTREP10
WTREP11
WTREP12
WTREP13
WTREP14
WTREP15
WTREP16
WTREP17
WTREP18
WTREP19
WTREP20
WTREP21
WTREP22
WTREP23
WTREP24
WTREP25
WTREP26
WTREP27
WTREP28
WTREP29
WTREP30
WTREP31
WTREP32
WTREP33
WTREP34
WTREP35
WTREP36
WTREP37
WTREP38
WTREP39
WTREP40
WTREP41
WTREP42
WTREP43
WTREP44
TOTEXPPQ
TOTEXPCQ
FOODPQ
FOODCQ
FDHOMEPQ
FDHOMECQ
FDAWAYPQ
FDAWAYCQ
FDXMAPPQ
FDXMAPCQ
FDMAPPQ
FDMAPCQ
ALCBEVPQ
ALCBEVCQ
HOUSPQ
HOUSCQ
SHELTPQ
SHELTCQ
OWNDWEPQ
OWNDWECQ
MRTINTPQ
MRTINTCQ
PROPTXPQ
PROPTXCQ
MRPINSPQ
MRPINSCQ
RENDWEPQ
RENDWECQ
RNTXRPPQ
RNTXRPCQ
RNTAPYPQ
RNTAPYCQ
OTHLODPQ
OTHLODCQ
UTILPQ
UTILCQ
NTLGASPQ
NTLGASCQ
ELCTRCPQ
ELCTRCCQ
ALLFULPQ
ALLFULCQ
FULOILPQ
FULOILCQ
OTHFLSPQ
OTHFLSCQ
TELEPHPQ
TELEPHCQ
WATRPSPQ
WATRPSCQ
HOUSOPPQ
HOUSOPCQ
DOMSRVPQ
DOMSRVCQ
DMSXCCPQ
DMSXCCCQ
BBYDAYPQ
BBYDAYCQ
OTHHEXPQ
OTHHEXCQ
HOUSEQPQ
HOUSEQCQ
TEXTILPQ
TEXTILCQ
FURNTRPQ
FURNTRCQ
FLRCVRPQ
FLRCVRCQ
MAJAPPPQ
MAJAPPCQ
SMLAPPPQ
SMLAPPCQ
MISCEQPQ
MISCEQCQ
APPARPQ
APPARCQ
MENBOYPQ
MENBOYCQ
MENSIXPQ
MENSIXCQ
BOYFIFPQ
BOYFIFCQ
WOMGRLPQ
WOMGRLCQ
WOMSIXPQ
WOMSIXCQ
GRLFIFPQ
GRLFIFCQ
CHLDRNPQ
CHLDRNCQ
FOOTWRPQ
FOOTWRCQ
OTHAPLPQ
OTHAPLCQ
TRANSPQ
TRANSCQ
CARTKNPQ
CARTKNCQ
CARTKUPQ
CARTKUCQ
OTHVEHPQ
OTHVEHCQ
GASMOPQ
GASMOCQ
VEHFINPQ
VEHFINCQ
MAINRPPQ
MAINRPCQ
VEHINSPQ
VEHINSCQ
VRNTLOPQ
VRNTLOCQ
PUBTRAPQ
PUBTRACQ
TRNTRPPQ
TRNTRPCQ
TRNOTHPQ
TRNOTHCQ
HEALTHPQ
HEALTHCQ
HLTHINPQ
HLTHINCQ
MEDSRVPQ
MEDSRVCQ
PREDRGPQ
PREDRGCQ
MEDSUPPQ
MEDSUPCQ
ENTERTPQ
ENTERTCQ
FEEADMPQ
FEEADMCQ
TVRDIOPQ
TVRDIOCQ
OTHEQPPQ
OTHEQPCQ
PETTOYPQ
PETTOYCQ
OTHENTPQ
OTHENTCQ
PERSCAPQ
PERSCACQ
READPQ
READCQ
EDUCAPQ
EDUCACQ
TOBACCPQ
TOBACCCQ
MISCPQ
MISCCQ
MISC1PQ
MISC1CQ
MISC2PQ
MISC2CQ
CASHCOPQ
CASHCOCQ
PERINSPQ
PERINSCQ
LIFINSPQ
LIFINSCQ
RETPENPQ
RETPENCQ
HH_CU_Q
HH_CU_Q_ $
HHID
HHID_ $
POV_CY $
POV_CY_ $
POV_PY $
POV_PY_ $
HEATFUEL $
HEAT_UEL $
SWIMPOOL $
SWIM_OOL $
WATERHT $
WATERHT_ $
APTMENT $
APTMENT_ $
OFSTPARK $
OFST_ARK $
WINDOWAC $
WIND_WAC $
CNTRALAC $
CNTR_LAC $
CHILDAGE $
CHIL_AGE $
INCLASS $
STATE $
CHDOTHX
CHDOTHX_ $
ALIOTHX
ALIOTHX_ $
CHDLMPX
CHDLMPX_ $
ERANKH
ERANKH_ $
TOTEX4PQ
TOTEX4CQ
MISCX4PQ
MISCX4CQ
VEHQL
VEHQL_ $
NUM_TVAN
NUM__VAN $
TTOTALP
TTOTALC
TFOODTOP
TFOODTOC
TFOODAWP
TFOODAWC
TFOODHOP
TFOODHOC
TALCBEVP
TALCBEVC
TOTHRLOP
TOTHRLOC
TTRANPRP
TTRANPRC
TGASMOTP
TGASMOTC
TVRENTLP
TVRENTLC
TCARTRKP
TCARTRKC
TOTHVHRP
TOTHVHRC
TOTHTREP
TOTHTREC
TTRNTRIP
TTRNTRIC
TFAREP
TFAREC
TAIRFARP
TAIRFARC
TOTHFARP
TOTHFARC
TLOCALTP
TLOCALTC
TENTRMNP
TENTRMNC
TFEESADP
TFEESADC
TOTHENTP
TOTHENTC
OWNVACP
OWNVACC
VOTHRLOP
VOTHRLOC
VMISCHEP
VMISCHEC
UTILOWNP
UTILOWNC
VFUELOIP
VFUELOIC
VOTHRFLP
VOTHRFLC
VELECTRP
VELECTRC
VNATLGAP
VNATLGAC
VWATERPP
VWATERPC
MRTPRNOP
MRTPRNOC
UTILRNTP
UTILRNTC
RFUELOIP
RFUELOIC
ROTHRFLP
ROTHRFLC
RELECTRP
RELECTRC
RNATLGAP
RNATLGAC
RWATERPP
RWATERPC
POVLEVCY
POVL_VCY $
POVLEVPY
POVL_VPY $
COOKING $
COOKING_ $
PORCH $
PORCH_ $
ETOTALP
ETOTALC
ETOTAPX4
ETOTACX4
EHOUSNGP
EHOUSNGC
ESHELTRP
ESHELTRC
EOWNDWLP
EOWNDWLC
EOTHLODP
EOTHLODC
EMRTPNOP
EMRTPNOC
EMRTPNVP
EMRTPNVC
ETRANPTP
ETRANPTC
EVEHPURP
EVEHPURC
ECARTKNP
ECARTKNC
ECARTKUP
ECARTKUC
EOTHVEHP
EOTHVEHC
EENTRMTP
EENTRMTC
EOTHENTP
EOTHENTC
ENOMOTRP
ENOMOTRC
EMOTRVHP
EMOTRVHC
EENTMSCP
EENTMSCC
EMISCELP
EMISCELC
EMISCMTP
EMISCMTC
UNISTRQ $
UNISTRQ_ $
INTEARNB $
INTE_RNB $
INTERNBX
INTE_NBX $
FININCB $
FININCB_ $
FININCBX
FINI_CBX $
PENSIONB $
PENS_ONB $
PNSIONBX
PNSI_NBX $
UNEMPLB $
UNEMPLB_ $
UNEMPLBX
UNEM_LBX $
COMPENSB $
COMP_NSB $
COMPNSBX
COMP_SBX $
WELFAREB $
WELF_REB $
WELFREBX
WELF_EBX $
FOODSMPX
FOOD_MPX $
FOODSMPB $
FOOD_MPB $
FOODSPBX
FOOD_PBX $
INCLOSAB $
INCL_SAB $
INCLSABX
INCL_ABX $
INCLOSBB $
INCL_SBB $
INCLSBBX
INCL_BBX $
CHDLMPB $
CHDLMPB_ $
CHDLMPBX
CHDL_PBX $
CHDOTHB $
CHDOTHB_ $
CHDOTHBX
CHDO_HBX $
ALIOTHB $
ALIOTHB_ $
ALIOTHBX
ALIO_HBX $
LUMPSUMB $
LUMP_UMB $
LMPSUMBX
LMPS_MBX $
SALEINCB $
SALE_NCB $
SALINCBX
SALI_CBX $
OTHRINCB $
OTHR_NCB $
OTRINCBX
OTRI_CBX $
INCLASS2 $
INCL_SS2 $
CUID
INTERI
HORREF1 $
HORREF1_ $
HORREF2 $
HORREF2_ $
ALIOTHXM
ALIO_HXM $
ALIOTHX1
ALIOTHX2
ALIOTHX3
ALIOTHX4
ALIOTHX5
ALIOTHXI
CHDOTHXM
CHDO_HXM $
CHDOTHX1
CHDOTHX2
CHDOTHX3
CHDOTHX4
CHDOTHX5
CHDOTHXI
COMPENSM
COMP_NSM $
COMPENS1
COMPENS2
COMPENS3
COMPENS4
COMPENS5
COMPENSI
ERANKHM
ERANKHM_ $
FAMTFEDM
FAMT_EDM $
FAMTFED1
FAMTFED2
FAMTFED3
FAMTFED4
FAMTFED5
FFRMINCM
FFRM_NCM $
FFRMINC1
FFRMINC2
FFRMINC3
FFRMINC4
FFRMINC5
FFRMINCI
FGOVRETM
FGOV_ETM $
FINCATXM
FINCA_XM $
FINCATX1
FINCATX2
FINCATX3
FINCATX4
FINCATX5
FINCBTXM
FINCB_XM $
FINCBTX1
FINCBTX2
FINCBTX3
FINCBTX4
FINCBTX5
FINCBTXI
FININCXM
FINI_CXM $
FININCX1
FININCX2
FININCX3
FININCX4
FININCX5
FININCXI
FJSSDEDM
FJSS_EDM $
FJSSDED1
FJSSDED2
FJSSDED3
FJSSDED4
FJSSDED5
FNONFRMM
FNON_RMM $
FNONFRM1
FNONFRM2
FNONFRM3
FNONFRM4
FNONFRM5
FNONFRMI
FOODSMPM
FOOD_MPM $
FOODSMP1
FOODSMP2
FOODSMP3
FOODSMP4
FOODSMP5
FOODSMPI
FPRIPENM
FPRI_ENM $
FRRDEDM
FRRDEDM_ $
FRRETIRM
FRRE_IRM $
FRRETIR1
FRRETIR2
FRRETIR3
FRRETIR4
FRRETIR5
FRRETIRI
FSALARYM
FSAL_RYM $
FSALARY1
FSALARY2
FSALARY3
FSALARY4
FSALARY5
FSALARYI
FSLTAXXM
FSLT_XXM $
FSLTAXX1
FSLTAXX2
FSLTAXX3
FSLTAXX4
FSLTAXX5
FSSIXM
FSSIXM_ $
FSSIX1
FSSIX2
FSSIX3
FSSIX4
FSSIX5
FSSIXI
INC_RNKM
INC__NKM $
INC_RNK1
INC_RNK2
INC_RNK3
INC_RNK4
INC_RNK5
INCLOSAM
INCL_SAM $
INCLOSA1
INCLOSA2
INCLOSA3
INCLOSA4
INCLOSA5
INCLOSAI
INCLOSBM
INCL_SBM $
INCLOSB1
INCLOSB2
INCLOSB3
INCLOSB4
INCLOSB5
INCLOSBI
INTEARNM
INTE_RNM $
INTEARN1
INTEARN2
INTEARN3
INTEARN4
INTEARN5
INTEARNI
OTHRINCM
OTHR_NCM $
OTHRINC1
OTHRINC2
OTHRINC3
OTHRINC4
OTHRINC5
OTHRINCI
PENSIONM
PENS_ONM $
PENSION1
PENSION2
PENSION3
PENSION4
PENSION5
PENSIONI
POV_CYM $
POV_CYM_ $
POV_CY1 $
POV_CY2 $
POV_CY3 $
POV_CY4 $
POV_CY5 $
POV_PYM $
POV_PYM_ $
POV_PY1 $
POV_PY2 $
POV_PY3 $
POV_PY4 $
POV_PY5 $
PRINERNM $
PRIN_RNM $
PRINERN1 $
PRINERN2 $
PRINERN3 $
PRINERN4 $
PRINERN5 $
TOTTXPDM
TOTT_PDM $
TOTTXPD1
TOTTXPD2
TOTTXPD3
TOTTXPD4
TOTTXPD5
UNEMPLXM
UNEM_LXM $
UNEMPLX1
UNEMPLX2
UNEMPLX3
UNEMPLX4
UNEMPLX5
UNEMPLXI
WELFAREM
WELF_REM $
WELFARE1
WELFARE2
WELFARE3
WELFARE4
WELFARE5
WELFAREI
COLPLAN $
COLPLAN_ $
COLPLANX
COLP_ANX $
PSU $
REVSMORT $
REVS_ORT $
RVSLUMP $
RVSLUMP_ $
RVSREGMO $
RVSR_GMO $
RVSLOC $
RVSLOC_ $
RVSOTHPY $
RVSO_HPY $
TYPEPYX
TYPEPYX_ $
HISP_REF $
HISP2 $
BUILT $
BUILT_ $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/**********************************************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\FMLI&YR2.1.CSV"
            OUT=FMLYI&YR2.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
***********************************************************************************************/

data WORK.FMLYI121                                ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile 'C:\2011_CEX\Intrvw11\FMLI121.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat NEWID best32. ;
informat DIRACC $3. ;
informat DIRACC_ $3. ;
informat AGE_REF best32. ;
informat AGE_REF_ $3. ;
informat AGE2 best32. ;
informat AGE2_ $3. ;
informat AS_COMP1 best32. ;
informat AS_C_MP1 $3. ;
informat AS_COMP2 best32. ;
informat AS_C_MP2 $3. ;
informat AS_COMP3 best32. ;
informat AS_C_MP3 $3. ;
informat AS_COMP4 best32. ;
informat AS_C_MP4 $3. ;
informat AS_COMP5 best32. ;
informat AS_C_MP5 $3. ;
informat BATHRMQ best32. ;
informat BATHRMQ_ $3. ;
informat BEDROOMQ best32. ;
informat BEDR_OMQ $3. ;
informat BLS_URBN $3. ;
informat BSINVSTX best32. ;
informat BSIN_STX $3. ;
informat BUILDING $4. ;
informat BUIL_ING $3. ;
informat CKBKACTX best32. ;
informat CKBK_CTX $3. ;
informat COMPBND $4. ;
informat COMPBND_ $3. ;
informat COMPBNDX best32. ;
informat COMP_NDX $3. ;
informat COMPCKG $4. ;
informat COMPCKG_ $3. ;
informat COMPCKGX best32. ;
informat COMP_KGX $3. ;
informat COMPENSX best32. ;
informat COMP_NSX $3. ;
informat COMPOWD $1. ;
informat COMPOWD_ $3. ;
informat COMPOWDX best32. ;
informat COMP_WDX $3. ;
informat COMPSAV $4. ;
informat COMPSAV_ $3. ;
informat COMPSAVX best32. ;
informat COMP_AVX $3. ;
informat COMPSEC $4. ;
informat COMPSEC_ $3. ;
informat COMPSECX best32. ;
informat COMP_ECX $3. ;
informat CUTENURE $3. ;
informat CUTE_URE $3. ;
informat EARNCOMP $3. ;
informat EARN_OMP $3. ;
informat EDUC_REF $4. ;
informat EDUC0REF $3. ;
informat EDUCA2 $5. ;
informat EDUCA2_ $3. ;
informat FAM_SIZE best32. ;
informat FAM__IZE $3. ;
informat FAM_TYPE $3. ;
informat FAM__YPE $3. ;
informat FAMTFEDX best32. ;
informat FAMT_EDX $3. ;
informat FEDRFNDX best32. ;
informat FEDR_NDX $3. ;
informat FEDTAXX best32. ;
informat FEDTAXX_ $3. ;
informat FFRMINCX best32. ;
informat FFRM_NCX $3. ;
informat FGOVRETX best32. ;
informat FGOV_ETX $3. ;
informat FINCATAX best32. ;
informat FINCAT_X $3. ;
informat FINCBTAX best32. ;
informat FINCBT_X $3. ;
informat FINDRETX best32. ;
informat FIND_ETX $3. ;
informat FININCX best32. ;
informat FININCX_ $3. ;
informat FINLWT21 best32. ;
informat FJSSDEDX best32. ;
informat FJSS_EDX $3. ;
informat FNONFRMX best32. ;
informat FNON_RMX $3. ;
informat FPRIPENX best32. ;
informat FPRI_ENX $3. ;
informat FRRDEDX best32. ;
informat FRRDEDX_ $3. ;
informat FRRETIRX best32. ;
informat FRRE_IRX $3. ;
informat FSALARYX best32. ;
informat FSAL_RYX $3. ;
informat FSLTAXX best32. ;
informat FSLTAXX_ $3. ;
informat FSSIX best32. ;
informat FSSIX_ $3. ;
informat GOVTCOST $3. ;
informat GOVT_OST $3. ;
informat HLFBATHQ best32. ;
informat HLFB_THQ $3. ;
informat INC_HRS1 best32. ;
informat INC__RS1 $3. ;
informat INC_HRS2 best32. ;
informat INC__RS2 $3. ;
informat INC_RANK best32. ;
informat INC__ANK $3. ;
informat INCLOSSA best32. ;
informat INCL_SSA $3. ;
informat INCLOSSB best32. ;
informat INCL_SSB $3. ;
informat INCNONW1 $3. ;
informat INCN_NW1 $3. ;
informat INCNONW2 $4. ;
informat INCN_NW2 $3. ;
informat INCOMEY1 $4. ;
informat INCO_EY1 $3. ;
informat INCOMEY2 $4. ;
informat INCO_EY2 $3. ;
informat INCWEEK1 best32. ;
informat INCW_EK1 $3. ;
informat INCWEEK2 best32. ;
informat INCW_EK2 $3. ;
informat INSRFNDX best32. ;
informat INSR_NDX $3. ;
informat INTEARNX best32. ;
informat INTE_RNX $3. ;
informat MISCTAXX best32. ;
informat MISC_AXX $3. ;
informat LUMPSUMX best32. ;
informat LUMP_UMX $3. ;
informat MARITAL1 $3. ;
informat MARI_AL1 $3. ;
informat MONYOWDX best32. ;
informat MONY_WDX $3. ;
informat NO_EARNR best32. ;
informat NO_E_RNR $3. ;
informat NONINCMX best32. ;
informat NONI_CMX $3. ;
informat NUM_AUTO best32. ;
informat NUM__UTO $3. ;
informat OCCUCOD1 $5. ;
informat OCCU_OD1 $3. ;
informat OCCUCOD2 $5. ;
informat OCCU_OD2 $3. ;
informat OTHRFNDX best32. ;
informat OTHR_NDX $3. ;
informat OTHRINCX best32. ;
informat OTHR_NCX $3. ;
informat PENSIONX best32. ;
informat PENS_ONX $3. ;
informat PERSLT18 best32. ;
informat PERS_T18 $3. ;
informat PERSOT64 best32. ;
informat PERS_T64 $3. ;
informat POPSIZE $3. ;
informat PRINEARN $4. ;
informat PRIN_ARN $3. ;
informat PTAXRFDX best32. ;
informat PTAX_FDX $3. ;
informat PUBLHOUS $3. ;
informat PUBL_OUS $3. ;
informat PURSSECX best32. ;
informat PURS_ECX $3. ;
informat QINTRVMO $2. ;
informat QINTRVYR 4. ;
informat RACE2 $4. ;
informat RACE2_ $3. ;
informat REF_RACE $3. ;
informat REF__ACE $3. ;
informat REGION $3. ;
informat RENTEQVX best32. ;
informat RENT_QVX $3. ;
informat RESPSTAT $3. ;
informat RESP_TAT $3. ;
informat ROOMSQ best32. ;
informat ROOMSQ_ $3. ;
informat SALEINCX best32. ;
informat SALE_NCX $3. ;
informat SAVACCTX best32. ;
informat SAVA_CTX $3. ;
informat SECESTX best32. ;
informat SECESTX_ $3. ;
informat SELLSECX best32. ;
informat SELL_ECX $3. ;
informat SETLINSX best32. ;
informat SETL_NSX $3. ;
informat SEX_REF $3. ;
informat SEX_REF_ $3. ;
informat SEX2 $4. ;
informat SEX2_ $3. ;
informat SLOCTAXX best32. ;
informat SLOC_AXX $3. ;
informat SLRFUNDX best32. ;
informat SLRF_NDX $3. ;
informat SMSASTAT $3. ;
informat SSOVERPX best32. ;
informat SSOV_RPX $3. ;
informat ST_HOUS $3. ;
informat ST_HOUS_ $3. ;
informat TAXPROPX best32. ;
informat TAXP_OPX $3. ;
informat TOTTXPDX best32. ;
informat TOTT_PDX $3. ;
informat UNEMPLX best32. ;
informat UNEMPLX_ $3. ;
informat USBNDX best32. ;
informat USBNDX_ $3. ;
informat VEHQ best32. ;
informat VEHQ_ $3. ;
informat WDBSASTX best32. ;
informat WDBS_STX $3. ;
informat WDBSGDSX best32. ;
informat WDBS_DSX $3. ;
informat WELFAREX best32. ;
informat WELF_REX $3. ;
informat WTREP01 best32. ;
informat WTREP02 best32. ;
informat WTREP03 best32. ;
informat WTREP04 best32. ;
informat WTREP05 best32. ;
informat WTREP06 best32. ;
informat WTREP07 best32. ;
informat WTREP08 best32. ;
informat WTREP09 best32. ;
informat WTREP10 best32. ;
informat WTREP11 best32. ;
informat WTREP12 best32. ;
informat WTREP13 best32. ;
informat WTREP14 best32. ;
informat WTREP15 best32. ;
informat WTREP16 best32. ;
informat WTREP17 best32. ;
informat WTREP18 best32. ;
informat WTREP19 best32. ;
informat WTREP20 best32. ;
informat WTREP21 best32. ;
informat WTREP22 best32. ;
informat WTREP23 best32. ;
informat WTREP24 best32. ;
informat WTREP25 best32. ;
informat WTREP26 best32. ;
informat WTREP27 best32. ;
informat WTREP28 best32. ;
informat WTREP29 best32. ;
informat WTREP30 best32. ;
informat WTREP31 best32. ;
informat WTREP32 best32. ;
informat WTREP33 best32. ;
informat WTREP34 best32. ;
informat WTREP35 best32. ;
informat WTREP36 best32. ;
informat WTREP37 best32. ;
informat WTREP38 best32. ;
informat WTREP39 best32. ;
informat WTREP40 best32. ;
informat WTREP41 best32. ;
informat WTREP42 best32. ;
informat WTREP43 best32. ;
informat WTREP44 best32. ;
informat TOTEXPPQ best32. ;
informat TOTEXPCQ best32. ;
informat FOODPQ best32. ;
informat FOODCQ best32. ;
informat FDHOMEPQ best32. ;
informat FDHOMECQ best32. ;
informat FDAWAYPQ best32. ;
informat FDAWAYCQ best32. ;
informat FDXMAPPQ best32. ;
informat FDXMAPCQ best32. ;
informat FDMAPPQ best32. ;
informat FDMAPCQ best32. ;
informat ALCBEVPQ best32. ;
informat ALCBEVCQ best32. ;
informat HOUSPQ best32. ;
informat HOUSCQ best32. ;
informat SHELTPQ best32. ;
informat SHELTCQ best32. ;
informat OWNDWEPQ best32. ;
informat OWNDWECQ best32. ;
informat MRTINTPQ best32. ;
informat MRTINTCQ best32. ;
informat PROPTXPQ best32. ;
informat PROPTXCQ best32. ;
informat MRPINSPQ best32. ;
informat MRPINSCQ best32. ;
informat RENDWEPQ best32. ;
informat RENDWECQ best32. ;
informat RNTXRPPQ best32. ;
informat RNTXRPCQ best32. ;
informat RNTAPYPQ best32. ;
informat RNTAPYCQ best32. ;
informat OTHLODPQ best32. ;
informat OTHLODCQ best32. ;
informat UTILPQ best32. ;
informat UTILCQ best32. ;
informat NTLGASPQ best32. ;
informat NTLGASCQ best32. ;
informat ELCTRCPQ best32. ;
informat ELCTRCCQ best32. ;
informat ALLFULPQ best32. ;
informat ALLFULCQ best32. ;
informat FULOILPQ best32. ;
informat FULOILCQ best32. ;
informat OTHFLSPQ best32. ;
informat OTHFLSCQ best32. ;
informat TELEPHPQ best32. ;
informat TELEPHCQ best32. ;
informat WATRPSPQ best32. ;
informat WATRPSCQ best32. ;
informat HOUSOPPQ best32. ;
informat HOUSOPCQ best32. ;
informat DOMSRVPQ best32. ;
informat DOMSRVCQ best32. ;
informat DMSXCCPQ best32. ;
informat DMSXCCCQ best32. ;
informat BBYDAYPQ best32. ;
informat BBYDAYCQ best32. ;
informat OTHHEXPQ best32. ;
informat OTHHEXCQ best32. ;
informat HOUSEQPQ best32. ;
informat HOUSEQCQ best32. ;
informat TEXTILPQ best32. ;
informat TEXTILCQ best32. ;
informat FURNTRPQ best32. ;
informat FURNTRCQ best32. ;
informat FLRCVRPQ best32. ;
informat FLRCVRCQ best32. ;
informat MAJAPPPQ best32. ;
informat MAJAPPCQ best32. ;
informat SMLAPPPQ best32. ;
informat SMLAPPCQ best32. ;
informat MISCEQPQ best32. ;
informat MISCEQCQ best32. ;
informat APPARPQ best32. ;
informat APPARCQ best32. ;
informat MENBOYPQ best32. ;
informat MENBOYCQ best32. ;
informat MENSIXPQ best32. ;
informat MENSIXCQ best32. ;
informat BOYFIFPQ best32. ;
informat BOYFIFCQ best32. ;
informat WOMGRLPQ best32. ;
informat WOMGRLCQ best32. ;
informat WOMSIXPQ best32. ;
informat WOMSIXCQ best32. ;
informat GRLFIFPQ best32. ;
informat GRLFIFCQ best32. ;
informat CHLDRNPQ best32. ;
informat CHLDRNCQ best32. ;
informat FOOTWRPQ best32. ;
informat FOOTWRCQ best32. ;
informat OTHAPLPQ best32. ;
informat OTHAPLCQ best32. ;
informat TRANSPQ best32. ;
informat TRANSCQ best32. ;
informat CARTKNPQ best32. ;
informat CARTKNCQ best32. ;
informat CARTKUPQ best32. ;
informat CARTKUCQ best32. ;
informat OTHVEHPQ best32. ;
informat OTHVEHCQ best32. ;
informat GASMOPQ best32. ;
informat GASMOCQ best32. ;
informat VEHFINPQ best32. ;
informat VEHFINCQ best32. ;
informat MAINRPPQ best32. ;
informat MAINRPCQ best32. ;
informat VEHINSPQ best32. ;
informat VEHINSCQ best32. ;
informat VRNTLOPQ best32. ;
informat VRNTLOCQ best32. ;
informat PUBTRAPQ best32. ;
informat PUBTRACQ best32. ;
informat TRNTRPPQ best32. ;
informat TRNTRPCQ best32. ;
informat TRNOTHPQ best32. ;
informat TRNOTHCQ best32. ;
informat HEALTHPQ best32. ;
informat HEALTHCQ best32. ;
informat HLTHINPQ best32. ;
informat HLTHINCQ best32. ;
informat MEDSRVPQ best32. ;
informat MEDSRVCQ best32. ;
informat PREDRGPQ best32. ;
informat PREDRGCQ best32. ;
informat MEDSUPPQ best32. ;
informat MEDSUPCQ best32. ;
informat ENTERTPQ best32. ;
informat ENTERTCQ best32. ;
informat FEEADMPQ best32. ;
informat FEEADMCQ best32. ;
informat TVRDIOPQ best32. ;
informat TVRDIOCQ best32. ;
informat OTHEQPPQ best32. ;
informat OTHEQPCQ best32. ;
informat PETTOYPQ best32. ;
informat PETTOYCQ best32. ;
informat OTHENTPQ best32. ;
informat OTHENTCQ best32. ;
informat PERSCAPQ best32. ;
informat PERSCACQ best32. ;
informat READPQ best32. ;
informat READCQ best32. ;
informat EDUCAPQ best32. ;
informat EDUCACQ best32. ;
informat TOBACCPQ best32. ;
informat TOBACCCQ best32. ;
informat MISCPQ best32. ;
informat MISCCQ best32. ;
informat MISC1PQ best32. ;
informat MISC1CQ best32. ;
informat MISC2PQ best32. ;
informat MISC2CQ best32. ;
informat CASHCOPQ best32. ;
informat CASHCOCQ best32. ;
informat PERINSPQ best32. ;
informat PERINSCQ best32. ;
informat LIFINSPQ best32. ;
informat LIFINSCQ best32. ;
informat RETPENPQ best32. ;
informat RETPENCQ best32. ;
informat HH_CU_Q best32. ;
informat HH_CU_Q_ $3. ;
informat HHID best32. ;
informat HHID_ $3. ;
informat POV_CY $3. ;
informat POV_CY_ $3. ;
informat POV_PY $3. ;
informat POV_PY_ $3. ;
informat HEATFUEL $4. ;
informat HEAT_UEL $3. ;
informat SWIMPOOL $5. ;
informat SWIM_OOL $3. ;
informat WATERHT $4. ;
informat WATERHT_ $3. ;
informat APTMENT $1. ;
informat APTMENT_ $3. ;
informat OFSTPARK $4. ;
informat OFST_ARK $3. ;
informat WINDOWAC $5. ;
informat WIND_WAC $3. ;
informat CNTRALAC $4. ;
informat CNTR_LAC $3. ;
informat CHILDAGE $3. ;
informat CHIL_AGE $3. ;
informat INCLASS $4. ;
informat STATE $4. ;
informat CHDOTHX best32. ;
informat CHDOTHX_ $3. ;
informat ALIOTHX best32. ;
informat ALIOTHX_ $3. ;
informat CHDLMPX best32. ;
informat CHDLMPX_ $3. ;
informat ERANKH best32. ;
informat ERANKH_ $3. ;
informat TOTEX4PQ best32. ;
informat TOTEX4CQ best32. ;
informat MISCX4PQ best32. ;
informat MISCX4CQ best32. ;
informat VEHQL best32. ;
informat VEHQL_ $3. ;
informat NUM_TVAN best32. ;
informat NUM__VAN $3. ;
informat TTOTALP best32. ;
informat TTOTALC best32. ;
informat TFOODTOP best32. ;
informat TFOODTOC best32. ;
informat TFOODAWP best32. ;
informat TFOODAWC best32. ;
informat TFOODHOP best32. ;
informat TFOODHOC best32. ;
informat TALCBEVP best32. ;
informat TALCBEVC best32. ;
informat TOTHRLOP best32. ;
informat TOTHRLOC best32. ;
informat TTRANPRP best32. ;
informat TTRANPRC best32. ;
informat TGASMOTP best32. ;
informat TGASMOTC best32. ;
informat TVRENTLP best32. ;
informat TVRENTLC best32. ;
informat TCARTRKP best32. ;
informat TCARTRKC best32. ;
informat TOTHVHRP best32. ;
informat TOTHVHRC best32. ;
informat TOTHTREP best32. ;
informat TOTHTREC best32. ;
informat TTRNTRIP best32. ;
informat TTRNTRIC best32. ;
informat TFAREP best32. ;
informat TFAREC best32. ;
informat TAIRFARP best32. ;
informat TAIRFARC best32. ;
informat TOTHFARP best32. ;
informat TOTHFARC best32. ;
informat TLOCALTP best32. ;
informat TLOCALTC best32. ;
informat TENTRMNP best32. ;
informat TENTRMNC best32. ;
informat TFEESADP best32. ;
informat TFEESADC best32. ;
informat TOTHENTP best32. ;
informat TOTHENTC best32. ;
informat OWNVACP best32. ;
informat OWNVACC best32. ;
informat VOTHRLOP best32. ;
informat VOTHRLOC best32. ;
informat VMISCHEP best32. ;
informat VMISCHEC best32. ;
informat UTILOWNP best32. ;
informat UTILOWNC best32. ;
informat VFUELOIP best32. ;
informat VFUELOIC best32. ;
informat VOTHRFLP best32. ;
informat VOTHRFLC best32. ;
informat VELECTRP best32. ;
informat VELECTRC best32. ;
informat VNATLGAP best32. ;
informat VNATLGAC best32. ;
informat VWATERPP best32. ;
informat VWATERPC best32. ;
informat MRTPRNOP best32. ;
informat MRTPRNOC best32. ;
informat UTILRNTP best32. ;
informat UTILRNTC best32. ;
informat RFUELOIP best32. ;
informat RFUELOIC best32. ;
informat ROTHRFLP best32. ;
informat ROTHRFLC best32. ;
informat RELECTRP best32. ;
informat RELECTRC best32. ;
informat RNATLGAP best32. ;
informat RNATLGAC best32. ;
informat RWATERPP best32. ;
informat RWATERPC best32. ;
informat POVLEVCY best32. ;
informat POVL_VCY $3. ;
informat POVLEVPY best32. ;
informat POVL_VPY $3. ;
informat COOKING $4. ;
informat COOKING_ $3. ;
informat PORCH $4. ;
informat PORCH_ $3. ;
informat ETOTALP best32. ;
informat ETOTALC best32. ;
informat ETOTAPX4 best32. ;
informat ETOTACX4 best32. ;
informat EHOUSNGP best32. ;
informat EHOUSNGC best32. ;
informat ESHELTRP best32. ;
informat ESHELTRC best32. ;
informat EOWNDWLP best32. ;
informat EOWNDWLC best32. ;
informat EOTHLODP best32. ;
informat EOTHLODC best32. ;
informat EMRTPNOP best32. ;
informat EMRTPNOC best32. ;
informat EMRTPNVP best32. ;
informat EMRTPNVC best32. ;
informat ETRANPTP best32. ;
informat ETRANPTC best32. ;
informat EVEHPURP best32. ;
informat EVEHPURC best32. ;
informat ECARTKNP best32. ;
informat ECARTKNC best32. ;
informat ECARTKUP best32. ;
informat ECARTKUC best32. ;
informat EOTHVEHP best32. ;
informat EOTHVEHC best32. ;
informat EENTRMTP best32. ;
informat EENTRMTC best32. ;
informat EOTHENTP best32. ;
informat EOTHENTC best32. ;
informat ENOMOTRP best32. ;
informat ENOMOTRC best32. ;
informat EMOTRVHP best32. ;
informat EMOTRVHC best32. ;
informat EENTMSCP best32. ;
informat EENTMSCC best32. ;
informat EMISCELP best32. ;
informat EMISCELC best32. ;
informat EMISCMTP best32. ;
informat EMISCMTC best32. ;
informat UNISTRQ $4. ;
informat UNISTRQ_ $3. ;
informat INTEARNB $5. ;
informat INTE_RNB $3. ;
informat INTERNBX best32. ;
informat INTE_NBX $3. ;
informat FININCB $1. ;
informat FININCB_ $3. ;
informat FININCBX best32. ;
informat FINI_CBX $3. ;
informat PENSIONB $5. ;
informat PENS_ONB $3. ;
informat PNSIONBX best32. ;
informat PNSI_NBX $3. ;
informat UNEMPLB $1. ;
informat UNEMPLB_ $3. ;
informat UNEMPLBX best32. ;
informat UNEM_LBX $3. ;
informat COMPENSB $1. ;
informat COMP_NSB $3. ;
informat COMPNSBX best32. ;
informat COMP_SBX $3. ;
informat WELFAREB $1. ;
informat WELF_REB $3. ;
informat WELFREBX best32. ;
informat WELF_EBX $3. ;
informat FOODSMPX best32. ;
informat FOOD_MPX $3. ;
informat FOODSMPB $1. ;
informat FOOD_MPB $3. ;
informat FOODSPBX best32. ;
informat FOOD_PBX $3. ;
informat INCLOSAB $1. ;
informat INCL_SAB $3. ;
informat INCLSABX best32. ;
informat INCL_ABX $3. ;
informat INCLOSBB $1. ;
informat INCL_SBB $3. ;
informat INCLSBBX best32. ;
informat INCL_BBX $3. ;
informat CHDLMPB $1. ;
informat CHDLMPB_ $3. ;
informat CHDLMPBX best32. ;
informat CHDL_PBX $3. ;
informat CHDOTHB $1. ;
informat CHDOTHB_ $3. ;
informat CHDOTHBX best32. ;
informat CHDO_HBX $3. ;
informat ALIOTHB $1. ;
informat ALIOTHB_ $3. ;
informat ALIOTHBX best32. ;
informat ALIO_HBX $3. ;
informat LUMPSUMB $1. ;
informat LUMP_UMB $3. ;
informat LMPSUMBX best32. ;
informat LMPS_MBX $3. ;
informat SALEINCB $1. ;
informat SALE_NCB $3. ;
informat SALINCBX best32. ;
informat SALI_CBX $3. ;
informat OTHRINCB $1. ;
informat OTHR_NCB $3. ;
informat OTRINCBX best32. ;
informat OTRI_CBX $3. ;
informat INCLASS2 $3. ;
informat INCL_SS2 $3. ;
informat CUID best32. ;
informat INTERI best32. ;
informat HORREF1 $4. ;
informat HORREF1_ $3. ;
informat HORREF2 $4. ;
informat HORREF2_ $3. ;
informat ALIOTHXM best32. ;
informat ALIO_HXM $3. ;
informat ALIOTHX1 best32. ;
informat ALIOTHX2 best32. ;
informat ALIOTHX3 best32. ;
informat ALIOTHX4 best32. ;
informat ALIOTHX5 best32. ;
informat ALIOTHXI best32. ;
informat CHDOTHXM best32. ;
informat CHDO_HXM $3. ;
informat CHDOTHX1 best32. ;
informat CHDOTHX2 best32. ;
informat CHDOTHX3 best32. ;
informat CHDOTHX4 best32. ;
informat CHDOTHX5 best32. ;
informat CHDOTHXI best32. ;
informat COMPENSM best32. ;
informat COMP_NSM $3. ;
informat COMPENS1 best32. ;
informat COMPENS2 best32. ;
informat COMPENS3 best32. ;
informat COMPENS4 best32. ;
informat COMPENS5 best32. ;
informat COMPENSI best32. ;
informat ERANKHM best32. ;
informat ERANKHM_ $3. ;
informat FAMTFEDM best32. ;
informat FAMT_EDM $3. ;
informat FAMTFED1 best32. ;
informat FAMTFED2 best32. ;
informat FAMTFED3 best32. ;
informat FAMTFED4 best32. ;
informat FAMTFED5 best32. ;
informat FFRMINCM best32. ;
informat FFRM_NCM $3. ;
informat FFRMINC1 best32. ;
informat FFRMINC2 best32. ;
informat FFRMINC3 best32. ;
informat FFRMINC4 best32. ;
informat FFRMINC5 best32. ;
informat FFRMINCI best32. ;
informat FGOVRETM best32. ;
informat FGOV_ETM $3. ;
informat FINCATXM best32. ;
informat FINCA_XM $3. ;
informat FINCATX1 best32. ;
informat FINCATX2 best32. ;
informat FINCATX3 best32. ;
informat FINCATX4 best32. ;
informat FINCATX5 best32. ;
informat FINCBTXM best32. ;
informat FINCB_XM $3. ;
informat FINCBTX1 best32. ;
informat FINCBTX2 best32. ;
informat FINCBTX3 best32. ;
informat FINCBTX4 best32. ;
informat FINCBTX5 best32. ;
informat FINCBTXI best32. ;
informat FININCXM best32. ;
informat FINI_CXM $3. ;
informat FININCX1 best32. ;
informat FININCX2 best32. ;
informat FININCX3 best32. ;
informat FININCX4 best32. ;
informat FININCX5 best32. ;
informat FININCXI best32. ;
informat FJSSDEDM best32. ;
informat FJSS_EDM $3. ;
informat FJSSDED1 best32. ;
informat FJSSDED2 best32. ;
informat FJSSDED3 best32. ;
informat FJSSDED4 best32. ;
informat FJSSDED5 best32. ;
informat FNONFRMM best32. ;
informat FNON_RMM $3. ;
informat FNONFRM1 best32. ;
informat FNONFRM2 best32. ;
informat FNONFRM3 best32. ;
informat FNONFRM4 best32. ;
informat FNONFRM5 best32. ;
informat FNONFRMI best32. ;
informat FOODSMPM best32. ;
informat FOOD_MPM $3. ;
informat FOODSMP1 best32. ;
informat FOODSMP2 best32. ;
informat FOODSMP3 best32. ;
informat FOODSMP4 best32. ;
informat FOODSMP5 best32. ;
informat FOODSMPI best32. ;
informat FPRIPENM best32. ;
informat FPRI_ENM $3. ;
informat FRRDEDM best32. ;
informat FRRDEDM_ $3. ;
informat FRRETIRM best32. ;
informat FRRE_IRM $3. ;
informat FRRETIR1 best32. ;
informat FRRETIR2 best32. ;
informat FRRETIR3 best32. ;
informat FRRETIR4 best32. ;
informat FRRETIR5 best32. ;
informat FRRETIRI best32. ;
informat FSALARYM best32. ;
informat FSAL_RYM $3. ;
informat FSALARY1 best32. ;
informat FSALARY2 best32. ;
informat FSALARY3 best32. ;
informat FSALARY4 best32. ;
informat FSALARY5 best32. ;
informat FSALARYI best32. ;
informat FSLTAXXM best32. ;
informat FSLT_XXM $3. ;
informat FSLTAXX1 best32. ;
informat FSLTAXX2 best32. ;
informat FSLTAXX3 best32. ;
informat FSLTAXX4 best32. ;
informat FSLTAXX5 best32. ;
informat FSSIXM best32. ;
informat FSSIXM_ $3. ;
informat FSSIX1 best32. ;
informat FSSIX2 best32. ;
informat FSSIX3 best32. ;
informat FSSIX4 best32. ;
informat FSSIX5 best32. ;
informat FSSIXI best32. ;
informat INC_RNKM best32. ;
informat INC__NKM $3. ;
informat INC_RNK1 best32. ;
informat INC_RNK2 best32. ;
informat INC_RNK3 best32. ;
informat INC_RNK4 best32. ;
informat INC_RNK5 best32. ;
informat INCLOSAM best32. ;
informat INCL_SAM $3. ;
informat INCLOSA1 best32. ;
informat INCLOSA2 best32. ;
informat INCLOSA3 best32. ;
informat INCLOSA4 best32. ;
informat INCLOSA5 best32. ;
informat INCLOSAI best32. ;
informat INCLOSBM best32. ;
informat INCL_SBM $3. ;
informat INCLOSB1 best32. ;
informat INCLOSB2 best32. ;
informat INCLOSB3 best32. ;
informat INCLOSB4 best32. ;
informat INCLOSB5 best32. ;
informat INCLOSBI best32. ;
informat INTEARNM best32. ;
informat INTE_RNM $3. ;
informat INTEARN1 best32. ;
informat INTEARN2 best32. ;
informat INTEARN3 best32. ;
informat INTEARN4 best32. ;
informat INTEARN5 best32. ;
informat INTEARNI best32. ;
informat OTHRINCM best32. ;
informat OTHR_NCM $3. ;
informat OTHRINC1 best32. ;
informat OTHRINC2 best32. ;
informat OTHRINC3 best32. ;
informat OTHRINC4 best32. ;
informat OTHRINC5 best32. ;
informat OTHRINCI best32. ;
informat PENSIONM best32. ;
informat PENS_ONM $3. ;
informat PENSION1 best32. ;
informat PENSION2 best32. ;
informat PENSION3 best32. ;
informat PENSION4 best32. ;
informat PENSION5 best32. ;
informat PENSIONI best32. ;
informat POV_CYM $3. ;
informat POV_CYM_ $3. ;
informat POV_CY1 $3. ;
informat POV_CY2 $3. ;
informat POV_CY3 $3. ;
informat POV_CY4 $3. ;
informat POV_CY5 $3. ;
informat POV_PYM $3. ;
informat POV_PYM_ $3. ;
informat POV_PY1 $3. ;
informat POV_PY2 $3. ;
informat POV_PY3 $3. ;
informat POV_PY4 $3. ;
informat POV_PY5 $3. ;
informat PRINERNM $4. ;
informat PRIN_RNM $3. ;
informat PRINERN1 $4. ;
informat PRINERN2 $4. ;
informat PRINERN3 $4. ;
informat PRINERN4 $4. ;
informat PRINERN5 $4. ;
informat TOTTXPDM best32. ;
informat TOTT_PDM $3. ;
informat TOTTXPD1 best32. ;
informat TOTTXPD2 best32. ;
informat TOTTXPD3 best32. ;
informat TOTTXPD4 best32. ;
informat TOTTXPD5 best32. ;
informat UNEMPLXM best32. ;
informat UNEM_LXM $3. ;
informat UNEMPLX1 best32. ;
informat UNEMPLX2 best32. ;
informat UNEMPLX3 best32. ;
informat UNEMPLX4 best32. ;
informat UNEMPLX5 best32. ;
informat UNEMPLXI best32. ;
informat WELFAREM best32. ;
informat WELF_REM $3. ;
informat WELFARE1 best32. ;
informat WELFARE2 best32. ;
informat WELFARE3 best32. ;
informat WELFARE4 best32. ;
informat WELFARE5 best32. ;
informat WELFAREI best32. ;
informat COLPLAN $4. ;
informat COLPLAN_ $3. ;
informat COLPLANX best32. ;
informat COLP_ANX $3. ;
informat PSU $8. ;
informat REVSMORT $4. ;
informat REVS_ORT $3. ;
informat RVSLUMP $1. ;
informat RVSLUMP_ $3. ;
informat RVSREGMO $1. ;
informat RVSR_GMO $3. ;
informat RVSLOC $1. ;
informat RVSLOC_ $3. ;
informat RVSOTHPY $1. ;
informat RVSO_HPY $3. ;
informat TYPEPYX best32. ;
informat TYPEPYX_ $3. ;
informat HISP_REF $3. ;
informat HISP2 $4. ;
informat BUILT $8. ;
informat BUILT_ $3. ;
input
NEWID
DIRACC $
DIRACC_ $
AGE_REF
AGE_REF_ $
AGE2
AGE2_ $
AS_COMP1
AS_C_MP1 $
AS_COMP2
AS_C_MP2 $
AS_COMP3
AS_C_MP3 $
AS_COMP4
AS_C_MP4 $
AS_COMP5
AS_C_MP5 $
BATHRMQ
BATHRMQ_ $
BEDROOMQ
BEDR_OMQ $
BLS_URBN $
BSINVSTX
BSIN_STX $
BUILDING $
BUIL_ING $
CKBKACTX
CKBK_CTX $
COMPBND $
COMPBND_ $
COMPBNDX
COMP_NDX $
COMPCKG $
COMPCKG_ $
COMPCKGX
COMP_KGX $
COMPENSX
COMP_NSX $
COMPOWD $
COMPOWD_ $
COMPOWDX
COMP_WDX $
COMPSAV $
COMPSAV_ $
COMPSAVX
COMP_AVX $
COMPSEC $
COMPSEC_ $
COMPSECX
COMP_ECX $
CUTENURE $
CUTE_URE $
EARNCOMP $
EARN_OMP $
EDUC_REF $
EDUC0REF $
EDUCA2 $
EDUCA2_ $
FAM_SIZE
FAM__IZE $
FAM_TYPE $
FAM__YPE $
FAMTFEDX
FAMT_EDX $
FEDRFNDX
FEDR_NDX $
FEDTAXX
FEDTAXX_ $
FFRMINCX
FFRM_NCX $
FGOVRETX
FGOV_ETX $
FINCATAX
FINCAT_X $
FINCBTAX
FINCBT_X $
FINDRETX
FIND_ETX $
FININCX
FININCX_ $
FINLWT21
FJSSDEDX
FJSS_EDX $
FNONFRMX
FNON_RMX $
FPRIPENX
FPRI_ENX $
FRRDEDX
FRRDEDX_ $
FRRETIRX
FRRE_IRX $
FSALARYX
FSAL_RYX $
FSLTAXX
FSLTAXX_ $
FSSIX
FSSIX_ $
GOVTCOST $
GOVT_OST $
HLFBATHQ
HLFB_THQ $
INC_HRS1
INC__RS1 $
INC_HRS2
INC__RS2 $
INC_RANK
INC__ANK $
INCLOSSA
INCL_SSA $
INCLOSSB
INCL_SSB $
INCNONW1 $
INCN_NW1 $
INCNONW2 $
INCN_NW2 $
INCOMEY1 $
INCO_EY1 $
INCOMEY2 $
INCO_EY2 $
INCWEEK1
INCW_EK1 $
INCWEEK2
INCW_EK2 $
INSRFNDX
INSR_NDX $
INTEARNX
INTE_RNX $
MISCTAXX
MISC_AXX $
LUMPSUMX
LUMP_UMX $
MARITAL1 $
MARI_AL1 $
MONYOWDX
MONY_WDX $
NO_EARNR
NO_E_RNR $
NONINCMX
NONI_CMX $
NUM_AUTO
NUM__UTO $
OCCUCOD1 $
OCCU_OD1 $
OCCUCOD2 $
OCCU_OD2 $
OTHRFNDX
OTHR_NDX $
OTHRINCX
OTHR_NCX $
PENSIONX
PENS_ONX $
PERSLT18
PERS_T18 $
PERSOT64
PERS_T64 $
POPSIZE $
PRINEARN $
PRIN_ARN $
PTAXRFDX
PTAX_FDX $
PUBLHOUS $
PUBL_OUS $
PURSSECX
PURS_ECX $
QINTRVMO $
QINTRVYR
RACE2 $
RACE2_ $
REF_RACE $
REF__ACE $
REGION $
RENTEQVX
RENT_QVX $
RESPSTAT $
RESP_TAT $
ROOMSQ
ROOMSQ_ $
SALEINCX
SALE_NCX $
SAVACCTX
SAVA_CTX $
SECESTX
SECESTX_ $
SELLSECX
SELL_ECX $
SETLINSX
SETL_NSX $
SEX_REF $
SEX_REF_ $
SEX2 $
SEX2_ $
SLOCTAXX
SLOC_AXX $
SLRFUNDX
SLRF_NDX $
SMSASTAT $
SSOVERPX
SSOV_RPX $
ST_HOUS $
ST_HOUS_ $
TAXPROPX
TAXP_OPX $
TOTTXPDX
TOTT_PDX $
UNEMPLX
UNEMPLX_ $
USBNDX
USBNDX_ $
VEHQ
VEHQ_ $
WDBSASTX
WDBS_STX $
WDBSGDSX
WDBS_DSX $
WELFAREX
WELF_REX $
WTREP01
WTREP02
WTREP03
WTREP04
WTREP05
WTREP06
WTREP07
WTREP08
WTREP09
WTREP10
WTREP11
WTREP12
WTREP13
WTREP14
WTREP15
WTREP16
WTREP17
WTREP18
WTREP19
WTREP20
WTREP21
WTREP22
WTREP23
WTREP24
WTREP25
WTREP26
WTREP27
WTREP28
WTREP29
WTREP30
WTREP31
WTREP32
WTREP33
WTREP34
WTREP35
WTREP36
WTREP37
WTREP38
WTREP39
WTREP40
WTREP41
WTREP42
WTREP43
WTREP44
TOTEXPPQ
TOTEXPCQ
FOODPQ
FOODCQ
FDHOMEPQ
FDHOMECQ
FDAWAYPQ
FDAWAYCQ
FDXMAPPQ
FDXMAPCQ
FDMAPPQ
FDMAPCQ
ALCBEVPQ
ALCBEVCQ
HOUSPQ
HOUSCQ
SHELTPQ
SHELTCQ
OWNDWEPQ
OWNDWECQ
MRTINTPQ
MRTINTCQ
PROPTXPQ
PROPTXCQ
MRPINSPQ
MRPINSCQ
RENDWEPQ
RENDWECQ
RNTXRPPQ
RNTXRPCQ
RNTAPYPQ
RNTAPYCQ
OTHLODPQ
OTHLODCQ
UTILPQ
UTILCQ
NTLGASPQ
NTLGASCQ
ELCTRCPQ
ELCTRCCQ
ALLFULPQ
ALLFULCQ
FULOILPQ
FULOILCQ
OTHFLSPQ
OTHFLSCQ
TELEPHPQ
TELEPHCQ
WATRPSPQ
WATRPSCQ
HOUSOPPQ
HOUSOPCQ
DOMSRVPQ
DOMSRVCQ
DMSXCCPQ
DMSXCCCQ
BBYDAYPQ
BBYDAYCQ
OTHHEXPQ
OTHHEXCQ
HOUSEQPQ
HOUSEQCQ
TEXTILPQ
TEXTILCQ
FURNTRPQ
FURNTRCQ
FLRCVRPQ
FLRCVRCQ
MAJAPPPQ
MAJAPPCQ
SMLAPPPQ
SMLAPPCQ
MISCEQPQ
MISCEQCQ
APPARPQ
APPARCQ
MENBOYPQ
MENBOYCQ
MENSIXPQ
MENSIXCQ
BOYFIFPQ
BOYFIFCQ
WOMGRLPQ
WOMGRLCQ
WOMSIXPQ
WOMSIXCQ
GRLFIFPQ
GRLFIFCQ
CHLDRNPQ
CHLDRNCQ
FOOTWRPQ
FOOTWRCQ
OTHAPLPQ
OTHAPLCQ
TRANSPQ
TRANSCQ
CARTKNPQ
CARTKNCQ
CARTKUPQ
CARTKUCQ
OTHVEHPQ
OTHVEHCQ
GASMOPQ
GASMOCQ
VEHFINPQ
VEHFINCQ
MAINRPPQ
MAINRPCQ
VEHINSPQ
VEHINSCQ
VRNTLOPQ
VRNTLOCQ
PUBTRAPQ
PUBTRACQ
TRNTRPPQ
TRNTRPCQ
TRNOTHPQ
TRNOTHCQ
HEALTHPQ
HEALTHCQ
HLTHINPQ
HLTHINCQ
MEDSRVPQ
MEDSRVCQ
PREDRGPQ
PREDRGCQ
MEDSUPPQ
MEDSUPCQ
ENTERTPQ
ENTERTCQ
FEEADMPQ
FEEADMCQ
TVRDIOPQ
TVRDIOCQ
OTHEQPPQ
OTHEQPCQ
PETTOYPQ
PETTOYCQ
OTHENTPQ
OTHENTCQ
PERSCAPQ
PERSCACQ
READPQ
READCQ
EDUCAPQ
EDUCACQ
TOBACCPQ
TOBACCCQ
MISCPQ
MISCCQ
MISC1PQ
MISC1CQ
MISC2PQ
MISC2CQ
CASHCOPQ
CASHCOCQ
PERINSPQ
PERINSCQ
LIFINSPQ
LIFINSCQ
RETPENPQ
RETPENCQ
HH_CU_Q
HH_CU_Q_ $
HHID
HHID_ $
POV_CY $
POV_CY_ $
POV_PY $
POV_PY_ $
HEATFUEL $
HEAT_UEL $
SWIMPOOL $
SWIM_OOL $
WATERHT $
WATERHT_ $
APTMENT $
APTMENT_ $
OFSTPARK $
OFST_ARK $
WINDOWAC $
WIND_WAC $
CNTRALAC $
CNTR_LAC $
CHILDAGE $
CHIL_AGE $
INCLASS $
STATE $
CHDOTHX
CHDOTHX_ $
ALIOTHX
ALIOTHX_ $
CHDLMPX
CHDLMPX_ $
ERANKH
ERANKH_ $
TOTEX4PQ
TOTEX4CQ
MISCX4PQ
MISCX4CQ
VEHQL
VEHQL_ $
NUM_TVAN
NUM__VAN $
TTOTALP
TTOTALC
TFOODTOP
TFOODTOC
TFOODAWP
TFOODAWC
TFOODHOP
TFOODHOC
TALCBEVP
TALCBEVC
TOTHRLOP
TOTHRLOC
TTRANPRP
TTRANPRC
TGASMOTP
TGASMOTC
TVRENTLP
TVRENTLC
TCARTRKP
TCARTRKC
TOTHVHRP
TOTHVHRC
TOTHTREP
TOTHTREC
TTRNTRIP
TTRNTRIC
TFAREP
TFAREC
TAIRFARP
TAIRFARC
TOTHFARP
TOTHFARC
TLOCALTP
TLOCALTC
TENTRMNP
TENTRMNC
TFEESADP
TFEESADC
TOTHENTP
TOTHENTC
OWNVACP
OWNVACC
VOTHRLOP
VOTHRLOC
VMISCHEP
VMISCHEC
UTILOWNP
UTILOWNC
VFUELOIP
VFUELOIC
VOTHRFLP
VOTHRFLC
VELECTRP
VELECTRC
VNATLGAP
VNATLGAC
VWATERPP
VWATERPC
MRTPRNOP
MRTPRNOC
UTILRNTP
UTILRNTC
RFUELOIP
RFUELOIC
ROTHRFLP
ROTHRFLC
RELECTRP
RELECTRC
RNATLGAP
RNATLGAC
RWATERPP
RWATERPC
POVLEVCY
POVL_VCY $
POVLEVPY
POVL_VPY $
COOKING $
COOKING_ $
PORCH $
PORCH_ $
ETOTALP
ETOTALC
ETOTAPX4
ETOTACX4
EHOUSNGP
EHOUSNGC
ESHELTRP
ESHELTRC
EOWNDWLP
EOWNDWLC
EOTHLODP
EOTHLODC
EMRTPNOP
EMRTPNOC
EMRTPNVP
EMRTPNVC
ETRANPTP
ETRANPTC
EVEHPURP
EVEHPURC
ECARTKNP
ECARTKNC
ECARTKUP
ECARTKUC
EOTHVEHP
EOTHVEHC
EENTRMTP
EENTRMTC
EOTHENTP
EOTHENTC
ENOMOTRP
ENOMOTRC
EMOTRVHP
EMOTRVHC
EENTMSCP
EENTMSCC
EMISCELP
EMISCELC
EMISCMTP
EMISCMTC
UNISTRQ $
UNISTRQ_ $
INTEARNB $
INTE_RNB $
INTERNBX
INTE_NBX $
FININCB $
FININCB_ $
FININCBX
FINI_CBX $
PENSIONB $
PENS_ONB $
PNSIONBX
PNSI_NBX $
UNEMPLB $
UNEMPLB_ $
UNEMPLBX
UNEM_LBX $
COMPENSB $
COMP_NSB $
COMPNSBX
COMP_SBX $
WELFAREB $
WELF_REB $
WELFREBX
WELF_EBX $
FOODSMPX
FOOD_MPX $
FOODSMPB $
FOOD_MPB $
FOODSPBX
FOOD_PBX $
INCLOSAB $
INCL_SAB $
INCLSABX
INCL_ABX $
INCLOSBB $
INCL_SBB $
INCLSBBX
INCL_BBX $
CHDLMPB $
CHDLMPB_ $
CHDLMPBX
CHDL_PBX $
CHDOTHB $
CHDOTHB_ $
CHDOTHBX
CHDO_HBX $
ALIOTHB $
ALIOTHB_ $
ALIOTHBX
ALIO_HBX $
LUMPSUMB $
LUMP_UMB $
LMPSUMBX
LMPS_MBX $
SALEINCB $
SALE_NCB $
SALINCBX
SALI_CBX $
OTHRINCB $
OTHR_NCB $
OTRINCBX
OTRI_CBX $
INCLASS2 $
INCL_SS2 $
CUID
INTERI
HORREF1 $
HORREF1_ $
HORREF2 $
HORREF2_ $
ALIOTHXM
ALIO_HXM $
ALIOTHX1
ALIOTHX2
ALIOTHX3
ALIOTHX4
ALIOTHX5
ALIOTHXI
CHDOTHXM
CHDO_HXM $
CHDOTHX1
CHDOTHX2
CHDOTHX3
CHDOTHX4
CHDOTHX5
CHDOTHXI
COMPENSM
COMP_NSM $
COMPENS1
COMPENS2
COMPENS3
COMPENS4
COMPENS5
COMPENSI
ERANKHM
ERANKHM_ $
FAMTFEDM
FAMT_EDM $
FAMTFED1
FAMTFED2
FAMTFED3
FAMTFED4
FAMTFED5
FFRMINCM
FFRM_NCM $
FFRMINC1
FFRMINC2
FFRMINC3
FFRMINC4
FFRMINC5
FFRMINCI
FGOVRETM
FGOV_ETM $
FINCATXM
FINCA_XM $
FINCATX1
FINCATX2
FINCATX3
FINCATX4
FINCATX5
FINCBTXM
FINCB_XM $
FINCBTX1
FINCBTX2
FINCBTX3
FINCBTX4
FINCBTX5
FINCBTXI
FININCXM
FINI_CXM $
FININCX1
FININCX2
FININCX3
FININCX4
FININCX5
FININCXI
FJSSDEDM
FJSS_EDM $
FJSSDED1
FJSSDED2
FJSSDED3
FJSSDED4
FJSSDED5
FNONFRMM
FNON_RMM $
FNONFRM1
FNONFRM2
FNONFRM3
FNONFRM4
FNONFRM5
FNONFRMI
FOODSMPM
FOOD_MPM $
FOODSMP1
FOODSMP2
FOODSMP3
FOODSMP4
FOODSMP5
FOODSMPI
FPRIPENM
FPRI_ENM $
FRRDEDM
FRRDEDM_ $
FRRETIRM
FRRE_IRM $
FRRETIR1
FRRETIR2
FRRETIR3
FRRETIR4
FRRETIR5
FRRETIRI
FSALARYM
FSAL_RYM $
FSALARY1
FSALARY2
FSALARY3
FSALARY4
FSALARY5
FSALARYI
FSLTAXXM
FSLT_XXM $
FSLTAXX1
FSLTAXX2
FSLTAXX3
FSLTAXX4
FSLTAXX5
FSSIXM
FSSIXM_ $
FSSIX1
FSSIX2
FSSIX3
FSSIX4
FSSIX5
FSSIXI
INC_RNKM
INC__NKM $
INC_RNK1
INC_RNK2
INC_RNK3
INC_RNK4
INC_RNK5
INCLOSAM
INCL_SAM $
INCLOSA1
INCLOSA2
INCLOSA3
INCLOSA4
INCLOSA5
INCLOSAI
INCLOSBM
INCL_SBM $
INCLOSB1
INCLOSB2
INCLOSB3
INCLOSB4
INCLOSB5
INCLOSBI
INTEARNM
INTE_RNM $
INTEARN1
INTEARN2
INTEARN3
INTEARN4
INTEARN5
INTEARNI
OTHRINCM
OTHR_NCM $
OTHRINC1
OTHRINC2
OTHRINC3
OTHRINC4
OTHRINC5
OTHRINCI
PENSIONM
PENS_ONM $
PENSION1
PENSION2
PENSION3
PENSION4
PENSION5
PENSIONI
POV_CYM $
POV_CYM_ $
POV_CY1 $
POV_CY2 $
POV_CY3 $
POV_CY4 $
POV_CY5 $
POV_PYM $
POV_PYM_ $
POV_PY1 $
POV_PY2 $
POV_PY3 $
POV_PY4 $
POV_PY5 $
PRINERNM $
PRIN_RNM $
PRINERN1 $
PRINERN2 $
PRINERN3 $
PRINERN4 $
PRINERN5 $
TOTTXPDM
TOTT_PDM $
TOTTXPD1
TOTTXPD2
TOTTXPD3
TOTTXPD4
TOTTXPD5
UNEMPLXM
UNEM_LXM $
UNEMPLX1
UNEMPLX2
UNEMPLX3
UNEMPLX4
UNEMPLX5
UNEMPLXI
WELFAREM
WELF_REM $
WELFARE1
WELFARE2
WELFARE3
WELFARE4
WELFARE5
WELFAREI
COLPLAN $
COLPLAN_ $
COLPLANX
COLP_ANX $
PSU $
REVSMORT $
REVS_ORT $
RVSLUMP $
RVSLUMP_ $
RVSREGMO $
RVSR_GMO $
RVSLOC $
RVSLOC_ $
RVSOTHPY $
RVSO_HPY $
TYPEPYX
TYPEPYX_ $
HISP_REF $
HISP2 $
BUILT $
BUILT_ $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;



  /*** IMPORT DIARY FMLY   **************************/

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\FMLD&YR1.1.CSV"
            OUT=FMLYD&YR1.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\FMLD&YR1.2.CSV"
            OUT=FMLYD&YR1.2
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\FMLD&YR1.3.CSV"
            OUT=FMLYD&YR1.3
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\FMLD&YR1.4.CSV"
            OUT=FMLYD&YR1.4
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;


  /*** COMBINE INTRVW AND DIARY FMLY AND ADJUST WEIGHTS  ***/

DATA FMLY;
  SET 
      FMLYI&YR1.1 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 QINTRVYR QINTRVMO IN=INTRVW) 
      FMLYI&YR1.2 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 QINTRVYR QINTRVMO IN=INTRVW) 
      FMLYI&YR1.3 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 QINTRVYR QINTRVMO IN=INTRVW) 
      FMLYI&YR1.4 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 QINTRVYR QINTRVMO IN=INTRVW)
      FMLYI&YR2.1 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 QINTRVYR QINTRVMO IN=INTRVW)

      FMLYD&YR1.1 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 IN=DIARY) 
      FMLYD&YR1.2 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 IN=DIARY) 
      FMLYD&YR1.3 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 IN=DIARY) 
      FMLYD&YR1.4 (KEEP = NEWID INCLASS WTREP01-WTREP44 FINLWT21 IN=DIARY);

    ARRAY REPS_A(45) WTREP01-WTREP44 FINLWT21;
    ARRAY REPS_B(45) REPWT1-REPWT45;

	IF INTRVW THEN DO;

      IF (QINTRVYR="&YEAR") AND (QINTRVMO <= "03") THEN MO_SCOPE = (QINTRVMO - 1);
      ELSE IF (QINTRVYR = %EVAL(&YEAR+1)) THEN MO_SCOPE = (4 - QINTRVMO);
      ELSE MO_SCOPE = 3;
	  /* CREATE MONTH IN SCOPE VARIABLE (MO_SCOPE) */

      DO i = 1 TO 45;
	  IF REPS_A(i) > 0 THEN
         REPS_B(i) = (REPS_A(i) * MO_SCOPE / 12); 
		 ELSE REPS_B(i) = 0;	
	  END;
      /* ADJUST WEIGHTS BY MO_SCOPE TO ACCOUNT FOR SAMPLE ROTATION */
	  SOURCE = "I";
	END;

    IF DIARY THEN DO;

      DO i = 1 TO 45;
	  IF REPS_A(i) > 0 THEN
         REPS_B(i) = (REPS_A(i) / 4); 
		 ELSE REPS_B(i) = 0;	
	  END;
	SOURCE = "D";
	END;	
RUN;

PROC SORT DATA=FMLY;
  BY NEWID;
RUN;



  /*** IMPORT INTRVW MTAB  **************************/

/*********************************************************************************************
 ** PROC IMPORT was removed and replaced by the internal SAS code produced via PROC IMPORT. **
 ** This was done because SAS assigned incorrect formats to REFYR and REFMO                 **
 *********************************************************************************************

PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\MTBI&YR1.1x.CSV"
            OUT=MTABI&YR1.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
/********************************************************************************************/

          data WORK.MTABI111                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
         infile 'C:\2011_CEX\Intrvw11\MTBI111x.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat SEQNO best32. ;
             informat ALCNO best32. ;
             informat NEWID best32. ;
             informat EXPNAME $10. ;
             informat COST_ $3. ;
             informat REF_MO $2. ;
             informat REF_YR 4. ;
             informat RTYPE $5. ;
             informat GIFT $3. ;
             informat UCCSEQ best32. ;
             informat UCC $8. ;
             informat COST best32. ;
             informat PUBFLAG $3. ;
			          input
                      SEQNO
                      ALCNO
                      NEWID
                      EXPNAME $
                      COST_ $
                      REF_MO $
                      REF_YR
                      RTYPE $
                      GIFT $
                      UCCSEQ
                      UCC $
                      COST
                      PUBFLAG $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;
/**************************************************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\MTBI&YR1.2.CSV"
            OUT=MTABI&YR1.2
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
*****************************************************************************************************/

		  data WORK.MTABI112                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
         infile 'C:\2011_CEX\Intrvw11\MTBI112.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat SEQNO best32. ;
             informat ALCNO best32. ;
             informat NEWID best32. ;
             informat EXPNAME $10. ;
             informat COST_ $3. ;
             informat REF_MO $2. ;
             informat REF_YR 4. ;
             informat RTYPE $5. ;
             informat GIFT $3. ;
             informat UCCSEQ best32. ;
             informat UCC $8. ;
             informat COST best32. ;
             informat PUBFLAG $3. ;
             		  input
                      SEQNO
                      ALCNO
                      NEWID
                      EXPNAME $
                      COST_ $
                      REF_MO $
                      REF_YR
                      RTYPE $
                      GIFT $
                      UCCSEQ
                      UCC $
                      COST
                      PUBFLAG $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;

/**********************************************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\MTBI&YR1.3.CSV"
            OUT=MTABI&YR1.3
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
************************************************************************************************/

		  data WORK.MTABI113                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
         infile 'C:\2011_CEX\Intrvw11\MTBI113.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat SEQNO best32. ;
             informat ALCNO best32. ;
             informat NEWID best32. ;
             informat EXPNAME $10. ;
             informat COST_ $3. ;
             informat REF_MO $2. ;
             informat REF_YR 4. ;
             informat RTYPE $5. ;
             informat GIFT $3. ;
             informat UCCSEQ best32. ;
             informat UCC $8. ;
             informat COST best32. ;
             informat PUBFLAG $3. ;
                      input
                      SEQNO
                      ALCNO
                      NEWID
                      EXPNAME $
                      COST_ $
                      REF_MO $
                      REF_YR
                      RTYPE $
                      GIFT $
                      UCCSEQ
                      UCC $
                      COST
                      PUBFLAG $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;
/************************************************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\MTBI&YR1.4.CSV"
            OUT=MTABI&YR1.4
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
**************************************************************************************************/
data WORK.MTABI114                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
         infile 'C:\2011_CEX\Intrvw11\MTBI114.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat SEQNO best32. ;
             informat ALCNO best32. ;
             informat NEWID best32. ;
             informat EXPNAME $10. ;
             informat COST_ $3. ;
             informat REF_MO $2. ;
             informat REF_YR 4. ;
             informat RTYPE $5. ;
             informat GIFT $3. ;
             informat UCCSEQ best32. ;
             informat UCC $8. ;
             informat COST best32. ;
             informat PUBFLAG $3. ;
                      input
                      SEQNO
                      ALCNO
                      NEWID
                      EXPNAME $
                      COST_ $
                      REF_MO $
                      REF_YR
                      RTYPE $
                      GIFT $
                      UCCSEQ
                      UCC $
                      COST
                      PUBFLAG $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;

/**********************************************************************************************
		PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\MTBI&YR2.1.CSV"
            OUT=MTABI&YR2.1
  			DBMS = CSV
  			REPLACE;
  			GETNAMES=YES;
		RUN;
**************************************************************************************************/

data WORK.MTABI121                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
         infile 'C:\2011_CEX\Intrvw11\MTBI121.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat SEQNO best32. ;
             informat ALCNO best32. ;
             informat NEWID best32. ;
             informat EXPNAME $10. ;
             informat COST_ $3. ;
             informat REF_MO $2. ;
             informat REF_YR 4. ;
             informat RTYPE $5. ;
             informat GIFT $3. ;
             informat UCCSEQ best32. ;
             informat UCC $8. ;
             informat COST best32. ;
             informat PUBFLAG $3. ;
                      input
                      SEQNO
                      ALCNO
                      NEWID
                      EXPNAME $
                      COST_ $
                      REF_MO $
                      REF_YR
                      RTYPE $
                      GIFT $
                      UCCSEQ
                      UCC $
                      COST
                      PUBFLAG $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;



  /*** IMPORT INTRVW ITAB  **************************/

/*********************************************************************************************
 ** PROC IMPORT was removed and replaced by the internal SAS code produced via PROC IMPORT. **
 ** This was done because SAS assigned incorrect formats to REFYR and REFMO.                **
 *********************************************************************************************

PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\ITBI&YR1.1x.CSV"
            OUT=ITABI&YR1.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
**********************************************************************************************/
data WORK.ITABI111                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
          infile 'C:\2011_CEX\Intrvw11\ITBI111x.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat NEWID best32. ;
             informat REFMO $2. ;
             informat REFYR 4. ;
             informat UCC $8. ;
             informat PUBFLAG $3. ;
             informat VALUE best32. ;
             informat VALUE_ $3. ;
                      input
                      NEWID
                      REFMO $
                      REFYR
                      UCC $
                      PUBFLAG $
                      VALUE
                      VALUE_ $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;
/***************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\ITBI&YR1.2.CSV"
            OUT=ITABI&YR1.2
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
****************************************************************/
data WORK.ITABI112                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
          infile 'C:\2011_CEX\Intrvw11\ITBI112.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat NEWID best32. ;
             informat REFMO $2. ;
             informat REFYR 4. ;
             informat UCC $8. ;
             informat PUBFLAG $3. ;
             informat VALUE best32. ;
             informat VALUE_ $3. ;
                      input
                      NEWID
                      REFMO $
                      REFYR
                      UCC $
                      PUBFLAG $
                      VALUE
                      VALUE_ $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;
/***********************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\ITBI&YR1.3.CSV"
            OUT=ITABI&YR1.3
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
*************************************************************/

data WORK.ITABI113                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
          infile 'C:\2011_CEX\Intrvw11\ITBI113.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat NEWID best32. ;
             informat REFMO $2. ;
             informat REFYR 4. ;
             informat UCC $8. ;
             informat PUBFLAG $3. ;
             informat VALUE best32. ;
             informat VALUE_ $3. ;
                      input
                      NEWID
                      REFMO $
                      REFYR
                      UCC $
                      PUBFLAG $
                      VALUE
                      VALUE_ $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;
/************************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\ITBI&YR1.4.CSV"
            OUT=ITABI&YR1.4
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
*************************************************************/
data WORK.ITABI114                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
          infile 'C:\2011_CEX\Intrvw11\ITBI114.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat NEWID best32. ;
             informat REFMO $2. ;
             informat REFYR 4. ;
             informat UCC $8. ;
             informat PUBFLAG $3. ;
             informat VALUE best32. ;
             informat VALUE_ $3. ;
                      input
                      NEWID
                      REFMO $
                      REFYR
                      UCC $
                      PUBFLAG $
                      VALUE
                      VALUE_ $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;
/***********************************************************
PROC IMPORT FILE="C:\&YEAR._CEX\Intrvw&YR1\ITBI&YR2.1.CSV"
            OUT=ITABI&YR2.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;
************************************************************/

data WORK.ITABI121                                ;
          %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
          infile 'C:\2011_CEX\Intrvw11\ITBI121.CSV' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
             informat NEWID best32. ;
             informat REFMO $2. ;
             informat REFYR 4. ;
             informat UCC $8. ;
             informat PUBFLAG $3. ;
             informat VALUE best32. ;
             informat VALUE_ $3. ;
			          input
                      NEWID
                      REFMO $
                      REFYR
                      UCC $
                      PUBFLAG $
                      VALUE
                      VALUE_ $
          ;
          if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
          run;


  /*** IMPORT DIARY EXPN   **************************/

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\EXPD&YR1.1.CSV"
            OUT=EXPND&YR1.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\EXPD&YR1.2.CSV"
            OUT=EXPND&YR1.2
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\EXPD&YR1.3.CSV"
            OUT=EXPND&YR1.3
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\EXPD&YR1.4.CSV"
            OUT=EXPND&YR1.4
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;


  /*** IMPORT DIARY DTAB   **************************/

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\DTBD&YR1.1.CSV"
            OUT=DTABD&YR1.1
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\DTBD&YR1.2.CSV"
            OUT=DTABD&YR1.2
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\DTBD&YR1.3.CSV"
            OUT=DTABD&YR1.3
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;

PROC IMPORT FILE="C:\&YEAR._CEX\Diary&YR1\DTBD&YR1.4.CSV"
            OUT=DTABD&YR1.4
  DBMS = CSV
  REPLACE;
  GETNAMES=YES;
RUN;


  /*** COMBINE INTRVW AND DIARY INCOME AND EXPENDITURE FILES  *******/

DATA EXPEND;
  SET 
      MTABI&YR1.1 (KEEP = NEWID UCC COST REF_YR PUBFLAG)
      MTABI&YR1.2 (KEEP = NEWID UCC COST REF_YR PUBFLAG)
	  MTABI&YR1.3 (KEEP = NEWID UCC COST REF_YR PUBFLAG)
	  MTABI&YR1.4 (KEEP = NEWID UCC COST REF_YR PUBFLAG)
      MTABI&YR2.1 (KEEP = NEWID UCC COST REF_YR PUBFLAG)

      ITABI&YR1.1 (KEEP = NEWID UCC VALUE REFYR PUBFLAG RENAME=(VALUE=COST))
      ITABI&YR1.2 (KEEP = NEWID UCC VALUE REFYR PUBFLAG RENAME=(VALUE=COST))
	  ITABI&YR1.3 (KEEP = NEWID UCC VALUE REFYR PUBFLAG RENAME=(VALUE=COST))
	  ITABI&YR1.4 (KEEP = NEWID UCC VALUE REFYR PUBFLAG RENAME=(VALUE=COST))
      ITABI&YR2.1 (KEEP = NEWID UCC VALUE REFYR PUBFLAG RENAME=(VALUE=COST))

      EXPND&YR1.1 (KEEP = NEWID UCC COST PUB_FLAG)
      EXPND&YR1.2 (KEEP = NEWID UCC COST PUB_FLAG)
	  EXPND&YR1.3 (KEEP = NEWID UCC COST PUB_FLAG)
	  EXPND&YR1.4 (KEEP = NEWID UCC COST PUB_FLAG)

      DTABD&YR1.1 (KEEP = NEWID UCC AMOUNT PUB_FLAG RENAME=(AMOUNT=COST))
      DTABD&YR1.2 (KEEP = NEWID UCC AMOUNT PUB_FLAG RENAME=(AMOUNT=COST))
	  DTABD&YR1.3 (KEEP = NEWID UCC AMOUNT PUB_FLAG RENAME=(AMOUNT=COST))
	  DTABD&YR1.4 (KEEP = NEWID UCC AMOUNT PUB_FLAG RENAME=(AMOUNT=COST));

        IF (PUBFLAG = '2') THEN DO;
		  SOURCE = 'I';
		  IF UCC = '710110'  THEN COST = (COST * 4);
		  IF ((REF_YR = &YEAR) OR (REFYR = &YEAR)); 
          OUTPUT;
		END;

		ELSE IF (PUB_FLAG = '2') THEN DO;
          SOURCE = 'D';
		  COST = (COST * 13);          
		  OUTPUT;
		END;

		ELSE DELETE;
RUN;

PROC SORT DATA=EXPEND;
  BY NEWID;
RUN;



  /*** COMBINE ALL DATA AND WEIGHT EXPNDITURES AND INCOMES ************/

DATA PUBFILE (KEEP= NEWID SOURCE INCLASS UCC RCOST1-RCOST45);
  MERGE FMLY   (IN= INFAM)
        EXPEND (IN= INEXP);
  BY NEWID;
  IF (INEXP AND INFAM);

  IF (COST = .) THEN COST = 0;
	 
     ARRAY REPS_A(45) WTREP01-WTREP44 FINLWT21;
     ARRAY REPS_B(45) RCOST1-RCOST45;

     DO i = 1 TO 45;
	   IF REPS_A(i) > 0
         THEN REPS_B(i) = (REPS_A(i) * COST);
	     ELSE REPS_B(i) = 0; 	
	 END; 
RUN;



  /***************************************************************************/
  /* STEP3: CALCULATE POPULATIONS                                            */
  /* ----------------------------------------------------------------------- */
  /*  SUM ALL 45 WEIGHT VARIABLES TO DERIVE REPLICATE POPULATIONS            */
  /*  FORMATS FOR CORRECT COLUMN CLASSIFICATIONS                             */
  /***************************************************************************/


PROC SUMMARY NWAY DATA=FMLY SUMSIZE=MAX;
  CLASS INCLASS SOURCE / MLF;
  VAR REPWT1-REPWT45;
  FORMAT INCLASS $INC.;
  OUTPUT OUT = POP (DROP = _TYPE_ _FREQ_) SUM = RPOP1-RPOP45;
RUN;

 

  /***************************************************************************/
  /* STEP4: CALCULATE WEIGHTED AGGREGATE EXPENDITURES                        */
  /* ----------------------------------------------------------------------- */
  /*  SUM THE 45 REPLICATE WEIGHTED EXPENDITURES TO DERIVE AGGREGATES/UCC    */
  /*  FORMATS FOR CORRECT COLUMN CLASSIFICATIONS                             */
  /***************************************************************************/


PROC SUMMARY NWAY DATA=PUBFILE SUMSIZE=MAX COMPLETETYPES;
  CLASS SOURCE UCC INCLASS / MLF;
  VAR RCOST1-RCOST45;
  FORMAT INCLASS $INC.;
   OUTPUT OUT= AGG (DROP= _TYPE_ _FREQ_) 
   SUM= RCOST1-RCOST45;
RUN;



  /***************************************************************************/
  /* STEP5: CALCULTATE MEAN EXPENDITURES                                     */
  /* ----------------------------------------------------------------------- */
  /* 1 READ IN POPULATIONS AND LOAD INTO MEMORY USING A 3 DIMENSIONAL ARRAY  */
  /*   POPULATIONS ARE ASSOCIATED BY INCLASS, SOURCE(t), AND REPLICATE(j)    */
  /* 2 READ IN AGGREGATE EXPENDITURES FROM AGG DATASET                       */
  /* 3 CALCULATE MEANS BY DIVIDING AGGREGATES BY CORRECT SOURCE POPULATIONS  */
  /*   EXPENDITURES SOURCED FROM DIARY ARE CALULATED USING DIARY POPULATIONS */
  /*   WHILE INTRVIEW EXPENDITURES USE INTERVIEW POPULATIONS                 */
  /* 4 SUM EXPENDITURE MEANS PER UCC INTO CORRECT LINE ITEM AGGREGATIONS     */
  /***************************************************************************/


DATA AVGS1 (KEEP = SOURCE INCLASS UCC MEAN1-MEAN45);

  /* READS IN POP DATASET. _TEMPORARY_ LOADS POPULATIONS INTO SYSTEM MEMORY  */
  ARRAY POP{01:10,2,45} _TEMPORARY_ ;
  IF _N_ = 1 THEN DO i = 1 TO 20;
    SET POP;
	ARRAY REPS{45} RPOP1--RPOP45;
	IF SOURCE = 'D' THEN t = 1;
	ELSE t = 2;
	  DO j = 1 TO 45;
	    POP{INCLASS,t,j} = REPS{j};
	  END;
	END;

  /* READS IN AGG DATASET AND CALCULATES MEANS BY DIVIDING BY POPULATIONS  */
  SET AGG (KEEP = UCC INCLASS SOURCE RCOST1-RCOST45);
	IF SOURCE = 'D' THEN t = 1;
	ELSE t = 2;
  ARRAY AGGS(45) RCOST1-RCOST45;
  ARRAY AVGS(45) MEAN1-MEAN45;
	DO k = 1 TO 45;
	  IF AGGS(k) = .  THEN AGGS(k) = 0;
	  AVGS(k) = AGGS(k) / POP{INCLASS,t,k};
	END;
RUN;


PROC SUMMARY DATA=AVGS1 NWAY;
  CLASS INCLASS UCC / MLF;
  VAR MEAN1-MEAN45;
  FORMAT UCC $AGGFMT.;
  OUTPUT OUT=AVGS2 (DROP= _TYPE_ _FREQ_  RENAME=(UCC= LINE)) SUM= ;
  /* SUM UCC MEANS TO CREATE AGGREGATION SCHEME */
RUN;


  /***************************************************************************/
  /* STEP6: CALCULTATE STANDARD ERRORS                                       */
  /* ----------------------------------------------------------------------- */
  /*  CALCULATE STANDARD ERRORS USING REPLICATE FORMULA                      */
  /***************************************************************************/


DATA SE (KEEP = INCLASS LINE MEAN SE);
  SET AVGS2;
  ARRAY RMNS(44) MEAN1-MEAN44;
  ARRAY DIFF(44) DIFF1-DIFF44;
    DO i = 1 TO 44;
      DIFF(i) = (RMNS(i) - MEAN45)**2;
    END;
  MEAN = MEAN45;
  SE = SQRT((1/44)*SUM(OF DIFF(*)));
RUN;


  /***************************************************************************/
  /* STEP7: TABULATE EXPENDITURES                                            */
  /* ----------------------------------------------------------------------- */
  /* 1 ARRANGE DATA INTO TABULAR FORM                                        */
  /* 2 SET OUT INTERVIEW POPULATIONS FOR POPULATION LINE ITEM                */
  /* 3 INSERT POPULATION LINE INTO TABLE                                     */
  /* 4 INSERT ZERO EXPENDITURE LINE ITEMS INTO TABLE FOR COMPLETENESS        */
  /***************************************************************************/


PROC SORT DATA=SE;
  BY LINE INCLASS;

PROC TRANSPOSE DATA=SE OUT=TAB1
  NAME = ESTIMATE PREFIX = INCLASS;
  BY LINE;
  VAR MEAN SE;
  /*ARRANGE DATA INTO TABULAR FORM */
RUN;


PROC TRANSPOSE DATA=POP (KEEP = SOURCE RPOP45) OUT=CUS
  NAME = LINE PREFIX = INCLASS;
  VAR RPOP45;
  WHERE SOURCE = 'I';
  /* SET ASIDE POPULATIONS FROM INTERVIEW */
RUN;


DATA TAB2;
  SET CUS TAB1;
  IF LINE = 'RPOP45' THEN DO;
    LINE = '100001';
	ESTIMATE = 'N';
	END;
  /* INSERT POPULATION LINE ITEM INTO TABLE AND ASSIGN LINE NUMBER */
RUN;


DATA TAB;
  MERGE TAB2 STUBFILE;
  BY LINE;
    IF LINE NE '100001' THEN DO;
	  IF SURVEY = 'S' THEN DELETE;
	END;
	ARRAY CNTRL(10) INCLASS1-INCLASS10;
	  DO i = 1 TO 10;
	    IF CNTRL(i) = . THEN CNTRL(i) = 0;
		IF SUM(OF CNTRL(*)) = 0 THEN ESTIMATE = 'MEAN';
	  END;

	IF GROUP IN ('CUCHARS' 'INCOME') THEN DO;
	  IF LAG(LINE) = LINE THEN DELETE;
	END;
  /* MERGE STUBFILE BACK INTO TABLE TO INSERT EXPENDITURE LINES */
  /* THAT HAD ZERO EXPENDITURES FOR THE YEAR                    */
RUN;


PROC TABULATE DATA=TAB;
  CLASS LINE / GROUPINTERNAL ORDER=DATA;
  CLASS ESTIMATE;
  VAR INCLASS1-INCLASS10;
  FORMAT LINE $LBLFMT.;

    TABLE (LINE * ESTIMATE), (INCLASS10 INCLASS1 INCLASS2 INCLASS3 INCLASS4 
                              INCLASS5  INCLASS6 INCLASS7 INCLASS8 INCLASS9) 
    *SUM='' / RTS=25;
    LABEL ESTIMATE=ESTIMATE LINE=LINE
          INCLASS1='LESS THAN $5,000'   INCLASS2='$5,000 TO $9,999' 
          INCLASS3='$10,000 TO $14,999' INCLASS4='$15,000 TO $19,999'
          INCLASS5='$20,000 TO $29,999' INCLASS6='$30,000 TO $39,999'
          INCLASS7='$40,000 TO $49,999' INCLASS8='$50,000 TO $69,999'
          INCLASS9='$70,000 AND OVER'   INCLASS10='ALL CONSUMER UNITS';
	OPTIONS NODATE NOCENTER NONUMBER LS=167 PS=MAX;
	WHERE LINE NE 'OTHER';
    TITLE "INTEGRATED EXPENDITURES FOR &YEAR BY INCOME BEFORE TAXES";
RUN;
