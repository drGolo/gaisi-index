*--------------------
**# A - Setting stata |
*--------------------
	clear all
	collect clear

	*data directory
	global ses_2023 "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Felstead - SES 2023\final"
	global ses_2017 "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Felstead - SES 2017\dataset"

	* root 
	cd "C:\Users\utnvghe\OneDrive - University College London\Documents\Research\Skills\automation\uk_genai_task_exposure\gaiei_ses_based"

	* Add any additional ado paths;
	adopath ++ "C:\Users\utnvghe\OneDrive - University College London\ado"
	adopath ++ "N:\StataMP18"

*-----------------------------------------------------
**#B Load and prepare SES 2024, 2017 
*-----------------------------------------------------
**# 2024 
use "${ses_2023}\P16561-SES-F2F-Panel-Combined UK + quals + pay.dta", clear
drop if bsoc2010>=.

*AI Exposure
merge 1:1 serial_scrambled using ".\output\ses2024_job_gaisi.dta", ///
	keep(1 3) nogen keepusing(T E?_wt )
rename (E?_wt) (T_E?_gemini)

*AI Index
gen E1=T_E1_gemini/T
gen E2=T_E2_gemini/T

g gaisi_beta=E1+ 0.5*E2

label var T "Total Tasks (Importance-weighted)"
label var E1 "Direct LLM Exposure (E1)"
label var E2 "LLM+ Exposure (E2)"
label var gaisi_beta "SES GAISI (E2 discounted with 0.5)"

*Working Hours
recode bhours (997=.v)
replace bhours = ghours if bhours>=. & (ghours>0&ghours<.)
g ln_wh=ln(bhours)
label var bhours "Usual Weekly Hours Worked"

*Survey interview
gen f2f_intdate=date(isdate,"DMY")
g intym=mofd(f2f_intdate) if f2f_intdate<.
replace intym=mofd(panel_intdate) if panel_intdate<.

g intyq=qofd(f2f_intdate) if f2f_intdate<.
replace intyq=qofd(panel_intdate) if panel_intdate<.

g year=yofd(f2f_intdate) if f2f_intdate<.
replace year=yofd(panel_intdate) if panel_intdate<.

*AI use
recode cdigtype2 (1=1) (2=0), gen(ai)
replace ai=0 if cusepc==5 & cdigauto==2 & ai>=.
label var ai "AI use"

*Keep essentials
keep bsoc2020 bsoc2010 gwtcombw1uk65 gwtcombw2uk65 ///
	E1 E2 gaisi_beta T  bhours year ///
	region wtcombw1uk65

tempfile ses2024
save `ses2024'

*-------------------------------	
**# 2017
*-------------------------------
use "${ses_2017}\ses_2017\SES_2017_Mar2019_v3.dta", clear
drop if bsoc2010>=.

*AI Exposure
merge 1:1 serialno using ".\output\ses2017_job_gaisi.dta", ///
	keep(1 3) nogen keepusing(T E?_wt)
rename (E?_wt) (T_E?_gemini)

*AI Index
gen E1=T_E1_gemini/T
gen E2=T_E2_gemini/T

g gaisi_beta=E1+ 0.5*E2

label var T "Total Tasks (Importance-weighted)"
label var E1 "Direct LLM Exposure (E1)"
label var E2 "LLM+ Exposure (E2)"
label var gaisi_beta "SES GAISI (E2 discounted with 0.5)"

*Hours
recode bhours (-3=.v)
replace bhours = ghours if bhours>=. & (ghours>0&ghours<.)
label var bhours "Usual Weekly Hours Worked"

*Survey interview
gen year=2017


*Keep essentials
keep bsoc2010 gwt65 wt65 ///
	E1 E2 gaisi_beta T bhours  year ///

tempfile ses2017
save `ses2017'

*-------------------------------------------------------------
**#C Merge with the combined file
*------------------------------------------------------------
clear
append using `ses2017' `ses2024'
keep if gaisi_beta<.

*Weight
replace gwt65= gwtcombw1uk65 if year>=2023
replace wt65= wtcombw1uk65 if year>=2023

*#Covariates
recode bsoc2010 (3550=5114)
gen b2soc10=int(bsoc2010/100)
gen b3soc10=int(bsoc2010/10)

