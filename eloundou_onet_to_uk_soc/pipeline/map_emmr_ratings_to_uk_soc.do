********************************************************************************
* Map Eloundou et al. (2024) EMMR Ratings to UK SOC
* File: map_emmr_ratings_to_uk_soc.do
*
* Purpose:
*   Maps the task-level GenAI exposure classifications from Eloundou et al.
*   (2024) "GPTs are GPTs" to UK Standard Occupational Classification (SOC)
*   codes, using the Standard Skills Classification (SSC) as a bridge between
*   O*NET tasks and UK SOC.
*
* Method:
*   1. Load O*NET task-level exposure ratings (human rater + GPT-4) from
*      Eloundou et al. full_labelset.tsv
*   2. Merge with SSC-to-O*NET task crosswalk; weight by similarity score to
*      produce SSC task-level exposure scores
*   3. Merge with SSC unit group task-relatedness weights (sugs)
*   4. Collapse to SOC 2020 (4-digit), weighted by task-relatedness
*   5. Convert to SOC 2010 via ONS employment-share crosswalk
*
* Inputs:
*   ./source/full_labelset.tsv
*   ./ssc_onet_bridge/SSC - Mappings - ONET - v0.9.0 - 20251124.xlsx
*   ./ssc_onet_bridge/sugs_task_description.xlsx
*   ./ssc_onet_bridge/soc20_to_soc10_crosswalk.dta
*
* Outputs:
*   ./output/soc2020_4digit_gpts_are_gpts.dta/.csv
*   ./output/soc2010_4digit_gpts_are_gpts.dta/.csv
*
* Source: Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2024).
*   GPTs are GPTs: An early look at the labor market impact potential of
*   large language models. Science, 384(6702), 1306-1308.
*   https://doi.org/10.1126/science.adj0998
*   Ratings cloned from: https://github.com/openai/GPTs-are-GPTs
*
* Last updated: March 2025
********************************************************************************

*# Setting up Stata
	clear all
	collect clear

	* root — all paths below are relative to this folder
	cd "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Skills\automation\uk_genai_task_exposure\eloundou_onet_to_uk_soc"

	* Add any additional ado paths
	adopath ++ "C:\Users\utnvghe\OneDrive - University College London\ado"
	adopath ++ "N:\StataMP18"

*----------------------------------------------------
**# Load Eloundou et al. O*NET task exposure ratings
*----------------------------------------------------
import delimited "./source/full_labelset.tsv", clear
keep taskid human_exposure_agg gpt4_exposure alpha beta gamma automation human_labels
tempfile emmr
save `emmr'

*----------------------------------------------------
**# Build SSC task-level exposure scores via O*NET bridge
*----------------------------------------------------
* SSC-to-O*NET task crosswalk (similarity-weighted)
import excel "./ssc_onet_bridge/SSC - Mappings - ONET - v0.9.0 - 20251124.xlsx", ///
	sheet("ONET Tasks to SSC Tasks") firstrow clear
split ONETTaskID, parse(.) destring
rename _all, lower
rename (taskid onettaskid3) (ssc_taskid taskid)

* Merge in Eloundou exposure levels
merge m:1 taskid using `emmr', keep(3)

* Assign similarity-weighted exposure scores for each O*NET classification
sort ssc_taskid taskid
foreach l in E0 E1 E2 {
	g human_`l'=0
	replace human_`l' = similarityscore if human_labels=="`l'"

	g gpt_`l'=0
	replace gpt_`l' = similarityscore if gpt4_exposure=="`l'"
}

* Collapse to SSC task level (normalise by total similarity)
collapse (sum) similarityscore human_E0-gpt_E2, by(ssc_taskid)
aorder

foreach var of varlist gpt_* human_* {
	replace `var'=`var'/similarityscore
}
drop similarityscore
rename ssc_taskid taskid
tempfile elm
save `elm'

*----------------------------------------------------
**# Load SSC unit group task-relatedness weights
*----------------------------------------------------
import excel "./ssc_onet_bridge/sugs_task_description.xlsx", ///
	sheet("Sheet1") firstrow case(lower) allstring clear
destring taskrelatedness, replace
drop sugdescription
tempfile sugs
save `sugs'

*----------------------------------------------------
**# Combine: merge sugs with SSC-bridged Eloundou scores
*----------------------------------------------------
use `sugs', clear
merge m:1 taskid using `elm', keep(3) nogen

g bsoc2020 = substr(sugcode,1,4)
replace bsoc2020="2311" if bsoc2020=="23+A"
destring bsoc2020, gen(soc20m) 
g n = 1

* Task-relatedness weight (0–1 scale)
g taskweight = taskrelatedness/100

* Apply weights
foreach var of varlist gpt_* human_* {
	g w_`var' = `var'*taskweight
}

*----------------------------------------------------
**# SOC 2020: export GPTs are GPTs scores
*----------------------------------------------------

preserve

* Restrict to tasks with matched Eloundou ratings
replace taskweight=. if missing(gpt_E0)

collapse (sum) N=taskweight ///
	w_gpt_E1 w_gpt_E2 ///
	w_human_E1 w_human_E2 ///
	, by(soc20m)

	g emmr_gpt   = (w_gpt_E1   + 0.5*w_gpt_E2)   / N
	g emmr_human = (w_human_E1 + 0.5*w_human_E2) / N

	label var emmr_gpt   "GPT-4 rated GenAI Exposure: (E1 + 0.5*E2) / N"
	label var emmr_human "Human rater GenAI Exposure: (E1 + 0.5*E2) / N"

save "./output/soc2020_4digit_gpts_are_gpts.dta", replace
export delimited "./output/soc2020_4digit_gpts_are_gpts.csv", replace

restore

*----------------------------------------------------
**# SOC 2010: convert via employment-share crosswalk
*----------------------------------------------------

merge m:m soc20m using "./ssc_onet_bridge/soc20_to_soc10_crosswalk.dta"

* Rescale weights by employment share
foreach var of varlist taskweight gpt_* human_* {
	replace `var' = `var'*emp_share_rescaled
}

*# SOC 2010: human rater scores (elm_ssc)
preserve

g sc2010mg = int(sc2010m/10)
collapse (sum) N=taskweight ///
	w_human_E1 w_human_E2 ///
	, by(sc2010m sc2010mg)

	rename sc2010m soc10m
	g emmr_human = (w_human_E1 + 0.5*w_human_E2) / N
	label var emmr_human "Human rater GenAI Exposure: (E1 + 0.5*E2) / N"

	* Fall back to 3-digit average for small cells
	foreach var of varlist w_human_* N {
		egen `var'_3d = total(`var'), by(sc2010mg)
	}
	g gaisi_human_3rd = (w_human_E1_3d + 0.5*w_human_E2_3d) / N_3d
	replace emmr_human = gaisi_human_3rd if N < 5

drop *_3d *_3rd

save "./output/soc2010_gpts_are_gpts.dta", replace
export delimited "./output/soc2010_gpts_are_gpts.csv", replace

restore
