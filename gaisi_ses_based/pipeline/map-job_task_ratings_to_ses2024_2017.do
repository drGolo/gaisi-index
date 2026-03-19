/*
The code loads SES 2024 file
It reshapes into long format with individual-occupation-task cells and importance ratings for each task
It merges the LLM derived exposure probabilities at occupation-task level into the SES files
It weights those probabilities with task importance (weight =1 for essentials, etc)
It computes a task-importance weighted average probability of AI exposure categories (E0, E1, E2) by workers 
IT sotres the probabilites into a survey_ID probabilities_E? file
*/
*# Setting up Stata
	clear all
	collect clear
	
	* root 
	cd "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Skills\automation\uk_genai_task_exposure\gaiei_ses_based"

	*data directory
	global ses_2023 "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Felstead - SES 2023\final\"
	global ses_2017 "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Felstead - SES 2017\ses_2017\"

	* Add any additional ado paths;
	adopath ++ "C:\Users\utnvghe\OneDrive - University College London\ado"
	adopath ++ "N:\StataMP18"
	
*------------------------------------
**# Load Gemini 1.5 exposure ratings
*-----------------------------------
use "./output/job_task_level_exposure_scores.dta" if model==1 //keep gemini ratings
collapse (mean) E? , by(occupation_code task_handle)
tempfile gem_ratings
save `gem_ratings'	
	
*------------------------------------
**# Load SES 2023-24				|
*------------------------------------
use "${ses_2023}\P16561-SES-F2F-Panel-Combined UK + quals + pay.dta", clear
drop if b2soc10>=.

*drop non-essential variables
keep serial_scrambled b2soc10 c*
drop cacce cnoac cnoac_oth
drop cusepc- cdigtasks4
rename cstrengt cstrength

*Impute missing task valus
replace cstats=5 if ccalca==5 & cpercent==5
replace clong=5 if cshort==5 & cread==5
replace cwritelg=5 if cwrite==5 & cwritesh==5

*Reshape into a long file
rename c* importance_c*
reshape long importance_, i(serial_scrambled b2soc10) j(task_handle) string
rename (importance_ b2soc10) (importance occupation_code)

*Merge in Gem 1.5 Pro AI Exposure classification
merge m:1 task_handle occupation_code using `gem_ratings', keep(1 3) nogen

* rescale importance
gen imp01=(5-importance)/4
replace imp01=.i if imp01==0
 
*compute importance weighted AI exposure

*Combine E3 with E2
replace E2 = E2 + E3
drop E3

*Weight task-level exposure and aggregate
foreach var of varlist E0 E1 E2 {
	g `var'_wt=imp01*`var'
}

foreach var of varlist E1 E2 {
	egen `var'_sum=sum(`var'_wt), by(serial_scrambled)
}
egen imp01_sum=sum(imp01), by(serial_scrambled)

g E1_mean=E1_sum/imp01_sum
g E2_mean=E2_sum/imp01_sum


collapse (sum) T=imp01 (sum) E?_wt , by(serial_scrambled)

**# Save 
save ".\output\ses2024_job_gaisi.dta", replace

*------------------------------------
**# Load Combined SES				|
*------------------------------------
use "${ses_2017}\SES_2017_Mar2019_v3.dta", clear
drop if b2soc10>=.

*drop non-essential variables
rename (bupto bideas bimpl) (cupto cideas cimpl)
keep serialno b2soc10 c*
drop cacce cself cnoac?
drop corgwork cusepc cpcskil2 cpcskil3 cend country
rename cstrengt cstrength

*Reshape into a long file
rename c* importance_c*
reshape long importance_, i(serialno b2soc10) j(task_handle) string
rename (importance_ b2soc10) (importance occupation_code)

*Merge in AI Exposure classification
merge m:1 task_handle occupation_code using `gem_ratings', keep(1 3) nogen

*Combine E3 with E2
replace E2 = E2 + E3
drop E3

* rescale importance
gen imp01=(5-importance)/4
replace imp01=0 if importance>=. 

*compute importance weighted AI exposure
foreach var of varlist E0 E1 E2 {
	g `var'_wt=imp01*`var'
}

* within job variation in AI exposure
foreach var of varlist E1 E2 {
	egen `var'_sum=sum(`var'_wt), by(serialno)
}
egen imp01_sum=sum(imp01), by(serialno)

g E1_mean=E1_sum/imp01_sum
g E2_mean=E2_sum/imp01_sum


collapse (sum) T=imp01 (sum) E?_wt , by(serialno)

**# Save 
save ".\output\ses2017_job_gaisi.dta", replace

