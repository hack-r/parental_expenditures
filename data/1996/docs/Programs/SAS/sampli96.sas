

%let y =96;

%let y2=%eval(&y+1);


libname a "d:\intrvw&y";
filename agg "d:\intrvw&y\aggi&y..txt";
filename labls "d:\intrvw&y\labeli&y..txt";

options linesize=153 pagesize=52 missing='';



data fmlyall(drop=qintrvmo);
  set a.fmli&y.1x(in=in1 keep=newid finlwt21 inclass qintrvmo)
      a.fmli&y.2 (keep=newid finlwt21 inclass qintrvmo)
      a.fmli&y.3 (keep=newid finlwt21 inclass qintrvmo)
      a.fmli&y.4 (keep=newid finlwt21 inclass qintrvmo)
      a.fmli&y2.1(in=in5 keep=newid finlwt21 inclass qintrvmo);

   if in1 then mo_scope=qintrvmo-1;
   else if in5 then mo_scope=4-qintrvmo;
   else mo_scope=3;

   uspop = finlwt21 * mo_scope/12;
   proc sort; by newid;

   proc summary nway data = fmlyall;
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
    title "Population Counts for 19&y";


data mtab;
  set a.mtbi&y.1x(keep=newid ref_yr ucc cost)
      a.mtbi&y.2 (keep=newid ref_yr ucc cost)
      a.mtbi&y.3 (keep=newid ref_yr ucc cost)
      a.mtbi&y.4 (keep=newid ref_yr ucc cost)
      a.mtbi&y2.1(keep=newid ref_yr ucc cost);
   if ref_yr="19&y";
   proc sort; by newid;

data itab(rename=(value=cost)) ;
  set a.itbi&y.1x(keep=newid refyr ucc value)
      a.itbi&y.2 (keep=newid refyr ucc value)
      a.itbi&y.3 (keep=newid refyr ucc value)
      a.itbi&y.4 (keep=newid refyr ucc value)
      a.itbi&y2.1(keep=newid refyr ucc value);
   if refyr="19&y";
   proc sort; by newid;

data expend (drop=ref_yr refyr);
  set mtab itab;
   by newid;
   if  ucc='710110' then cost=cost*4;
   proc sort; by newid;
   proc datasets; delete mtab itab;


data pubfile;
    merge fmlyall (in = infam drop=mo_scope)
          expend  (in = inexp)
          ;
    by newid ;
    if cost='.' then cost=0;
    wcost = finlwt21 * cost;
    if not inexp then delete;

    proc summary nway data = pubfile;
     class ucc inclass;
     var wcost;
     output out = aggcst sum = wcost;

data aggray1 (drop=inclass  _type_  _freq_ wcost);
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
     infile agg;
       input @3 ucc $6.  @10 gift $1.
             @15 line $6.;
     if gift='2';
     proc sort data = agfile;
     by ucc ;

data pubray ;
     merge aggray1(in = inray)
           agfile (in = inagg);
        by ucc ;
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
     if line='100500' or line='101000' then grpt=grpc;

data addlab;
     infile labls;
     input @1 line $6. @8 title $char40.;

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
     title "CE Microdata Interview Survey Means, for Calendar Year 19&y by Income";
     title2 ' ';


 run;
