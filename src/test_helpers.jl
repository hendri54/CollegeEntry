# Set to get interior entry rates
function values_for_test(rng, J, nc, nl; typicalValue = 1.0)
    # vWork_jV = (0.8 * nl) .+ 1.0 .* rand(rng, Float64, J);
    vCollege_jcM = typicalValue .* (1.0 .+ 0.1 .* rand(rng, Float64, J, nc));
    vWork_jV = vec(sum(vCollege_jcM, dims = 2)) ./ nc .+ (0.6 * nl);
    return vWork_jV, vCollege_jcM
end

function make_test_symbol_table()
    st = SymbolTable();
    add_symbol!(st, SymbolInfo(:rankWt, "\\alpha", "Ranking weight", "Admissions"));
    add_symbol!(st, SymbolInfo(:collPrefScale, "\\pi_{c}", "College choice pref scale", "Admissions"));
    add_symbol!(st, SymbolInfo(:pScaleEntry, "\\pi", "Entry pref scale", "Admissions"));
    add_symbol!(st, SymbolInfo(:uLocal, "U_{local}", "Value local", "Admissions"));
    return st
end

# ------------