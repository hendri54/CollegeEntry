# Generic functions that apply to all (or most) objects

Base.show(io :: IO, e :: AbstractEntrySwitches) =
    print(io, typeof(e));
Base.show(io :: IO, e :: AbstractEntryDecision) =
    print(io, typeof(e), ":  preference scale ",  
        round(entry_pref_scale(e), digits = 2));

min_entry_prob(e :: AbstractEntryDecision) = e.switches.minEntryProb;
max_entry_prob(e :: AbstractEntryDecision) = e.switches.maxEntryProb;

fix_entry_probs!(e :: AbstractEntryDecision) = fix_entry_probs!(e.switches);
fix_entry_probs!(e :: AbstractEntrySwitches) = e.fixEntryProbs = true;

entry_probs_fixed(e :: AbstractEntryDecision) = e.switches.fixEntryProbs;
entry_pref_scale(e :: AbstractEntryDecision) = e.entryPrefScale;


## Scale entry probabilities to bound away from 0 and bound sum away from 1
# Does not guarantee particular min or max values (that is hard to do)
function scale_entry_probs!(entryS :: AbstractEntryDecision, 
    entryProb_jcM :: Matrix{F1}) where F1 <: AbstractFloat

    minEntryProb = min_entry_prob(entryS);
    maxEntryProb = max_entry_prob(entryS);
    for iType = 1 : size(entryProb_jcM)[1]
        entryProb_jcM[iType, :] = max.(entryProb_jcM[iType, :], minEntryProb);
		pSum = sum(entryProb_jcM[iType,:]);
		if pSum > maxEntryProb
			entryProb_jcM[iType,:] .*= (maxEntryProb / pSum);
		end
	end
	return nothing
end


"""
    `init_entry_decision(objId :: ObjectId, switches :: AbstractEntrySwitches)`

Initializes an `AbstractEntryDecision` from its switches.
"""
function init_entry_decision end


"""
    `entry_probs(e :: AbstractEntryDecision, vWork_jV, vCollege_jcM, admitV)`

Entry probability for a student who is admitted to colleges in `admitV`.
Returns: Entry prob by [type, college], expected value at decision stage by type.
"""
function entry_probs end


"""
	$(SIGNATURES)

Compute entry probabilities and expected values at entry from admission rule and entry decision objects.
"""
function entry_decisions(
    entryS :: AbstractEntryDecision, admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: AbstractVector{F1}, vCollege_jcM :: AbstractMatrix{F1}, 
    hsGpaPctV :: AbstractVector{F1})  where {I1 <: Integer, F1 <: AbstractFloat}

    # Solve separately for each set of colleges the student could get into
    nSets = n_colleges(admissionS);
    J, nc = size(vCollege_jcM);

    # For one step entry: these are conditional on entry.
    # For two step entry: they are not conditional on entry.
    entryProb_jcM = zeros(F1, J, nc);
    eVal_jV = zeros(F1, J);
    for (iSet, admitV) in enumerate(admissionS)
        # Prob that each person draws this college set
        probSet_jV = prob_coll_set(admissionS, iSet, hsGpaPctV);
        prob_jxM, eValSet_jV = 
            entry_probs(entryS, vWork_jV, vCollege_jcM, admitV);
        for j = 1 : J
            entryProb_jcM[j,:] .+= probSet_jV[j] .* prob_jxM[j, :];
            eVal_jV .+= probSet_jV[j] .* eValSet_jV;
        end
    end

    return entryProb_jcM, eVal_jV
end

# --------------