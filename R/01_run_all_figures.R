# 01_run_all_figures.R
# Draws every figure from plot_data/. Needs only R, not Stata and not the microdata.
#
# From the package folder:  Rscript --vanilla R/01_run_all_figures.R
# If Rscript is not on your PATH, use its full path, for example in PowerShell
#   & "C:\Program Files\R\R-4.5.0\bin\Rscript.exe" --vanilla R/01_run_all_figures.R
# or, in RStudio with this folder as the working directory, source("R/01_run_all_figures.R").
# Each figure script (R/fig*.R) also runs on its own.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) setwd(args[1])
if (!file.exists("00_run_all.do")) stop("Run this from the package folder (the one with 00_run_all.do).")

scripts <- list.files("R", pattern = "^fig.*[.]R$", full.names = TRUE)
for (s in scripts) {
  message("Running ", s)
  source(s, local = new.env())
}

# Marker for 00_run_all.do, which passes the folder as an argument: this script has finished
if (length(args) >= 1) {
  dir.create("logs", showWarnings = FALSE)
  writeLines(format(Sys.time()), file.path("logs", "01_run_all_figures.done"))
}
message("Finished ", length(scripts), " figures")
