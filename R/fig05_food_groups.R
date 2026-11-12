# Figure 5: individual food groups
# Data: plot_data/fig05_food_groups.csv (Stata: stata/02_regressions.do, block B)
# 'Fish' is the FBDG group of meat, eggs and fish.
source("R/00_setup.R")

fig <- read_coefficients("fig05_food_groups") |>
  plot_points(colours = c("#30469c", "#8c0049", "#EEAB73", "green", "darkgreen", "black"), hjust = -0.15)
save_figure(fig, "fig05_food_groups")