*#AI exposure
_pctile gaisi_beta [pw=gwt65], p(80)
gen hi_gaisi=(gaisi_beta>`r(r1)') if gaisi_beta<.

xtile gaisi_rank=gaisi_beta [pw=gwt65], nq(1000) 
replace gaisi_rank=gaisi_rank/100

*------------------------------------
*Save occupation averages	SOC 2010|
*------------------------------------

preserve
* 1. Collapse to occupation level in both waves
collapse (mean) hi_gaisi gaisi_rank ///
		 (median) p50_gaisi_rank=gaisi_rank ///
         (rawsum) N = wt65 ///
         , by(b2soc10)
keep if b2soc10<.
rename (hi_gaisi gaisi_rank p50_gaisi_rank N) (hi_gaisi_2d gaisi_2d p50_gaisi_2d N_2d)
tempfile 2digit
save `2digit'
restore 

preserve
* 1. Collapse to occupation level in both waves
collapse (mean) hi_gaisi gaisi_rank ///
		 (median) p50_gaisi_rank=gaisi_rank ///
         (rawsum) N = wt65 ///
         , by(b3soc10 b2soc10)

* append
merge m:1 b2soc10 using `2digit', nogen

*impute 3-digit index if missing or cell size small
replace hi_gaisi=. if N<6 
replace gaisi_rank=. if N<6 
replace p50_gaisi_rank=. if N<6 

*Impute missing GAISI score
tobit gaisi_rank hi_gaisi_2d gaisi_2d, ll(0) ul(10)
predict yhat, ystar(0,1)
replace gaisi_rank=yhat if gaisi_rank>=.
drop yhat

*Impute missing GAISI score
tobit p50_gaisi_rank hi_gaisi_2d p50_gaisi_2d, ll(0) ul(10)
predict yhat, ystar(0,1)
replace p50_gaisi_rank=yhat if p50_gaisi_rank>=.
drop yhat

*Impute missing high-exposed share
tobit hi_gaisi hi_gaisi_2d gaisi_2d, ll(0) ul(1)
predict yhat, ystar(0,1)
replace hi_gaisi=yhat if hi_gaisi>=.

drop *_2d *hat
save ".\output\soc2010_3digit_gaisi_ses.dta", replace
export delimited ".\output\soc2010_3digit_gaisi_ses.csv", replace
restore 


*----------------------------
**# SOC 2020
*----------------------------
g b2soc20=int(bsoc2020/100)
g b3soc20=int(bsoc2020/10)

preserve
* 1. Collapse to occupation level in both waves
collapse (mean) hi_gaisi gaisi_rank ///
		 (median) p50_gaisi_rank=gaisi_rank ///
         (rawsum) N = wt65 ///
         , by(b2soc20)
keep if b2soc20<.
rename (hi_gaisi gaisi_rank p50_gaisi_rank N) (hi_gaisi_2d gaisi_2d p50_gaisi_2d N_2d)
tempfile 2digit
save `2digit'
restore 

preserve
* 1. Collapse to occupation level in both waves
collapse (mean) hi_gaisi gaisi_rank ///
		 (median) p50_gaisi_rank=gaisi_rank ///
         (rawsum) N = wt65 ///
         , by(b3soc20 b2soc20)

* append
merge m:1 b2soc20 using `2digit', nogen

*impute 3-digit index if missing or cell size small
replace hi_gaisi=. if N<6 // 
replace gaisi_rank=. if N<6 //
replace p50_gaisi_rank=. if N<6 //

*Impute missing GAISI score
tobit gaisi_rank hi_gaisi_2d gaisi_2d, ll(0) ul(10)
predict yhat, ystar(0,1)
replace gaisi_rank=yhat if gaisi_rank>=.
drop yhat

*Impute missing GAISI score
tobit p50_gaisi_rank hi_gaisi_2d p50_gaisi_2d, ll(0) ul(10)
predict yhat, ystar(0,1)
replace p50_gaisi_rank=yhat if p50_gaisi_rank>=.
drop yhat

*Impute missing high-exposed share
tobit hi_gaisi hi_gaisi_2d gaisi_2d, ll(0) ul(1)
predict yhat, ystar(0,1)
replace hi_gaisi=yhat if hi_gaisi>=.

drop *_2d *hat
save ".\output\soc2020_3digit_gaisi_ses.dta", replace
export delimited ".\output\soc2020_3digit_gaisi_ses.csv", replace
restore 
