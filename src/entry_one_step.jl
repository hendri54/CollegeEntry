# One step entry decision

function make_test_entry_one_step()
    objId = ObjectId(:entryOneStep);
    switches = EntryOneStepSwitches{Float64}();
    return init_entry_decision(objId, switches)
end

function init_entry_decision(objId :: ObjectId, 
    switches :: EntryOneStepSwitches{F1}) where F1

    pEntryPref = init_entry_prefscale(switches);
    pvec = ParamVector(objId, [pEntryPref]);
    return EntryOneStep(objId, pvec, ModelParams.value(pEntryPref), switches)
end


function entry_probs(e :: EntryOneStep{F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

    return one_step_entry_probs(entry_pref_scale(e), vWork_jV, vCollege_jcM, admitV);
end

# The same for one individual
function entry_probs(e :: EntryOneStep{F1}, 
    vWork :: F1, vCollege_cV :: Vector{F1}, admitV) where F1 <: AbstractFloat

    return one_step_entry_probs(entry_pref_scale(e), vWork, vCollege_cV, admitV);
end


# ------------