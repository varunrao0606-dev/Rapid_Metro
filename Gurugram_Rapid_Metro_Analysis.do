* Gurugram Rapid Metro- Spatial DiD Analysis

cd "/Users/varun/Desktop/econ policy/diss/quant/"

ssc install csdid, replace
ssc install drdid, replace
ssc install coefplot, replace
ssc install estout, replace
ssc install reghdfe, replace
ssc install ftools, replace

import excel "GGN_NTL.xlsx", firstrow clear
describe
save "GGN_NTL.dta", replace

xtset ward year


* Variable Construction

* Corrected treatment assignment:

replace phase1 = 0
replace phase1 = 1 if (ward == 34 | ward == 35) & year >= 2013

replace phase2 = 0
replace phase2 = 1 if (ward == 32 | ward == 33) & year >= 2017

gen yellow_line = 0
replace yellow_line = 1 if ward == 29

* Log radiance
generate true_ln_ntl = ln(ln_ntl_radiance + 0.01)

* Two-year lagged treatment, to capture the maturation period before commercial real estate responds. Missing pre-treatment lags are set to 0 rather than dropped, so early panel years are retained.
gen phase1_lag2 = L2.phase1
replace phase1_lag2 = 0 if missing(phase1_lag2)

gen phase2_lag2 = L2.phase2
replace phase2_lag2 = 0 if missing(phase2_lag2)

* Cohort variable for the Callaway-Sant'Anna estimator: the year each ward was first treated (0 = never treated)
gen first_treat = 0
replace first_treat = 2013 if (ward == 34 | ward == 35)
replace first_treat = 2017 if (ward == 32 | ward == 33)


* Baseline Model (Table 4)
eststo clear
quietly xtreg true_ln_ntl phase1 phase2 i.year c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Clear_Result

esttab Clear_Result using "Table4_Baseline.rtf", replace ///
    title("Table 4: Baseline TWFE Estimates") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(phase1 phase2) ///
    label varlabels(phase1 "Rapid Metro Phase 1" phase2 "Rapid Metro Phase 2") ///
    stats(N N_g r2_w, labels("Observations" "Number of Wards" "Within R-Squared")) ///
    addnotes("Standard errors clustered at the ward level are in parentheses." ///
              "Controls for Year Fixed Effects and Baseline Interactions included.")


* Lagged-Effects Model (2-year delay)
quietly xtreg true_ln_ntl phase1_lag2 phase2_lag2 i.year c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Base_Lagged


* Robustness Checks (Table 5)
* a. In-space placebo: assigns a fake metro, from 2017, to wards 25 and 26, two untreated wards chosen to structurally resemble Golf Course Road
gen fake_phase2_space = 0
replace fake_phase2_space = 1 if (ward == 25 | ward == 26) & year >= 2017

quietly xtreg true_ln_ntl phase1 fake_phase2_space i.year c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Placebo_Model

* b. Yellow Line control: 2-year lagged phases, with ward 29 controlled for as a time-varying spillover from the Delhi Metro Yellow Line
quietly xtreg true_ln_ntl phase1_lag2 phase2_lag2 yellow_line#i.year i.year ///
    c.popdn#ib2012.year c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Yellow_Line_Model

esttab Placebo_Model Yellow_Line_Model using "Table5_Robustness.rtf", replace ///
    title("Table 5: Robustness and Sensitivity Checks") ///
    mtitles("In-Space Placebo" "Yellow Line Control") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(phase1 phase1_lag2 fake_phase2_space phase2_lag2) ///
    order(phase1 phase1_lag2 fake_phase2_space phase2_lag2) ///
    label varlabels(phase1 "Phase 1 (Contemporaneous)" ///
                    phase1_lag2 "Phase 1 (2-Year Lag)" ///
                    fake_phase2_space "Placebo Corridor (2017)" ///
                    phase2_lag2 "Phase 2 (2-Year Lag)") ///
    stats(N N_g r2_w, labels("Observations" "Number of Wards" "Within R-Squared")) ///
    addnotes("Standard errors clustered at the ward level are in parentheses." ///
              "Both models include Ward and Year Fixed Effects, and Baseline Interactions.")


* Event Study - Callaway-Sant'Anna (CS-DID)
csdid true_ln_ntl, ivar(ward) time(year) gvar(first_treat) method(dripw)
estat simple
estat group, estore(CS_Group)

csdid true_ln_ntl, ivar(ward) time(year) gvar(first_treat) method(dripw)
estat event
csdid_plot, ytitle("ATT (Log Radiance)") xtitle("Years Since Metro Opened")
graph export "Figure_2.pdf", replace


