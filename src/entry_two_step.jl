# Two step entry decision

make_test_entry_two_step(J, nc) = 
    EntryTwoStepSwitches{Float64}(nTypes = J, nColleges = nc);

function init_entry_decision(objId :: ObjectId,
    switches :: EntryTwoStepSwitches{F1},
    st :: SymbolTable) where F1
    
    pEntryPref = init_entry_prefscale(switches, st);

    collPrefScale = switches.collPrefScale;
    pCollPref = Param(:collPrefScale, 
        LatexLH.description(st, :collPresScale), latex(st, :collPrefScale), 
        collPrefScale, collPrefScale, 0.1, 3.0, 
        switches.calEntryPrefScale);

    pvec = ParamVector(objId, [pEntryPref]);
    return EntryTwoStep(objId,  pvec, ModelParams.pvalue(pEntryPref), 
        collPrefScale, switches)
end


"""
    $(SIGNATURES)

Entry probability for a student who is admitted to colleges in `admitV`.
Value of work argument is not used in this case, but provided so that interface is consistent with one step entry decision.

OUT: 
- Entry prob by [type, college]. Conditional on entry
- Expected value by type
"""
function entry_probs(e :: EntryTwoStep{F1}, vWork_jV :: Vector{F1},
    vCollege_jcM :: Matrix{F1}, admitV;
    prefShocks :: Bool = true) where F1 <: Real

    J, nc = size(vCollege_jcM);
    prob_jxM = zeros(F1, J, nc);

    if isempty(admitV)
        eVal_jV = fill(F1(-1e8), J);
    else
        if prefShocks
            probM, eVal_jV = EconLH.extreme_value_decision(
                vCollege_jcM[:, admitV], entry_pref_scale(e); demeaned = true);
            prob_jxM[:, admitV] .= probM;
        else
            eVal_jV, icV = max_choices(fill(F1(-1e8), J),
                vCollege_jcM, admitV);
            prob_jxM[:, icV] .= one(F1);
        end
    end
    return prob_jxM, eVal_jV
end

# The same for one individual
function entry_probs(e :: EntryTwoStep{F1}, 
    vWork :: F1, vCollege_cV :: Vector{F1}, admitV;
    profShocks :: Bool = true) where F1 <: Real

    nc = length(vCollege_cV);
    prob_cV = zeros(F1, nc);

    @assert !isempty(admitV)  "Two step entry cannot have empty admission set"
    if prefShocks
        # eVal is a one element vector and probV is a Matrix
        probV, eVal = EconLH.extreme_value_decision_one(
            vCollege_cV[admitV], entry_pref_scale(e); demeaned = true);
        prob_cV[admitV] .= probV;
    else
        eVal, ic = max_choice(F1(-1e8), vCollege_cV, admitV);
        (ic > 0)  &&  (prob_cV[ic] = one(F1));
    end

    @assert check_float(eVal)
    return prob_cV, eVal
end


function entry_decisions(
    entryS :: EntryTwoStep{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: AbstractVector{F1}, vCollege_jcM :: AbstractMatrix{F1}, 
    endowPctV :: AbstractVector{F1}, rank_jV)  where {I1, F1}

    error("Not implemented for two step entry yet")
end

# -----------------