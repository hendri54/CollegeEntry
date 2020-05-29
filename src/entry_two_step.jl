# Two step entry decision

function make_test_entry_two_step()
    objId = ObjectId(:entryTwoStep);
    switches = EntryTwoStepSwitches{Float64}();
    return init_entry_decision(objId, switches)
end

function init_entry_decision(objId :: ObjectId,
    switches :: EntryTwoStepSwitches{F1}) where F1
    # objId = make_child_id(model_id(), :entryDecision);
    
    pEntryPref = init_entry_prefscale(switches);

    collPrefScale = switches.collPrefScale;
    pCollPref = Param(:collPrefScale, "Collge choice preference shocks",
        "\\piC", collPrefScale, collPrefScale, 0.1, 3.0, 
        switches.calEntryPrefScale);

    pvec = ParamVector(objId, [pEntryPref]);
    return EntryTwoStep(objId,  pvec, ModelParams.value(pEntryPref), 
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
    vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

    @assert !isempty(admitV)  "Two step entry cannot have empty admission set"
    d = ExtremeValueDecision(entry_pref_scale(e), true, false);
    probM, eVal_jV = EconLH.extreme_value_decision(d, vCollege_jcM[:, admitV]);

    prob_jxM = zeros(F1, size(vCollege_jcM));
    prob_jxM[:, admitV] .= probM;
    return prob_jxM, eVal_jV
end

# The same for one individual
function entry_probs(e :: EntryTwoStep{F1}, 
    vWork :: F1, vCollege_cV :: Vector{F1}, admitV) where F1 <: AbstractFloat

    @assert !isempty(admitV)  "Two step entry cannot have empty admission set"
    d = ExtremeValueDecision(entry_pref_scale(e), true, false);
    # eVal is a one element vector and probV is a Matrix
    probV, eVal = EconLH.extreme_value_decision(d, Matrix{F1}(vCollege_cV[admitV]'));

    nc = length(vCollege_cV);
    prob_cV = zeros(F1, nc);
    prob_cV[admitV] .= vec(probV);
    return prob_cV, eVal[1]
end


# -----------------