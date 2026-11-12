# Figure 6: livestock species, one species per model
# Data: plot_data/fig06_species.csv (Stata: stata/02_regressions.do, block C)
# Extensive margin, small ruminants: rum_d, sold goats + sold sheep (0-2).
source("R/00_setup.R")

fig <- read_coefficients("fig06_species") |>
  plot_points(colours = c("#30469c", "#8c0049", "#EEAB73", "black"), strip_alpha = 0.8)
save_figure(fig, "fig06_species")
