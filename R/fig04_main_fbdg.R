# Figure 4: main results, FBDG
# Data: plot_data/fig04_main_fbdg.csv (Stata: stata/02_regressions.do, block A)
# 'OLS' is the CRE model, 'IV' the IV-CRE model.
source("R/00_setup.R")

fig <- read_coefficients("fig04_main_fbdg") |>
  plot_bars("Commercialization and Dietary Diversity (FBDGs)")
save_figure(fig, "fig04_main_fbdg")
