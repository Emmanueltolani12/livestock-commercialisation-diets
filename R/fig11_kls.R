# Figure 11: kinky least squares (KLS) estimates over the postulated endogeneity, with the 2SLS estimate
# Data: plot_data/fig11_kls.csv (Stata: stata/02_regressions.do, block H)
# 'Income' is livestock sales revenue (totlv_inc); 'Off-farm income' is off-farm participation.
source("R/00_setup.R")

d <- read_plot_data("fig11_kls") |>
  mutate(panel = in_order(panel))

fig <- ggplot(d, aes(x = endogeneity)) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey85", linetype = "dashed") +
  geom_ribbon(aes(ymin = iv_low, ymax = iv_high, fill = "IV 95% CI")) +
  geom_ribbon(aes(ymin = kls_low, ymax = kls_high, fill = "KLS >=95% CI")) +
  geom_line(aes(y = iv, colour = "IV estimate"), linewidth = 0.6) +
  geom_line(aes(y = kls, colour = "KLS estimate"), linewidth = 0.6) +
  facet_wrap(~panel, ncol = 2, scales = "free_y") +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  scale_fill_manual(NULL, values = c("IV 95% CI" = "#F3EFDF", "KLS >=95% CI" = "grey85")) +
  scale_colour_manual(NULL, values = c("IV estimate" = "#00BA7C", "KLS estimate" = "#FFD400")) +
  # Set the order: without it, ggplot's order of the two legends can differ between R sessions
  guides(fill = guide_legend(order = 1), colour = guide_legend(order = 2)) +
  labs(x = "Postulated endogeneity of livestock commercialization",
       y = "Livestock commercialization coefficient estimate") +
  theme_base_rals(base_size = 12) +
  theme(legend.position = "right", legend.key = element_rect(colour = NA, fill = NA),
        plot.background = element_rect(colour = NA), strip.background = element_rect(fill = "white", colour = NA),
        strip.text = element_text(size = 14), panel.border = element_blank(),
        axis.line = element_line(colour = "black"), axis.ticks.length = unit(0.25, "lines"))
save_figure(fig, "fig11_kls", width = 30, height = 18)
