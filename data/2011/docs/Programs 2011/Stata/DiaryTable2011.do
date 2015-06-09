

set memory 200m

cd C:\2011_CEX\PROGRAMS
infix  str type 1  str agglvl 4  str title 7-69  ///
       str ucc 70-75  str survey 80  str group 86-93  ///
       str publvl 99  using Dstub2011.txt
	keep if type=="1"
	drop if group=="ADDENDA"
	format title %-63s

cd C:\2011_CEX\Diary11

save stubfile

generate count = (_n+9999)
generate line = string(count) + agglvl
	generate line1=line if ucc>"A" & substr(line,6,1)=="1"
	generate line2=line if ucc>"A" & substr(line,6,1)=="2"
	generate line3=line if ucc>"A" & substr(line,6,1)=="3"
	generate line4=line if ucc>"A" & substr(line,6,1)=="4"
	generate line5=line if ucc>"A" & substr(line,6,1)=="5"
	generate line6=line if ucc <= "A"
sort line
save aggfile1

keep title line
save lblfile

use aggfile1
	keep line ucc
	sort line
save l

use aggfile1
	keep if line1 > " "
	keep line line1
save l1

use aggfile1
	keep if line2 > " "
	keep line line2
save l2

use aggfile1
	keep if line3 > " "
	keep line line3
save l3

use aggfile1
	keep if line4 > " "
	keep line line4
save l4

use aggfile1
	keep if line5 > " "
	keep line line5
save l5

use aggfile1
	keep if line6 > " "
	keep ucc line line6
	sort line
save l6

use l
	cross using l1
	drop if line1 > line
	gsort +line -line1
	duplicates drop line, force
save c1

cross using l2
	drop if line2 > line
	gsort +line -line2
	duplicates drop line, force
save c2

cross using l3
	drop if line3 > line
	gsort +line -line3
	duplicates drop line, force
save c3

cross using l4
	drop if line4 > line
	gsort +line -line4
	duplicates drop line, force
save c4

cross using l5
	drop if line5 > line
	gsort +line -line5
	duplicates drop line, force
save c5

use l
merge line using c1 c2 c3 c4 c5 l6, sort
	drop _merge* line
	drop if line6==""
sort ucc

stack  ucc line6 line1  ucc line6 line2  ucc line6 line3  ///
       ucc line6 line4  ucc line6 line5  ucc line6 line6  ///
       ,into(ucc compare line)  clear
drop if line==""

keep if substr(compare,6,1) > substr(line,6,1) | compare==line
	sort ucc line
	drop _stack compare
save aggfile


use fmld111
keep newid finlwt21 inclass
	append using fmld112, keep(newid finlwt21 inclass)
	append using fmld113, keep(newid finlwt21 inclass)
	append using fmld114, keep(newid finlwt21 inclass)
generate weight=finlwt21/4
sort newid
describe
list newid inclass finlwt21 weight in 1/15, divider
save fmly

use dtbd111
keep newid ucc amount
	append using dtbd112, keep(newid ucc amount)
	append using dtbd113, keep(newid ucc amount)
	append using dtbd114, keep(newid ucc amount)
rename amount cost
	append using expd111, keep(newid ucc cost)
	append using expd112, keep(newid ucc cost)
	append using expd113, keep(newid ucc cost)
	append using expd114, keep(newid ucc cost)
sort newid
describe
list newid ucc cost in 1/15, divider
save expend

use fmly
	joinby newid using expend, unmatched(using)
generate wtcost=cost*weight
sort ucc
describe
list newid inclass ucc weight cost wtcost in 1/15, divider
save tabdata

use fmly
	statsby pops=r(sum), saving(pops1) by(inclass, missing) nodots: sum weight

use pops1
      gen _varname="pop"+inclass
      drop inclass
      xpose, clear varname
      egen pop10=rsum(pop01-pop09)
      xpose, clear varname
      gen inclass=substr(_varname,4,2)
      drop _varname
save pops

use tabdata
	statsby aggs=r(sum), saving(agg1) by(inclass ucc, missing) nodots: sum wtcost

use agg1
      reshape wide aggs, i(ucc) j(inclass) string
      egen aggs10=rsum(aggs01-aggs09)
      reshape long aggs, i(ucc) j(inclass) string
save agg2

use pops
	joinby inclass using agg2, unmatched(using)
	generate uccmean=aggs/pops
	format pops aggs uccmean %16.2g
describe
list inclass ucc pops aggs uccmean in 1/15, divider
	sort inclass ucc
	keep inclass ucc uccmean
save tab1

reshape wide uccmean, i(ucc) j(inclass) string
save tab2

merge ucc using aggfile
	keep if _merge==3
	drop _merge
	sort line
		by line, sort: egen Inclass01 = sum(uccmean01)
		by line, sort: egen Inclass02 = sum(uccmean02)
		by line, sort: egen Inclass03 = sum(uccmean03)
		by line, sort: egen Inclass04 = sum(uccmean04)
		by line, sort: egen Inclass05 = sum(uccmean05)
		by line, sort: egen Inclass06 = sum(uccmean06)
		by line, sort: egen Inclass07 = sum(uccmean07)
		by line, sort: egen Inclass08 = sum(uccmean08)
		by line, sort: egen Inclass09 = sum(uccmean09)
		by line, sort: egen Inclass10 = sum(uccmean10)
	drop ucc uccmean*
	duplicates drop line, force
save tab

use lblfile
merge line using tab
	keep if _merge==3
		format Inclass01 %10.2fc
		format Inclass02 %10.2fc
		format Inclass03 %10.2fc
		format Inclass04 %10.2fc
		format Inclass05 %10.2fc
		format Inclass06 %10.2fc
		format Inclass07 %10.2fc
		format Inclass08 %10.2fc
		format Inclass09 %10.2fc
		format Inclass10 %10.2fc
		label variable Inclass01 "Less than $5,000"
		label variable Inclass02 "$5,000 to $9,999"
		label variable Inclass03 "$10,000 to $14,999"
		label variable Inclass04 "$15,000 to $19,999"
		label variable Inclass05 "$20,000 to $29,000"
		label variable Inclass06 "$30,000 to $39,999"
		label variable Inclass07 "$40,000 to $49,999"
		label variable Inclass08 "$50,000 to $69,999"
		label variable Inclass09 "$70,000 and over"
		label variable Inclass10 "Incomplete Reporters"
		label variable title "Item"
	drop line _merge
save DiaryTable

outsheet  title Inclass01 Inclass02 Inclass03 Inclass04 Inclass05 ///
                Inclass06 Inclass07 Inclass08 Inclass09 Inclass10 ///
          using DiaryTable, noquote
