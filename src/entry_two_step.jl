# Two step entry decision

function init_entry_decision(objId :: ObjectId,
    switches :: EntryTwoStepSwitches{F1}) where F1
    # objId = make_child_id(model_id(), :entryDecision);
    
    entryPrefScale = switches.entryPrefScale;
    pEntryPref = Param(:entryPrefScale, "Entry preference shocks",
        "\\pi", entryPrefScale, entryPrefScale, 0.1, 3.0, 
        switches.calEntryPrefScale);

    collPrefScale = switches.collPrefScale;
    pCollPref = Param(:collPrefScale, "Collge choice preference shocks",
        "\\piC", collPrefScale, collPrefScale, 0.1, 3.0, 
        switches.calEntryPrefScale);

    pvec = ParamVector(objId, [pEntryPref]);
    return EntryTwoStep(objId,  pvec, entryPrefScale, collPrefScale, switches)
end


"""
    $(SIGNATURES)

Entry probability for a student who is admitted to colleges in `admitV`.
Value of work argument is not used in this case, but provided so that interface is consistent with one step entry decision.

OUT: 
- Entry prob by [type, college]. Conditional on entry
- Expected value by type
"""
function entry_probs(e :: EntryTwoStep{F1}, vWork_jV,
    vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

    d = ExtremeValueDecision(entry_pref_scale(e), true, false);
    # Prob of work in column 1. Then admitted colleges.
    probM, eVal_jV = EconLH.extreme_value_decision(d, vCollege_jcM[:, admitV]);

    prob_jxM = zeros(F1, size(vCollege_jcM));
    prob_jxM[:, admitV] .= probM;
    return prob_jxM, eVal_jV
end

# -----------------