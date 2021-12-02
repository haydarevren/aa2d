clear
set more off, perm
set autotabgraphs on

use "$AA2D_input\DATASETS.dta", clear



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



keep if AdvNo<=9

keep Year AdvNo SlNo DeptSeats* alpha*

drop alphaEWS DeptSeatsEWS


export excel using "$AA2D_output\DataForSim.xls", firstrow(variables) replace
