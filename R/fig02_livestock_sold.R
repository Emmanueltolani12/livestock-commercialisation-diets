# Figure 2: livestock sold per household, by species and wave
# Data: plot_data/fig02_livestock_sold.csv (Stata: stata/01_descriptives.do, section 1)
# Mean TLU sold per household; small ruminants are goats and sheep.
source("R/00_setup.R")

d <- read_plot_data("fig02_livestock_sold")

one_panel <- function(x) {
  ggplot(x, aes(x = factor(wave), y = mean_tlu_sold)) +
    geom_col(width = 0.63, fill = "grey55") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
    labs(x = NULL, y = x$y_title[1], title = x$panel[1]) +
    theme_base_rals(base_size = 12) +
    theme(plot.title = element_text(hjust = 0.5, face = "plain", size = 14),
          plot.background = element_rect(colour = NA),
          panel.border = element_blank(), axis.line = element_line(colour = "black"),
          axis.ticks.length = unit(0.25, "lines"))
}
panels <- lapply(split(d, d$order), one_panel)
save_figure(wrap_plots(panels, ncol = 3), "fig02_livestock_sold", width = 30, height = 21)
