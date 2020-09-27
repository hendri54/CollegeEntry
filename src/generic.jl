# Generic functions that apply to all (or most) objects

set_pref_scale!(switches :: AbstractEntrySwitches{F1},
    prefScale :: F1) where F1 =
    switches.entryPrefScale = prefScale;


"""
	$(SIGNATURES)

Scale entry probabilities by (j,l) -> c to bound away from 0.
Bound entry probs by (j,l) away from 1.
Does not guarantee particular min values (that is hard to do).
"""
function scale_entry_probs!(entryProb_jlcM :: Array{F1, 3},
    minEntryProb :: F1, maxEntryProb :: F1) where F1 <: AbstractFloat

    J, nl, nc = size(entryProb_jlcM);
    for iType = 1 : J
        for l = 1 : nl
            prob_cV = 
                max.(minEntryProb, entryProb_jlcM[iType, l, :]);

            pSum = sum(prob_cV);
            if pSum > maxEntryProb
                prob_cV .*= (maxEntryProb / pSum);
            end
            entryProb_jlcM[iType, l, :] .= prob_cV;    
        end
        # for ic = 1 : nc
        #     # Scale so that total entry prob j -> c is at least minEntryProb
        #     prob_lV = entryProb_jlcM[iType, :, ic];
        #     pSum = sum(prob_lV);
        #     if pSum < 0.000001
        #         # Basically all zero entries. Set to a constant
        #         prob_lV = fill(minEntryProb / nl, nl);
        #     elseif pSum < minEntryProb
        #         prob_lV .*= (minEntryProb / pSum);
        #     end
        #     entryProb_jlcM[iType, :, ic] = prob_lV;
        # end

        # # Scale so that entry prob j <= maxEntryProb
        # pSum = sum(entryProb_jlcM[iType,:,:]);
		# if pSum > maxEntryProb
		# 	entryProb_jlcM[iType,:,:] .*= (maxEntryProb / pSum);
        # end
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
function init_entry_prefscale(switches :: AbstractEntrySwitches{F1},
    st :: SymbolTable) where F1
    entryPrefScale = switches.entryPrefScale;
    pEntryPref = Param(:entryPrefScale, 
    description(st, :pScaleEntry), latex(st, :pScaleEntry), entryPrefScale, entryPrefScale, F1(0.1), F1(3.0), 
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
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, admitV;
    prefShocks :: Bool = true) where F1 <: AbstractFloat

    if prefShocks
        prefScale = entry_pref_scale(e);
    else
        prefScale = zero(F1);
    end
    return one_step_entry_probs(prefScale, vWork_jV, vCollege_jcM, admitV);
end

# The same for one student
function entry_probs(e :: AbstractEntryDecision{F1}, 
    vWork :: F1, vCollege_cV :: Vector{F1}, admitV;
    prefShocks :: Bool = true) where F1

    if prefShocks
        prefScale = entry_pref_scale(e);
    else
        prefScale = zero(F1);
    end
    return one_step_entry_probs(prefScale, vWork, vCollege_cV, admitV)
end


# The same shutting down preference shocks
# function entry_probs_no_pref_shocks(e :: AbstractEntryDecision{F1}, 
#     vWork :: F1, vCollege_cV :: Vector{F1}, admitV) where F1

#     return one_step_entry_probs(zero(F1), vWork, vCollege_cV, admitV)
# end


# Generic entry decision. One step. Given pref shock scale.
# Works for any entry protocol where entry works in one step (work/study and which college at the same time).
function one_step_entry_probs(entryPrefScale :: F1, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, admitV) where F1 <: AbstractFloat

    J, nc = size(vCollege_jcM);
    prob_jxM = zeros(F1, J, nc);
    if isempty(admitV)
        eVal_jV = copy(vWork_jV);
    else
        if entryPrefScale > 0.00001
            # Prob of work in column 1. Then admitted colleges.
            probM, eVal_jV = EconLH.extreme_value_decision( 
                hcat(vWork_jV, vCollege_jcM[:, admitV]), 
                entryPrefScale; demeaned = true);
            for j = 1 : J
                probV = probM[j,:];
                make_valid_probs!(probV);
                prob_jxM[j, admitV] .= probV[2 : end];
            end
        else
            eVal_jV, icV = max_choices(vWork_jV, vCollege_jcM, admitV);
            for j = 1 : J
                if icV[j] > 0
                    prob_jxM[j, icV[j]] = one(F1);
                end
            end
        end
    end
    return prob_jxM, eVal_jV
end


# The same for one type.
# Preference shocks may be zero.
function one_step_entry_probs(entryPrefScale :: F1,
    vWork :: F1, vCollege_cV :: Vector{F1}, admitV) where F1 <: AbstractFloat

    nc = length(vCollege_cV);
    prob_cV = zeros(F1, nc);
    if isempty(admitV)
        eVal = vWork;
    else
        if entryPrefScale > 0.00001
            probV, eVal = EconLH.extreme_value_decision_one(
                vcat(vWork, vCollege_cV[admitV]), entryPrefScale;
                demeaned = true);
            make_valid_probs!(probV);
            prob_cV[admitV] .= probV[2 : end];
        else
            # No preference shocks - just choose the best option
            eVal, ic = max_choice(vWork, vCollege_cV, admitV);
            if ic > 0
                prob_cV[ic] = one(F1);
            end
        end
    end
    return prob_cV, eVal
