*****AA2D Static Analysis*****
clear
set more off, perm
set autotabgraphs on
save "$AA2D_output\MultiPdSim.dta", emptyok replace

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

keep if SequenceClass==1 //other ads are not part of the simulation

gen alphaOBC=0.27 if OBC!=.
replace alphaOBC=0 if OBC==.

gen alphaSC=0.15 if SC!=.
replace alphaSC=0 if SC==.

gen alphaST=0.075 if ST!=.
replace alphaST=0 if ST==.

gen alphaUR= 1-(alphaOBC+alphaSC+alphaST)

foreach i in UR OBC SC ST{
rename `i' DeptSeats`i'
replace DeptSeats`i'=0 if DeptSeats`i'==.
}


forvalues j = 1(1)9{
preserve
keep if AdvNo<=`j'
egen T = max(Year)


collapse T alpha* (sum) DeptSeats*, by(SlNo)
gen Simulation=0

gen DeptSeats=DeptSeatsUR+DeptSeatsOBC+DeptSeatsSC+DeptSeatsST

egen UnivSeats = sum(DeptSeats)

foreach i in UR OBC SC ST{
egen UnivSeats`i' = sum(DeptSeats`i')
}


foreach i in UR OBC SC ST{
gen DeptFairShare`i'=DeptSeats*alpha`i'
gen DeptFairShareFloor`i'=floor(DeptFairShare`i')
gen DeptFairShareCeiling`i'=ceil(DeptFairShare`i')

gen UnivFairShare`i'=UnivSeats*alpha`i'
gen UnivFairShareFloor`i'=floor(UnivFairShare`i')
gen UnivFairShareCeiling`i'=ceil(UnivFairShare`i')
}


foreach i in UR OBC SC ST{
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
}

foreach i in UR OBC SC ST{
replace DeptFairShareViolation`i'=0 if DeptFairShareViolation`i'==.
replace UnivFairShareViolation`i'=0 if UnivFairShareViolation`i'==.
egen AdvDeptFairShareViolation`i' = sum(DeptFairShareViolation`i')
egen AdvUnivFairShareViolation`i' = max(UnivFairShareViolation`i')
}

gen AdvDeptFairShareViolation=AdvDeptFairShareViolationUR+AdvDeptFairShareViolationOBC+AdvDeptFairShareViolationSC+AdvDeptFairShareViolationST
gen AdvUnivFairShareViolation=AdvUnivFairShareViolationUR+AdvUnivFairShareViolationOBC+AdvUnivFairShareViolationSC+AdvUnivFairShareViolationST


foreach i in UR OBC SC ST{
gen BiasDept`i'= (DeptSeats`i'-DeptFairShare`i') if alpha`i'!=0
gen BiasUniv`i'= (UnivSeats`i'-UnivFairShare`i') if alpha`i'!=0 & SlNo==1
//tabstat BiasDept`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
//tabstat BiasUniv`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
}

tabstat BiasDept* BiasUniv*, stat(mean min max) columns(stats) format(%9.1f) 


foreach i in UR OBC SC ST{
gen BiasViolDept`i'= (BiasDept`i') if alpha`i'!=0
gen BiasViolUniv`i'= (BiasUniv`i') if alpha`i'!=0 & SlNo==1
}



keep T SlNo Simulation AdvDeptFairShareViolation AdvUnivFairShareViolation BiasViolDept* BiasViolUniv*

append using "$AA2D_output\MultiPdSim.dta"

save "$AA2D_output\MultiPdSim.dta", replace
drop T
restore
}


