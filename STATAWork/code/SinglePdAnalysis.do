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

// keep if InstitutionClass==5 //universities only
// gen Treatment=1
// replace Treatment=2 if Year==2019
// label define TreatmentLabel 1 "Department as Unit" 2 "University as Unit"
// label values Treatment TreatmentLabel

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

gen DeptSeats=DeptSeatsUR+DeptSeatsOBC+DeptSeatsSC+DeptSeatsST+DeptSeatsEWS

bysort AdvNo: egen UnivSeats = sum(DeptSeats)

preserve
bysort AdvNo: egen DeptNo = max(SlNo)
keep if SlNo==DeptNo

//for Table 2: OVERVIEW OF RECRUITMENT ADS
latabstat DeptNo DeptSeats UnivSeats, by(InstitutionClass) stat(min max mean n) columns(stat) format(%9.1f) nototal
restore



foreach i in UR OBC SC ST EWS{
bysort AdvNo: egen UnivSeats`i' = sum(DeptSeats`i')
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

tabstat DeptFairShareViolation`i', by(InstitutionClass) stats(mean n sum p10 p25 p50 p75 p90)
tabstat UnivFairShareViolation`i', by(InstitutionClass) stats(mean n sum p10 p25 p50 p75 p90)
}

//keep if InstitutionClass==5
//replace InstitutionClass=6 if Year==2019

tabstat DeptFairShareViolation* UnivFairShareViolation*, by(InstitutionClass) stat(sum n mean) format(%9.2f)
tabstat DeptFairShareFloorViolation* UnivFairShareFloorViolation*, by(InstitutionClass) stat(sum n mean) format(%9.2f)
tabstat DeptFairShareCeilingViolation* UnivFairShareCeilingViolation*, by(InstitutionClass) stat(sum n mean) format(%9.2f)

latabstat DeptFairShareViolation*, by(InstitutionClass) stat(sum n mean) columns(stat) format(%9.1f)
latabstat UnivFairShareViolation*, by(InstitutionClass) stat(sum n mean) columns(stat) format(%9.1f)


preserve
collapse (mean) DeptFairShareViolation* (mean) UnivFairShareViolation*, by(InstitutionClass AdvNo)

gen alpha2=0.27
gen alpha3=0.15
gen alpha4=0.075
gen alpha1= 1-(alpha2+alpha3+alpha4)

rename DeptFairShareViolationUR DeptFairShareViolation1
rename DeptFairShareViolationOBC DeptFairShareViolation2
rename DeptFairShareViolationSC DeptFairShareViolation3
rename DeptFairShareViolationST DeptFairShareViolation4

rename UnivFairShareViolationUR UnivFairShareViolation1
rename UnivFairShareViolationOBC UnivFairShareViolation2
rename UnivFairShareViolationSC UnivFairShareViolation3
rename UnivFairShareViolationST UnivFairShareViolation4

reshape long DeptFairShareViolation UnivFairShareViolation alpha, i(InstitutionClass AdvNo) j(Category)
drop if AdvNo>=50 //the EWS ads
drop if AdvNo==41 | AdvNo==42
	
//for Figure:  QUOTAVIOLATIONS BY CATEGORY
graph bar DeptFairShareViolation UnivFairShareViolation, over(Category, gap(*0.5) relabel(1 `""UR" "50.5%""' 2 `""OBC" "27%""' 3 `""SC" "15%""' 4 `""ST" "7.5%""')) nooutside ytitle("Fraction of Violations", size(medsmall)) ///
 note("") legend(order(1 "Department Quota" 2 "University Quota") rows(2) position(0) bplacement(neast) size(medsmall) symxsize(*0.6)) ///
 name(ViolationsByCategory, replace) graphregion(color(white) ) xsize(4) ysize(3) bar(1, fcolor(gs15) lcolor(gs15)) bar(2, fcolor(gs11) lcolor(gs11))
graph export "$AA2D_output\ViolationsByCategory.png", replace
graph export "$AA2D_output\ViolationsByCategory.eps", replace
graph export "$AA2D_output\ViolationsByCategory.pdf", replace
graph save "$AA2D_output\ViolationsByCategory", replace
restore


foreach i in UR OBC SC ST EWS{
replace DeptFairShareViolation`i'=0 if DeptFairShareViolation`i'==.
replace UnivFairShareViolation`i'=0 if UnivFairShareViolation`i'==.
bysort AdvNo: egen AdvDeptFairShareViolation`i' = sum(DeptFairShareViolation`i')
bysort AdvNo: egen AdvUnivFairShareViolation`i' = max(UnivFairShareViolation`i')
}

gen AdvDeptFairShareViolation=AdvDeptFairShareViolationUR+AdvDeptFairShareViolationOBC+AdvDeptFairShareViolationSC+AdvDeptFairShareViolationST+AdvDeptFairShareViolationEWS
gen AdvUnivFairShareViolation=AdvUnivFairShareViolationUR+AdvUnivFairShareViolationOBC+AdvUnivFairShareViolationSC+AdvUnivFairShareViolationST+AdvUnivFairShareViolationEWS


preserve
collapse AdvDeptFairShareViolation AdvUnivFairShareViolation, by(InstitutionClass AdvNo)

//for Table 3:  SINGLE PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat AdvDeptFairShareViolation, by(InstitutionClass) stat(mean min max sum n) columns(stat) format(%9.1f)
latabstat AdvUnivFairShareViolation, by(InstitutionClass) stat(mean min max sum n) columns(stat) format(%9.1f)
restore


foreach i in UR OBC SC ST EWS{
gen BiasDept`i'= (DeptSeats`i'-DeptFairShare`i') if alpha`i'!=0
gen BiasUniv`i'= (UnivSeats`i'-UnivFairShare`i') if alpha`i'!=0 & SlNo==1
//tabstat BiasDept`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
//tabstat BiasUniv`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
}

