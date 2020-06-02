# Sequential assignment. Multiple locations

# Inputs are
# - `nc`: number of colleges
# - `totalCapacity` of all colleges; in multiples of  total `typeMass`
function make_test_entry_sequ_multiloc(J, nc, nl, totalCapacity)
    # objId = ObjectId(:entryOneStep);
    @assert nl > 1
    typeMass_jlM = range(1.0, 1.3, length = J) * range(1.0, 0.8, length = nl)';
    totalMass = sum(typeMass_jlM);
    capacity_clM = range(1.0, 1.5, length = nc) * range(1.0, 0.7, length = nl)';
    capacity_clM = capacity_clM ./ sum(capacity_clM) .* totalCapacity .* totalMass;

    switches = EntrySequMultiLocSwitches{Float64}(
        nTypes = J, nColleges = nc, valueLocal = 0.5,
        typeMass_jlM = typeMass_jlM, capacity_clM = capacity_clM);
    return switches
end

function init_entry_decision(objId :: ObjectId, 
    switches :: EntrySequMultiLocSwitches{F1}) where F1

    pEntryPref = init_entry_prefscale(switches);
    pValueLocal = init_value_local(switches);
    pvec = ParamVector(objId, [pEntryPref, pValueLocal]);
    return EntrySequMultiLoc(objId, pvec, ModelParams.value(pEntryPref), 
        ModelParams.value(pValueLocal), switches)
end

function init_value_local(switches :: EntrySequMultiLocSwitches{F1}) where F1
    valueLocal = switches.valueLocal;
    pEntryPref = Param(:valueLocal, "Value of local college",
        "vLocal", valueLocal, valueLocal, F1(0.1), F1(5.0), 
        switches.calValueLocal);
    return pEntryPref
end



## ------------  Entry decisions

# Just a wrapper for consistent interface.
function entry_decisions(entryS :: EntrySequMultiLoc{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, 
    endowPctV :: Vector{F1},
    rank_jV :: Vector{I2}) where {I1, I2 <: Integer, F1}

    return entry_sequ_multiloc(entryS,  admissionS, 
        vWork_jV, vCollege_jcM, endowPctV,  rank_jV);
end


# A method that can be called directly. Avoids potential method ambiguities or dispatch errors.
function entry_sequ_multiloc(entryS :: EntrySequMultiLoc{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, 
    endowPctV :: Vector{F1},
    rank_jV :: Vector{I2}) where {I1, I2 <: Integer, F1}

    nTypes, nc = size(vCollege_jcM);
    nl = n_locations(entryS);

    enroll_clM = zeros(F1, nc, nl);
    # Prob that student (j, l) attends college (c, l)
    probLocal_jcM = zeros(F1, nTypes, nc);
    probNonLocal_jcM = zeros(F1, nTypes, nc);
    eVal_jlM = zeros(F1, nTypes, nl);

    # Loop over students in order of ranking
    for j in rank_jV
        # Loop over locations in ascending order
        for l = 1 : nl
            full_clM = (enroll_clM .>= capacities(entryS));

            # This is the standard one-step entry decision, but with colleges from all locations stacked.
            entryProb_clM, eVal_jlM[j, l] = entry_decisions_one_student(
                entryS, admissionS, vWork_jV[j], vCollege_jcM[j,:],
                endowPctV[j], full_clM, l);

            # entryProb_clM = reshape(prob_clV, nc, nl);
            # Record enrollment
            enroll_clM .+= college_enrollment(entryS, entryProb_clM, j, l);
            probLocal_jcM[j,:] = entryProb_clM[:,l];
            probNonLocal_jcM[j,:] = 
                sum(entryProb_clM, dims = 2) .- probLocal_jcM[j,:];
        end
    end

    er = EntryResultsMultiLoc(entryS.switches, probLocal_jcM, probNonLocal_jcM,
        eVal_jlM, enroll_clM);
    @assert validate_er(er)
    return er
end


# College enrollments of student `j` in `l`
function college_enrollment(entryS :: EntrySequMultiLoc{F1}, 
    entryProb_clM :: Matrix{F1}, j :: Integer, l :: Integer) where F1

    return entryProb_clM .* type_mass(entryS, j, l)
end

# --------------