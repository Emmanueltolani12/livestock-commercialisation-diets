# Figure 9: pathway variables and dietary diversity. 'Income' is total household income per
# 100,000 kwacha (inc100k).
# Data: plot_data/fig09_pathways_diets.csv (Stata: stata/02_regressions.do, block F)
source("R/00_setup.R")

fig <- read_coefficients("fig09_pathways_diets") |>
  plot_bars("Pathway outcomes and dietary diversity")
save_figure(fig, "fig09_pathways_diets")
