/*==============================================================================
  03_export_plot_data.do
  Writes the coefficients and 95% intervals, ready for plotting in R.

   - plot_data/coefficients_all.csv and tables/all_estimates.xlsx: the estimates behind
     Figures 4-11 and Tables 1-2, S4-S9 and S12-S19, one row per key
   - plot_data/fig04_main_fbdg.csv ... fig10_hdds12.csv: one CSV per figure, with the
     rows of that figure in plotting order. stata/figure_map.csv says which estimate goes
     where and under which label.

  Input : $PLOT_DATA/coefficients_all.dta, $STATA/figure_map.csv
==============================================================================*/

version 18
if "$RUN_ALL" == "" | "$RUN_ALL" != "$ROOT" {
    display as error "Run this file through 00_run_all.do"
    exit 198
}
capture log close export
log using "$LOGS/03_export_plot_data.log", replace text name(export)

*------------------------------------------------------------------------------
* 1. All estimates, with plain column names
*------------------------------------------------------------------------------
use "$PLOT_DATA/coefficients_all.dta", clear
rename (b se p ci_lo ci_hi n n_clust) (estimate std_error p_value conf_low conf_high n_obs n_clusters)
generate str3 stars = cond(p_value < 0.01, "***", cond(p_value < 0.05, "**", cond(p_value < 0.1, "*", "")))
local stats estimate std_error conf_low conf_high p_value stars n_obs n_clusters
local about exhibit key outcome treatment model cluster
order `about' `stats'
sort exhibit key
isid key
export delimited `about' `stats' using "$PLOT_DATA/coefficients_all.csv", replace
export excel using "$TABLES/all_estimates.xlsx", sheet("estimates") firstrow(variables) replace
tempfile all
save `all'

*------------------------------------------------------------------------------
* 2. One CSV per figure
*------------------------------------------------------------------------------
import delimited using "$STATA/figure_map.csv", clear varnames(1) stringcols(_all) encoding(utf-8) bindquote(strict)
destring order, replace
isid file order
merge m:1 key using `all', keep(master match) keepusing(`stats' outcome treatment model cluster)
quietly count if _merge != 3
if r(N) > 0 {
    display as error "figure_map.csv names estimates that do not exist:"
    list file key if _merge != 3, noobs clean
    exit 111
}
drop _merge
sort file order
levelsof file, local(files)
foreach f of local files {
    preserve
    keep if file == "`f'"
    export delimited order panel group label `stats' outcome treatment model cluster key ///
        using "$PLOT_DATA/`f'.csv", replace
    display as text "`f'.csv: " as result _N as text " estimates"
    restore
}

log close export
