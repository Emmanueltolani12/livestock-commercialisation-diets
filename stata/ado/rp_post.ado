*! rp_post 2.0  12nov2026  E. Tolani
*! Stores the coefficient coef() of the last estimation in the results frame rp_results:
*! estimate, standard error, p-value, 95% interval, observations and clusters.
*! The p-value and interval use the t distribution when the estimation has residual
*! degrees of freedom, and the normal distribution otherwise.
program define rp_post
    version 18
    syntax , EXhibit(string) Key(string) OUTcome(string) TReatment(string) ///
        MOdel(string) COEF(string) [CLuster(string)]

    capture frame rp_results: describe, short
    if _rc rp_init

    if ustrlen(`"`key'"') > 48 {
        display as error "rp_post: key longer than 48 characters: `key'"
        exit 198
    }

    local b  = _b[`coef']
    local se = _se[`coef']
    if `se' == 0 | missing(`se') {
        display as error "rp_post: `coef' is omitted or has no standard error (key `key')"
        exit 498
    }
    local df .
    capture local df = e(df_r)
    if "`df'" == "" local df .
    if `df' < . local p = 2 * ttail(`df', abs(`b' / `se'))
    else        local p = 2 * normal(-abs(`b' / `se'))
    local crit = cond(`df' < ., invttail(`df', 0.025), invnormal(0.975))
    local lo = `b' - `crit' * `se'
    local hi = `b' + `crit' * `se'
    local n = e(N)

    if "`cluster'" == "" local cluster = e(clustvar)
    if ustrlen(`"`cluster'"') > 32 {
        display as error "rp_post: cluster name longer than 32 characters"
        exit 198
    }

    * Clusters in the estimation sample, counted directly: after xtivreg, e(N_clust)
    * counts clusters outside e(sample) and depends on the sort order.
    local nc .
    if wordcount("`cluster'") == 1 & !inlist("`cluster'", "none", "") {
        capture confirm numeric variable `cluster'
        if !_rc {
            tempvar tag
            quietly egen byte `tag' = tag(`cluster') if e(sample)
            quietly count if `tag' == 1
            local nc = r(N)
        }
    }

    frame rp_results {
        quietly drop if key == `"`key'"'
        frame post rp_results (`"`exhibit'"') (`"`key'"') (`"`outcome'"') (`"`treatment'"') ///
            (`"`model'"') (`"`cluster'"') (`b') (`se') (`p') (`lo') (`hi') (`n') (`nc')
    }
    display as text %-44s "`key'" as result "  b = " %9.4f `b' "  se = " %8.4f `se' "  p = " %6.4f `p'
end
