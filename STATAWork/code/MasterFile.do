global AA2D "C:\Users\khann\Downloads\103\STATAWork"

global AA2D_code "$AA2D/code"
global AA2D_input "$AA2D/input"
global AA2D_output "$AA2D/output"
global AA2D_temp "$AA2D/temp"

clear all
set autotabgraphs on
set more off, perm

cd	"$AA2D"

//uncomment to install the following packages
//ssc install rowsort, replace
//ssc install estout, replace
//ssc install cibar, replace
//ssc install coefplot, replace

//comment whichever file you don't want to run. results will get saved in the output folder.

do "$AA2D_code/StaticAnalysis.do"



//import excel "$AA2D_input\DATASETS.xlsx", sheet("Sheet1") firstrow
//save "$AA2D_input\DATASETS.dta", replace


