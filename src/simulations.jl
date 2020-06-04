# Simulate entry decisions for one student. Mainly for testing.
function sim_one_student(entryS :: AbstractEntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork :: F1, vCollege_cV :: AbstractVector{F1}, 
    endowPct :: F1, full_clM :: AbstractMatrix{Bool}, l :: Integer,
    nSim :: Integer, rng :: AbstractRNG) where {I1, F1}

    for j = 1 : nSim
        sim_once(entryS, admissionS, vWork, vCollege_cV, 
            endowPct, full_clM, l, rng);
    end

end


function sim_once(entryS :: AbstractEntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork :: F1, vCollege_cV :: AbstractVector{F1}, 
    endowPct :: F1, full_clM :: AbstractMatrix{Bool}, l :: Integer,
    rng :: AbstractRNG) where {I1, F1}

    nc = n_colleges(entryS);
    nl = n_locations(entryS);

    # Draw admissions set
    probSetV = prob_coll_sets(admissionS, endowPct);
    aSet = rand(rng, 1 : length(probSetV));
    admitV = college_set(admissionS, aSet);

    # Available colleges
    avail_clM = fill(false, nc, nl);
    avail_clM[admitV, :] .= true;
    avail_clM[full_clM] .= false;

    # Draw type 1 shocks for all colleges
    rand_clM = rand(rng, Gumbel(),  nc, nl) .-= 0.5772;

    # Value of college is the same for all locations, except local
    vCollege_clM = repeat(vCollege_cV, outer = (1, nl));
    vCollege_clM[:, l] .+= value_local(entryS);

    # Pick the max value
    valueM = vCollege_clM  .-  rand_clM .* entry_pref_scale(entryS);
end


# Simulate a single entry decision.
# For testing `entry_probs`
function sim_entry_probs(entryS :: AbstractEntryDecision{F1}, 
    vWork :: F1, vCollege_clM :: Matrix{F1}, avail_clM :: Matrix{Bool}, 
    nSim :: Integer, rng :: AbstractRNG) where F1

    nc, nl = size(vCollege_clM);
    eVal = zero(F1);
    prob_clM = zeros(F1, nc, nl);
    for iSim = 1 : nSim
        eVal1, ic, l = sim_entry_probs_once(entryS, 
            vWork, vCollege_clM, avail_clM, rng);
        if ic > 0
            prob_clM[ic, l] += 1 / nSim;
        end
        eVal += eVal1 / nSim;
    end
    return prob_clM, eVal
end


function sim_entry_probs_once(entryS :: AbstractEntryDecision{F1}, 
    vWork :: F1, vCollege_clM :: Matrix{F1}, avail_clM :: Matrix{Bool}, 
    rng :: AbstractRNG) where F1

    prefScale = entry_pref_scale(entryS);
    nc, nl = size(vCollege_clM);
    # Draw type 1 shocks for all colleges
    rand_clM = draw_gumbel_shocks(rng, prefScale, nc, nl);

    # Pick the max value
        # According to EconLH, this should be subtracted ++++++++++
    valueM = vCollege_clM  .+  rand_clM;
    valueM[.!avail_clM] .= F1(-1e8);
    maxVal, idxV = findmax(valueM);
    ic = idxV[1];
    l = idxV[2];
    @assert maxVal == valueM[ic, l]

    valueWork = vWork + draw_gumbel_shocks(rng, prefScale, 1)[1];
    if valueWork > maxVal
        eVal = valueWork;
        ic = 0;
        l = 0;
    else
        eVal = maxVal;
    end
    return eVal, ic, l
end

# move to econLH +++++++++
function draw_gumbel_shocks(rng, prefScale, sizeV...)
    return prefScale .* (rand(rng, Gumbel(),  sizeV...) .-= 0.5772);
end

# ------------