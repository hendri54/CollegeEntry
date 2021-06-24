## -------------- Rank is a weighted average of endowment percentiles

"""
	$(SIGNATURES)

Switches for linear endowment percentile weights. 

`eNameV` contains the endowments used for ranking. It must be possible to call `retrieve_draws(EndowmentDraws, eName)`.

`wtV` are the weights to be used if not calibrated. This omits the first weight, which is fixed at 1 (or -1). 
This is empty when there is only one endowment to rank on.
Weights are bounded in the interval `lbV` to `ubV`. Weights may be negative.

`doCal` determines whether weights are calibrated or fixed.
"""
mutable struct EndowPctRankingSwitches{F1} <: AbstractRankingSwitches{F1}
    # Endowments to rank on
    eNameV :: Vector{Symbol}
    # Weights on those endowments, if fixed. First is omitted as fixed.
    wtV :: Vector{F1}
    # Bounds on the weights (first again omitted)
    lbV :: Vector{F1}
    ubV :: Vector{F1}
    # Calibrate weights? The first is always fixed (normalization).
    doCal :: Bool
    # High first endowments => rank first?
    highDrawsFirst :: Bool
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

# StructLH.describe(e :: EndowPctRanking) = StructLH.describe(e.switches);

# high_draws_first(e :: EndowPctRanking{F1}) where F1 = 
#     high_draws_first(e.switches);

high_draws_first(switches :: EndowPctRankingSwitches{F1}) where F1 = 
    switches.highDrawsFirst;

first_weight(switches :: EndowPctRankingSwitches{F1}) where F1 = 
    high_draws_first(switches) ? one(F1) : -one(F1);

fixed_weights(switches :: EndowPctRankingSwitches{F1}) where F1 = 
    [first_weight(switches), switches.wtV...];

weights(e :: EndowPctRanking{F1}) where F1 =
    [first_weight(e.switches), e.wtV...];

calibrate_weights(switches :: EndowPctRankingSwitches{F1}) where F1 = 
    switches.doCal;
# calibrate_weights(e :: EndowPctRanking{F1}) where F1 = 
#     calibrate_weights(e.switches);


"""
	$(SIGNATURES)

Set bounds for one endowment.

# Example
```
set_bounds!(switches, :ability, -1.0, 1.0);
```
"""
function set_bounds!(switches :: EndowPctRankingSwitches{F1}, eName :: Symbol, 
    lb :: F1, ub :: F1) where F1

    idx = findfirst(endow_names(switches) .== eName);
    @assert idx > 1  "Cannot set bounds for $eName in $switches"
    switches.lbV[idx-1] = lb;
    switches.ubV[idx-1] = ub;
    switches.wtV[idx-1] = 0.5 * (lb + ub);
    return nothing
end


# ------  Constructing

"""
	$(SIGNATURES)

Constructor with keyword arguments.
Properly handles the case of a single endowment.
"""
function EndowPctRankingSwitches(eNameV :: Vector{Symbol}; 
    wtInV = nothing, lbInV = nothing, ubInV = nothing,
    doCalIn :: Bool = true, highDrawsFirst :: Bool = true)

    if length(eNameV) == 1
        wtV = Vector{Float64}();
        lbV = Vector{Float64}();
        ubV = Vector{Float64}();
        doCal = false;
    else
        n = length(eNameV) - 1;
        wtV = isnothing(wtInV) ? fill(1.0, n) : wtInV;
        lbV = isnothing(lbInV) ? zeros(n) : lbInV;
        ubV = isnothing(ubInV) ? fill(3.0, n) : ubInV;
        doCal = doCalIn;
    end
    return EndowPctRankingSwitches(eNameV, wtV, lbV, ubV, doCal, highDrawsFirst);
end

"""
	$(SIGNATURES)

Rank on a single endowment.
"""
EndowPctRankingSwitches(eName :: Symbol; highDrawsFirst :: Bool = true) = 
    EndowPctRankingSwitches([eName]; highDrawsFirst = highDrawsFirst);


function make_test_endowpct_switches(n :: Integer, highDrawsFirst :: Bool)
    eNameV = [:abilPct, :parentalPct, :hsGpaPct, :h0Pct];
    lbV = [-1.0, 0.0, 0.2];
    ubV = [0.0, 3.0, 2.0];
    wtV = 0.6 .* lbV .+ 0.4 .* ubV;
    # This produces an [] wtV when n == 1
    e = EndowPctRankingSwitches(eNameV[1 : n], 
        wtV[1 : (n-1)], lbV[1 : (n-1)], ubV[1 : (n-1)], true, highDrawsFirst);
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
        wtV, wtV, switches.lbV, switches.ubV, switches.doCal);
    return p
end

function validate_ranking_switches(e :: EndowPctRankingSwitches{F1}) where F1
    isValid = true
    if !(length(endow_names(e)) == 1 + length(e.wtV))
        @warn "Weights have wrong length: $e"
        isValid = false;
    end
    if !isempty(e.wtV)
        if !all_greater(e.wtV, e.lbV; atol = 1e-5)  ||  any(isinf.(e.wtV))
            @warn "Invalid weights: $(e.wtV)"
            isValid = false;
        end
        if !all(e.ubV .> e.lbV)
            @warn "Invalid bounds: $(e.lbV), $(e.ubV)"
            isValid = false;
        end
    end
    if !(length(e.lbV) == length(e.ubV) == length(e.wtV))
        @warn "Invalid sizes: $(e.lbV), $(e.wtV), $(e.ubV)"
        isValid = false;
    end
    return isValid
end

function validate_ranking(e :: EndowPctRanking{F1}) where F1
    isValid = true;
    isValid = isValid && (size(endow_names(e)) == size(weights(e)))
    return isValid
end

# -------------