end


"""
	$(SIGNATURES)

Entry probs for one student across all admissions sets. Handles the case where some colleges are full.
Always for multiple locations (matrix inputs). But one location is allowed.

# Outputs
- `entryProb_clM`: probability of entering each college
- `eVal`: expected value
- `entryProbBest_clM`: fraction of students who enter college `c, l` and for who `c` is the best available college (in any location). For the top college, this is identical to the entry rate.
"""
function entry_decisions_one_student(entryS :: AbstractEntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork :: F1, vCollege_cV :: AbstractVector{F1}, 
    endowPct :: F1, full_clM :: AbstractMatrix{Bool}, l :: Integer;
    prefShocks :: Bool = true)  where {I1, F1}

    nl = n_locations(entryS);
    nc = n_colleges(entryS);
    @check size(full_clM) == (nc, nl)

    # Value of college is the same for all locations, except local
    vCollege_clM = repeat(vCollege_cV, outer = (1, nl));
    vCollege_clM[:, l] .+= value_local(entryS);

    entryProb_clM = zeros(F1, nc, nl);
    eVal = zero(F1);
    # Fraction of students who attend the best available college (regardless of location). By quality attended. For the best college, this equals `entryProb_cV`.
    entryProbBest_clM = zeros(F1, nc, nl);
    # Admission rule gives admission to one college type in all locations
    for (iSet, admitV) in enumerate(admissionS)
        # Prob that each person draws this college set
        probSet = prob_coll_set(admissionS, iSet, endowPct);
        avail_clM = available_colleges(entryS, full_clM, admitV, l);
        @check size(avail_clM) == size(vCollege_clM)

        # Entry probs for this set
        prob_clV, eValSet = 
            entry_probs(entryS, vWork, vec(vCollege_clM), vec(avail_clM);
                prefShocks = prefShocks);
        # Tested separately that `reshape` undoes `vec`
        prob_clM = reshape(prob_clV, nc, nl);
        entryProb_clM .+= probSet .* prob_clM;
        eVal += probSet * eValSet;

        # Fraction attending best available.
        cBest = best_available(avail_clM);
        entryProbBest_clM[cBest,:] .+= probSet .* prob_clM[cBest, :];
    end

    make_valid_probs!(entryProb_clM);
    make_valid_probs!(entryProbBest_clM);
    # Deal with rounding errors that arise during scaling.
    bracket_array!(entryProbBest_clM, zeros(F1, nc, nl), entryProb_clM);
    return entryProb_clM, eVal, entryProbBest_clM
end


# Can only attend colleges that are not full, where student is admitted.
function available_colleges(entryS :: AbstractEntryDecision{F1}, 
    full_clM :: AbstractMatrix{Bool}, 
    admitV, l :: Integer) where F1

    # Do not use falses here. It creates a BitArray
    avail_clM = fill(false, size(full_clM));
    # Admitted counts for all locations
    avail_clM[admitV, :] .= true;
    avail_clM[full_clM] .= false;
    # If there are local-only colleges, mark those as not available
    mark_local_only_colleges!(entryS, avail_clM, l);
    return avail_clM
end


function best_available(avail_clM)
    cBest = 1;
    for ic = 2 : size(avail_clM, 1)
        if any(avail_clM[ic,:])
            cBest = ic;
        end
    end
    return cBest
end


# Mark local only colleges as unavailable when not local.
function mark_local_only_colleges!(entryS :: AbstractEntryDecision{F1}, 
    avail_clM, l) where F1

    idxV = local_only_colleges(entryS);
    if !isempty(idxV)
        for ic ∈ idxV
            aLocal = avail_clM[ic, l];
            avail_clM[ic, :] .= false;
            avail_clM[ic, l] = aLocal;
        end
    end
    return nothing
end


# The same with one location. Simply calls the multi-location code with one location dimension.
function entry_decisions_one_student(entryS :: AbstractEntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork :: F1, vCollege_cV :: AbstractVector{F1}, 
    endowPct :: F1, full_cV :: AbstractVector{Bool};
    prefShocks :: Bool = true)  where {I1, F1}

    # Just solve the multi-location version for the first location.
    entryProb_clM, eVal, entryProbBest_clM = 
        entry_decisions_one_student(entryS, admissionS, 
        vWork, vCollege_cV, endowPct,  repeat(full_cV, outer = (1,1)), 1;
        prefShocks = prefShocks);

    make_valid_probs!(entryProb_clM)
    return vec(entryProb_clM), eVal, entryProbBest_clM
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