* Graph Descriptive Trends By Two Ward Cohort (Figure 1)

capture drop cohort
gen cohort = 0
replace cohort = 1 if (ward == 34 | ward == 35)
replace cohort = 2 if (ward == 32 | ward == 33)
label define cohort_lbl 0 "Control Baseline" 1 "Phase 1" 2 "Phase 2", replace
label values cohort cohort_lbl

preserve
collapse (mean) avg_ntl = true_ln_ntl, by(year cohort)
twoway ///
    (line avg_ntl year if cohort == 1, lwidth(medium) lcolor(navy)) ///
    (line avg_ntl year if cohort == 2, lwidth(medium) lcolor(cranberry) lpattern(dash)) ///
    (line avg_ntl year if cohort == 0, lwidth(medium) lcolor(gs8) lpattern(shortdash)), ///
    xline(2013, lpattern(dot) lcolor(black) lwidth(thin)) ///
    xline(2017, lpattern(dot) lcolor(black) lwidth(thin)) ///
    text(1.5 2013.2 "Phase 1 Launch", size(small) place(e)) ///
    text(1.5 2017.2 "Phase 2 Launch", size(small) place(e)) ///
    ytitle("Mean Log Radiance", size(medium)) ///
    xtitle("Year", size(medium)) ///
    xlabel(2012(1)2023, angle(45)) ///
    legend(order(1 "Phase 1 (Cyber City)" 2 "Phase 2 (Golf Course Rd)" 3 "Control Pool") ///
        rows(1) pos(6)) ///
    graphregion(color(white))
graph export "Figure_1.pdf", replace
restore


* Graph Sensitivity Forest Plot (Figure 3)
coefplot (Base_Lagged, label("Baseline Lagged Model")) ///
         (Yellow_Line_Model, label("Yellow Line Controlled")), ///
    keep(phase1_lag2 phase2_lag2) ///
    xline(0, lpattern(dash) lcolor(red)) ///
    coeflabels(phase1_lag2 = "Phase 1 (Cyber City)" phase2_lag2 = "Phase 2 (Golf Course Rd)") ///
    xtitle("Estimated Effect on Log Nighttime Radiance") ///
    legend(ring(1) position(6) rows(1)) ///
    ciopts(lwidth(thin)) msymbol(O) graphregion(color(white))
graph export "Figure_3.pdf", replace


* Identification and Inference Checks (Table 6)

* Ward lists come from GGN_Rapid_Metro_Spatial.ipynb (see README)
* GMRL wards: untreated wards with at least a quarter of their area within 800m of the planned GMRL route. Ward 29 is left out as it is the Yellow Line ward.
* Neighbours: untreated wards that share a boundary with wards 32-35
global GMRL_WARDS "2 3 4 5 6 10 11 12 14 19 20 21 27 28 30"
global NEIGHBOURS "4 17 25 29 30 31"

capture drop fake gmrl_ctrl neighbour phase2_award p1_w34 p1_w35 p2_w32 p2_w33

* Same baseline as Table 4, run with reghdfe so the checks below use the same command
reghdfe true_ln_ntl phase1 phase2 i.year c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, absorb(ward) vce(cluster ward)
eststo Base_HDFE
local b1 = _b[phase1]
local b2 = _b[phase2]

