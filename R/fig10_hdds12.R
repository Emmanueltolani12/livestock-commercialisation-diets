# Figure 10: household dietary diversity score, 12 groups
# Data: plot_data/fig10_hdds12.csv (Stata: stata/02_regressions.do, block G)
source("R/00_setup.R")

fig <- read_coefficients("fig10_hdds12") |>
  plot_bars("Commercialization and Dietary Diversity (HDDS)")
save_figure(fig, "fig10_hdds12")
