/*==============================================================================
  01_descriptives.do
  1. Figure 2: livestock sold per household, by species and wave (2012, 2015, 2019)
  2. Figure 3: share of households consuming each FBDG food group, by wave
  3. Table S3: food-group consumption by livestock seller status and tercile of
     TLU sold
  4. Table S1: the conversion factors for tropical livestock units (TLU)
  5. Table S2: the RALS food items and the food groups of the HDDS-12 and the FBDG score

  Input : $ANALYSIS_DATA, $SALES_DATA
  Output: $PLOT_DATA/fig02_livestock_sold.csv, $PLOT_DATA/fig03_food_groups_by_wave.csv
          $TABLES/TableS3_food_groups_by_seller.csv and .docx
          $TABLES/TableS1_tlu_factors.docx, $TABLES/TableS2_food_groups.docx
==============================================================================*/

version 18
if "$RUN_ALL" == "" | "$RUN_ALL" != "$ROOT" {
    display as error "Run this file through 00_run_all.do"
    exit 198
}
capture log close describe
log using "$LOGS/01_descriptives.log", replace text name(describe)

use "$ANALYSIS_DATA", clear

local fbdg     consumed_FruitsZ consumed_VegetablesZ consumed_DairyZ consumed_PulsesZ ///
               consumed_CerealsZ consumed_Meat_ProdZ

*------------------------------------------------------------------------------
* 1. Figure 2: livestock sold per household, by species and wave (all three waves).
*    Mean TLU sold per household; small ruminants are goats and sheep.
*------------------------------------------------------------------------------
preserve
use "$SALES_DATA", clear
generate double rum = goat + sheep
foreach v in tlu_sold cattle pig poultry {
    recast double `v'
}
collapse (mean) m_tlu_sold = tlu_sold m_cattle = cattle m_rum = rum m_pig = pig m_poultry = poultry, by(Panel)
reshape long m_, i(Panel) j(measure) string
generate byte order = .
generate str20 panel = ""
generate str40 y_title = ""
local i = 0
foreach triple in "tlu_sold|Total TLU|Average Total TLU Sold" "cattle|Cattle|Average Cattle Sold (TLU)" ///
                  "rum|Small ruminants|Average Small Ruminants Sold (TLU)" "pig|Pigs|Average Pigs Sold (TLU)" ///
                  "poultry|Poultry|Average Poultry Sold (TLU)" {
    tokenize "`triple'", parse("|")
    local ++i
    replace order   = `i'   if measure == "`1'"
    replace panel   = "`3'" if measure == "`1'"
    replace y_title = "`5'" if measure == "`1'"
}
assert !missing(order)
rename (Panel m_) (wave mean_tlu_sold)
sort order wave
order order panel y_title wave mean_tlu_sold measure
list, noobs sepby(order)
export delimited using "$PLOT_DATA/fig02_livestock_sold.csv", replace
restore

*------------------------------------------------------------------------------
* 2. Figure 3: share of households consuming each FBDG group, by wave
*    (all households with dietary data: 6,625 in 2015, 6,139 in 2019).
*------------------------------------------------------------------------------
preserve
keep Panel `fbdg'
foreach v of local fbdg {
    recast double `v'
}
collapse (mean) `fbdg', by(Panel)
foreach v of local fbdg {
    replace `v' = 100 * `v'
}
rename consumed_* m_*
reshape long m_, i(Panel) j(variable) string
rename (Panel m_) (wave percent)
generate byte order = .
generate str20 group = ""
local i = 0
foreach pair in CerealsZ=Cereals VegetablesZ=Vegetables Meat_ProdZ=Meat PulsesZ=Pulses FruitsZ=Fruits DairyZ=Dairy {
    gettoken name lab : pair, parse("=")
    local lab : subinstr local lab "=" ""
    local ++i
    replace order = `i'     if variable == "`name'"
    replace group = "`lab'" if variable == "`name'"
}
assert !missing(order)
sort wave order
order wave order group percent variable
export delimited using "$PLOT_DATA/fig03_food_groups_by_wave.csv", replace
restore

