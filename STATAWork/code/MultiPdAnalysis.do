*****AA2D Static Analysis*****
clear
set more off, perm
set autotabgraphs on

use "$AA2D_input\DATASETS.dta", clear

gen InstitutionClass=0
replace InstitutionClass=1 if AdvNo<=15
replace InstitutionClass=2 if AdvNo>=16 & AdvNo<=22
replace InstitutionClass=3 if AdvNo>=23 & AdvNo<=30
replace InstitutionClass=4 if AdvNo>=31 & AdvNo<=37
replace InstitutionClass=5 if AdvNo>=38

label define InstitutionClassLabel 1 "IAS" 2 "IFS" 3 "IPS" 4 "RBI" 5 "DU"
label values InstitutionClass InstitutionClassLabel

gen SequenceClass=0
replace SequenceClass=1 if AdvNo>=1 & AdvNo<=9
replace SequenceClass=2 if AdvNo>=10 & AdvNo<=14
replace SequenceClass=3 if AdvNo>=16 & AdvNo<=18
replace SequenceClass=4 if AdvNo>=19 & AdvNo<=22
replace SequenceClass=5 if AdvNo>=23 & AdvNo<=24
replace SequenceClass=6 if AdvNo>=26 & AdvNo<=30
replace SequenceClass=7 if AdvNo>=31 & AdvNo<=36

label define SequenceClassLabel 1 "IAS 2005-13" 2 "IAS 2014-18" 3 "IFS 2011-13" 4 "IFS 2015-18" 5 "IPS 2010-11" 6 "IPS 2014-18" 7 "RBI 2012-17"
label values SequenceClass SequenceClassLabel

drop if SequenceClass==0 //these ads are not part of multi period analysis

gen alphaOBC=0.27 if OBC!=.
replace alphaOBC=0 if OBC==.

gen alphaSC=0.15 if SC!=.
replace alphaSC=0 if SC==.

gen alphaST=0.075 if ST!=.
replace alphaST=0 if ST==.

gen alphaEWS=0.1 if EWS!=.
replace alphaEWS=0 if EWS==.

gen alphaUR= 1-(alphaOBC+alphaSC+alphaST+alphaEWS)

foreach i in UR OBC SC ST EWS{
rename `i' DeptSeats`i'
replace DeptSeats`i'=0 if DeptSeats`i'==.
}

collapse alpha* (sum) DeptSeats*, by(SlNo SequenceClass)


gen DeptSeats=DeptSeatsUR+DeptSeatsOBC+DeptSeatsSC+DeptSeatsST+DeptSeatsEWS

bysort SequenceClass: egen UnivSeats = sum(DeptSeats)

preserve
bysort SequenceClass: egen DeptNo = max(SlNo)
keep if SlNo==DeptNo

latabstat DeptNo DeptSeats UnivSeats, by(SequenceClass) stat(min max mean n) columns(stat) format(%9.1f) nototal
restore

foreach i in UR OBC SC ST EWS{
bysort SequenceClass: egen UnivSeats`i' = sum(DeptSeats`i')
}


foreach i in UR OBC SC ST EWS{
gen DeptFairShare`i'=DeptSeats*alpha`i'
gen DeptFairShareFloor`i'=floor(DeptFairShare`i')
gen DeptFairShareCeiling`i'=ceil(DeptFairShare`i')

gen UnivFairShare`i'=UnivSeats*alpha`i'
gen UnivFairShareFloor`i'=floor(UnivFairShare`i')
gen UnivFairShareCeiling`i'=ceil(UnivFairShare`i')
}


foreach i in UR OBC SC ST EWS{
gen DeptFairShareFloorViolation`i'=0 if alpha`i'!=0
replace DeptFairShareFloorViolation`i'=1 if DeptSeats`i'<DeptFairShareFloor`i' & alpha`i'!=0

gen DeptFairShareCeilingViolation`i'=0 if alpha`i'!=0
replace DeptFairShareCeilingViolation`i'=1 if DeptSeats`i'>DeptFairShareCeiling`i' & alpha`i'!=0

gen DeptFairShareViolation`i'=max(DeptFairShareFloorViolation`i',DeptFairShareCeilingViolation`i') if alpha`i'!=0

gen UnivFairShareFloorViolation`i'=0 if alpha`i'!=0 & SlNo==1
replace UnivFairShareFloorViolation`i'=1 if UnivSeats`i'<UnivFairShareFloor`i' & alpha`i'!=0 & SlNo==1

gen UnivFairShareCeilingViolation`i'=0 if alpha`i'!=0 & SlNo==1
replace UnivFairShareCeilingViolation`i'=1 if UnivSeats`i'>UnivFairShareCeiling`i' & alpha`i'!=0 & SlNo==1

gen UnivFairShareViolation`i'=max(UnivFairShareFloorViolation`i',UnivFairShareCeilingViolation`i') if alpha`i'!=0 & SlNo==1

tabstat DeptFairShareViolation`i', by(SequenceClass) stats(mean n sum p10 p25 p50 p75 p90)
tabstat UnivFairShareViolation`i', by(SequenceClass) stats(mean n sum p10 p25 p50 p75 p90)
}

//keep if InstitutionClass==5
//replace InstitutionClass=6 if Year==2019

