# Sequential assignment

# no longer used +++++

# Inputs are
# - `nc`: number of colleges
# - `totalCapacity` of all colleges; in multiples of  total `typeMass`
function make_test_entry_sequential(J, nc, totalCapacity)
    # objId = ObjectId(:entryOneStep);
    typeMass_jV = ones(J);
    typeMass = sum(typeMass_jV);
    capacityV = collect(range(1.0, 1.5, length = nc));
    capacityV = capacityV ./ sum(capacityV) .* totalCapacity .* typeMass;
    switches = EntrySequentialSwitches{Float64}(nTypes = J, nColleges = nc,
        typeMass_jV = typeMass_jV, capacityV = capacityV);
    return switches
    # return init_entry_decision(objId, switches)
end

function init_entry_decision(objId :: ObjectId, 
    switches :: EntrySequentialSwitches{F1}) where F1

    pEntryPref = init_entry_prefscale(switches);
    pvec = ParamVector(objId, [pEntryPref]);
    return EntrySequential(objId, pvec, ModelParams.value(pEntryPref), switches)
end


## ------------  Entry decisions

# Just a wrapper for consistent interface.
function entry_decisions(entryS :: EntrySequential{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, 
    endowPctV :: Vector{F1},
    rank_jV :: Vector{I2};
    prefShocks :: Bool = true) where {I1, I2 <: Integer, F1}

    return entry_sequential(entryS,  admissionS, 
        vWork_jV, vCollege_jcM, endowPctV,  rank_jV;
        prefShocks = prefShocks);
end


# A method that can be called directly. Avoids potential method ambiguities or dispatch errors.
function entry_sequential(entryS :: EntrySequential{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, 
    endowPctV :: Vector{F1},
    rank_jV :: Vector{I2}; 
    prefShocks :: Bool = true) where {I1, I2 <: Integer, F1}

    nc = n_colleges(admissionS);
    nTypes = length(vWork_jV);
    enrollV = zeros(F1, nc);
    fullV = fill(false, nc);

    entryProb_jcM = zeros(F1, nTypes, nc);
    eVal_jV = zeros(F1, nTypes);

    # Loop over students in order of ranking
    for j in rank_jV
        entryProb_jcM[j, :], eVal_jV[j] = entry_decisions_one_student(
            entryS, admissionS, vWork_jV[j], vCollege_jcM[j, :],
            endowPctV[j], fullV);

        # Record enrollment
        enrollV .+= college_enrollment(entryS, entryProb_jcM[j,:], j);
        fullV = (enrollV .>= capacities(entryS));
    end

    er = EntryResults(entryS.switches, entryProb_jcM, eVal_jV, enrollV);
    @assert validate_er(er; validateFracLocal = prefShocks);
    return er
    # return entryProb_jcM, eVal_jV
end




# --------------