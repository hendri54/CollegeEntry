# Sequential assignment. Multiple locations

## ------------- Switches

# Inputs are
# - `totalCapacity` of all colleges; in multiples of  total `typeMass`
function make_test_entry_sequ_multiloc(J, nc, nl, totalCapacity)
    if nl > 1
        valueLocal = 0.7;
        calValueLocal = true;
        typeMass_jlM = range(1.0, 1.3, length = J) * range(1.0, 0.8, length = nl)';
        totalMass = sum(typeMass_jlM);
        capacity_clM = range(1.0, 1.5, length = nc) * range(1.0, 0.7, length = nl)';
        capacity_clM = capacity_clM ./ sum(capacity_clM) .* 
            totalCapacity .* totalMass;
    else
        valueLocal = 0.0;
        calValueLocal = false;
        typeMass_jlM = matrix_from_vector(range(1.0, 1.3, length = J));
        totalMass = sum(typeMass_jlM);
        capacity_clM = matrix_from_vector(range(1.0, 1.5, length = nc));
        capacity_clM = capacity_clM ./ sum(capacity_clM) .* 
            totalCapacity .* totalMass;
    end

    switches = EntryDecisionSwitches(
        nTypes = J, nColleges = nc, nLocations = nl, valueLocal = valueLocal,
        typeMass_jlM = typeMass_jlM, capacity_clM = capacity_clM, 
        calValueLocal = calValueLocal);
    @assert validate_es(switches)
    return switches
end


# function make_entry_

function validate_es(switches :: EntryDecisionSwitches{F1}) where F1
    isValid = true;
    J = n_types(switches);
    nc = n_colleges(switches);
    nl = n_locations(switches);
    if nl == 1
        if switches.calValueLocal  ||  !(switches.valueLocal == zero(F1))
            isValid = false;
            @warn  "Cannot have local value with one location"
        end
    end
    return isValid
end


## ---------------  Entry Decision constructor

function init_entry_decision(objId :: ObjectId, 
    switches :: EntryDecisionSwitches{F1}) where F1

    pEntryPref = init_entry_prefscale(switches);
    pValueLocal = init_value_local(switches);
    pvec = ParamVector(objId, [pEntryPref, pValueLocal]);
    return EntryDecision(objId, pvec, ModelParams.value(pEntryPref), 
        ModelParams.value(pValueLocal), switches)
end

function init_value_local(switches :: EntryDecisionSwitches{F1}) where F1
    if n_locations(switches) == 1
        # Cannot have local value
        valueLocal = zero(F1);
        calValueLocal = false;
    else
        valueLocal = switches.valueLocal;
        calValueLocal = switches.calValueLocal;
    end

    ub = max(F1(5.0), valueLocal + 2.0);
    pEntryPref = Param(:valueLocal, "Value of local college",
        "vLocal", valueLocal, valueLocal, F1(0.0), ub, 
        calValueLocal);
    return pEntryPref
end



## ------------  Entry decisions

"""
    $(SIGNATURES)

Compute entry probabilities and expected values at entry from admission rule and entry decision objects.
"""
function entry_decisions(entryS :: EntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, 
    endowPctV :: Vector{F1},
    rank_jV :: Vector{I2}) where {I1, I2 <: Integer, F1}

    nTypes = n_types(entryS);
    nc = n_colleges(entryS);
    nl = n_locations(entryS);
    er = EntryResults(entryS.switches);

    # enroll_clM = zeros(F1, nc, nl);
    # # Prob that student (j, l) attends college (c, l)
    # probLocal_jcM = zeros(F1, nTypes, nc);
    # probNonLocal_jcM = zeros(F1, nTypes, nc);
    # eVal_jlM = zeros(F1, nTypes, nl);

    # Loop over students in order of ranking
    for j in rank_jV
        # Loop over locations in ascending order
        for l = 1 : nl
            full_clM = (enrollments(er) .>= capacities(entryS));

            # This is the standard one-step entry decision, but with colleges from all locations stacked.
            entryProb_clM, er.eVal_jlM[j, l] = entry_decisions_one_student(
                entryS, admissionS, vWork_jV[j], vCollege_jcM[j,:],
                endowPctV[j], full_clM, l);

            # Record enrollment
            er.enroll_clM .+= enrollment_cl(entryS, entryProb_clM, j, l);
            er.probLocal_jcM[j,:] = entryProb_clM[:,l];
            er.probNonLocal_jcM[j,:] = 
                sum(entryProb_clM, dims = 2) .- er.probLocal_jcM[j,:];
        end
    end

    @assert validate_er(er)
    return er
end


# College enrollments of student `j` in `l`
function enrollment_cl(entryS :: EntryDecision{F1}, 
    entryProb_clM :: Matrix{F1}, j :: Integer, l :: Integer) where F1

    return entryProb_clM .* type_mass(entryS, j, l)
end

# --------------