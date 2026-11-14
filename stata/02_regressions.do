/*==============================================================================
  02_regressions.do
  The regressions behind Figures 4-11, Tables 1 and 2, and Supplementary Tables S4-S20
  (S4-S9 and S12: the full models of Figures 4-10; S15 and S20: of Tables 1 and 2).

  Models (constituency and year dummies in all of them unless stated otherwise):
    CRE     random effects with the household means of the time-varying controls
            (correlated random effects; labelled OLS in the figures)
    IV-CRE  the same, with the treatment instrumented by tlu_sale_mean, the
            leave-one-out share of livestock sellers in the household's constituency,
            2015 and 2019 pooled (labelled IV in the figures)
  Treatments: tlu_sale, sold livestock (1/0; extensive margin), and tlu_sold, livestock
  sold in TLU (intensive margin). Standard errors are clustered on hh.

  Input : $ANALYSIS_DATA
  Output: $PLOT_DATA/coefficients_all.dta, one row per estimate
          $PLOT_DATA/fig11_kls.csv, the kinky least squares estimates of Figure 11
          $TABLES/Table1_lci.docx, Table2_lci_income.docx and Tables S4-S9, S12-S20 (Word)
          $TABLES/TableS10_joint_strategy.csv and .docx
          $TABLES/TableS11_estimates_in_sd_units.csv and .docx
==============================================================================*/

version 18
if "$RUN_ALL" == "" | "$RUN_ALL" != "$ROOT" {
    display as error "Run this file through 00_run_all.do"
    exit 198
}
capture log close regressions
log using "$LOGS/02_regressions.log", replace text name(regressions)

rp_init
use "$ANALYSIS_DATA", clear
xtset hhid Panel

local cl  $CLUSTER
local CT  $controls $tcontrols
local FE  i.const i.Panel
local SEnote Standard errors clustered on `cl'.
global TABLEKEEP tlu_sale tlu_sold cattle_d pig_d rum_d poultry_d cattle pig rum poultry lci ///
                 inc100k Off_Farm_Partic prod_diversity gender_Maindecision_maker ///
                 $controls $tcontrols _cons

* One Word table of models. depvars: when outcomes differ between columns, the
* regressors share one row each and one outcome label heads each column. keep: the
* rows to show (default: all coefficients in $TABLEKEEP). collabels: column heads in place
* of the outcome labels, as level-label pairs (1 "..." 2 "...").
capture program drop model_table
program define model_table
    args name models title note depvars keep collabels
    if "`keep'" == "" local keep $TABLEKEEP
    local recode
    local ys : list uniq depvars
    foreach y of local ys {
        local recode `recode' `y' = xb
    }
    if "`recode'" != "" local recode eqrecode(`recode')
    local columns index
    if `: word count `depvars'' == `: word count `models'' local columns dvlabel
    etable, estimates(`models') column(`columns') `recode' keep(`keep') ///
        cstat(_r_b, nformat(%9.3f)) cstat(_r_se, nformat(%9.3f)) ///
        showstars showstarsnote stars(.1 "*" .05 "**" .01 "***", attach(_r_b)) mstat(N, nformat(%9.0fc)) ///
        title("`title'") note("`note'")
    collect label levels colname _cons "Constant", modify
    if `"`collabels'"' != "" collect label levels etable_dvlabel `collabels', modify
    rp_docx "$TABLES/`name'.docx"
end

* Short labels for the row and column heads of the Word tables
capture program drop short_labels
program define short_labels
    label variable number_food6groupZ   "FBDG score"
    label variable number_food12group   "HDDS-12"
    label variable number_food9groupH   "HDDS-9"
    label variable totlv_inc            "Livestock income (kwacha)"
    label variable prod_diversity       "Production diversity"
    label variable cash_crop            "Cash crops"
    label variable food_crop            "Food crops"
    label variable Off_Farm_Partic      "Off-farm activity (1/0)"
    label variable consumed_FruitsZ     "Fruits"
    label variable consumed_VegetablesZ "Vegetables"
    label variable consumed_DairyZ      "Dairy"
    label variable consumed_PulsesZ     "Legumes"
    label variable consumed_CerealsZ    "Starch"
    label variable consumed_Meat_ProdZ  "Fish"
end
short_labels