tabstat BiasDept* BiasUniv*, by(InstitutionClass) stat(mean min max) columns(stats) format(%9.1f) 


foreach i in UR OBC SC ST EWS{
gen BiasViolDept`i'= abs(BiasDept`i'/DeptFairShareViolation`i') if alpha`i'!=0
gen BiasViolUniv`i'= abs(BiasUniv`i'/UnivFairShareViolation`i') if alpha`i'!=0 & SlNo==1
}

tabstat BiasViolDept* BiasViolUniv*, by(InstitutionClass) stat(mean min max) format(%9.1f)

preserve
collapse (mean) BiasViolDept* (min) minBiasViolDeptUR=BiasViolDeptUR (min) minBiasViolDeptOBC=BiasViolDeptOBC (min) minBiasViolDeptSC=BiasViolDeptSC (min) minBiasViolDeptST=BiasViolDeptST (min) minBiasViolDeptEWS=BiasViolDeptEWS (max) maxBiasViolDeptUR=BiasViolDeptUR (max) maxBiasViolDeptOBC=BiasViolDeptOBC (max) maxBiasViolDeptSC=BiasViolDeptSC (max) maxBiasViolDeptST=BiasViolDeptST (max) maxBiasViolDeptEWS=BiasViolDeptEWS, by(InstitutionClass)

egen BiasViolDept_mean = rowmean(BiasViolDept*)
egen BiasViolDept_min = rowmin(minBiasViolDept*)
egen BiasViolDept_max = rowmax(maxBiasViolDept*)

//for Table 3:  SINGLE PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat BiasViolDept_m*, by(InstitutionClass) stat(mean) format(%9.1f)
restore


preserve
collapse (mean) BiasViolUniv* (min) minBiasViolUnivUR=BiasViolUnivUR (min) minBiasViolUnivOBC=BiasViolUnivOBC (min) minBiasViolUnivSC=BiasViolUnivSC (min) minBiasViolUnivST=BiasViolUnivST (min) minBiasViolUnivEWS=BiasViolUnivEWS (max) maxBiasViolUnivUR=BiasViolUnivUR (max) maxBiasViolUnivOBC=BiasViolUnivOBC (max) maxBiasViolUnivSC=BiasViolUnivSC (max) maxBiasViolUnivST=BiasViolUnivST (max) maxBiasViolUnivEWS=BiasViolUnivEWS, by(InstitutionClass)

egen BiasViolUniv_mean = rowmean(BiasViolUniv*)
egen BiasViolUniv_min = rowmin(minBiasViolUniv*)
egen BiasViolUniv_max = rowmax(maxBiasViolUniv*)

//for Table 3:  SINGLE PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat BiasViolUniv_m*, by(InstitutionClass) stat(mean) format(%9.1f)
restore


preserve
collapse BiasViolDept* BiasViolUniv*, by(InstitutionClass)

egen AdvBiasViolDept_mean = rowmean(BiasViolDept*)
egen AdvBiasViolUniv_mean = rowmean(BiasViolUniv*)

//for Table 3:  SINGLE PERIOD QUOTA VIOLATIONS – STATISTICS
latabstat AdvBiasViolDept_mean, by(InstitutionClass) stat(mean min max) columns(stat) format(%9.1f)
latabstat AdvBiasViolUniv_mean, by(InstitutionClass) stat(mean min max) columns(stat) format(%9.1f)
restore


/*
preserve
foreach i in UR OBC SC ST EWS{
replace BiasViolUniv`i'=BiasViolUniv`i'/6 if InstitutionClass==4
}

graph box BiasViolDept*, over(InstitutionClass) nooutside capsize(3) ytitle("Bias") note("") legend(order(1 "UR" 2 "OBC" 3 "SC" 4 "ST" 5 "EWS") rows(1)) yline(0, lcolor(gs11)) name(BoxPlot1, replace) graphregion(color(white) margin(zero)) xsize(9) 
graph export "$AA2D_output\BoxPlotDeptBias.png", replace
graph export "$AA2D_output\BoxPlotDeptBias.eps", replace
graph export "$AA2D_output\BoxPlotDeptBias.pdf", replace
graph save "$AA2D_output\BoxPlotDeptBias", replace

graph box BiasViolUniv*, over(InstitutionClass) nooutside capsize(3) ytitle("Bias") note("") legend(order(1 "UR" 2 "OBC" 3 "SC" 4 "ST" 5 "EWS") rows(1)) yline(0, lcolor(gs11)) name(BoxPlot2, replace) graphregion(color(white) margin(zero)) xsize(9) 
graph export "$AA2D_output\BoxPlotUnivBias.png", replace
graph export "$AA2D_output\BoxPlotUnivBias.eps", replace
graph export "$AA2D_output\BoxPlotUnivBias.pdf", replace
graph save "$AA2D_output\BoxPlotUnivBias", replace
restore