* a. Wild cluster bootstrap (restricted, Webb weights), as there are only two treated wards per phase
capture program drop wildboot
program define wildboot, rclass
    args testvar othervar reps seed
    tempvar e xb g u w ystar
    quietly reghdfe true_ln_ntl `testvar' `othervar' i.year c.popdn#ib2012.year ///
        c.blr#ib2012.year c.bsws#ib2012.year, absorb(ward) vce(cluster ward)
    local t0 = _b[`testvar'] / _se[`testvar']
    * null imposed: re-estimate without the tested variable
    quietly reghdfe true_ln_ntl `othervar' i.year c.popdn#ib2012.year ///
        c.blr#ib2012.year c.bsws#ib2012.year, absorb(ward) resid(`e')
    quietly predict double `xb', xbd
    quietly egen `g' = group(ward)
    quietly gen double `u' = .
    quietly gen double `w' = .
    quietly gen double `ystar' = .
    set seed `seed'
    local exceed = 0
    forvalues r = 1/`reps' {
        quietly {
            * one Webb weight per ward
            replace `u' = runiform()
            bysort `g': replace `u' = `u'[1]
            replace `w' = cond(`u' < 1/6, -sqrt(1.5), cond(`u' < 2/6, -1, cond(`u' < 3/6, -sqrt(0.5), ///
                          cond(`u' < 4/6, sqrt(0.5), cond(`u' < 5/6, 1, sqrt(1.5))))))
            replace `ystar' = `xb' + `w' * `e'
            reghdfe `ystar' `testvar' `othervar' i.year c.popdn#ib2012.year ///
                c.blr#ib2012.year c.bsws#ib2012.year, absorb(ward) vce(cluster ward)
        }
        if abs(_b[`testvar'] / _se[`testvar']) >= abs(`t0') local ++exceed
    }
    return scalar p = `exceed' / `reps'
    di "Wild bootstrap p-value for `testvar' = " %5.3f `exceed' / `reps'
end

sort ward year
wildboot phase1 phase2 999 20261027
local wcb1 = r(p)
wildboot phase2 phase1 999 20261027
local wcb2 = r(p)
sort ward year

* b. Randomisation inference: give each phase to every pair of never-treated wards (31 wards, so 465 pairs)
levelsof ward if first_treat == 0, local(pool)
local n : word count `pool'
tempname ri
postfile `ri' str2 phase w1 w2 b using "RI_draws.dta", replace
forvalues a = 1/`=`n'-1' {
    forvalues c = `=`a'+1'/`n' {
        local wa : word `a' of `pool'
        local wc : word `c' of `pool'
        capture drop fake
        gen fake = (ward == `wa' | ward == `wc') & year >= 2013
        quietly reghdfe true_ln_ntl fake phase2 c.popdn#ib2012.year c.blr#ib2012.year ///
            c.bsws#ib2012.year if !inlist(ward, 34, 35), absorb(ward year)
        post `ri' ("p1") (`wa') (`wc') (_b[fake])
        replace fake = (ward == `wa' | ward == `wc') & year >= 2017
        quietly reghdfe true_ln_ntl phase1 fake c.popdn#ib2012.year c.blr#ib2012.year ///
            c.bsws#ib2012.year if !inlist(ward, 32, 33), absorb(ward year)
        post `ri' ("p2") (`wa') (`wc') (_b[fake])
    }
}
postclose `ri'
capture drop fake

preserve
use "RI_draws.dta", clear
gen extreme = (phase == "p1" & abs(b) >= abs(`b1')) | (phase == "p2" & abs(b) >= abs(`b2'))
quietly count if phase == "p1"
local N1 = r(N)
quietly count if phase == "p1" & extreme
local ri1 = (r(N) + 1) / (`N1' + 1)
quietly count if phase == "p2"
local N2 = r(N)
quietly count if phase == "p2" & extreme
local ri2 = (r(N) + 1) / (`N2' + 1)
di "RI p-value Phase 1 = " %5.3f `ri1' "  (" `N1' " pairs)"
di "RI p-value Phase 2 = " %5.3f `ri2' "  (" `N2' " pairs)"

twoway (histogram b if phase == "p1", fcolor(gs12) lcolor(gs8)), ///
    xline(`b1', lcolor(navy) lpattern(dash) lwidth(medthick)) ///
    xtitle("Placebo Phase 1 coefficient") ytitle("Density") graphregion(color(white))
graph export "Figure_B1a_RI_Phase1.pdf", replace
twoway (histogram b if phase == "p2", fcolor(gs12) lcolor(gs8)), ///
    xline(`b2', lcolor(cranberry) lpattern(dash) lwidth(medthick)) ///
    xtitle("Placebo Phase 2 coefficient") ytitle("Density") graphregion(color(white))
graph export "Figure_B1b_RI_Phase2.pdf", replace
restore

* add the p-values to the baseline column of Table 6
estimates restore Base_HDFE
estadd scalar wcb_p1 = `wcb1'
estadd scalar wcb_p2 = `wcb2'
estadd scalar ri_p1 = `ri1'
estadd scalar ri_p2 = `ri2'
eststo Base_HDFE

* c. Controls restricted to wards on the planned GMRL route, which were also picked for a metro but do not have one yet
gen gmrl_ctrl = 0
foreach w of global GMRL_WARDS {
    replace gmrl_ctrl = 1 if ward == `w'
}
reghdfe true_ln_ntl phase1 phase2 c.popdn#ib2012.year c.blr#ib2012.year ///
    c.bsws#ib2012.year if first_treat > 0 | gmrl_ctrl == 1, absorb(ward year) vce(cluster ward)
eststo GMRL_Control

* ward 28 sits close to the 25% cut-off, so check the estimate without it (not in Table 6)
reghdfe true_ln_ntl phase1 phase2 c.popdn#ib2012.year c.blr#ib2012.year ///
    c.bsws#ib2012.year if first_treat > 0 | (gmrl_ctrl == 1 & ward != 28), absorb(ward year) vce(cluster ward)

* d. Spillovers: drop the untreated wards bordering the metro corridors
gen neighbour = 0
foreach w of global NEIGHBOURS {
    replace neighbour = 1 if ward == `w'
}
reghdfe true_ln_ntl phase1 phase2 c.popdn#ib2012.year c.blr#ib2012.year ///
    c.bsws#ib2012.year if neighbour == 0, absorb(ward year) vce(cluster ward)
eststo No_Spillover

* e. Anticipation: Phase 2 dated from its October 2012 award (2013 is the first full year)
gen phase2_award = (ward == 32 | ward == 33) & year >= 2013
reghdfe true_ln_ntl phase1 phase2_award c.popdn#ib2012.year c.blr#ib2012.year ///
    c.bsws#ib2012.year, absorb(ward year) vce(cluster ward)
eststo Award_Dating

* f. Ward-by-ward effects (Table B.1)
gen p1_w34 = ward == 34 & year >= 2013
gen p1_w35 = ward == 35 & year >= 2013
gen p2_w32 = ward == 32 & year >= 2017
gen p2_w33 = ward == 33 & year >= 2017
reghdfe true_ln_ntl p1_w34 p1_w35 p2_w32 p2_w33 c.popdn#ib2012.year c.blr#ib2012.year ///
    c.bsws#ib2012.year, absorb(ward year) vce(cluster ward)
eststo By_Ward

esttab By_Ward using "TableB1_ByWard.rtf", replace ///
    title("Table B.1: Ward-by-Ward Treatment Effects") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(p1_w34 p1_w35 p2_w32 p2_w33) ///
    varlabels(p1_w34 "Phase 1, ward 34" p1_w35 "Phase 1, ward 35" ///
              p2_w32 "Phase 2, ward 32" p2_w33 "Phase 2, ward 33") ///
    stats(N, labels("Observations"))

esttab Base_HDFE GMRL_Control No_Spillover Award_Dating CS_Group using "Table6_Identification.rtf", replace ///
    title("Table 6: Identification and Inference Checks") ///
    mtitles("Baseline" "GMRL-Route Controls" "Excl. Neighbours" "Phase 2 From Award" "Callaway-Sant'Anna") ///
    rename(phase2_award phase2 G2013 phase1 G2017 phase2) ///
    keep(phase1 phase2) order(phase1 phase2) ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    varlabels(phase1 "Rapid Metro Phase 1" phase2 "Rapid Metro Phase 2") ///
    stats(N wcb_p1 ri_p1 wcb_p2 ri_p2, fmt(0 3 3 3 3) ///
        labels("Observations" "Phase 1: Wild Bootstrap p" "Phase 1: Randomisation p" ///
               "Phase 2: Wild Bootstrap p" "Phase 2: Randomisation p")) ///
    addnotes("Standard errors clustered at the ward level are in parentheses." ///
             "Columns 1-4 include Ward and Year Fixed Effects, and Baseline Interactions." ///
             "Column 5 reports cohort ATTs from the Callaway-Sant'Anna estimator.")

* g. Jackknife: drop one ward at a time and re-run the baseline (Figure B.2)
preserve
tempname jk
postfile `jk' dropped b1 b2 using "Jackknife.dta", replace
levelsof ward, local(allw)
foreach w of local allw {
    quietly reghdfe true_ln_ntl phase1 phase2 c.popdn#ib2012.year c.blr#ib2012.year ///
        c.bsws#ib2012.year if ward != `w', absorb(ward year)
    post `jk' (`w') (_b[phase1]) (_b[phase2])
}
postclose `jk'
use "Jackknife.dta", clear
summarize b1 b2, detail
twoway (scatter b1 dropped, mcolor(navy)) (scatter b2 dropped, mcolor(cranberry) msymbol(D)), ///
    yline(0, lpattern(dash) lcolor(red)) xtitle("Ward Dropped") ytitle("Coefficient") ///
    legend(order(1 "Phase 1" 2 "Phase 2") rows(1) pos(6)) graphregion(color(white))
graph export "Figure_B2_Jackknife.pdf", replace
restore
