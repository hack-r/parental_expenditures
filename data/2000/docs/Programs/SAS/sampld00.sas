%let y =00;

libname a      "d:\diary&y";
filename agg   "d:\diary&y\aggd&y..txt";
filename labls "d:\diary&y\labeld&y..txt";



options linesize=153 pagesize=52 missing='';



data fmlyall;
   set a.fmld&y.1 (keep=newid finlwt21 inclass)
       a.fmld&y.2 (keep=newid finlwt21 inclass)
       a.fmld&y.3 (keep=newid finlwt21 inclass)
       a.fmld&y.4 (keep=newid finlwt21 inclass) ;
      by newid;

   uspop  = finlwt21 / 4;
   proc sort; by newid;

   proc summary nway data = fmlyall (drop=finlwt21);
       class inclass;
       var uspop;
       output out = newpop sum = popus;
   proc transpose data = newpop out = transpop prefix = pop;
       var popus;

data subagg (drop = _name_);
     set transpop;
      popt = sum (of pop1-pop10);
      popc = sum (of pop1-pop9);
     proc print data=subagg;
     title "Population Counts for 20&y";


data dtab(rename=(amount=cost));
   set a.dtbd&y.1 (keep=newid ucc amount)
       a.dtbd&y.2 (keep=newid ucc amount)
       a.dtbd&y.3 (keep=newid ucc amount)
       a.dtbd&y.4 (keep=newid ucc amount) ;
     by newid;
   proc sort; by newid;

data expn;
   set a.expd&y.1 (keep=newid ucc cost)
       a.expd&y.2 (keep=newid ucc cost)
       a.expd&y.3 (keep=newid ucc cost)
       a.expd&y.4 (keep=newid ucc cost) ;
     by newid;
   if cost > 0;
   proc sort; by newid;


data expend ;
  set dtab expn;
   by newid;
   proc sort; by newid;
   proc datasets; delete dtab expn;

data pubfile (drop= uspop) ;
    merge fmlyall (in = infam)
          expend  (in = inexp)
          ;
    by newid ;
    if not inexp then delete;
    if cost='.' then cost=0;

    wcost  = finlwt21 * cost/4;

    proc summary nway data = pubfile (drop=newid);
     class ucc inclass;
     var wcost ;
     output out = aggcst sum = ;

    proc datasets;
      delete expend pubfile;

data aggray1 (drop =  inclass  _type_  _freq_ wcost);
  set aggcst;
   by ucc ;
      array trncost grp1-grp10;
       retain grp1-grp10;
        if first.ucc then do over trncost;
            trncost = 0;
        end;
        _I_=inclass;
        trncost=wcost;
        if last.ucc then output;

data agfile;
     infile agg missover pad;
       input @3 ucc $6.
             @15 line $6.;
     proc sort data = agfile;
     by ucc ;

data pubray ;
     merge aggray1 (in = inray)
           agfile (in = inagg);
        by ucc;
     if inray and inagg;

     proc summary nway data = pubray;
       class line;
       var grp1-grp10;
       output out =aggsum sum = ;

data cstpop1 (drop = _type_ _freq_ popt popc pop1-pop10);
     if _n_ = 1 then set subagg;
     set aggsum;
       grpt = sum (of grp1-grp10);
       grpc = sum (of grp1-grp9);
     array ex grpt grpc grp1-grp10;
     array wt popt popc pop1-pop10;
      do over ex;
        ex = ex/wt;
      end;

data numcus (rename=(popt=grpt popc=grpc pop1=grp1 pop2=grp2
                     pop3=grp3 pop4=grp4 pop5=grp5 pop6=grp6
                     pop7=grp7 pop8=grp8 pop9=grp9 pop10=grp10));
     set subagg;
     line = '000000';

data cstpop;
     set numcus cstpop1;
       by line;

data addlab ;
     infile labls missover pad;
     input @1 line $6. @10 title $char40.;
     proc sort; by line;

data pubtab (drop = line);
     merge cstpop (in = inline)
           addlab (in = inlabl);
     by line;
     if not inlabl then delete;

     proc print split='*' uniform;
      label
      grpt='      All* Consumer*    Units*_________'
      grpc='    Total* Complete*Reporting*_________'
      grp1='     Less*     Than*   $5,000*_________'
      grp2='   $5,000*       To*   $9,999*_________'
      grp3='  $10,000*       To*  $14,999*_________'
      grp4='  $15,000*       To*  $19,999*_________'
      grp5='  $20,000*       To*  $29,999*_________'
      grp6='  $30,000*       To*  $39,999*_________'
      grp7='  $40,000*       To*  $49,999*_________'
      grp8='  $50,000*       To*  $69,999*_________'
      grp9='  $70,000*      And*     Over*_________'
     grp10='Incomplete*  Income*Reporters*_________';
     format title $char40.;
     format grpt grpc grp1-grp10 comma9.2;
     id title;
     var grpc grp1-grp9;
     title "CE Microdata Diary Survey Average Weekly Expenditures, for Calendar Year 20&y by Income";
     title2 ' ';

 run;
