# Generic functions that apply to all (or most) objects


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
This function does not handle the sequential nature of admissions. It is mainly here for unified interface.
It defaults to the one step entry protocol. If that does not apply for a protocol, need to define a new method (e.g. two step entry).
"""
function entry_probs(e :: AbstractEntryDecision{F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

    return one_step_entry_probs(entry_pref_scale(e), vWork_jV, vCollege_jcM, admitV);
end

# The same for one student
function entry_probs(e :: AbstractEntryDecision{F1}, 
    vWork :: F1, vCollege_cV :: Vector{F1}, admitV) where F1

    return one_step_entry_probs(entry_pref_scale(e), vWork, vCollege_cV, admitV)
end



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


# """
# 	$(SIGNATURES)

# Compute entry probabilities and expected values at entry from admission rule and entry decision objects.
# The `rank_jV` argument does nothing, but is here for consistency with the sequential entry case.
# Beware of ambiguous dispatch. The signature of methods for specific entry decisions must match exactly.
# """
# function entry_decisions(
#     entryS :: AbstractEntryDecision{F1}, 
#     admissionS :: AbstractAdmissionsRule{I1, F1}, 
#     vWork_jV :: AbstractVector{F1}, vCollege_jcM :: AbstractMatrix{F1}, 
#     endowPctV :: AbstractVector{F1}, rank_jV)  where {I1, F1}

#     # Avoid potential incorrect dispatch
#     if isa(entryS, EntrySequential)
#         return entry_sequential(entryS,  admissionS, 
#             vWork_jV, vCollege_jcM, endowPctV,  rank_jV);
#     elseif isa(entryS, EntryTwoStep)
#         error("Not implemented for two step entry")
#     end
#     @assert n_locations(entryS) == 1

#     # Solve separately for each set of colleges the student could get into
#     nSets = n_colleges(admissionS);
#     J, nc = size(vCollege_jcM);

#     # For one step entry: these are conditional on entry.
#     # For two step entry: they are not conditional on entry.
#     entryProb_jcM = zeros(F1, J, nc);
#     eVal_jV = zeros(F1, J);
#     for (iSet, admitV) in enumerate(admissionS)
#         # Prob that each person draws this college set
#         probSet_jV = prob_coll_set(admissionS, iSet, endowPctV);
#         prob_jxM, eValSet_jV = 
#             entry_probs(entryS, vWork_jV, vCollege_jcM, admitV);
#         for j = 1 : J
#             entryProb_jcM[j,:] .+= probSet_jV[j] .* prob_jxM[j, :];
#             eVal_jV[j] += probSet_jV[j] * eValSet_jV[j];
#         end
#     end

#     enrollV = college_enrollment(entryS, entryProb_jcM);
#     er = EntryResults(entryS.switches, entryProb_jcM, eVal_jV, enrollV);
#     @assert validate_er(er);
#     return er
#     # return entryProb_jcM, eVal_jV
# end


"""
	$(SIGNATURES)

Entry probs for one student across all admissions sets. Handles the case where some colleges are full.
Always for multiple locations (matrix inputs). But one location is allowed.
"""
function entry_decisions_one_student(entryS :: AbstractEntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork :: F1, vCollege_cV :: AbstractVector{F1}, 
    endowPct :: F1, full_clM :: AbstractMatrix{Bool}, l :: Integer)  where {I1, F1}

    nl = n_locations(entryS);
    nc = n_colleges(entryS);
    @check size(full_clM) == (nc, nl)

    # Value of college is the same for all locations, except local
    vCollege_clM = repeat(vCollege_cV, outer = (1, nl));
    vCollege_clM[:, l] .+= value_local(entryS);

    entryProb_clM = zeros(F1, nc, nl);
    eVal = zero(F1);
    # Admission rule gives admission to one college type in all locations
    for (iSet, admitV) in enumerate(admissionS)
        # Prob that each person draws this college set
        probSet = prob_coll_set(admissionS, iSet, endowPct);
        # Can only attend colleges that are not full
        # Do not use falses here. It creates 
        avail_clM = fill(false, nc, nl);
        avail_clM[admitV, :] .= true;
        avail_clM[full_clM] .= false;
        @check size(avail_clM) == size(vCollege_clM)

        # Entry probs for this set
        prob_clV, eValSet = 
            entry_probs(entryS, vWork, vec(vCollege_clM), vec(avail_clM));
        # Tested separately that `reshape` undoes `vec`
        prob_clM = reshape(prob_clV, nc, nl);
        entryProb_clM .+= probSet .* prob_clM;
        eVal += probSet * eValSet;
    end

    @assert check_prob_array(entryProb_clM)
    return entryProb_clM, eVal
end


# The same with one location. Simply calls the multi-location code with one location dimension.
function entry_decisions_one_student(entryS :: AbstractEntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork :: F1, vCollege_cV :: AbstractVector{F1}, 
    endowPct :: F1, full_cV :: AbstractVector{Bool})  where {I1, F1}

    entryProb_clM, eVal = entry_decisions_one_student(entryS, admissionS, vWork, 
        vCollege_cV, endowPct,
        repeat(full_cV, outer = (1,1)), 1);

    @assert check_prob_array(entryProb_clM)
    return vec(entryProb_clM), eVal
end


## ------------  Implied outcomes

# """
# 	$(SIGNATURES)

# Compute college enrollment from type mass and entry probabilities.
# """
# function college_enrollment(entryProb_jcM :: Matrix{F1}, 
#     typeMass_jV) where F1 <: AbstractFloat

#     J, nc = size(entryProb_jcM);
#     enrollV = zeros(F1, nc);
#     for ic = 1 : nc
#         enrollV[ic] = sum(entryProb_jcM[:, ic] .* typeMass_jV);
#     end
#     return enrollV
# end

# function college_enrollment(e :: AbstractEntryDecision{F1}, 
#     entryProb_jcM :: Matrix{F1}) where F1 <: AbstractFloat
#     return college_enrollment(e.switches, entryProb_jcM);
# end

# function college_enrollment(e :: AbstractEntrySwitches{F1}, 
#     entryProb_jcM :: Matrix{F1}) where F1 <: AbstractFloat

#     @assert n_locations(e) == 1
#     J = size(entryProb_jcM, 1);
#     return college_enrollment(entryProb_jcM, type_masses(e));
# end

# function college_enrollment(e :: AbstractEntryDecision{F1}, 
#     entryProb_cV :: Vector{F1},  j :: Integer) where F1   
    
#     @assert n_locations(e) == 1
#     return entryProb_cV .* type_mass(e, j);
# end


# """
#     $(SIGNATURES)

# Return `Bool` vector that indicates which colleges are full. Only matters for entry structures with capacity constraints.
# """
# function colleges_full(e :: AbstractEntryDecision{F1}, 
#     entryProb_jcM :: Matrix{F1}) where F1 <: AbstractFloat
  
#     @assert n_locations(e) == 1  "Not valid for multiple locations"
#     return college_enrollment(e, entryProb_jcM) .>= capacities(e)
# end

# --------------