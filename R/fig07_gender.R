# Figure 7: by sex of the main decision-maker
# Data: plot_data/fig07_gender.csv (Stata: stata/02_regressions.do, block D)
source("R/00_setup.R")

d <- read_coefficients("fig07_gender")
panels <- unique(d$panel)

male <- d |>
  filter(panel == panels[1]) |>
  plot_bars(panels[1], ylab = "Estimates(95% Robust CI)")
female <- d |>
  filter(panel == panels[2]) |>
  plot_bars(panels[2], ylab = NULL)
save_figure(male + female, "fig07_gender", width = 43, height = 18)
