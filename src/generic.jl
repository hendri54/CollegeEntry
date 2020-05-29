# Generic functions that apply to all (or most) objects

## --------------   Access methods

Base.show(io :: IO, e :: AbstractEntrySwitches) =
    print(io, typeof(e));
Base.show(io :: IO, e :: AbstractEntryDecision) =
    print(io, typeof(e), ":  preference scale ",  
        round(entry_pref_scale(e), digits = 2));

min_entry_prob(e :: AbstractEntryDecision{F1}) where F1 = e.switches.minEntryProb;
max_entry_prob(e :: AbstractEntryDecision{F1}) where F1 = e.switches.maxEntryProb;

fix_entry_probs!(e :: AbstractEntryDecision) = fix_entry_probs!(e.switches);
fix_entry_probs!(e :: AbstractEntrySwitches) = e.fixEntryProbs = true;

entry_probs_fixed(e :: AbstractEntryDecision) = e.switches.fixEntryProbs;
entry_pref_scale(e :: AbstractEntryDecision) = e.entryPrefScale;


"""
	$(SIGNATURES)

Mass of each type. Only plays a role when colleges have capacities. Set to 1 otherwise.
"""
type_mass(e :: AbstractEntryDecision{F1}) where F1 = one(F1);

"""
	$(SIGNATURES)

College capacities. Set to an arbitrary large number for entry mechanisms where capacities do not matter.
"""
capacities(e :: AbstractEntryDecision{F1}) where F1 = F1(1e8);


"""
	$(SIGNATURES)

Scale entry probabilities to bound away from 0 and bound sum away from 1.
Does not guarantee particular min or max values (that is hard to do).
"""
function scale_entry_probs!(entryS :: AbstractEntryDecision{F1}, 
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


## ---------------  Constructors

"""
    `init_entry_decision(objId :: ObjectId, switches :: AbstractEntrySwitches)`

Initializes an `AbstractEntryDecision` from its switches.
"""
function init_entry_decision end


# Initialize entry preference scale parameter.
function init_entry_prefscale(switches :: AbstractEntrySwitches{F1}) where F1
    entryPrefScale = switches.entryPrefScale;
    pEntryPref = Param(:entryPrefScale, "Entry preference shocks",
        "\\pi", entryPrefScale, entryPrefScale, F1(0.1), F1(3.0), 
        switches.calEntryPrefScale);
end


## --------------  Solve entry decisions

"""
    $(SIGNATURES)

Entry probability for a student who is admitted to colleges in `admitV`.
Returns: Entry prob by [type, college], expected value at decision stage by type.
"""
function entry_probs end


# Generic entry decision. One step. Given pref shock scale.
# Works for any entry protocol where entry works in one step (work/study and which college at the same time).
function one_step_entry_probs(entryPrefScale :: F1, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

    prob_jxM = zeros(F1, size(vCollege_jcM));
    if isempty(admitV)
        eVal_jV = copy(vWork_jV);
    else
        d = ExtremeValueDecision(entryPrefScale, true, false);
        # Prob of work in column 1. Then admitted colleges.
        probM, eVal_jV = EconLH.extreme_value_decision(d, 
            hcat(vWork_jV, vCollege_jcM[:, admitV]));
        prob_jxM[:, admitV] .= probM[:, 2 : end];
    end
    return prob_jxM, eVal_jV
end

# The same for one type
function one_step_entry_probs(entryPrefScale :: F1,
    vWork :: F1, vCollege_cV :: Vector{F1}, admitV) where F1 <: AbstractFloat

    nc = length(vCollege_cV);
    prob_cV = zeros(F1, nc);
    if isempty(admitV)
        eVal = vWork;
    else
        d = ExtremeValueDecision(entryPrefScale, true, false);
        # Prob of work in column 1. Then admitted colleges.
        # eVal is a one element vector and probV is a Matrix
        probV, eValV = EconLH.extreme_value_decision(d, 
            hcat(vWork, Matrix{F1}(vCollege_cV[admitV]')));
        prob_cV[admitV] .= probV[2 : end];
        eVal = eValV[1];
    end
    return prob_cV, eVal
end


"""
	$(SIGNATURES)

Compute entry probabilities and expected values at entry from admission rule and entry decision objects.
The `rank_jV` argument does nothing, but is here for consistency with the sequential entry case.
"""
function entry_decisions(
    entryS :: AbstractEntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: AbstractVector{F1}, vCollege_jcM :: AbstractMatrix{F1}, 
    hsGpaPctV :: AbstractVector{F1}, rank_jV)  where {I1, F1}

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


## ------------  Implied outcomes

"""
	$(SIGNATURES)

Compute college enrollment from type mass and entry probabilities.
"""
college_enrollment(entryProb_jcM :: Matrix{F1}, 
    typeMass :: F1) where F1 <: AbstractFloat =
    vec(sum(entryProb_jcM, dims = 1)) .* typeMass;

college_enrollment(e :: AbstractEntryDecision, 
    entryProb_jcM :: Matrix{F1}) where F1 <: AbstractFloat =
    college_enrollment(entryProb_jcM, type_mass(e));

"""
    $(SIGNATURES)

Return `Bool` vector that indicates which colleges are full. Only matters for entry structures with capacity constraints.
"""
colleges_full(e :: AbstractEntryDecision{F1}, entryProb_jcM :: Matrix{F1}) where F1 <: AbstractFloat =
    college_enrollment(e, entryProb_jcM) .>= capacities(e)

# --------------