//tabstat DeptFairShareViolation* UnivFairShareViolation*, by(InstitutionClass) stat(sum n mean) format(%9.2f)
//tabstat DeptFairShareFloorViolation* UnivFairShareFloorViolation*, by(InstitutionClass) stat(sum n mean) format(%9.2f)
//tabstat DeptFairShareCeilingViolation* UnivFairShareCeilingViolation*, by(InstitutionClass) stat(sum n mean) format(%9.2f)

latabstat DeptFairShareViolation*, by(SequenceClass) stat(sum n mean) columns(stat) format(%9.1f)
latabstat UnivFairShareViolation*, by(SequenceClass) stat(sum n mean) columns(stat) format(%9.1f)


foreach i in UR OBC SC ST EWS{
replace DeptFairShareViolation`i'=0 if DeptFairShareViolation`i'==.
replace UnivFairShareViolation`i'=0 if UnivFairShareViolation`i'==.
bysort SequenceClass: egen AdvDeptFairShareViolation`i' = sum(DeptFairShareViolation`i')
bysort SequenceClass: egen AdvUnivFairShareViolation`i' = max(UnivFairShareViolation`i')
}

gen AdvDeptFairShareViolation=AdvDeptFairShareViolationUR+AdvDeptFairShareViolationOBC+AdvDeptFairShareViolationSC+AdvDeptFairShareViolationST+AdvDeptFairShareViolationEWS
gen AdvUnivFairShareViolation=AdvUnivFairShareViolationUR+AdvUnivFairShareViolationOBC+AdvUnivFairShareViolationSC+AdvUnivFairShareViolationST+AdvUnivFairShareViolationEWS


preserve
collapse AdvDeptFairShareViolation AdvUnivFairShareViolation, by(SequenceClass)

//for Table 4:  MULTI PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat AdvDeptFairShareViolation, by(SequenceClass) stat(mean min max sum n) columns(stat) format(%9.1f)
latabstat AdvUnivFairShareViolation, by(SequenceClass) stat(mean min max sum n) columns(stat) format(%9.1f)
restore


foreach i in UR OBC SC ST EWS{
gen BiasDept`i'= (DeptSeats`i'-DeptFairShare`i') if alpha`i'!=0
gen BiasUniv`i'= (UnivSeats`i'-UnivFairShare`i') if alpha`i'!=0 & SlNo==1
//tabstat BiasDept`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
//tabstat BiasUniv`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
}

tabstat BiasDept* BiasUniv*, by(SequenceClass) stat(mean min max) columns(stats) format(%9.1f) 


foreach i in UR OBC SC ST EWS{
gen BiasViolDept`i'= abs(BiasDept`i'/DeptFairShareViolation`i') if alpha`i'!=0
gen BiasViolUniv`i'= abs(BiasUniv`i'/UnivFairShareViolation`i') if alpha`i'!=0 & SlNo==1
}

tabstat BiasViolDept* BiasViolUniv*, by(SequenceClass) stat(mean min max) format(%9.1f)

preserve
collapse (mean) BiasViolDept* (min) minBiasViolDeptUR=BiasViolDeptUR (min) minBiasViolDeptOBC=BiasViolDeptOBC (min) minBiasViolDeptSC=BiasViolDeptSC (min) minBiasViolDeptST=BiasViolDeptST (min) minBiasViolDeptEWS=BiasViolDeptEWS (max) maxBiasViolDeptUR=BiasViolDeptUR (max) maxBiasViolDeptOBC=BiasViolDeptOBC (max) maxBiasViolDeptSC=BiasViolDeptSC (max) maxBiasViolDeptST=BiasViolDeptST (max) maxBiasViolDeptEWS=BiasViolDeptEWS, by(SequenceClass)

egen BiasViolDept_mean = rowmean(BiasViolDept*)
egen BiasViolDept_min = rowmin(minBiasViolDept*)
egen BiasViolDept_max = rowmax(maxBiasViolDept*)

//for Table 4:  MULTI PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat BiasViolDept_m*, by(SequenceClass) stat(mean) format(%9.1f)
restore


preserve
collapse (mean) BiasViolUniv* (min) minBiasViolUnivUR=BiasViolUnivUR (min) minBiasViolUnivOBC=BiasViolUnivOBC (min) minBiasViolUnivSC=BiasViolUnivSC (min) minBiasViolUnivST=BiasViolUnivST (min) minBiasViolUnivEWS=BiasViolUnivEWS (max) maxBiasViolUnivUR=BiasViolUnivUR (max) maxBiasViolUnivOBC=BiasViolUnivOBC (max) maxBiasViolUnivSC=BiasViolUnivSC (max) maxBiasViolUnivST=BiasViolUnivST (max) maxBiasViolUnivEWS=BiasViolUnivEWS, by(SequenceClass)

egen BiasViolUniv_mean = rowmean(BiasViolUniv*)
egen BiasViolUniv_min = rowmin(minBiasViolUniv*)
egen BiasViolUniv_max = rowmax(maxBiasViolUniv*)

//for Table 4:  MULTI PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat BiasViolUniv_m*, by(SequenceClass) stat(mean) format(%9.1f)
restore


preserve
collapse BiasViolDept* BiasViolUniv*, by(SequenceClass)

egen AdvBiasViolDept_mean = rowmean(BiasViolDept*)
egen AdvBiasViolUniv_mean = rowmean(BiasViolUniv*)

//for Table 4:  MULTI PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat AdvBiasViolDept_mean, by(SequenceClass) stat(mean min max) columns(stat) format(%9.1f)
latabstat AdvBiasViolUniv_mean, by(SequenceClass) stat(mean min max) columns(stat) format(%9.1f)
restore

