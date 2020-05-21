# Generic functions that apply to all (or most) objects

Base.show(io :: IO, e :: AbstractEntrySwitches) =
    print(io, typeof(e));
Base.show(io :: IO, e :: AbstractEntryDecision) =
    print(io, typeof(e), ":  preference scale ",  
        round(entry_pref_scale(e), digits = 2));

min_entry_prob(e :: AbstractEntryDecision) = e.switches.minEntryProb;
max_entry_prob(e :: AbstractEntryDecision) = e.switches.maxEntryProb;
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

# --------------