"""
	$(SIGNATURES)

Abstract type for admissions rules.
Not a ModelObject. This is combined with an `AbstractAdmProbFct` that potentially contains calibrated parameters.
"""
abstract type AbstractAdmissionsRule{I1, F1 <: Real} end

"""
	$(SIGNATURES)

Abstract type for switches from which admissions rules are constructed.
"""
abstract type AbstractAdmissionsSwitches{I1, F1 <: Real} end


StructLH.describe(a :: AbstractAdmissionsRule) = StructLH.describe(a.switches);

"""
	$(SIGNATURES)

Initialize an admission rule from its switches. 
"""
function make_admissions(switches :: AbstractAdmissionsSwitches) end


"""
	$(SIGNATURES)

Stash admissions probability functions inside the object (usually not needed).
"""
function stash_admprob_functions(a :: AbstractAdmissionsRule, fctV) end



n_colleges(a :: AbstractAdmissionsRule) = a.switches.nColleges;

# By default, college sets are of the form `1:n`.
n_college_sets(a :: AbstractAdmissionsRule) = n_colleges(a);
college_set(a :: AbstractAdmissionsRule, iSet :: Integer) = 1 : iSet;
open_admission(a :: AbstractAdmissionsRule) = false;
open_admission(a :: AbstractAdmissionsSwitches) = false;

# Iterate over college sets
function Base.iterate(a :: AbstractAdmissionsRule, j)
    if j > n_college_sets(a)
        return nothing
    else
        return college_set(a, j), j+1
    end
end

Base.iterate(a :: AbstractAdmissionsRule) = Base.iterate(a, 1);

min_coll_set_prob(a :: AbstractAdmissionsRule{I1, F1}) where {I1, F1} = 
    min_coll_set_prob(a.switches);
min_coll_set_prob(a :: AbstractAdmissionsSwitches{I1, F1}) where {I1, F1} =     
    a.minCollSetProb;


# Probability of being admitted at each college
function admission_probs(a :: AbstractAdmissionsRule{I1, F1}, pctV :: AbstractVector) where {I1, F1}

    nSets = n_college_sets(a);
    nc = n_colleges(a);
    J = length(pctV);
    prob_jcM = zeros(F1, J, nc);
    for iSet = 1 : nSets
        probV = prob_coll_set(a, iSet, pctV);
        iCollV = college_set(a, iSet);
        prob_jcM[:, iCollV] .+= probV;
    end
    return prob_jcM
end


# Prob of each college set.
function prob_coll_set(a :: AbstractAdmissionsRule{I1, F1}, iSet :: Integer, 
    hsGpaPctV :: AbstractVector{F2}) where {I1, F1, F2 <: Real}

    J = length(hsGpaPctV);
    probV = Vector{F1}(undef, J);
    for j = 1 : J
        probV[j] = prob_coll_set(a, iSet, hsGpaPctV[j]);
    end
    return probV
end


function prob_coll_sets(a :: AbstractAdmissionsRule{I1, F1}, 
    hsGpaPctV :: AbstractVector{F2}) where {I1, F1, F2 <: Real}

    nSets = n_college_sets(a);
    n = length(hsGpaPctV);
    prob_jsM = Matrix{F1}(undef, n, nSets);
    for j = 1 : n
        prob_jsM[j, :] = prob_coll_sets(a, hsGpaPctV[j]);
    end

    @assert all_at_least(prob_jsM, a.switches.minCollSetProb)
    @assert all_at_most(prob_jsM, 1.0)
    @check all(isapprox.(sum(prob_jsM, dims = 2), 1.0, atol = 1e-6))
    return prob_jsM
end


# ----------