"""
	$(SIGNATURES)

Abstract type for admissions rules.
"""
abstract type AbstractAdmissionsRule{I1, F1 <: AbstractFloat} end

"""
	$(SIGNATURES)

Abstract type for switches from which admissions rules are constructed.
"""
abstract type AbstractAdmissionsSwitches{I1, F1 <: AbstractFloat} end


StructLH.describe(a :: AbstractAdmissionsRule) = StructLH.describe(a.switches);

"""
	$(SIGNATURES)

Initialize an admission rule from its switches. 
"""
function make_admissions(switches :: AbstractAdmissionsSwitches) end


n_colleges(a :: AbstractAdmissionsRule) = a.switches.nColleges;
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


# ----------