# Replication package

**Smallholder Livestock Commercialisation and Dietary Diversity: Panel Data Evidence from Zambia**
Martin Paul Jr. Tabe-Ojong, Emmanuel Tolani, Abebayehu G. Geffersa

This package runs the analysis of the paper from the cleaned data: the regressions and the data behind Figures 2–11, the figures themselves, Tables 1 and 2, and Tables S1–S20 of the Supplementary Information. One command runs everything.

## Data availability

The analysis uses the Rural Agricultural Livelihoods Survey (RALS), a panel survey of smallholder farm households in Zambia, run by the Indaba Agricultural Policy Research Institute (IAPRI) with the Zambia Statistics Agency and the Ministry of Agriculture. The package uses the 2012, 2015 and 2019 waves. Dietary diversity is observed in 2015 and 2019; the 2012 wave enters only Figure 2.

**The data are not included in this package.** The RALS is household-level microdata that IAPRI does not allow to be redistributed, so the package holds the code only. To run it:

1. Request the RALS 2012, 2015 and 2019 waves from IAPRI ([iapri.org.zm](https://www.fsdzambia.org/vs/iapri/)).
2. Save the analysis data files listed below in the `data/` folder.
3. Run the package (see How to run). `00_run_all.do` stops with a message if a data file is missing.

The outputs in `plot_data/`, `figures/`, `tables/` and `logs/` hold estimates and group averages only, no household-level data.

| File to save in `data/` | Content |
|---|---|
| `data/analysis_data.dta` | The analysis data: 13,252 household-wave observations of 6,626 households in 2015 and 2019, 68 variables (listed below). The main models use 11,963 observations of 6,494 households (`insample == 1`). |
| `data/livestock_sales_2012_2019.dta` | Livestock sold by species and household in 2012, 2015 and 2019 (19,878 observations), for Figure 2. |

## Software and run time

- Stata 18 (SE or MP). The one user-written package, `kinkyreg` 1.1.1 (Kripfganz and Kiviet; Figure 11), is bundled in `stata/ado/plus`, so nothing needs installing.
- R 4.5 with `ggplot2`, `patchwork`, `dplyr`, `tidyr` and `readr`. `00_run_all.do` finds `Rscript` in `C:/Program Files/R`; elsewhere, set the global `RSCRIPT` at the top of the file.
- **Run time.** The full run took 15 minutes. Almost all of it is `02_regressions.do` (14.7 minutes); `01_descriptives.do` and `03_export_plot_data.do` take a few seconds, and the figures in R about 20 seconds.
- **Computer used.** 32 GB of RAM (5,600 MT/s), Windows 11 and a 2 TB NVMe SSD.

## How to run

Open Stata, `cd` to this folder and type:

```
do 00_run_all.do
```

This runs, in order:

| Step | File | What it does |
|---|---|---|
| 1 | `stata/01_descriptives.do` | Data behind Figures 2 and 3; Tables S1, S2 and S3 |
| 2 | `stata/02_regressions.do` | All regressions: Figures 4–11, Tables 1, 2 and S4–S20 |
| 3 | `stata/03_export_plot_data.do` | The coefficients and 95% intervals of Figures 4–10, one CSV per figure; all estimates in `coefficients_all.csv` and `all_estimates.xlsx` |
| 4 | `R/01_run_all_figures.R` | Draws Figures 2–11 from `plot_data/` |

To draw the figures again without Stata:

```
Rscript --vanilla R/01_run_all_figures.R
```

## Models

- **Outcomes.** The FBDG score: the number of the six food groups of Zambia's Food-Based Dietary Guidelines the household consumed (`number_food6groupZ`, 0–6). The household dietary diversity score with 12 groups (HDDS-12, `number_food12group`), and with 9 groups in Tables 1, 2 and S15 (HDDS-9, `number_food9groupH`). The six FBDG groups one by one in Figure 5 and Table S17, the twelve HDDS-12 groups in Table S16.
- **Livestock commercialisation.** Extensive margin: sold livestock (1/0, `tlu_sale`). Intensive margin: livestock sold in tropical livestock units (TLU, `tlu_sold`). In Tables 1, 2 and S15–S20, the livestock commercialisation index, LCI = 100 × TLU sold / (TLU sold + TLU owned at the survey), the per cent of the herd before the sales that was sold; it is instrumented by `tlu_sale_mean` like the other treatments.
- **CRE** (labelled OLS in the figures): random-effects model with the controls, the household means of the time-varying controls (Mundlak), and constituency and year dummies (`xtreg, re`).
- **IV-CRE** (labelled IV in the figures): the same model with livestock commercialisation instrumented by `tlu_sale_mean`, the leave-one-out share of livestock sellers in the household's constituency, 2015 and 2019 pooled (`xtivreg, re`).
- **Controls.** The head's sex, education and age, household size, access to credit, cultivated land, land owned, crop market participation, FISP participation, drought, floods, pests and diseases, other shocks and the asset index.
- **Standard errors** are clustered on `hh`.

Exceptions:

- **Figure 6 and Tables S13–S14:** one species per model, with the FBDG score (Figure 6) or the HDDS-12 (Tables S13 and S14) as the outcome. Extensive margin: sold cattle, pigs or poultry (1/0) and, for small ruminants (goats and sheep), `rum_d`, sold goats + sold sheep (0–2). Intensive margin: TLU sold of the species.
- **Figure 7:** the models of Figure 4, for households with a male and with a female main decision-maker.
- **Figure 8, livestock income:** household fixed effects (FE, labelled OLS) and IV-FE, with the controls and a year dummy.
- **Table S18:** livestock income (column 1) is IV-FE with the controls and a year dummy; the other pathways are IV-CRE.
- **Figure 9 and Table S9:** one pathway variable per CRE model; total household income enters per 100,000 kwacha (`inc100k`). In the 'Male decision' model the head's sex is not among the controls, because it coincides with the decision-maker's sex for 98% of the observations.
- **Figure 11:** 2SLS and kinky least squares (`kinkyreg`, postulated endogeneity from −0.75 to 0.75) with the controls and household means, without fixed effects, with non-robust standard errors.
- **Table 2 and Table S20:** total household income (per 100,000 kwacha, `inc100k`) is added to the controls, without its household mean.
- **Table S19:** the LCI models of the HDDS-12 and the FBDG score, for households with a male and with a female main decision-maker.
- **Table S10:** households that sell both crops and livestock against all others, in the CRE model of Figure 4 without crop market participation among the controls, for the FBDG score and the HDDS-12.

## Exhibits and their files

| Exhibit | Code | Files |
|---|---|---|
| Figure 2 | `01_descriptives.do`, section 1 | `fig02_livestock_sold` |
| Figure 3 | `01_descriptives.do`, section 2 | `fig03_food_groups_by_wave` |
| Figure 4 | `02_regressions.do`, block A | `fig04_main_fbdg`; full models in Table S4 |
| Figure 5 | block B | `fig05_food_groups`; full models in Table S5 |
| Figure 6 | block C | `fig06_species`; full models in Table S6 |
| Figure 7 | block D | `fig07_gender`; full models in Table S7 |
| Figure 8 | block E | `fig08_pathways`; full models in Table S8 |
| Figure 9 | block F | `fig09_pathways_diets`; full models in Table S9 |
| Figure 10 | block G | `fig10_hdds12`; full models in Table S12 |
| Figure 11 | block H | `fig11_kls` |
| Table 1 | block I | `tables/Table1_lci.docx` |
| Table 2 | block I | `tables/Table2_lci_income.docx` |
| Table S1 | `01_descriptives.do`, section 4 | `tables/TableS1_tlu_factors.docx` |
| Table S2 | `01_descriptives.do`, section 5 | `tables/TableS2_food_groups.docx` |
| Table S3 | `01_descriptives.do`, section 3 | `tables/TableS3_food_groups_by_seller.docx`, `.csv` |
| Table S4 | block A | `tables/TableS4_fig4_fbdg.docx` (full models of Figure 4) |
| Table S5 | block B | `tables/TableS5_fig5_food_groups.docx` (full models of Figure 5) |
| Table S6 | block C | `tables/TableS6_fig6_species.docx` (full models of Figure 6) |
| Table S7 | block D | `tables/TableS7_fig7_decision_maker_sex.docx` (full models of Figure 7) |
| Table S8 | block E | `tables/TableS8_fig8_pathways.docx` (full models of Figure 8) |
| Table S9 | block F | `tables/TableS9_fig9_pathways_diets.docx` (full models of Figure 9) |
| Table S10 | block J | `tables/TableS10_joint_strategy.docx`, `.csv` |
| Table S11 | block K | `tables/TableS11_estimates_in_sd_units.docx`, `.csv` |
| Table S12 | block G | `tables/TableS12_fig10_hdds12.docx` (full models of Figure 10) |
| Table S13 | block C | `tables/TableS13_species_extensive_hdds12.docx` |
| Table S14 | block C | `tables/TableS14_species_intensive_hdds12.docx` |
| Table S15 | block I | `tables/TableS15_lci_dietary_diversity.docx` (full models of Table 1) |
| Table S16 | block I | `tables/TableS16_lci_hdds_food_groups.docx` |
| Table S17 | block I | `tables/TableS17_lci_fbdg_food_groups.docx` |
| Table S18 | block I | `tables/TableS18_lci_pathways.docx` |
| Table S19 | block I | `tables/TableS19_lci_decision_maker_sex.docx` |
| Table S20 | block I | `tables/TableS20_lci_income_full.docx` (full models of Table 2) |

- **Figures** are in `figures/` as PDF, PNG (300 dpi) and TIFF (600 dpi), one R script each in `R/` with the same name; `R/00_setup.R` holds the shared theme and plot functions.
- **Figure data** are in `plot_data/`, with the same names: for Figures 4–10, one row per bar or point with the estimate, standard error, 95% interval, p-value, stars, observations and clusters. `stata/figure_map.csv` says which estimate goes where and under which label.
- **All estimates** behind Figures 4–11 and Tables 1, 2, S4–S9 and S12–S20, one row per model, are in `plot_data/coefficients_all.csv` and `tables/all_estimates.xlsx`; those of Tables S3, S10 and S11 are in the CSV files beside their Word tables.
- **Logs** of the last run are in `logs/`.

Labels in the figures: 'Fish' in Figure 5 and 'Meat' in Figure 3 are the FBDG group of meat, eggs and fish; 'Income' in Figures 8 and 11 is livestock sales revenue, and in Figure 9 total household income per 100,000 kwacha; 'Off-farm income' in Figures 8, 9 and 11 is off-farm participation (1/0).

## Folder layout

```
00_run_all.do          runs everything
data/                  analysis data (not included; see Data availability)
stata/                 01-03 do-files, figure_map.csv, ado/ (table helpers and kinkyreg)
R/                     00_setup.R, 01_run_all_figures.R and one script per figure
plot_data/             coefficients and 95% intervals for the figures (no microdata)
figures/               Figures 2-11
tables/                Tables 1, 2 and S1-S20, all_estimates.xlsx
logs/                  logs of the last run
```

## Variables in `data/analysis_data.dta`

| Variable | Description |
|---|---|
| `hhid` | Household identifier (panel) |
| `hh` | Household serial number within the SEA |
| `const` | Constituency |
| `Panel` | Survey wave |
| `insample` | In the estimation sample of the main models (1/0) |
| `number_food6groupZ` | Dietary diversity: food groups of Zambia's FBDG (0-6) |
| `number_food12group` | Household dietary diversity score, 12 groups (0-12) |
| `number_food9groupH` | Household dietary diversity score, 9 groups (0-9) |
| `tlu_sale` | Sold livestock (1/0): extensive margin |
| `tlu_sold` | Livestock sold (TLU): intensive margin |
| `Sex_HH` | Head is male (1/0) |
| `Education_HH` | Head's education (0 none, 1-12 grade, 13-14 Form 6, 15-19 higher, -9 don't know) |
| `age` | Age of the head (years) |
| `tlu_today` | Livestock owned at survey (TLU) |
| `Access_Credit` | Access to credit (1/0) |
| `Cult_OwnLand_Size` | Cultivated land (ha) |
| `Total_OwnLand_Size` | Land owned (ha) |
| `Off_Farm_Partic` | Off-farm activity (1/0) |
| `Market_Participation` | Sold crops (1/0): crop market participation |
| `FISP_participation` | Received FISP input subsidy |
| `asset_index` | Asset index (quintile) |
| `drought` | Drought (1/0) |
| `Floods` | Floods (1/0) |
| `Pests_diseases` | Pests or diseases (1/0) |
| `shocks` | Other shocks (1/0) |
| `consumed_Cereals` | Consumed cereals (HDDS group, 1/0) |
| `consumed_Tubers` | Consumed tubers (HDDS group, 1/0) |
| `consumed_Oils` | Consumed oils (HDDS group, 1/0) |
| `consumed_Sugars` | Consumed sugars (HDDS group, 1/0) |
| `consumed_Fish` | Consumed fish (HDDS group, 1/0) |
| `consumed_Eggs` | Consumed eggs (HDDS group, 1/0) |
| `consumed_Meat_Prod` | Consumed meat (HDDS group, 1/0) |
| `consumed_Spices` | Consumed spices (HDDS group, 1/0) |
| `consumed_FruitsZ` | Consumed fruits (FBDG group, 1/0) |
| `consumed_VegetablesZ` | Consumed vegetables (FBDG group, 1/0) |
| `consumed_DairyZ` | Consumed dairy (FBDG group, 1/0) |
| `consumed_PulsesZ` | Consumed legumes (FBDG group, 1/0) |
| `consumed_CerealsZ` | Consumed starchy staples (FBDG group, 1/0) |
| `consumed_Meat_ProdZ` | Consumed meat, eggs or fish (FBDG group, 1/0) |
| `totlv_inc` | Livestock sales revenue (kwacha) |
| `gender_Maindecision_maker` | Main decision-maker is male (1/0) |
| `hhsize` | Household size |
| `cattle` | Cattle sold (TLU) |
| `pig` | Pigs sold (TLU) |
| `poultry` | Poultry sold (TLU) |
| `cattle_d` | Sold cattle (1/0) |
| `pig_d` | Sold pigs (1/0) |
| `poultry_d` | Sold poultry (1/0) |
| `Education_HHbar` | Household mean of Education_HH (2015 and 2019, all observations) |
| `agebar` | Household mean of age (2015 and 2019, all observations) |
| `hhsizebar` | Household mean of hhsize (2015 and 2019, all observations) |
| `Access_Creditbar` | Household mean of Access_Credit (2015 and 2019, all observations) |
| `Cult_OwnLand_Sizebar` | Household mean of Cult_OwnLand_Size (2015 and 2019, all observations) |
| `Total_OwnLand_Sizebar` | Household mean of Total_OwnLand_Size (2015 and 2019, all observations) |
| `Market_Participationbar` | Household mean of Market_Participation (2015 and 2019, all observations) |
| `FISP_participationbar` | Household mean of FISP_participation (2015 and 2019, all observations) |
| `droughtbar` | Household mean of drought (2015 and 2019, all observations) |
| `Floodsbar` | Household mean of Floods (2015 and 2019, all observations) |
| `Pests_diseasesbar` | Household mean of Pests_diseases (2015 and 2019, all observations) |
| `shocksbar` | Household mean of shocks (2015 and 2019, all observations) |
| `asset_indexbar` | Household mean of asset_index (2015 and 2019, all observations) |
| `prod_diversity` | Production diversity (number of crops) |
| `cash_crop` | Number of cash crops |
| `food_crop` | Number of food crops |
| `rum` | Small ruminants (goats and sheep) sold (TLU) |
| `rum_d` | Sold small ruminants: sold goats + sold sheep (0-2) |
| `tlu_sale_mean` | Instrument: leave-one-out share of sellers in the constituency, waves pooled |
| `inc100k` | Total household income (100,000 kwacha) |
