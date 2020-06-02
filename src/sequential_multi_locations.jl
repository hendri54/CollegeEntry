# Sequential assignment. Multiple locations

# Inputs are
# - `nc`: number of colleges
# - `totalCapacity` of all colleges; in multiples of  total `typeMass`
function make_test_entry_sequ_multiloc(J, nc, nl, totalCapacity)
    objId = ObjectId(:entryOneStep);
    typeMass_jlM = range(1.0, 1.3, length = J) * range(1.0, 0.8, length = nl)';
    totalMass = sum(typeMass_jlM);
    capacity_clM = range(1.0, 1.5, length = nc) * range(1.0, 0.7, length = nl)';
    capacity_clM = capacity_clM ./ sum(capacity_clM) .* totalCapacity .* totalMass;
    switches = EntrySequMultiLocSwitches{Float64}(
        typeMass_jlM = typeMass_jlM, capacity_clM = capacity_clM);
    return init_entry_decision(objId, switches)
end

function init_entry_decision(objId :: ObjectId, 
    switches :: EntrySequMultiLocSwitches{F1}) where F1

    pEntryPref = init_entry_prefscale(switches);
    pvec = ParamVector(objId, [pEntryPref]);
    return EntrySequMultiLoc(objId, pvec, ModelParams.value(pEntryPref), switches)
end


## ----------  Access routines

capacities(a :: EntrySequMultiLocSwitches{F1}) where F1 = a.capacity_clM;
type_mass(a :: EntrySequMultiLocSwitches{F1}, j, l) where F1 = a.typeMass_jlM[j, l];



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
    entryProb_jlclM = zeros(F1, nTypes, nl, nc, nl);
    eVal_jlM = zeros(F1, nTypes, nl);

    # Loop over students in order of ranking
    for j in rank_jV
        # Loop over locations in ascending order
        for l = 1 : nl
            full_clM = (enroll_clM .>= capacities(entryS));
            # Value of college is the same for all locations, except local
            vCollege_clM = repeat(vCollege_jcM[j,:], outer = (1, nl));
            vCollege_clM[:, l] .+= valueLocal;  # part of object +++++++

            # This is the standard one-step entry decision, but with colleges from all locations stacked.
            prob_clV, eVal_jlM[j, l] = entry_decisions_one_student(
                entryS, admissionS, vWork_jV[j], vec(vCollege_clM),
                endowPctV[j], vec(full_clM));

            entryProb_clM = reshape(prob_clV, nc, nl);
            # Record enrollment
            enroll_clM .+= college_enrollment(entryS, entryProb_clM, j, l);
            entryProb_jlclM[j,l,:,:] = entryProb_clM;  # or just return local / non-local? +++++
        end
    end

    return entryProb_jlclM, eVal_jlM
end


# entry_probs does not solve a useful problem ++++++++++

# # The actual entry decision is the same as for the OneStep case. But has to be computed one student at a time.
# # This function does not handle the sequential nature of admissions. It is mainly here for testing.
# function entry_probs(e :: EntrySequMultiLoc{F1}, 
#     vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

#     return one_step_entry_probs(entry_pref_scale(e), vWork_jV, vCollege_jcM, admitV);
# end

# function entry_probs(e :: EntrySequMultiLoc{F1}, 
#     vWork :: F1, vCollege_cV :: Vector{F1}, admitV) where F1

#     return one_step_entry_probs(entry_pref_scale(e), vWork, vCollege_cV, admitV)
# end


# --------------