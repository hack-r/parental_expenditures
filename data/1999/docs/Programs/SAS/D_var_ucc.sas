/*NOTE:  THIS PROGRAM WAS WRITTEN USING THE SASDATASETS NOW AVAILABLE ON
         ANOTHER CD-ROM.  IT MUST BE CONVERTED FOR USE WITH THE ASCII
         FILES.
*/
/***                     DIARY                                                ***/
/***   THIS PROGRAM WILL GENERATE THE MEAN, VARIANCE, STANDARD ERROR OF MEAN, ***/
/***   AND COEFFICIENT OF VARIATION FOR DIARY DATA FOR A SPECIFIC UCC.        ***/
/***   ANOTHER PROGRAM EXISTS THAT WILL GENERATE DATA FOR ALL UCC's.          ***/
/***   THE REQUESTED UCC MUST BE ADDED IN THE SECOND LINE BELOW.              ***/


%let y =99;
%let ucc='020110';


libname a "d:\diary&y";

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
      a.dtbd&y.4 (keep=newid ucc amount);
  proc sort; by newid;

data expn;
  set a.expd&y.1 (keep=newid ucc cost )
      a.expd&y.2 (keep=newid ucc cost )
      a.expd&y.3 (keep=newid ucc cost )
      a.expd&y.4 (keep=newid ucc cost );
  if cost > 0;
  proc sort; by newid;


data expend ;
  set dtab expn;
   by newid;
   if ucc=&ucc;
   proc sort; by newid;

   proc datasets; delete dtab expn;


data pubfile (drop= finlwt21 wtrep1-wtrep44 cost) ;
    merge fmlyall (in = infam drop=uspop uspop1-uspop44)
          expend  (in = inexp)
          ;
    by newid ;
    if not inexp then delete;
    if cost='.' then cost=0;

    wtcost  = finlwt21 * cost / 4;
    %macro halfcost;
     %do i=1 %to 44;
      wtcost&i = wtrep&i * cost / 4;
     %end;
    %mend halfcost;
    %halfcost;

    proc summary nway data = pubfile (drop=newid);
     class ucc ;
     var wtcost wtcost1-wtcost44;
     output out = aggcst sum = ;

    proc datasets;
      delete expend pubfile;



data cstpop ;
    if _n_ = 1 then set totpop;
     set aggcst;

       array ex wtcost wtcost1-wtcost44;
       array wt uspop uspop1-uspop44;

       do over ex;
          ex = ex/wt;
       end;

data stats (drop = wtcost1-wtcost44 sse1-sse44) ;
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


data mean;
  set stats (drop = var sem cv);
    stat = 'mean($)';
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

proc print data=complete noobs;
  var stat wtcost;
  title "CE Diary Survey Microdata, Average Weekly Expenditure UCC=&ucc";



 run;
