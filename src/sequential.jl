# Sequential assignment

function sequential_entry_probs(assignS :: CollegeAssignment{F1}, entryS :: EntryOneStep{F1}, admissionS :: AbstractAdmissionsRule{I1, F1}, vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, endowPctV :: Vector{F1}, rank_jV :: Vector{I2}) where {I1, I2 <: Integer, F1}

    nc = n_colleges(admissionS);
    nTypes = length(vWork_jV);
    enrollV = zeros(F1, nc);
    fullV = falses(nc);

    entryProb_jcM = zeros(F1, nTypes, nc);
    eVal_jV = zeros(F1, nTypes);

    for j in rank_jV
        for (iSet, admitV) in enumerate(admissionS)
            # Prob that each person draws this college set
            probSet = prob_coll_set(admissionS, iSet, endowPctV[j]);
            # Can only attend colleges that are not full
            availV = falses(nc);
            availV[admitV .& !fullV] .= true;

            # Entry probs for this set
            # does this work for one j +++++
            prob_cV, eValSet = entry_probs(entryS, vWork_jV[j], vCollege_jcM[j,:], availV);
            entryProb_jcM[j,:] .+= probSet .* prob_cV;
            eVal_jV .+= probSet .* eValSet;

        end

        # Record enrollment
        enrollV .+= entryProb_jcM[j,:] .* type_mass(assignS);
        fullV = (enrollV .< capacities(assignS));
    end

    return entryProb_jcM, eVal_jV
end





# --------------