
* Gurugram Rapid Metro- Spatial DiD Analysis

cd "/Users/varun/Desktop/econ policy/diss/quant/"

ssc install csdid, replace
ssc install drdid, replace
ssc install coefplot, replace

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

* Baseline Model
eststo clear
quietly xtreg true_ln_ntl phase1 phase2 i.year c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Clear_Result

esttab Clear_Result using "Final_Results.rtf", replace ///
    title("Table 3: The Economic Impact of Rapid Metro Phases") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(phase1 phase2) ///
    label varlabels(phase1 "Rapid Metro Phase 1" phase2 "Rapid Metro Phase 2") ///
    stats(N N_g r2_w, labels("Observations" "Number of Wards" "Within R-Squared")) ///
    addnotes("Standard errors clustered at the ward level are in parentheses." ///
              "Controls for Year Fixed Effects and Baseline Interactions included.")


* Lagged-Effects Model (2-year delay)

xtreg true_ln_ntl phase1_lag2 phase2_lag2 i.year c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)

* Robustness Checks
* a. In-space placebo: assigns a fake metro, from 2017, to wards 25 and 26, two untreated wards chosen to structurally resemble Golf Course Road
gen fake_phase2_space = 0
replace fake_phase2_space = 1 if (ward == 25 | ward == 26) & year >= 2017

quietly xtreg true_ln_ntl phase1 fake_phase2_space c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Placebo_Model

* b. Yellow Line control: 2-year lagged phases, with ward 29 controlled for as a time-varying spillover from the Delhi Metro Yellow Line
quietly xtreg true_ln_ntl phase1_lag2 phase2_lag2 yellow_line#i.year i.year ///
    c.popdn#ib2012.year c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Yellow_Line_Model

esttab Placebo_Model Yellow_Line_Model using "Robustness_Checks.rtf", replace ///
    title("Table 2: Robustness and Sensitivity Checks") ///
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
estat event                          
estat group                       

csdid_plot, title("Dynamic Treatment Effects of the Rapid Metro") ///
            ytitle("ATT (Log Radiance)") ///
            xtitle("Years Since Metro Opened") ///
            note("Dashed line represents 95% Confidence Intervals")


* Graph Descriptive Trends By Two Ward Cohort

capture drop cohort
gen cohort = 0                                   
replace cohort = 1 if (ward == 34 | ward == 35) 
replace cohort = 2 if (ward == 32 | ward == 33)  
label define cohort_lbl 0 "Control Baseline" 1 "Phase 1" 2 "Phase 2"
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
    ytitle("Mean Log Radiance (true_ln_ntl)", size(medium)) ///
    xtitle("Year", size(medium)) ///
    xlabel(2012(1)2023, angle(45)) ///
    legend(order(1 "Phase 1 (Cyber City)" 2 "Phase 2 (Golf Course Rd)" 3 "Control Pool") ///
        rows(1) pos(6)) ///
    graphregion(color(white)) ///
    title("Graph 1: Nighttime Radiance Trajectories by Ward Cohort (2012-2023)", size(medium))
graph export "Graph1_Radiance_Trends.png", replace
restore


* Graph Sensitivity Forest Plot
quietly xtreg true_ln_ntl phase1_lag2 phase2_lag2 i.year c.popdn#ib2012.year ///
    c.blr#ib2012.year c.bsws#ib2012.year, fe vce(cluster ward)
eststo Base_Lagged

coefplot (Base_Lagged, label("Baseline Lagged Model")) ///
         (Yellow_Line_Model, label("Yellow Line Controlled")), ///
    keep(phase1_lag2 phase2_lag2) ///
    xline(0, lpattern(dash) lcolor(red)) ///
    coeflabels(phase1_lag2 = "Phase 1 (Cyber City)" phase2_lag2 = "Phase 2 (Golf Course Rd)") ///
    title("Sensitivity of Rapid Metro Agglomeration Effects") ///
    subtitle("With and Without Delhi Metro (Yellow Line) Controls") ///
    xtitle("Estimated Effect on Log Nighttime Radiance") ///
    legend(ring(0) position(4)) ///
    ciopts(lwidth(thin)) mcolor(navy) msymbol(O)
