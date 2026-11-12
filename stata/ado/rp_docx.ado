*! rp_docx 1.0  30oct2026  E. Tolani
*! Writes the current collection (the table etable or dtable just built) to a Word file:
*! landscape, with columns fitted to their contents, so that no number breaks across lines.
program define rp_docx
    version 18
    args file
    collect style putdocx, layout(autofitcontents)
    putdocx begin, landscape
    putdocx collect
    putdocx save "`file'", replace
end
