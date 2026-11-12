# 00_setup.R
# Sourced by every figure script: packages, reading the plot data, theme, plot functions, saving.
# Run the scripts from the package folder (the one with 00_run_all.do).

required <- c("ggplot2", "patchwork", "dplyr", "tidyr", "readr")
missing_pkgs <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Please install: install.packages(c(", paste0('"', missing_pkgs, '"', collapse = ", "), "))")
}
suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(dplyr)
  library(tidyr)
  library(readr)
})

if (!file.exists("00_run_all.do")) {
  stop("Set the working directory to the package folder (the one with 00_run_all.do).")
}

# "sans" is Arial on Windows.
FONT <- "sans"

# Reading the plot data -------------------------------------------------------

# Coefficients of one figure, in plotting order. "\n" in a label is a line break.
read_coefficients <- function(name) {
  read_csv(
    file.path("plot_data", paste0(name, ".csv")), show_col_types = FALSE,
    col_types = cols(panel = col_character(), group = col_character(), label = col_character(),
                     stars = col_character())
  ) |>
    mutate(
      across(c(panel, group, label), \(x) gsub("\\n", "\n", x, fixed = TRUE)),
      stars = coalesce(stars, ""),
      # A bare "0" would sit behind the marker, so an estimate that rounds to zero prints in full
      est_label = paste0(ifelse(round(estimate, 3) == 0, "0.000", round(estimate, 3)), stars)
    )
}

# Means and shares behind the descriptive figures
read_plot_data <- function(name) {
  read_csv(file.path("plot_data", paste0(name, ".csv")), show_col_types = FALSE)
}

# Keeps the order of first appearance, which is the plotting order of the file
in_order <- function(x) factor(x, levels = unique(x))

# Theme -----------------------------------------------------------------------

# Equivalent of ggthemes::theme_base()
theme_base_rals <- function(base_size = 14) {
  theme_foundation <- theme_grey(base_size = base_size, base_family = FONT)
  theme_foundation +
    theme(
      line = element_line(colour = "black", lineend = "round", linetype = "solid"),
      rect = element_rect(fill = "white", colour = "black", linetype = "solid"),
      text = element_text(colour = "black", face = "plain", family = FONT, size = base_size),
      panel.background = element_rect(fill = NA, colour = NA),
      panel.border = element_rect(fill = NA, colour = "black"),
      panel.grid = element_blank(),
      plot.background = element_rect(colour = "black"),
      strip.background = element_rect(colour = NA),
      axis.text = element_text(colour = "black", size = base_size),
      axis.ticks.length = unit(0.5, "lines"),
      legend.position = "none"
    )
}

# Saving ----------------------------------------------------------------------

# R keeps the size of the letter M from the last device. A new device of the same type that
# opens at the same memory address reuses it in the wrong units, which now and then shifts the
# layout of a figure. Measuring on a device of another type replaces the stored value.
reset_text_metrics <- function() {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  invisible(grid::convertHeight(grid::stringHeight("M"), "inches"))
}

# name is "fig04_main_fbdg" and so on: same name as the data file and the script
save_figure <- function(plot, name, width = 24, height = 16) {
  dir.create(dirname(file.path("figures", name)), recursive = TRUE, showWarnings = FALSE)
  path <- file.path("figures", name)
  # A file open in another program cannot be replaced, and for a TIFF R only warns. Deleting
  # first makes that an error, so an old file cannot stay beside new ones.
  for (f in paste0(path, c(".pdf", ".png", ".tiff"))) {
    if (unlink(f) != 0 || file.exists(f)) stop(f, " cannot be replaced: close it in the other program and run again.")
  }
  reset_text_metrics()
  ggsave(paste0(path, ".pdf"), plot, width = width, height = height, units = "cm", device = cairo_pdf)
  reset_text_metrics()
  ggsave(paste0(path, ".png"), plot, width = width, height = height, units = "cm", dpi = 300, type = "cairo")
  reset_text_metrics()
  ggsave(paste0(path, ".tiff"), plot, width = width, height = height, units = "cm", dpi = 600,
         compression = "lzw", type = "cairo")
  message("Saved ", name)
}

# Plot types ------------------------------------------------------------------

# Bars with a red square, 95% CI and the estimate: Figures 4, 7, 8, 9 and 10
FILL_4 <- c("#FDE7EF", "#FDDAE3", "#FCC8E0", "#FFADC2")
FILL_2 <- c("#EF74C3", "#F39DCA")

