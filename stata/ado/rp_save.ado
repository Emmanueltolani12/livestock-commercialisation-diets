*! rp_save 2.0  12nov2026  E. Tolani
*! Saves the results frame to $PLOT_DATA/coefficients_all.dta.
*! 03_export_plot_data.do then writes the CSV files.
program define rp_save
    version 18
    frame rp_results {
        sort exhibit key
        label data "All estimates"
        quietly save "$PLOT_DATA/coefficients_all.dta", replace
        display as text "rp_save: " _N " estimates saved to $PLOT_DATA"
    }
end
