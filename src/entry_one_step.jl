# One step entry decision

function make_test_entry_one_step()
    objId = ObjectId(:entryOneStep);
    switches = EntryOneStepSwitches{Float64}();
    return init_entry_decision(objId, switches)
end

function init_entry_decision(objId :: ObjectId, 
    switches :: EntryOneStepSwitches{F1}) where F1

    # objId = make_child_id(model_id(), :entryDecision);
    entryPrefScale = switches.entryPrefScale;
    pEntryPref = Param(:entryPrefScale, "Entry preference shocks",
        "\\pi", entryPrefScale, entryPrefScale, F1(0.1), F1(3.0), 
        switches.calEntryPrefScale);
    pvec = ParamVector(objId, [pEntryPref]);
    return EntryOneStep(objId, pvec, entryPrefScale, switches)
end


function entry_probs(e :: EntryOneStep{F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

    d = ExtremeValueDecision(entry_pref_scale(e), true, false);
    # Prob of work in column 1. Then admitted colleges.
    probM, eVal_jV = EconLH.extreme_value_decision(d, 
        hcat(vWork_jV, vCollege_jcM[:, admitV]));
    prob_jxM = zeros(F1, size(vCollege_jcM));
    prob_jxM[:, admitV] .= probM[:, 2:end];
    return prob_jxM, eVal_jV
end




# ------------