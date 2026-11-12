*! rp_init 2.0  12nov2026  E. Tolani
*! Creates an empty results frame, rp_results. rp_post adds one row per estimate and
*! rp_save writes the frame to $PLOT_DATA/coefficients_all.dta.
program define rp_init
    version 18
    capture frame drop rp_results
    frame create rp_results ///
        str16 exhibit str48 key str32 outcome str40 treatment str120 model str32 cluster ///
        double(b se p ci_lo ci_hi) long(n n_clust)
end