plot_bars <- function(d, title, ylab = "Estimates(95% Robust CI)", fills = FILL_4) {
  if (nrow(d) == 0) stop("No rows to plot: a panel in stata/figure_map.csv does not match the R script.")
  d <- d |> mutate(label = in_order(label))
  ggplot(d, aes(x = label, y = estimate, fill = label)) +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey") +
    geom_col(width = 0.5) +
    geom_errorbar(aes(ymin = conf_low, ymax = conf_high), width = 0.035, linewidth = 0.6) +
    geom_point(size = 4, shape = 15, colour = "#FF0000") +
    geom_text(aes(y = estimate, label = est_label), hjust = -0.2, vjust = -0.75, size = 4.5, family = FONT) +
    scale_fill_manual(values = fills) +
    labs(x = NULL, y = ylab, title = title) +
    coord_cartesian(clip = "off") +
    theme_base_rals() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "plain", colour = "grey30", size = 14),
      axis.title.y = element_text(size = 14)
    )
}

# Points with 95% CI, rows = panel, columns = group: Figures 5 and 6.
plot_points <- function(d, colours, ylab = "Estimates(95% Robust CI)", hjust = -0.2, strip_alpha = 0.2) {
  d <- d |> mutate(panel = in_order(panel), group = in_order(group), label = in_order(label))
  p <- ggplot(d, aes(x = label, y = estimate, colour = label)) +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey") +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = conf_low, ymax = conf_high), width = 0.1) +
    geom_text(aes(label = est_label), hjust = hjust, size = 3.5, family = FONT, show.legend = FALSE) +
    facet_grid(panel ~ group, scales = "free") +
    labs(x = NULL, y = ylab) +
    scale_colour_manual(values = colours) +
    theme_base_rals() +
    theme(
      panel.border = element_rect(linewidth = 0.5, fill = NA),
      plot.background = element_rect(colour = NA),
      strip.background = element_rect(fill = adjustcolor("grey60", alpha.f = strip_alpha), colour = "grey60"),
      strip.text = element_text(family = FONT, size = 14, colour = "black"),
      strip.text.y = element_text(family = FONT, size = 12)
    )
  p + scale_x_discrete(labels = "")
}

# Food groups by wave, with the change between the waves: Figure 3
plot_food_groups <- function(shares, title, x_bars, x_change, change_suffix) {
  shares <- shares |> arrange(wave, order)
  labels <- unique(shares$group)
  fills <- setNames(c("#64ACEC", "#747DC4", "#8F75CA", "#B065C0", "#E55C96", "#EF7870"), labels)
  shares <- shares |> mutate(group = factor(group, levels = rev(labels)))

  base_theme <- theme_minimal(base_size = 14, base_family = FONT) +
    theme(legend.position = "none", panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
          plot.subtitle = element_text(hjust = 0.5, size = 15))
  bars <- function(year, show_y) {
    ggplot(filter(shares, wave == year), aes(x = percent, y = group, fill = group)) +
      geom_col(width = 0.8) +
      geom_text(aes(label = round(percent, 2)), hjust = 1.05, size = 5, colour = "grey10", family = FONT) +
      scale_fill_manual(values = fills) +
      scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 25)) +
      labs(subtitle = year, x = x_bars, y = if (show_y) "Food Group" else NULL) +
      base_theme
  }
  change <- shares |>
    select(wave, group, percent) |>
    pivot_wider(names_from = wave, values_from = percent, names_prefix = "y") |>
    mutate(diff = round(y2019 - y2015, 2))
  arrows <- ggplot(change, aes(y = group, colour = group)) +
    geom_vline(xintercept = 0, linewidth = 2, colour = "#D9E0FF") +
    geom_segment(aes(x = 0, xend = diff, yend = group), linewidth = 1.2,
                 arrow = arrow(length = unit(0.25, "cm"), type = "closed")) +
    geom_text(aes(x = diff, label = paste0(diff, change_suffix), vjust = ifelse(diff < 0, 2, -1)), size = 5,
              colour = "grey10", family = FONT) +
    scale_colour_manual(values = fills) +
    scale_x_continuous(expand = expansion(mult = 0.2)) +
    labs(subtitle = " ", x = x_change, y = NULL) +
    base_theme +
    theme(axis.text.y = element_blank())
  bars(2015, TRUE) + bars(2019, FALSE) + arrows +
    plot_annotation(title = title, theme = theme(plot.title = element_text(face = "bold", size = 18, family = FONT)))
}
