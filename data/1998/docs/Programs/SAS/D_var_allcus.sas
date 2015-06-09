/*NOTE:  THIS PROGRAM WAS WRITTEN USING THE SASDATASETS NOW AVAILABLE
         ON ANOTHER CD-ROM.  IT MUST BE CONVERTED FOR USE WITH THE
         ASCII FILES.
*/
/***                                DIARY                                       ***/
/***   THIS PROGRAM WILL GENERATE MEANS, VARIANCES, STANDARD ERROR OF MEANS,    ***/
/***   AND COEFFICIENT OF VARIATIONS FOR DIARY DATA AT THE PUBLISHED LEVEL      ***/
/***   FOR ALL CU'S.                                                            ***/
/***                                                                            ***/
/***   THE AMOUNT OF DATA RUN MAY BE TOO MUCH FOR SOME PC SYSTEMS.  IT MAY BE   ***/
/***   NECESSARY TO RUN THIS FOR SPECIFIC UCC'S ONLY.  (ANOTHER PROGRAM HAS     ***/
/***   BEEN INCLUDED ON THE CD-ROM WHICH GENERATES THIS DATA FOR A PARTICULAR   ***/
/***   UCC ONLY)                                                                ***/


%let y =98;

libname a "d:\diary&y";
filename pubagg "d:\diary&y\aggd&y..txt";
filename labls  "d:\diary&y\labeld&y..txt";


options linesize=153 pagesize=55 missing='' ;



data fmlyall(keep=newid finlwt21 wtrep1-wtrep44 uspop uspop1-uspop44);
  set a.fmld&y.1 (keep=newid finlwt21 wtrep01-wtrep44)
      a.fmld&y.2 (keep=newid finlwt21 wtrep01-wtrep44)
      a.fmld&y.3 (keep=newid finlwt21 wtrep01-wtrep44)
      a.fmld&y.4 (keep=newid finlwt21 wtrep01-wtrep44);

   uspop  = finlwt21 / 4;
   wtrep1 = wtrep01 ;
   wtrep2 = wtrep02 ;
   wtrep3 = wtrep03 ;
   wtrep4 = wtrep04 ;
   wtrep5 = wtrep05 ;
   wtrep6 = wtrep06 ;
   wtrep7 = wtrep07 ;
   wtrep8 = wtrep08 ;
   wtrep9 = wtrep09 ;
   %macro halfpops;
     %do i=1 %to 44;
       uspop&i = wtrep&i / 4;
     %end;
   %mend halfpops;
   %halfpops;
   proc sort; by newid;

   proc summary nway data = fmlyall (drop = finlwt21 wtrep1-wtrep44);
      var uspop uspop1-uspop44;
      output out = totpop sum = ;

data dtab (rename=(amount=cost)) ;
  set a.dtbd&y.1 (keep=newid ucc amount)
      a.dtbd&y.2 (keep=newid ucc amount)
      a.dtbd&y.3 (keep=newid ucc amount)
      a.dtbd&y.4 (keep=newid ucc amount) ;
  proc sort; by newid;
data expn;
  set a.expd&y.1 (keep=newid ucc cost)
      a.expd&y.2 (keep=newid ucc cost)
      a.expd&y.3 (keep=newid ucc cost)
      a.expd&y.4 (keep=newid ucc cost) ;
  if cost > 0;
  proc sort; by newid;


data expend ;
  set dtab expn;
   by newid;
   proc sort; by newid;

   proc datasets; delete dtab expn;

data pubfile (drop= wtrep1-wtrep44 finlwt21 cost);
    merge fmlyall (in = infam drop=uspop uspop1-uspop44 )
          expend  (in = inexp)
          ;
    by newid ;

    if not inexp then delete;
    if cost='.' then cost=0;

    wtcost  = finlwt21 * cost/4;
    %macro halfcost;
     %do i=1 %to 44;
      wtcost&i = wtrep&i * cost/4;
     %end;
    %mend halfcost;
    %halfcost;

    proc summary nway data = pubfile (drop=newid);
     class ucc ;
     var wtcost wtcost1-wtcost44;
     output out = aggcst sum = ;

    proc datasets;
      delete expend pubfile;

data agfile;
     infile pubagg;
       input @3 ucc $6.
             @15 line $6.;
     proc sort data = agfile;
     by ucc ;

data pubray ;
   merge aggcst (in = incst)
         agfile (in = inag);
     by ucc ;
     if not incst then delete;
     if not inag then delete;
     proc summary nway data = pubray;
       class line;
       var wtcost wtcost1-wtcost44;
     output out =aggsum sum = ;

     proc datasets; delete pubray;

data cstpop ;
    if _n_ = 1 then set totpop;
      set aggsum;

       array ex wtcost wtcost1-wtcost44;
       array wt uspop uspop1-uspop44;

       do over ex;
          ex = ex/wt;
       end;

data stats (drop = wtcost1-wtcost44 ) ;
  set cstpop (drop=uspop uspop1-uspop44);

  %macro sse;
    %do i = 1 %to 44;
      sse&i  = (wtcost&i-wtcost)**2;
    %end;
  %mend sse;
  %sse;

  sse = sum (of sse1-sse44);
  var = sse / 44;
  sem = var**.5;
  cv  = 100 * sem / wtcost;

  proc sort;
    by line ;


data mean;
  set stats (drop = var sem cv);
    if '002009' le line le '002024' then stat='percent';
    else if '002002' le line le '002008' then stat='mean';
    else if line='000000' then stat='';
    else stat = 'mean($)';
    n = _n_;

data var  (rename=(var=wtcost));
  set stats (drop = wtcost sem cv);
    stat = 'var';
    n = _n_;

data sem  (rename=(sem=wtcost));
  set stats (drop = wtcost var cv);
    stat = 'se';
    n = _n_;

data cv  (rename=(cv=wtcost));
  set stats (drop = wtcost sem var);
    stat = 'cv(%)';
    n = _n_;

data complete;
  length stat $7. ;
  set mean var sem cv ;
    by n;

data addlab;
     infile labls;
     input @1 line $6. @10 title $char40.;
     proc sort data=addlab;
      by line;

data pubtab (drop=line);
     merge complete (in = inline)
           addlab (in = inlabl);
     by line;
     if inlabl and inline;
     if title=lag(title) then title = '';

     proc print split='*' uniform;
       label
       wtcost='      All* Consumer*    Units*_________';
       format title $char40.;
       format wtcost comma10.2;
       id title;
       var stat wtcost ;
       title "CE Diary Survey Means, Variances, Standard Error of Means, and Coefficient of Variation";
       title2 "for Calendar Year 19&y";
       title3 ' ';
       title4 ' ';


 run;