*------------------------------------------------------------------------------
* 3. Table S3: share of households that consumed each FBDG and HDDS-12 food group on
*    the recall day, by livestock seller status and, for sellers, by tercile of TLU
*    sold. Estimation sample of the main models (insample), 2015 and 2019 pooled.
*    The HDDS-12 vegetables, fruits, legumes and milk groups are the same food items as
*    the FBDG vegetables, fruits, legumes and dairy groups (Table S2), so the FBDG
*    variables serve for them.
*------------------------------------------------------------------------------
preserve
keep if insample
xtile tercile = tlu_sold if tlu_sale == 1, nquantiles(3)
generate byte group = cond(tlu_sale == 0, 0, tercile)
* Each seller also enters the all-sellers column (group 9)
expand 2 if tlu_sale == 1, generate(dupl)
replace group = 9 if dupl
egen byte hh_first = tag(group hhid)
local shares consumed_CerealsZ consumed_VegetablesZ consumed_FruitsZ consumed_PulsesZ ///
    consumed_DairyZ consumed_Meat_ProdZ ///
    consumed_Cereals consumed_Tubers consumed_Meat_Prod consumed_Eggs consumed_Fish ///
    consumed_Oils consumed_Sugars consumed_Spices
foreach v of local shares {
    recast double `v'
}
recast double tlu_sold
collapse (mean) `shares' number_food6groupZ number_food12group tlu_sold ///
    (min) tlu_min = tlu_sold (max) tlu_max = tlu_sold ///
    (count) observations = hhid (sum) households = hh_first, by(group)
label define sgroup 0 "Non-sellers" 9 "All sellers" 1 "Sellers, lowest third of TLU sold" ///
    2 "Sellers, middle third" 3 "Sellers, top third"
label values group sgroup
generate byte col = cond(group == 0, 1, cond(group == 9, 2, group + 2))
sort col
list group observations households tlu_min tlu_max, noobs
export delimited group col `shares' number_food6groupZ number_food12group tlu_sold tlu_min ///
    tlu_max observations households using "$TABLES/TableS3_food_groups_by_seller.csv", replace

* Cells for the Word table: shares in % (one decimal), scores (two decimals)
forvalues c = 1/5 {
    foreach v of local shares {
        local s_`v'_`c' : display %5.1f 100 * `v'[`c']
    }
    local s_fbdg_`c'  : display %5.2f number_food6groupZ[`c']
    local s_hdds_`c'  : display %5.2f number_food12group[`c']
    local s_tlu_`c'   : display %6.3f tlu_sold[`c']
    local lo : display %6.3f tlu_min[`c']
    local hi : display %6.3f tlu_max[`c']
    local s_range_`c' = strtrim("`lo'") + "-" + strtrim("`hi'")
    local s_obs_`c'   : display %9.0fc observations[`c']
    local s_hh_`c'    : display %9.0fc households[`c']
}
local s_range_1 "0"