forvalues k = 1(1)50{
	clear
	import excel "$AA2D_input\Simulation\Simulation`k'.xls", sheet("Sheet1") firstrow

	drop alpha*

	gen alphaOBC=0.27 if DeptSeatsOBC!=.
	replace alphaOBC=0 if DeptSeatsOBC==.

	gen alphaSC=0.15 if DeptSeatsSC!=.
	replace alphaSC=0 if DeptSeatsSC==.

	gen alphaST=0.075 if DeptSeatsST!=.
	replace alphaST=0 if DeptSeatsST==.

	gen alphaUR= 1-(alphaOBC+alphaSC+alphaST)

	forvalues j = 1(1)9{
		preserve
		keep if AdvNo<=`j'
		egen T = max(Year)


		collapse T alpha* (sum) DeptSeats*, by(SlNo)
		gen Simulation=`k'

		egen UnivSeats = sum(DeptSeats)

		foreach i in UR OBC SC ST{
		egen UnivSeats`i' = sum(DeptSeats`i')
		}


		foreach i in UR OBC SC ST{
		gen DeptFairShare`i'=DeptSeats*alpha`i'
		gen DeptFairShareFloor`i'=floor(DeptFairShare`i')
		gen DeptFairShareCeiling`i'=ceil(DeptFairShare`i')

		gen UnivFairShare`i'=UnivSeats*alpha`i'
		gen UnivFairShareFloor`i'=floor(UnivFairShare`i')
		gen UnivFairShareCeiling`i'=ceil(UnivFairShare`i')
		}


		foreach i in UR OBC SC ST{
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
		}

		foreach i in UR OBC SC ST{
		replace DeptFairShareViolation`i'=0 if DeptFairShareViolation`i'==.
		replace UnivFairShareViolation`i'=0 if UnivFairShareViolation`i'==.
		egen AdvDeptFairShareViolation`i' = sum(DeptFairShareViolation`i')
		egen AdvUnivFairShareViolation`i' = max(UnivFairShareViolation`i')
		}

		gen AdvDeptFairShareViolation=AdvDeptFairShareViolationUR+AdvDeptFairShareViolationOBC+AdvDeptFairShareViolationSC+AdvDeptFairShareViolationST
		gen AdvUnivFairShareViolation=AdvUnivFairShareViolationUR+AdvUnivFairShareViolationOBC+AdvUnivFairShareViolationSC+AdvUnivFairShareViolationST


		foreach i in UR OBC SC ST{
		gen BiasDept`i'= (DeptSeats`i'-DeptFairShare`i') if alpha`i'!=0
		gen BiasUniv`i'= (UnivSeats`i'-UnivFairShare`i') if alpha`i'!=0 & SlNo==1
		//tabstat BiasDept`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
		//tabstat BiasUniv`i', by(Institution) stats(mean p10 p25 p50 p75 p90)
		}

		tabstat BiasDept* BiasUniv*, stat(mean min max) columns(stats) format(%9.1f) 


		foreach i in UR OBC SC ST{
		gen BiasViolDept`i'= (BiasDept`i') if alpha`i'!=0
		gen BiasViolUniv`i'= (BiasUniv`i') if alpha`i'!=0 & SlNo==1
		}



		keep T SlNo Simulation AdvDeptFairShareViolation AdvUnivFairShareViolation BiasViolDept* BiasViolUniv*

		append using "$AA2D_output\MultiPdSim.dta"

		save "$AA2D_output\MultiPdSim.dta", replace
		drop T
		restore
	}
}

clear
use "$AA2D_output\MultiPdSim.dta", clear

collapse Adv* Bias*, by(T Simulation SlNo)

gen ActualData=0
replace ActualData=1 if Simulation==0

label define DataLabel 0 "Proposed Solution" 1 "Existing Solution"
label values ActualData DataLabel

gen alpha2=0.27
gen alpha3=0.15
gen alpha4=0.075
gen alpha1= 1-(alpha2+alpha3+alpha4)

rename BiasViolDeptUR BiasViolDept1
rename BiasViolDeptOBC BiasViolDept2
rename BiasViolDeptSC BiasViolDept3
rename BiasViolDeptST BiasViolDept4

rename BiasViolUnivUR BiasViolUniv1
rename BiasViolUnivOBC BiasViolUniv2
rename BiasViolUnivSC BiasViolUniv3
rename BiasViolUnivST BiasViolUniv4

reshape long BiasViolDept BiasViolUniv alpha, i(T Simulation SlNo) j(Category)

//Figure 7:  COMPARISON OF PROPOSED AND EXISTING SOLUTION
graph box BiasViolDept, over(T) by(ActualData, note("")) scheme(s1mono) nooutside note("") intensity(0) medtype(cline) medline(lpattern(long dash) lcolor(gs7)) graphregion(color(white) margin(zero)) subtitle(,bcolor(white) size(large)) xsize(8) ylabel(-8(4)8) ytitle("Department Bias",  size(medium)) name(a3, replace)
graph export "$AA2D_output\DepartmentBias.png", replace
graph export "$AA2D_output\DepartmentBias.eps", replace
graph export "$AA2D_output\DepartmentBias.pdf", replace
graph save "$AA2D_output\DepartmentBias", replace

graph box BiasViolUniv, over(T) by(ActualData, note("")) scheme(s1mono) nooutside note("") intensity(0) medtype(cline) medline(lpattern(long dash) lcolor(gs7)) graphregion(color(white) margin(zero)) subtitle(,bcolor(white) size(large)) xsize(8) ylabel(-30(15)30) ytitle("University Bias", size(medium)) name(a4, replace)
graph export "$AA2D_output\UniversityBias.png", replace
graph export "$AA2D_output\UniversityBias.eps", replace
graph export "$AA2D_output\UniversityBias.pdf", replace
graph save "$AA2D_output\UniversityBias", replace

