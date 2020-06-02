# One step entry decision

make_test_entry_one_step(J, nc) = 
    EntryOneStepSwitches{Float64}(nTypes = J, nColleges = nc);


function init_entry_decision(objId :: ObjectId, 
    switches :: EntryOneStepSwitches{F1}) where F1

    pEntryPref = init_entry_prefscale(switches);
    pvec = ParamVector(objId, [pEntryPref]);
    return EntryOneStep(objId, pvec, ModelParams.value(pEntryPref), switches)
end


# ------------