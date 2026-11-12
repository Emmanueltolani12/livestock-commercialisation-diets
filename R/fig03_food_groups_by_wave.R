# Figure 3: food groups consumed by wave
# Data: plot_data/fig03_food_groups_by_wave.csv (Stata: stata/01_descriptives.do, section 2)
# 'Percentage Change' is the change in percentage points; 'Meat' is the FBDG group of meat,
# eggs and fish.
source("R/00_setup.R")

fig <- read_plot_data("fig03_food_groups_by_wave") |>
  plot_food_groups(
    title = "Consumption of food groups by Panel",
    x_bars = "Percentage of Households", x_change = "Percentage Change", change_suffix = "%"
  )
save_figure(fig, "fig03_food_groups_by_wave", width = 30, height = 15)
