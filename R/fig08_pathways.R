# Figure 8: pathways. Livestock income (household FE and IV-FE) and the IV-CRE estimates for
# production diversity, cash crops, food crops and off-farm participation.
# Data: plot_data/fig08_pathways.csv (Stata: stata/02_regressions.do, block E)
# 'Income' is livestock sales revenue (totlv_inc); 'OLS' is the household fixed-effects model;
# 'Off-farm income' is off-farm participation.
source("R/00_setup.R")

d <- read_coefficients("fig08_pathways")
panels <- unique(d$panel)
title <- "Livestock commercialization and pathway outcomes"

income <- d |>
  filter(panel == panels[1]) |>
  plot_bars(title, fills = FILL_2)
other <- d |>
  filter(panel == panels[2]) |>
  plot_bars(title, ylab = NULL)
save_figure(income + other, "fig08_pathways", width = 43, height = 18)
