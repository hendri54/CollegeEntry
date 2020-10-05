## -------------- Rank is a weighted average of endowment percentiles

"""
	$(SIGNATURES)

Switches for linear endowment percentile weights. 
`eNameV` contains the endowments used for ranking. It must be possible to call `retrieve_draws(EndowmentDraws, eName)`.
`wtV` are the weights to be used if not calibrated. This omits the first weight, which is fixed at 1. This is empty when there is only one endowment to rank on.
`doCal` determines whether weights are calibrated or fixed.
"""
mutable struct EndowPctRankingSwitches{F1} <: AbstractRankingSwitches{F1}
    # Endowments to rank on
    eNameV :: Vector{Symbol}
    # Weights on those endowments, if fixed. First is omitted as fixed.
    wtV :: Vector{F1}
    # Calibrate weights? The first is always fixed (normalization).
    doCal :: Bool
end


"""
	$(SIGNATURES)

Rank students by a linear combination of endowment percentiles.
"""
mutable struct EndowPctRanking{F1} <: AbstractRanking{F1}
    objId :: ObjectId
    pvec :: ParamVector
    # Weights, excluding the first, normalized one.
    wtV :: Vector{F1}
    switches :: EndowPctRankingSwitches{F1}
end

# ------  Access and show

Base.show(io :: IO,  e :: EndowPctRankingSwitches{F1}) where F1 =
    print(io, typeof(e), " with endowments ", endow_names(e));

Base.show(io :: IO,  e :: EndowPctRanking{F1}) where F1 =
    print(io, typeof(e), " with endowments ", endow_names(e),
        " and weights ",  round.(weights(e), digits = 2));

function StructLH.describe(e :: EndowPctRankingSwitches{F1}) where F1
    endowNameV = CollegeEntry.endow_names(e);
    calStr = calibrate_weights(e)  ?  "calibrated"  :  "fixed";
    return [
        "Ranking for sequential entry"  " ";
        "Ranking based on"  "$endowNameV";
        "Weights on endowments:"  "$calStr"
    ]
end

StructLH.describe(e :: EndowPctRanking) = StructLH.describe(e.switches);
      

fixed_weights(switches :: EndowPctRankingSwitches{F1}) where F1 = 
    [one(F1), switches.wtV...];
weights(e :: EndowPctRanking{F1}) where F1 = [one(F1), e.wtV...];
calibrate_weights(switches :: EndowPctRankingSwitches{F1}) where F1 = 
    switches.doCal;
calibrate_weights(e :: EndowPctRanking{F1}) where F1 = 
    calibrate_weights(e.switches);


# ------  Constructing

function make_test_endowpct_switches(n ::Integer)
    eNameV = [:abilPct, :parentalPct, :hsGpaPct, :h0Pct];
    wtV = [0.3, 2.0, 3.0];
    # This produces an [] wtV when n == 1
    e = EndowPctRankingSwitches(eNameV[1 : n], wtV[1 : (n-1)], true);
    @assert validate_ranking_switches(e);
    return e
end

function make_student_ranking(objId :: ObjectId, 
    switches :: EndowPctRankingSwitches{F1},
    st :: SymbolTable) where F1
    # switches = make_test_endowpct_switches(n);
    # objId = make_child_id(parentId, :studentRanking);
    pWtV = init_endow_pct_weights(switches, st);
    pvec = ParamVector(objId, [pWtV]);
    return EndowPctRanking(objId, pvec, ModelParams.value(pWtV), switches)
end

function init_endow_pct_weights(switches :: EndowPctRankingSwitches{F1},
    st :: SymbolTable) where F1
    wtV = switches.wtV;
    n = length(wtV);
    p = Param(:wtV, 
        LatexLH.description(st, :rankWt), latex(st, :rankWt), 
        wtV, wtV, zeros(F1, n), fill(F1(10.0), n), switches.doCal);
    return p
end

function validate_ranking_switches(e :: EndowPctRankingSwitches{F1}) where F1
    isValid = true
    isValid = isValid && (length(endow_names(e)) == 1 + length(e.wtV));
    isValid = isValid &&  all(e.wtV .>= 0.0)  &&  !any(isinf.(e.wtV))
    return isValid
end

function validate_ranking(e :: EndowPctRanking{F1}) where F1
    isValid = true;
    isValid = isValid && (size(endow_names(e)) == size(weights(e)))
    return isValid
end

# -------------