clear
local rows `""h|FBDG food groups (% of households)" "consumed_CerealsZ|Cereals, starchy roots and tubers" "consumed_VegetablesZ|Vegetables" "consumed_FruitsZ|Fruits""'
local rows `"`rows' "consumed_PulsesZ|Legumes, pulses and nuts" "consumed_DairyZ|Dairy" "consumed_Meat_ProdZ|Fish, insects and animal-source foods" "fbdg|FBDG score (mean, 0-6)""'
local rows `"`rows' "h|HDDS-12 food groups (% of households)" "consumed_Cereals|Cereals" "consumed_Tubers|Roots and tubers" "consumed_VegetablesZ|Vegetables""'
local rows `"`rows' "consumed_FruitsZ|Fruits" "consumed_PulsesZ|Pulses, legumes and nuts" "consumed_DairyZ|Milk and milk products" "consumed_Meat_Prod|Meat""'
local rows `"`rows' "consumed_Eggs|Eggs" "consumed_Fish|Fish" "consumed_Oils|Oils and fats" "consumed_Sugars|Sugar and sweets""'
local rows `"`rows' "consumed_Spices|Spices, condiments and beverages" "hdds|HDDS-12 (mean, 0-12)" "tlu|TLU sold (mean)" "range|TLU sold (range)""'
local rows `"`rows' "obs|Observations" "hh|Households""'
local n : word count `rows'
set obs `n'
generate str60 rlab = ""
forvalues c = 1/5 {
    generate str16 c`c' = ""
}
local r = 0
local heads
foreach row of local rows {
    local ++r
    gettoken key lab : row, parse("|")
    local lab : subinstr local lab "|" ""
    quietly replace rlab = "`lab'" in `r'
    if "`key'" == "h" {
        local heads `heads' `r'
        continue
    }
    local stem s_`key'
    forvalues c = 1/5 {
        quietly replace c`c' = strtrim("``stem'_`c''") in `r'
    }
}
putdocx clear
putdocx begin, font("Times New Roman", 10)
putdocx paragraph
putdocx text ("Table S3: Food-group consumption by livestock seller status and tercile of TLU sold"), bold
putdocx table fg = data(rlab c1 c2 c3 c4 c5), varnames border(all, nil) border(top) border(bottom) layout(autofitcontents)
putdocx table fg(1,1) = ("")
putdocx table fg(1,2) = ("Non-sellers"), bold halign(center)
putdocx table fg(1,3) = ("All sellers"), bold halign(center)
putdocx table fg(1,4) = ("Sellers, lowest third"), bold halign(center)
putdocx table fg(1,5) = ("Sellers, middle third"), bold halign(center)
putdocx table fg(1,6) = ("Sellers, top third"), bold halign(center)
putdocx table fg(1,.), border(bottom)
foreach h of local heads {
    local hr = `h' + 1
    putdocx table fg(`hr',1), bold
}
* rules before the HDDS-12 block and before the TLU and count rows
local hdds_head : word 2 of `heads'
local before_hdds = `hdds_head'
putdocx table fg(`before_hdds',.), border(bottom)
local before_tlu = `n' - 4 + 1
putdocx table fg(`before_tlu',.), border(bottom)
forvalues k = 2/6 {
    putdocx table fg(.,`k'), halign(center)
}
putdocx paragraph
putdocx text ("Share of households that consumed each food group on the recall day (24-hour recall, any household member), estimation sample of the main models, 2015 and 2019 pooled. Sellers are households that sold livestock (the treatment in the main models); they are split into thirds of TLU sold. The all-sellers column pools the three tercile columns, so each seller is counted there and in its tercile column. A household can also appear in more than one of the other columns if its selling or its tercile of TLU sold changes between waves; the household rows count distinct households in each column. The HDDS-12 vegetables, fruits, legumes and milk groups are the same food items as the FBDG vegetables, fruits, legumes and dairy groups (Table S2)."), italic
putdocx save "$TABLES/TableS3_food_groups_by_seller.docx", replace
restore

*------------------------------------------------------------------------------
* 4. Table S1: the TLU factors applied to the numbers of animals owned and sold
*------------------------------------------------------------------------------
local rows `""Cattle|0.70" "Donkeys|0.70" "Pigs|0.20" "Goats|0.10" "Sheep|0.10" "Chickens|0.01""'
local rows `"`rows' "Guinea fowl|0.01" "Ducks and geese|0.01" "Rabbits|0.01""'
local n : word count `rows'
putdocx clear
putdocx begin, font("Times New Roman", 10)
putdocx paragraph
putdocx text ("Table S1: Conversion factors used for computing tropical livestock units (TLU)"), bold
putdocx table tlu = (`=`n' + 1', 2), border(all, nil) border(top) border(bottom) layout(autofitcontents)
putdocx table tlu(1,1) = ("Animal"), bold
putdocx table tlu(1,2) = ("TLU"), bold halign(center)
putdocx table tlu(1,.), border(bottom)
local r = 1
foreach row of local rows {
    local ++r
    tokenize "`row'", parse("|")
    putdocx table tlu(`r',1) = ("`1'")
    putdocx table tlu(`r',2) = ("`3'"), halign(center)
}
putdocx paragraph
putdocx text ("Factors of Jahnke (1982) for cattle, pigs, goats, sheep and chickens; donkeys are given the cattle factor (0.70), and guinea fowl, ducks and geese and rabbits the chicken factor (0.01). One TLU is 250 kg of live animal weight. Livestock owned covers all the species listed; livestock sold covers cattle, pigs, goats, sheep and chickens."), italic
putdocx save "$TABLES/TableS1_tlu_factors.docx", replace

*------------------------------------------------------------------------------
* 5. Table S2: the RALS food items and the food groups of the HDDS-12 and the FBDG
*    score, as coded in the consumed_* variables
*------------------------------------------------------------------------------
local CRT Cereals, starchy roots and tubers
local ASF Fish, insects and animal-source foods
local rows `""Cereals (1)|nshima, porridge, bread, rice, biscuits, noodles; foods from maize, rice, wheat, millet, sorghum|Cereals|`CRT'""'
local rows `"`rows' "Roots and tubers (2)|white or yellow sweet potatoes, Irish potatoes, yam, white cassava|Roots and tubers|`CRT'""'
local rows `"`rows' "Milk and milk products (3)|milk, cheese, yoghurt, sour milk|Milk and milk products|Dairy""'
local rows `"`rows' "Vitamin A-rich vegetables and tubers (4)|pumpkins, carrots, squash, orange-fleshed sweet potatoes|Vegetables|Vegetables""'
local rows `"`rows' "Dark green leafy vegetables (5)|amaranthus, cassava, pumpkin and sweet potato leaves, rape, spinach, okra|Vegetables|Vegetables""'
local rows `"`rows' "Other vegetables (6)|tomatoes, onions|Vegetables|Vegetables""'
local rows `"`rows' "Vitamin A-rich fruits (7)|ripe mango, ripe pawpaw|Fruits|Fruits""'
local rows `"`rows' "Other fruits (8)|guavas, oranges, avocado, wild fruits|Fruits|Fruits""'
local rows `"`rows' "Offal (9)|liver, kidney, heart, other organ meats, blood-based foods|Meat|`ASF'""'
local rows `"`rows' "Flesh meat (10)|beef, pork, lamb, goat, game meat, chicken, duck, guinea fowl, other birds, insects|Meat|`ASF'""'
local rows `"`rows' "Eggs (11)|eggs from chicken, duck, guinea fowl|Eggs|`ASF'""'
local rows `"`rows' "Fish (12)|fresh or dried fish (kapenta, bream, chisense)|Fish|`ASF'""'
local rows `"`rows' "Legumes, nuts and seeds (13)|dried beans, groundnuts, peanut butter|Pulses, legumes and nuts|Legumes, pulses and nuts""'
local rows `"`rows' "Oils and fats (14)|oils, fats or butter added to food or used for cooking|Oils and fats|Not counted""'
local rows `"`rows' "Sweets (15)|sugar, honey|Sugar and sweets|Not counted""'
local rows `"`rows' "Spices, condiments and beverages (16)|spices, coffee, tea, alcoholic beverages|Spices, condiments and beverages|Not counted""'
local n : word count `rows'
putdocx clear
putdocx begin, font("Times New Roman", 10) landscape
putdocx paragraph
putdocx text ("Table S2: RALS food items and the food groups of the HDDS-12 and the FBDG score"), bold
putdocx table fi = (`=`n' + 2', 4), border(all, nil) border(top) border(bottom) layout(autofitcontents)
local c = 0
foreach h in "RALS food item (code)" "Examples in the questionnaire" "HDDS-12 group" "FBDG group" {
    local ++c
    putdocx table fi(1,`c') = ("`h'"), bold
}
putdocx table fi(1,.), border(bottom)
local r = 1
foreach row of local rows {
    local ++r
    tokenize "`row'", parse("|")
    putdocx table fi(`r',1) = ("`1'")
    putdocx table fi(`r',2) = ("`3'")
    putdocx table fi(`r',3) = ("`5'")
    putdocx table fi(`r',4) = ("`7'")
}
local last = `n' + 2
putdocx table fi(`last',1) = ("Number of groups (score range)")
putdocx table fi(`last',3) = ("12 (0-12)")
putdocx table fi(`last',4) = ("6 (0-6)")
putdocx table fi(`=`n' + 1',.), border(bottom)
putdocx paragraph
putdocx text ("The RALS dietary module asks the main respondent whether anyone in the household ate each of 16 food items in the past 24 hours (question fi01, yes/no); item codes and food categories are the same in 2015 and 2019, and the examples follow the 2019 wording. A household consumed a group if it consumed any item mapped to that group. The HDDS-12 counts the groups consumed out of 12; the FBDG score counts the six food groups of the Zambian Food-Based Dietary Guidelines (FAO, 2021). Oils and fats, sweets, and spices, condiments and beverages count in the HDDS-12 but not in the FBDG score; cereals and roots and tubers form one FBDG group, as do meat, eggs and fish. Examples abbreviate the questionnaire wording."), italic
putdocx save "$TABLES/TableS2_food_groups.docx", replace

log close describe
