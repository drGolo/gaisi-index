********************************************************************************
* SUPPORTING FILE: Create SSC-Based GAISI Indices
* File: create_soc_gaisi.do
* Status: ACTIVE - Supporting data preparation
*
* Purpose:
*   Creates GAISI indices using Standard Skills Classification (SSC) from LLM task-level exposure ratings 

* Method:
*   - Imports task-level ratings (LLM rating, reviewers comments, and adjudicator judgment)
*   - Merges tasks to occupations
*   - Creates multiple GAISI variants (beta, alpha, gamma indices)
*   - Exports to both SOC 2020 and SOC 2010 via crosswalk
*
* Inputs:
*   - GPTs are GPTs: gaisi_classifications_adjudicated.csv (task exposure classifications)
*   - SSC task mappings: sugs_task_description.xlsx
*   - SOC crosswalks: soc2020_to_soc2010.dta
*
* Outputs:
*   - soc2020_4digit_gaisi_ssc.dta (4-digit SOC 2020, SSC-based)
*   - soc2010_4digit_gaisi_ssc.dta (4-digit SOC 2010, SSC-based)
*
*
* Last updated: March 2026
********************************************************************************

*# Setting up Stata
	clear all
	collect clear

	*data directory
	global ses_data "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Felstead - SES 2023\final"
	global aie "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Skills\automation\uk_genai_task_exposure\gaiei_ssc_based\"

	* root 
	cd "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Skills\automation\uk_genai_task_exposure\gaiei_ssc_based\"

	* Add any additional ado paths;
	adopath ++ "C:\Users\utnvghe\OneDrive - University College London\ado"
	adopath ++ "N:\StataMP18"
	
*--------------------------------
**# Load GAISI ratings			|
*--------------------------------
*GAISI
import delimited ".\classification_results\gaisi_classifications_adjudicated.csv", bindquote(strict) varnames(1) clear

duplicates drop sugcode taskid, force
replace taskid="T.15458" if sugcode=="1224/04" & taskid=="T.15428"	
replace taskid="T.19695" if sugcode=="2112/06" & taskid=="T.19692"
replace taskid="T.04349" if sugcode=="2129/09" & taskid=="T.04346"
replace taskid="T.10305" if sugcode=="2212/14" & taskid=="T.10309"
replace taskid="T.13093" if sugcode=="2236/02" & taskid=="T.13097"
replace taskid="T.12552" if sugcode=="2452/03" & taskid=="T.12551"
replace taskid="T.14397" if sugcode=="2469/03" & taskid=="T.14398"
replace taskid="T.16553" if sugcode=="3319/06" & taskid=="T.16533"
replace taskid="T.14380" if sugcode=="3411/03" & taskid=="T.14382"
replace taskid="T.15244" if sugcode=="3412/04" & taskid=="T.15241"
replace taskid="T.08552" if sugcode=="5222/01" & taskid=="T.08554"
replace taskid="T.20390" if sugcode=="6116/02" & taskid=="T.20391"
replace taskid="T.15775" if sugcode=="8119/01" & taskid=="T.15755"
drop if sugcode=="1132/01" & taskid=="T.01320"
drop if sugcode=="2311/00" & taskid=="T.01535"

tempfile gaisi
save `gaisi'

*SUGS to Tasks Map
import excel ".\ssc_tasks\sugs_task_description.xlsx", sheet("Sheet1") firstrow case(lower) allstring clear

destring taskrelatedness, replace
drop sugdescription
tempfile sugs
save `sugs'

*Combine
use `sugs', clear
merge 1:1 sugcode taskid using `gaisi', keep(3) nogen

*Create 
forv i=0/3 {
 g final_e`i'=. 
 replace final_e`i'=adjudicator_e`i' 
 replace final_e`i'=e`i' if missing(final_e`i')
}


*combine E3 & E2
egen aux=rowtotal(final_e2 final_e3), missing
replace final_e2=aux if aux>final_e2 & !missing(final_e2)
drop *e3* aux

*probable E1 and E2
g hi_e1=(final_e1>.5)
g hi_e2=(final_e2>.5)

*Weights
g taskweight=taskrelatedness/100

foreach var of varlist final_* hi_* {
	g w_`var'=`var'*taskweight
}

**# Save task-level exposure scores
compress
save ".\output\ssc_task_level_genai_exposure_score.dta", replace
export delimited ".\output\ssc_task_level_genai_exposure_score.csv", replace


**# SOC 2020 scores
g soc20m=substr(sugcode,1,4)
destring soc20m, replace

preserve
collapse (sum) N=taskweight ///
	E1=w_final_e1 E2=w_final_e2 ///
	hi_E1=w_hi_e1 hi_E2=w_hi_e2, by(soc20m)
	
	g gaisi_beta = (E1+0.5*E2)/N
	g gaisi_alpha = (E1+0*E2)/N
    g gaisi_gamma = (E1+E2)/N
	
	g hi_gaisi = (hi_E1+0.5*hi_E2)/N
	
save ".\output\soc2020_4digit_gaisi_ssc.dta", replace
export delimited  ".\output\soc2020_4digit_gaisi_ssc.csv", replace
restore


**# Export to SOC 2010
merge m:m soc20m using ".\ssc_tasks\soc20_to_soc10_crosswalk.dta"

foreach var of varlist taskweight final_e? {
	replace `var'=`var'*emp_share_rescaled
}

preserve 
g sc2010mg=int(sc2010m/10)
collapse (sum) N=taskweight ///
	E0=w_final_e0 E1=w_final_e1 E2=w_final_e2  ///
	, by(sc2010m sc2010mg)
	
	rename sc2010m soc10m
	g gaisi_beta=(E1+0.5*E2)/N
	
	foreach var of varlist E1 E2 N {
	egen `var'_3d=total(`var'), by(sc2010mg)
	}
	g gaisi_3rd=(E1_3d+0.5*E2_3d)/N_3d
 
 replace gaisi_beta=gaisi_3rd if N<5
drop *_3rd
save ".\output\soc2010_4digit_gaisi_ssc.dta", replace
export delimited ".\output\soc2010_4digit_gaisi_ssc.csv", replace

restore