*------------------------------------------------------------------------------
* A. Figure 4 and Table S4: livestock commercialisation and dietary diversity (FBDG score)
*------------------------------------------------------------------------------
estimates clear
local models
foreach t in tlu_sale tlu_sold {
    local mg = cond("`t'" == "tlu_sale", "ext", "int")
    xtreg number_food6groupZ `t' `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(Fig4) key(f4_`mg'_cre) outcome(FBDG) treatment(`t') model(CRE constituency and year FE) coef(`t')
    estimates store `mg'_cre
    xtivreg number_food6groupZ (`t' = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(Fig4) key(f4_`mg'_iv) outcome(FBDG) treatment(`t') model(IV-CRE constituency and year FE) coef(`t')
    estimates store `mg'_iv
    local models `models' `mg'_cre `mg'_iv
}
model_table TableS4_fig4_fbdg "`models'" ///
    "Table S4: Livestock commercialisation and dietary diversity (FBDG score)" ///
    "Outcome: FBDG score. Columns (1)-(2): sold livestock (1/0); (3)-(4): TLU sold. All columns: the controls, their household means, constituency and year dummies; IV-CRE: the treatment instrumented by the leave-one-out share of livestock sellers in the constituency. The models of Figure 4. `SEnote'" ///
    "number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ" "" ///
    `"1 "CRE" 2 "IV-CRE" 3 "CRE" 4 "IV-CRE""'

*------------------------------------------------------------------------------
* B. Figure 5 and Table S5: individual FBDG food groups, IV-CRE
*------------------------------------------------------------------------------
estimates clear
local models
local depvars
foreach t in tlu_sale tlu_sold {
    local mg = cond("`t'" == "tlu_sale", "ext", "int")
    foreach g in Fruits Vegetables Dairy Pulses Cereals Meat_Prod {
        xtivreg consumed_`g'Z (`t' = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
        rp_post, exhibit(Fig5) key(f5_`mg'_`g') outcome(consumed_`g'Z) treatment(`t') model(IV-CRE constituency and year FE) coef(`t')
        estimates store `mg'_`g'
        local models `models' `mg'_`g'
        local depvars `depvars' consumed_`g'Z
    }
}
model_table TableS5_fig5_food_groups "`models'" ///
    "Table S5: Livestock commercialisation and individual food groups (FBDG)" ///
    "Outcome: consumed the food group (1/0). Columns (1)-(6): sold livestock (1/0); (7)-(12): TLU sold. Starch: cereals, starchy roots and tubers; Fish: fish, insects and animal-source foods. All columns: IV-CRE with the controls, their household means, constituency and year dummies; the treatment instrumented by the leave-one-out share of livestock sellers in the constituency. The models of Figure 5. `SEnote'" ///
    "`depvars'"

*------------------------------------------------------------------------------
* C. Figure 6 and Table S6 (FBDG score), Tables S13 and S14 (HDDS-12): livestock species,
*    one species per model, IV-CRE.
*    Extensive margin: sold cattle, pigs and poultry (1/0) and, for small ruminants,
*    rum_d, sold goats + sold sheep (0-2). Intensive margin: TLU sold of the species.
*------------------------------------------------------------------------------
estimates clear
local models
foreach mg in ext int {
    local suffix = cond("`mg'" == "ext", "_d", "")
    foreach sp in cattle pig rum poultry {
        local v `sp'`suffix'
        xtivreg number_food6groupZ (`v' = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
        rp_post, exhibit(Fig6) key(f6_`mg'_`sp') outcome(FBDG) treatment(`v') model(IV-CRE constituency and year FE) coef(`v')
        estimates store `mg'_`sp'
        local models `models' `mg'_`sp'
    }
}
model_table TableS6_fig6_species "`models'" ///
    "Table S6: Livestock species and dietary diversity (FBDG score)" ///
    "Outcome: FBDG score. One species per column. Columns (1)-(4), sold or not: cattle, pigs, small ruminants (goats and sheep; sold goats + sold sheep, 0-2) and poultry; (5)-(8): TLU sold of the same species. All columns: IV-CRE with the controls, their household means, constituency and year dummies; the treatment instrumented by the leave-one-out share of livestock sellers in the constituency. The models of Figure 6. `SEnote'" ///
    "number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ"
foreach mg in ext int {
    local suffix = cond("`mg'" == "ext", "_d", "")
    local tab    = cond("`mg'" == "ext", "S13", "S14")
    local lt     = lower("`tab'")
    estimates clear
    local models
    foreach pair in "a cattle" "b pig" "c rum" "e poultry" {
        gettoken id sp : pair
        local sp = strtrim("`sp'")
        local v `sp'`suffix'
        xtivreg number_food12group (`v' = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
        rp_post, exhibit(Table`tab') key(`lt'_`sp') outcome(HDDS12) treatment(`v') model(IV-CRE constituency and year FE) coef(`v')
        estimates store `id'
        local models `models' `id'
    }
    if "`mg'" == "ext" {
        model_table TableS13_species_extensive_hdds12 "`models'" ///
            "Table S13: Extensive livestock heterogeneity and dietary diversity (HDDS-12)" ///
            "Outcome: HDDS-12. One species per column, sold or not: (1) cattle; (2) pigs; (3) small ruminants (goats and sheep; sold goats + sold sheep, 0-2); (4) poultry. All columns: IV-CRE, constituency and year dummies. `SEnote'" ///
            "number_food12group number_food12group number_food12group number_food12group"
    }
    else {
        model_table TableS14_species_intensive_hdds12 "`models'" ///
            "Table S14: Intensive livestock heterogeneity and dietary diversity (HDDS-12)" ///
            "Outcome: HDDS-12. One species per column, TLU sold: (1) cattle; (2) pigs; (3) small ruminants (goats and sheep); (4) poultry. All columns: IV-CRE, constituency and year dummies. `SEnote'" ///
            "number_food12group number_food12group number_food12group number_food12group"
    }
}

*------------------------------------------------------------------------------
* D. Figure 7 and Table S7: by sex of the main decision-maker
*------------------------------------------------------------------------------
estimates clear
local models
foreach g in 1 0 {
    local sx = cond(`g' == 1, "male", "female")
    local if if gender_Maindecision_maker == `g'
    foreach t in tlu_sale tlu_sold {
        local mg = cond("`t'" == "tlu_sale", "ext", "int")
        xtreg number_food6groupZ `t' `CT' `FE' `if', re vce(cluster `cl')
        rp_post, exhibit(Fig7) key(f7_`sx'_`mg'_cre) outcome(FBDG) treatment(`t') model(CRE constituency and year FE, `sx' decision-maker) coef(`t')
        estimates store `sx'_`mg'_cre
        xtivreg number_food6groupZ (`t' = tlu_sale_mean) `CT' `FE' `if', re vce(cluster `cl')
        rp_post, exhibit(Fig7) key(f7_`sx'_`mg'_iv) outcome(FBDG) treatment(`t') model(IV-CRE constituency and year FE, `sx' decision-maker) coef(`t')
        estimates store `sx'_`mg'_iv
        local models `models' `sx'_`mg'_cre `sx'_`mg'_iv
    }
}
model_table TableS7_fig7_decision_maker_sex "`models'" ///
    "Table S7: Livestock commercialisation and dietary diversity by sex of the main decision-maker" ///
    "Outcome: FBDG score. Columns (1)-(4): households with a male main decision-maker; (5)-(8): with a female main decision-maker. In each group: sold livestock (1/0), then TLU sold. All columns: the controls, their household means, constituency and year dummies; IV-CRE: the treatment instrumented by the leave-one-out share of livestock sellers in the constituency. The models of Figure 7. `SEnote'" ///
    "number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ" "" ///
    `"1 "Male, CRE" 2 "Male, IV-CRE" 3 "Male, CRE" 4 "Male, IV-CRE" 5 "Female, CRE" 6 "Female, IV-CRE" 7 "Female, CRE" 8 "Female, IV-CRE""'

*------------------------------------------------------------------------------
* E. Figure 8 and Table S8: pathways.
*    Livestock income (livestock sales revenue): household fixed effects (FE) and IV-FE,
*    with the controls and a year dummy. Production diversity, cash crops, food crops and
*    off-farm participation: IV-CRE.
*------------------------------------------------------------------------------
estimates clear
xtreg totlv_inc tlu_sale $controls i.Panel, fe vce(cluster `cl')
rp_post, exhibit(Fig8) key(f8_lvinc_fe) outcome(Livestock income) treatment(tlu_sale) model(FE year FE) coef(tlu_sale)
estimates store lv_fe
xtivreg totlv_inc (tlu_sale = tlu_sale_mean) $controls i.Panel, fe vce(cluster `cl')
rp_post, exhibit(Fig8) key(f8_lvinc_iv_fe_year) outcome(Livestock income) treatment(tlu_sale) model(IV-FE year FE) coef(tlu_sale)
estimates store lv_iv
local models lv_fe lv_iv
local depvars totlv_inc totlv_inc
foreach pair in "prod_diversity proddiv" "cash_crop cash" "food_crop food" "Off_Farm_Partic offfarm" {
    gettoken y k : pair
    local k = strtrim("`k'")
    xtivreg `y' (tlu_sale = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(Fig8) key(f8_`k') outcome(`y') treatment(tlu_sale) model(IV-CRE constituency and year FE) coef(tlu_sale)
    estimates store p_`k'
    local models `models' p_`k'
    local depvars `depvars' `y'
}
model_table TableS8_fig8_pathways "`models'" ///
    "Table S8: Livestock commercialisation and pathways" ///
    "Treatment: sold livestock (1/0). Columns (1) and (2): livestock income (livestock sales revenue, kwacha), household fixed effects (1) and IV-FE (2), with the controls and a year dummy. Columns (3) production diversity, (4) cash crops, (5) food crops and (6) off-farm activity: IV-CRE with the controls, their household means, constituency and year dummies. The IV models use the leave-one-out share of livestock sellers in the constituency. The models of Figure 8. `SEnote'" ///
    "`depvars'"

*------------------------------------------------------------------------------
* F. Figure 9 and Table S9: pathway variables and dietary diversity, CRE, one variable
*    per model.
*    Income enters per 100,000 kwacha (inc100k). In the 'Male decision' model the head's
*    sex is not among the controls, because it coincides with the decision-maker's sex
*    for 98% of the observations.
*------------------------------------------------------------------------------
local c_all $controls
local c_sex Sex_HH
local c_nosex : list c_all - c_sex
estimates clear
local models
foreach triple in "a inc100k income" "b Off_Farm_Partic offfarm" ///
                  "c prod_diversity proddiv" "d gender_Maindecision_maker maledecision" {
    gettoken id triple : triple
    gettoken x k : triple
    local k = strtrim("`k'")
    local ctl `CT'
    local mdl CRE constituency and year FE
    if "`k'" == "maledecision" {
        local ctl `c_nosex' $tcontrols
        local mdl CRE constituency and year FE, head's sex not a control
    }
    xtreg number_food6groupZ `x' `ctl' `FE', re vce(cluster `cl')
    rp_post, exhibit(Fig9) key(f9_`k') outcome(FBDG) treatment(`x') model(`mdl') coef(`x')
    estimates store `id'
    local models `models' `id'
}
model_table TableS9_fig9_pathways_diets "`models'" ///
    "Table S9: Pathways and dietary diversity" ///
    "Outcome: FBDG score. One pathway variable per column: (1) household income per 100,000 kwacha; (2) off-farm activity; (3) production diversity; (4) male main decision-maker. All columns: CRE, constituency and year dummies; in column (4) the head's sex is not among the controls. The models of Figure 9. `SEnote'" ///
    "number_food6groupZ number_food6groupZ number_food6groupZ number_food6groupZ"

*------------------------------------------------------------------------------
* G. Figure 10 and Table S12: household dietary diversity score, 12 groups (HDDS-12)
*------------------------------------------------------------------------------
estimates clear
local models
foreach t in tlu_sale tlu_sold {
    local mg = cond("`t'" == "tlu_sale", "", "int_")
    xtreg number_food12group `t' `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(Fig10) key(f10_`mg'cre) outcome(HDDS12) treatment(`t') model(CRE constituency and year FE) coef(`t')
    estimates store h_`mg'cre
    xtivreg number_food12group (`t' = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(Fig10) key(f10_`mg'iv) outcome(HDDS12) treatment(`t') model(IV-CRE constituency and year FE) coef(`t')
    estimates store h_`mg'iv
    local models `models' h_`mg'cre h_`mg'iv
}
model_table TableS12_fig10_hdds12 "`models'" ///
    "Table S12: Livestock commercialisation and the household dietary diversity score (HDDS-12)" ///
    "Outcome: HDDS-12. Columns (1)-(2): sold livestock (1/0); (3)-(4): TLU sold. All columns: the controls, their household means, constituency and year dummies; IV-CRE: the treatment instrumented by the leave-one-out share of livestock sellers in the constituency. The models of Figure 10. `SEnote'" ///
    "number_food12group number_food12group number_food12group number_food12group" "" ///
    `"1 "CRE" 2 "IV-CRE" 3 "CRE" 4 "IV-CRE""'

*------------------------------------------------------------------------------
* H. Figure 11: kinky least squares (KLS) and 2SLS, without fixed effects.
*    The 2SLS line uses non-robust standard errors, as kinkyreg's small option does.
*    The KLS estimates and their intervals are stored over the grid of postulated
*    endogeneity correlations, and R draws the figure from them.
*------------------------------------------------------------------------------
tempname kls
tempfile klsfile
postfile `kls' byte order str24 panel double(endogeneity kls kls_low kls_high iv iv_low iv_high) using `klsfile'
local order = 0
foreach triple in "number_food6groupZ|fbdg|FBDGs" "totlv_inc|lvinc|Income" ///
                  "prod_diversity|proddiv|Production diversity" "Off_Farm_Partic|offfarm|Off-farm income" {
    tokenize "`triple'", parse("|")
    local y   `1'
    local k   `3'
    local ttl `5'
    local ++order
    ivregress 2sls `y' (tlu_sale = tlu_sale_mean) `CT', small
    rp_post, cluster(none) exhibit(Fig11) key(f11_2sls_`k') outcome(`y') treatment(tlu_sale) ///
        model(2SLS no FE non-robust SE) coef(tlu_sale)
    local iv      = _b[tlu_sale]
    local iv_low  = `iv' - invttail(e(df_r), 0.025) * _se[tlu_sale]
    local iv_high = `iv' + invttail(e(df_r), 0.025) * _se[tlu_sale]

    kinkyreg `y' (tlu_sale = tlu_sale_mean) `CT', range(-0.75 0.75) small inference(tlu_sale) nograph
    tempname b lo hi
    matrix `b'  = e(b_kls)
    matrix `lo' = e(cilb_kls)
    matrix `hi' = e(ciub_kls)
    local j = colnumb(`b', "tlu_sale")
    local grid_min  = e(grid_min)
    local grid_step = e(grid_step)
    forvalues g = 1/`=rowsof(`b')' {
        post `kls' (`order') ("`ttl'") (`grid_min' + (`g' - 1) * `grid_step') (`b'[`g', `j']) (`lo'[`g', `j']) (`hi'[`g', `j']) ///
            (`iv') (`iv_low') (`iv_high')
    }
}
postclose `kls'
preserve
use `klsfile', clear
export delimited order panel endogeneity kls kls_low kls_high iv iv_low iv_high ///
    using "$PLOT_DATA/fig11_kls.csv", replace
restore

*------------------------------------------------------------------------------
* I. The livestock commercialisation index (LCI), IV-CRE: Tables 1, 2, S15 and S20 (dietary
*    diversity), S16 and S17 (food groups), S18 (pathways) and S19 (by sex of the main
*    decision-maker).
*    LCI = 100 x TLU sold / (TLU sold + TLU owned at the survey): the per cent of the
*    herd before the sales that was sold. It is instrumented by tlu_sale_mean, as the
*    treatments of the main models. The livestock income model of Table S18 is IV-FE
*    with a year dummy, as in Figure 8.
*------------------------------------------------------------------------------
generate double lci = cond(tlu_sold == 0, 0, 100 * tlu_sold / (tlu_sold + tlu_today))
label variable lci "Livestock commercialisation index (LCI)"
local LCInote IV-CRE: LCI instrumented by the leave-one-out share of livestock sellers in the constituency; the controls, their household means, constituency and year dummies.

* Tables 1 and 2, as in the manuscript, and Tables S15 and S20, their full models.
* Table 2 adds household income (per 100,000 kwacha) to the controls, without its
* household mean.
foreach tab in 1 2 {
    estimates clear
    local models
    local depvars
    if `tab' == 1 {
        local inc
        local mdl IV-CRE constituency and year FE
        local outcomes `""number_food6groupZ fbdg" "number_food12group hdds12" "number_food9groupH hdds9""'
    }
    else {
        local inc inc100k
        local mdl IV-CRE constituency and year FE, income control
        local outcomes `""number_food12group hdds12" "number_food9groupH hdds9" "number_food6groupZ fbdg""'
    }
    foreach pair of local outcomes {
        gettoken y k : pair
        local k = strtrim("`k'")
        xtivreg `y' (lci = tlu_sale_mean) `CT' `inc' `FE', re vce(cluster `cl')
        rp_post, exhibit(Table`tab') key(t`tab'_`k') outcome(`y') treatment(lci) ///
            model(`mdl') coef(lci)
        estimates store t`tab'_`k'
        local models `models' t`tab'_`k'
        local depvars `depvars' `y'
    }
    if `tab' == 1 {
        model_table Table1_lci "`models'" ///
            "Table 1: Association between livestock commercialisation index and dietary diversity" ///
            "`LCInote' Full models in Table S15. `SEnote'" "`depvars'" "lci _cons"
        model_table TableS15_lci_dietary_diversity "`models'" ///
            "Table S15: Association between livestock commercialisation index and dietary diversity" ///
            "`LCInote' The models of Table 1. `SEnote'" "`depvars'"
    }
    else {
        model_table Table2_lci_income "`models'" ///
            "Table 2: Livestock commercialisation and dietary diversity after controlling for income" ///
            "`LCInote' Household income (100,000 kwacha) is added to the controls, without its household mean. Full models in Table S20. `SEnote'" "`depvars'" "lci _cons"
        model_table TableS20_lci_income_full "`models'" ///
            "Table S20: Livestock commercialisation and dietary diversity after controlling for income" ///
            "`LCInote' Household income (100,000 kwacha) is added to the controls, without its household mean. The models of Table 2. `SEnote'" "`depvars'"
    }
}

* Table S16: the twelve HDDS-12 food groups. The HDDS-12 vegetables, fruits, pulses and
* milk groups are the same food items as the FBDG groups (Table S2).
estimates clear
local models
local depvars
local i = 0
foreach triple in "consumed_DairyZ dairy Dairy" "consumed_Cereals cereals Cereals" ///
                  "consumed_Tubers tubers Tubers" "consumed_VegetablesZ vegetables Vegetables" ///
                  "consumed_FruitsZ fruits Fruits" "consumed_PulsesZ pulses Pulses" ///
                  "consumed_Oils oils Oils" "consumed_Sugars sugars Sugars" "consumed_Fish fish Fish" ///
                  "consumed_Eggs eggs Eggs" "consumed_Meat_Prod meat Meat" "consumed_Spices spices Spices" {
    gettoken y triple : triple
    gettoken k lab : triple
    local lab = strtrim("`lab'")
    label variable `y' "`lab'"
    local ++i
    xtivreg `y' (lci = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(TableS16) key(s16_`k') outcome(`y') treatment(lci) model(IV-CRE constituency and year FE) coef(lci)
    estimates store m`i'
    local models `models' m`i'
    local depvars `depvars' `y'
}
model_table TableS16_lci_hdds_food_groups "`models'" ///
    "Table S16: Association between livestock commercialisation index and individual food groups (HDDS-12)" ///
    "Outcome: consumed the food group (1/0). `LCInote' `SEnote'" "`depvars'"

* Table S17: the six FBDG food groups ('Starch': cereals, starchy roots and tubers; 'Fish':
* fish, insects and animal-source foods)
short_labels
estimates clear
local models
local depvars
local i = 0
foreach g in Fruits Vegetables Dairy Pulses Cereals Meat_Prod {
    local ++i
    xtivreg consumed_`g'Z (lci = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(TableS17) key(s17_`g') outcome(consumed_`g'Z) treatment(lci) model(IV-CRE constituency and year FE) coef(lci)
    estimates store m`i'
    local models `models' m`i'
    local depvars `depvars' consumed_`g'Z
}
model_table TableS17_lci_fbdg_food_groups "`models'" ///
    "Table S17: Association between livestock commercialisation index and individual food groups (FBDG)" ///
    "Outcome: consumed the food group (1/0). Starch: cereals, starchy roots and tubers; Fish: fish, insects and animal-source foods. `LCInote' `SEnote'" "`depvars'"

* Table S18: pathways
estimates clear
xtivreg totlv_inc (lci = tlu_sale_mean) $controls i.Panel, fe vce(cluster `cl')
rp_post, exhibit(TableS18) key(s18_lvinc) outcome(Livestock income) treatment(lci) model(IV-FE year FE) coef(lci)
estimates store m1
local models m1
local depvars totlv_inc
local i = 1
foreach pair in "prod_diversity proddiv" "cash_crop cash" "food_crop food" "Off_Farm_Partic offfarm" {
    gettoken y k : pair
    local k = strtrim("`k'")
    local ++i
    xtivreg `y' (lci = tlu_sale_mean) `CT' `FE', re vce(cluster `cl')
    rp_post, exhibit(TableS18) key(s18_`k') outcome(`y') treatment(lci) model(IV-CRE constituency and year FE) coef(lci)
    estimates store m`i'
    local models `models' m`i'
    local depvars `depvars' `y'
}
model_table TableS18_lci_pathways "`models'" ///
    "Table S18: Livestock commercialisation index and pathways" ///
    "Column (1): livestock income (livestock sales revenue, kwacha), IV-FE with household fixed effects, the controls and a year dummy. Columns (2) production diversity (number of crops), (3) cash crops, (4) food crops and (5) off-farm activity: IV-CRE with the controls, their household means, constituency and year dummies. LCI instrumented by the leave-one-out share of livestock sellers in the constituency. `SEnote'" ///
    "`depvars'"

* Table S19: by sex of the main decision-maker
estimates clear
local models
local depvars
local i = 0
foreach g in 1 0 {
    local sx = cond(`g' == 1, "male", "female")
    foreach pair in "number_food12group hdds12" "number_food6groupZ fbdg" {
        gettoken y k : pair
        local k = strtrim("`k'")
        local ++i
        xtivreg `y' (lci = tlu_sale_mean) `CT' `FE' if gender_Maindecision_maker == `g', re vce(cluster `cl')
        rp_post, exhibit(TableS19) key(s19_`sx'_`k') outcome(`y') treatment(lci) ///
            model(IV-CRE constituency and year FE, `sx' decision-maker) coef(lci)
        estimates store m`i'
        local models `models' m`i'
        local depvars `depvars' `y'
    }
}
model_table TableS19_lci_decision_maker_sex "`models'" ///
    "Table S19: Gendered decision making and dietary diversity" ///
    "Columns: (1) HDDS-12 and (2) FBDG score, households with a male main decision-maker; (3) HDDS-12 and (4) FBDG score, households with a female main decision-maker. `LCInote' `SEnote'" ///
    "`depvars'" "" `"1 "Male, HDDS-12" 2 "Male, FBDG score" 3 "Female, HDDS-12" 4 "Female, FBDG score""'

rp_save

*------------------------------------------------------------------------------
* J. Table S10: households that sell both crops and livestock (both = 1) against all
*    other households, who sell neither, only crops or only livestock (both = 0).
*    CRE model of Figure 4 on its estimation sample, with crop market participation and
*    its household mean left out of the controls, because selling crops is part of the
*    comparison.
*------------------------------------------------------------------------------
use "$ANALYSIS_DATA", clear
xtset hhid Panel
short_labels

local allc $controls
local allt $tcontrols
local drop Market_Participation
local c2 : list allc - drop
local drop Market_Participationbar
local t2 : list allt - drop

generate byte both = Market_Participation == 1 & tlu_sale == 1 if insample
label variable both "Sells both crops and livestock (1/0)"
count if insample & both == 1
local n_both = r(N)
count if insample & both == 0
local n_other = r(N)

tempname h
file open `h' using "$TABLES/TableS10_joint_strategy.csv", write replace
file write `h' "outcome,estimate,std_error,p_value,conf_low,conf_high,n_obs,n_clusters,n_both,n_others" _n
estimates clear
foreach y in number_food6groupZ number_food12group {
    xtreg `y' both `c2' `t2' i.const i.Panel if insample, re vce(cluster `cl')
    estimates store js_`y'
    local b = _b[both]
    local se = _se[both]
    local p = 2 * normal(-abs(`b' / `se'))
    file write `h' "`y'," %12.0g (`b') "," %12.0g (`se') "," %12.0g (`p') "," ///
        %12.0g (`b' - invnormal(0.975) * `se') "," %12.0g (`b' + invnormal(0.975) * `se') "," ///
        (e(N)) "," (e(N_clust)) ",`n_both',`n_other'" _n
}
file close `h'

etable, estimates(js_number_food6groupZ js_number_food12group) column(dvlabel) keep(both) ///
    eqrecode(number_food6groupZ = xb number_food12group = xb) ///
    cstat(_r_b, nformat(%9.3f)) cstat(_r_se, nformat(%9.3f)) ///
    showstars showstarsnote stars(.1 "*" .05 "**" .01 "***", attach(_r_b)) mstat(N, nformat(%9.0fc)) ///
    title("Table S10: joint crop and livestock market participation and dietary diversity") ///
    note("CRE with household means of the controls, constituency and year dummies; crop market participation is not a control. Reference group: households that sell neither, only crops or only livestock. Standard errors clustered on `cl'.")
rp_docx "$TABLES/TableS10_joint_strategy.docx"

*------------------------------------------------------------------------------
* K. Table S11: the estimates of Figure 4 (FBDG score) and Figure 10 (HDDS-12) on a
*    common scale, divided by the standard deviation (SD units) and by the mean (% of
*    mean) of the outcome on the estimation sample.
*------------------------------------------------------------------------------
use "$ANALYSIS_DATA", clear
foreach y in number_food6groupZ number_food12group {
    quietly summarize `y' if insample
    local km_`y' = r(mean)
    local ks_`y' = r(sd)
}
display as text "FBDG score: mean " %5.3f `km_number_food6groupZ' ", SD " %5.3f `ks_number_food6groupZ' ///
    "; HDDS-12: mean " %5.3f `km_number_food12group' ", SD " %5.3f `ks_number_food12group'

use "$PLOT_DATA/coefficients_all.dta", clear
keep if inlist(key, "f4_ext_cre", "f4_ext_iv", "f4_int_cre", "f4_int_iv", ///
                    "f10_cre", "f10_iv", "f10_int_cre", "f10_int_iv")
generate str8 yvar   = cond(substr(key, 1, 3) == "f4_", "FBDG", "HDDS12")
generate str3 margin = cond(strpos(key, "_int_"), "int", "ext")
generate str5 est    = cond(strpos(key, "_iv"), "ivcre", "cre")
generate double mean_y = cond(yvar == "FBDG", `km_number_food6groupZ', `km_number_food12group')
generate double sd_y   = cond(yvar == "FBDG", `ks_number_food6groupZ', `ks_number_food12group')
generate double b_sd   = b / sd_y
generate double se_sd  = se / sd_y
generate double b_pct  = 100 * b / mean_y
keep key yvar margin est b se p n b_sd se_sd b_pct mean_y sd_y
order key yvar margin est b se p b_sd se_sd b_pct mean_y sd_y n
sort yvar est margin
list key yvar est margin b b_sd b_pct p, noobs
export delimited using "$TABLES/TableS11_estimates_in_sd_units.csv", replace

* Cells: estimate row (coefficient with stars, SD units, % of mean), then SE row
foreach y in FBDG HDDS12 {
    foreach e in cre ivcre {
        foreach m in ext int {
            quietly levelsof key if yvar == "`y'" & est == "`e'" & margin == "`m'", local(k) clean
            quietly summarize b if key == "`k'"
            local b = r(mean)
            quietly summarize se if key == "`k'"
            local se = r(mean)
            quietly summarize p if key == "`k'"
            local p = r(mean)
            local st = cond(`p' < 0.01, "***", cond(`p' < 0.05, "**", cond(`p' < 0.1, "*", "")))
            local cb_`y'_`e'_`m' = strtrim(string(`b', "%6.3f")) + "`st'"
            local cs_`y'_`e'_`m' = "(" + strtrim(string(`se', "%6.3f")) + ")"
            quietly summarize b_sd if key == "`k'"
            local cd_`y'_`e'_`m' = strtrim(string(r(mean), "%6.3f"))
            quietly summarize se_sd if key == "`k'"
            local ce_`y'_`e'_`m' = "(" + strtrim(string(r(mean), "%6.3f")) + ")"
            quietly summarize b_pct if key == "`k'"
            local cp_`y'_`e'_`m' = strtrim(string(r(mean), "%5.1f"))
        }
    }
}
local mF : display %4.2f `km_number_food6groupZ'
local sF : display %4.2f `ks_number_food6groupZ'
local mH : display %4.2f `km_number_food12group'
local sH : display %4.2f `ks_number_food12group'
clear
set obs 10
generate str60 rlab = ""
forvalues c = 1/6 {
    generate str16 c`c' = ""
}
local r = 0
foreach y in FBDG HDDS12 {
    local ++r
    if "`y'" == "FBDG" quietly replace rlab = "FBDG score (mean `mF', SD `sF')" in `r'
    else               quietly replace rlab = "HDDS-12 (mean `mH', SD `sH')" in `r'
    local heads `heads' `r'
    foreach e in cre ivcre {
        local ++r
        quietly replace rlab = cond("`e'" == "cre", "CRE", "IV-CRE") in `r'
        quietly replace c1 = "`cb_`y'_`e'_ext'" in `r'
        quietly replace c2 = "`cd_`y'_`e'_ext'" in `r'
        quietly replace c3 = "`cp_`y'_`e'_ext'" in `r'
        quietly replace c4 = "`cb_`y'_`e'_int'" in `r'
        quietly replace c5 = "`cd_`y'_`e'_int'" in `r'
        quietly replace c6 = "`cp_`y'_`e'_int'" in `r'
        local ++r
        quietly replace c1 = "`cs_`y'_`e'_ext'" in `r'
        quietly replace c2 = "`ce_`y'_`e'_ext'" in `r'
        quietly replace c4 = "`cs_`y'_`e'_int'" in `r'
        quietly replace c5 = "`ce_`y'_`e'_int'" in `r'
    }
}
putdocx clear
putdocx begin, font("Times New Roman", 10)
putdocx paragraph
putdocx text ("Table S11: Associations on a common scale: standard deviations and per cent of the mean"), bold
putdocx table sd = data(rlab c1 c2 c3 c4 c5 c6), varnames border(all, nil) border(top) border(bottom) layout(autofitcontents)
putdocx table sd(1,1) = ("")
putdocx table sd(1,2) = ("Coef."), bold halign(center)
putdocx table sd(1,3) = ("SD units"), bold halign(center)
putdocx table sd(1,4) = ("% of mean"), bold halign(center)
putdocx table sd(1,5) = ("Coef."), bold halign(center)
putdocx table sd(1,6) = ("SD units"), bold halign(center)
putdocx table sd(1,7) = ("% of mean"), bold halign(center)
putdocx table sd(1,.), addrows(1, before)
putdocx table sd(1,2) = ("Sold livestock (1/0)"), bold halign(center)
putdocx table sd(1,5) = ("TLU sold"), bold halign(center)
putdocx table sd(1,5), colspan(3)
putdocx table sd(1,2), colspan(3)
putdocx table sd(2,.), border(bottom)
foreach h of local heads {
    local hr = `h' + 2
    putdocx table sd(`hr',1), bold
}
putdocx table sd(7,.), border(bottom)
forvalues k = 2/7 {
    putdocx table sd(.,`k'), halign(center)
}
putdocx paragraph
putdocx text ("Coefficients of Figure 4 (FBDG score) and Figure 10 (HDDS-12), models with constituency and year dummies (CRE and IV-CRE, labelled OLS and IV in the figures), divided by the standard deviation (SD units) and by the mean (% of mean) of the outcome in the estimation sample of 11,963 household-wave observations. Sold livestock: selling against not selling; TLU sold: one more TLU sold. The two margins are in different units and are not compared with each other. Standard errors clustered on hh in parentheses (in SD units under the SD-unit estimates); *** p<0.01, ** p<0.05, * p<0.1."), italic
putdocx save "$TABLES/TableS11_estimates_in_sd_units.docx", replace

log close regressions
