/*
The code reads in LLM generated exposure probabilities by SES tasks and 2-digit occupations
Created by gemini 1.5 pro and GPT-4o
It creates model-specific averages -> stick with GPT-4o, use Gemini 1.5pro as backup

*/
*# Setting up Stata
	clear all
	
	* root 
	cd "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Skills\automation\uk_genai_task_exposure\gaiei_ses_based"

	* Add any additional ado paths;
	adopath ++ "C:\Users\utnvghe\OneDrive - University College London\ado"
	adopath ++ "N:\StataMP18"

	
*-----------
**# GPT 4o |
*-----------
import excel "./classification_results/job_task_probabilities_gpt4o_batched_r1.xlsx", sheet("job_task_probabilities_gpt4o_ba") firstrow clear 

* First, generate the new columns
gen E0 = .
gen E1 = .
gen E2 = .
gen E3 = .

* Use regex to extract values for each key
replace E0 = real(regexs(1)) if regexm(probabilities, "'E0':\s*([0-9.]+)")
replace E1 = real(regexs(1)) if regexm(probabilities, "'E1':\s*([0-9.]+)")
replace E2 = real(regexs(1)) if regexm(probabilities, "'E2':\s*([0-9.]+)")
replace E3 = real(regexs(1)) if regexm(probabilities, "'E3':\s*([0-9.]+)")
drop probabilities

bysort  occupation_code task_handle: gen r=_n
keep if r==1
drop r

gen model="gpt_4o"
gen run=1
tempfile gpt_r1
save `gpt_r1'

*# Run 2
import excel ".\classification_results\job_task_probabilities_gpt4o_batched_r2.xlsx", sheet("job_task_probabilities_gpt4o_ba") firstrow clear
cap drop task_analysis
gen model="gpt_4o"
gen run=2
tempfile gpt_r2
save `gpt_r2'

*# Run 3
import excel ".\classification_results\job_task_probabilities_gpt4o_batched_r3.xlsx", sheet("job_task_probabilities_gpt4o_ba") firstrow clear
cap drop task_analysis
gen model="gpt_4o"
gen run=3
tempfile gpt_r3
save `gpt_r3'

*# Run 4
import excel ".\classification_results\job_task_probabilities_gpt4o_batched_r4.xlsx", sheet("job_task_probabilities_gpt4o_ba") firstrow clear
cap drop task_analysis
gen model="gpt_4o"
gen run=4
tempfile gpt_r4
save `gpt_r4'

*# Run 5 
import excel ".\classification_results\job_task_probabilities_gpt4o_batched_r5.xlsx", sheet("job_task_probabilities_gpt4o_ba") firstrow clear
cap drop task_analysis
gen model="gpt_4o"
gen run=5
tempfile gpt_r5
save `gpt_r5'

*--------------------------------------
**# Gemini Probabilistic classification
*--------------------------------------
forv i=1/5 {
	import delimited ".\classification_results\job_task_probabilities_gemini_r`i'.csv", clear
	rename (prob_e0 prob_e1 prob_e2 prob_e3) (E0 E1 E2 E3)
	gen model="gemini_1.5_pro"
	gen run=`i'
 tempfile g`i'
 save `g`i''
}


clear 
append using `gpt_r1' `gpt_r2' `gpt_r3' `gpt_r4' `gpt_r5'
append using `g1' `g2' `g3' `g4' `g5'

*---------------------------------------------------------------------
**# Data Preparation
*--------------------------------------------------------------------
gen task_categories=.
replace task_categories=1 if inlist(task_handle,"cteach", "cspeech", "cpersuad")
replace task_categories=2 if inlist(task_handle,"cpeople", "ccaring", "cselling", "cproduct")
replace task_categories=3 if inlist(task_handle,"cteamwk", "clisten", "ccoop")
replace task_categories=4 if inlist(task_handle,"cmefeel", "cothfeel", "clookprt", "csoundprt")
replace task_categories=5 if inlist(task_handle,"cstrength", "cstamina", "chands", "ctools")
replace task_categories=6 if inlist(task_handle,"cwrite", "cwritesh", "cwritelg")
replace task_categories=7 if inlist(task_handle,"cread", "cshort", "clong")
replace task_categories=8 if inlist(task_handle,"cstats", "ccalca", "cpercent")
replace task_categories=9 if inlist(task_handle,"canalyse", "cfaults", "ccause", "csolutn")
replace task_categories=10 if inlist(task_handle,"cspecial", "cupto", "cideas")
replace task_categories=11 if inlist(task_handle,"cplanme", "cplanoth", "cmytime", "cahead", "cimpl")
replace task_categories=12 if inlist(task_handle,"cmotivat", "cthings", "ccoach", "ccareers", "cfuture")

label define task_categories ///
1 "Professional Communication" ///
2 "Client Interaction" ///
3 "Collaboration" ///
4 "Emotion and Impression" ///
5 "Manual" ///
6 "Writing" ///
7 "Reading" ///
8 "Numeracy" ///
9 "Problem Analysis" ///
10 "Expertise and Innovation" ///
11 "Planning and Organising" ///
12 "Management"

label values task_categories task_categories

egen task=group(task_handle)
encode model, gen(aux)
drop model
rename aux model

egen batch=group(task_categories run model)
egen model_run=group(model run)
egen occupation_task=group(occupation_code task_handle)

label def model_run ///
	1 "Gem 1.5 Pro - r1" ///
	2 "Gem 1.5 Pro - r2" ///
	3 "Gem 1.5 Pro - r3" ///
	4 "Gem 1.5 Pro - r4" ///
	5 "Gem 1.5 Pro - r5" ///
	6 "GPT-4o - r1" ///
	7 "GPT-4o - r2" ///
	8 "GPT-4o - r3" ///
	9 "GPT-4o - r4" ///
	10 "GPT-4o - r5" ///
	
label val model_run model_run
	

*------------------------------------------------------------
**# Save the resulting AI exposure matrix
*------------------------------------------------------------
compress
save ".\output\job_task_exposure_probabilities_gpt4o_gemini.dta", replace
export delimited using ".\\output\job_task_exposure_probabilities_gpt4o_gemini.csv", replace


