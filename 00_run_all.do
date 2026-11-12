/*==============================================================================
  Smallholder Livestock Commercialisation and Dietary Diversity:
  Panel Data Evidence from Zambia
  Martin Paul Jr. Tabe-Ojong, Emmanuel Tolani, Abebayehu G. Geffersa

  00_run_all.do runs the whole analysis, from the analysis data to the figures and
  tables:

    stata/01_descriptives.do       Figures 2 and 3, Tables S1, S2 and S3
    stata/02_regressions.do        Figures 4-11, Tables 1, 2 and S4-S19
    stata/03_export_plot_data.do   coefficients and 95% intervals for the figures
    R/01_run_all_figures.R         draws Figures 2-11

  How to run
    Open Stata 18 (SE or MP), cd to this folder and type:  do 00_run_all.do

  Software: Stata 18 with kinkyreg (Figure 11), which is bundled in stata/ado/plus;
  R 4.5 with ggplot2, patchwork, dplyr, tidyr and readr.
==============================================================================*/

version 18
clear all
set more off
set varabbrev off
set linesize 120

*------------------------------------------------------------------------------
* 1. Paths. Leave ROOT empty to use the current working directory.
*------------------------------------------------------------------------------
global ROOT ""
if "$ROOT" == "" global ROOT = subinstr("`c(pwd)'", "\", "/", .)
capture confirm file "$ROOT/00_run_all.do"
if _rc {
    display as error "Cannot find 00_run_all.do under $ROOT."
    display as error "cd to this folder or set the global ROOT in 00_run_all.do."
    exit 601
}
* Checked by the do-files in stata/, so that they run only through this file
global RUN_ALL "$ROOT"

global DATA          "$ROOT/data"
global ANALYSIS_DATA "$DATA/analysis_data.dta"
global SALES_DATA    "$DATA/livestock_sales_2012_2019.dta"
global STATA         "$ROOT/stata"
global PLOT_DATA     "$ROOT/plot_data"
global TABLES        "$ROOT/tables"
global LOGS          "$ROOT/logs"

* Rscript. Leave empty to look in the standard Windows location.
global RSCRIPT ""

foreach path in "$DATA" "$PLOT_DATA" "$TABLES" "$LOGS" "$ROOT/figures" {
    capture mkdir "`path'"
    mata: st_local("ok", strofreal(direxists(st_local("path"))))
    if !`ok' {
        display as error "Cannot create the folder `path'"
        exit 693
    }
}

* The data are not part of the package (README.md, 'Data availability')
foreach f in "$ANALYSIS_DATA" "$SALES_DATA" {
    capture confirm file "`f'"
    if _rc {
        display as error "Data file not found: `f'"
        display as error "Request the RALS data from IAPRI and save the two analysis files in $DATA"
        display as error "(see README.md, 'Data availability')."
        exit 601
    }
}

* The table helpers and the bundled kinkyreg come first on the ado-path; your own
* Stata installation is not changed.
adopath ++ "$STATA/ado/plus"
adopath ++ "$STATA/ado"
mata: mata mlib index

*------------------------------------------------------------------------------
* 2. Specification
*------------------------------------------------------------------------------
global controls  Sex_HH Education_HH age hhsize Access_Credit Cult_OwnLand_Size ///
                 Total_OwnLand_Size Market_Participation FISP_participation ///
                 drought Floods Pests_diseases shocks asset_index
* Household means of the time-varying controls (correlated random effects, CRE)
global tcontrols Education_HHbar agebar hhsizebar Access_Creditbar Cult_OwnLand_Sizebar ///
                 Total_OwnLand_Sizebar Market_Participationbar FISP_participationbar ///
                 droughtbar Floodsbar Pests_diseasesbar shocksbar asset_indexbar
* Standard errors are clustered on hh
global CLUSTER   hh

*------------------------------------------------------------------------------
* 3. Log and software versions
*------------------------------------------------------------------------------
capture log close _all
log using "$LOGS/00_run_all.log", replace text name(master)
display as text "Folder: $ROOT"
display as text "Stata/" c(edition_real) " " c(stata_version) " (update of " c(born_date) "), " ///
    c(os) ", started " c(current_date) " " c(current_time)
which kinkyreg

*------------------------------------------------------------------------------
* 4. Analysis in Stata
*------------------------------------------------------------------------------
capture erase "$PLOT_DATA/coefficients_all.dta"
timer clear
local step = 0
foreach f in 01_descriptives 02_regressions 03_export_plot_data {
    local ++step
    timer on `step'
    display as text _n "{hline 78}" _n "Running `f'.do" _n "{hline 78}"
    do "$STATA/`f'.do"
    timer off `step'
}

*------------------------------------------------------------------------------
* 5. Figures in R. The script writes a marker file when it has finished, because
*    shell does not return the exit code of the program it runs.
*------------------------------------------------------------------------------
if "$RSCRIPT" == "" {
    local rdirs : dir "C:/Program Files/R" dirs "R-*"
    foreach d of local rdirs {
        capture confirm file "C:/Program Files/R/`d'/bin/Rscript.exe"
        if !_rc global RSCRIPT "C:/Program Files/R/`d'/bin/Rscript.exe"
    }
}
capture confirm file "$RSCRIPT"
if _rc {
    display as error "Rscript not found. Set the global RSCRIPT in 00_run_all.do."
    exit 601
}
local f 01_run_all_figures
timer on 20
display as text _n "{hline 78}" _n "Running R/`f'.R" _n "{hline 78}"
capture erase "$LOGS/`f'.done"
capture erase "$LOGS/`f'.log"
* The command goes through a small script, because cmd.exe mangles a command line
* that starts with a quoted path and contains other quoted paths. Stata writes UTF-8,
* so cmd.exe must read it as such, or a path with an umlaut is not found.
local script "$LOGS/`f'.cmd"
tempname h
file open `h' using "`script'", write replace
if c(os) == "Windows" file write `h' "chcp 65001 >nul" _n
file write `h' `""$RSCRIPT" --vanilla "$ROOT/R/`f'.R" "$ROOT" > "$LOGS/`f'.log" 2>&1"' _n
file close `h'
if c(os) == "Windows" shell "`script'"
else                  shell sh "`script'"
erase "`script'"
timer off 20
capture confirm file "$LOGS/`f'.done"
if _rc {
    display as error "`f'.R did not finish; see $LOGS/`f'.log"
    exit 9
}
erase "$LOGS/`f'.done"

timer list
display as text _n "Finished " c(current_date) " " c(current_time)
log close master
