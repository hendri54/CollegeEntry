## ----------  HS GPA or other endowment percentile cutoff

"""
	$(SIGNATURES)

Switches governing admissions by cutoff rule.
"""
mutable struct AdmissionsCutoffSwitches{I1, F1 <: Real} <: AbstractAdmissionsSwitches{I1, F1}
    nColleges :: I1
    # Name of the variable that holds the individual percentiles
    pctVar :: Symbol
    # Minimum HS GPA percentile required for each college; should be increasing
    minPctV :: Vector{F1}
    # Minimum probability of all college sets
    minCollSetProb :: F1
end

"""
	$(SIGNATURES)

Admissions are governed by a single indicator, such as a test score. Students can attend colleges for which they qualify in the sense that their indicator exceeds the college's cutoff value. Students may be allowed to attend other colleges with a fixed probability.

This means that there are only two probabilities. With a high probability, the student can attend colleges `1:n` where `n` is the best college for which the student qualifies. With a low probability, the student may draw each college set `1 : m` where `m != n`.
"""
struct AdmissionsCutoff{I1, F1 <: Real} <: AbstractAdmissionsRule{I1, F1}
    switches :: AdmissionsCutoffSwitches{I1, F1}
end

function Base.show(io :: IO, a :: AdmissionsCutoff)
    nc = n_colleges(a);
    print(io, typeof(a), " with cutoff percentiles",
        round.(min_percentiles(a), digits = 2));
end

StructLH.describe(a :: AdmissionsCutoffSwitches) = [
    "Admission rule"  " ";
    "Cutoff rule based on"  "$(a.pctVar)";
    "Min $(a.pctVar) percentile by college"  "$(a.minPctV)"
];


function validate_admissions(a :: AdmissionsCutoff{I1, F1}) where {I1, F1}
    isValid = true;
    if any(diff(min_percentiles(a)) .<= 0.0)
        @warn "Min percentiles should be increasing"
        isValid = false;
    end
    isValid  ||  println(a)
    return isValid
end


make_admissions(switches :: AdmissionsCutoffSwitches{I1, F1}) where {I1, F1} = 
    AdmissionsCutoff(switches);

make_test_adm_cutoff_switches(nc) = 
    AdmissionsCutoffSwitches(nc, :hsGpa, 
        collect(range(0.0, 0.8, length = nc)), 0.05);
make_test_admissions_cutoff(nc) = 
    AdmissionsCutoff(make_test_adm_cutoff_switches(nc));

min_percentiles(a :: AdmissionsCutoff{I1, F1}) where {I1, F1} = a.switches.minPctV;
percentile_var(a :: AdmissionsCutoff{I1, F1}) where {I1, F1} = a.switches.pctVar;

# Highest college for which a student qualifies
# Last GPA cutoff that is smaller than student's endowment percentile.
function highest_college(a :: AdmissionsCutoff{I1, F1}, endowPct :: F2) where 
    {I1, F1, F2 <: Real}
    qIdx = findlast(x -> x <= endowPct, min_percentiles(a));
    @check qIdx >= 1
    return qIdx
end

function highest_college(a :: AdmissionsCutoff{I1, F1}, endowPctV :: AbstractVector{F2}) where {I1, F1, F2 <: Real}

    highV = Vector{Int}(undef, length(endowPctV));
    for (j, endowPct) in enumerate(endowPctV)
        highV[j] = highest_college(a, endowPct);
    end
    return highV
end


# Probability that one student draws one college set
function prob_coll_set(a :: AdmissionsCutoff{I1, F1}, 
    iSet :: Integer, endowPct :: F2) where {I1, F1, F2 <: Real}

    qIdx = highest_college(a, endowPct);
    if qIdx == iSet
        # Best college the student qualifies for
        nSets = n_college_sets(a);
        prob = one(F1) - min_coll_set_prob(a) * (nSets - 1);
        # nNot = nSets - qIdx;
        # prob = (1.0 - min_coll_set_prob(a) * nNot) / qIdx;
    else
        # Student does not qualify
        prob = min_coll_set_prob(a);
    end
    return prob
end


# Prob that a given student draws each college set
# If student qualifies for college 2 out of 5, the probabilities are:
#   (1 - minProb * 3) / 2  for first 2 (where he qualifies)
#   minProb for the last 3 where he does not qualify
function prob_coll_sets(a :: AdmissionsCutoff{I1, F1}, endowPct :: F2) where {I1, F1, F2 <: Real}
    nSets = n_college_sets(a);
    probV = [prob_coll_set(a, iSet, endowPct)  for iSet = 1 : nSets];
    @check sum(probV) ≈ 1
    return probV
end


# function prob_coll_sets(a :: AdmissionsCutoff{I1, F1}, hsGpaPctV :: AbstractVector{F2}) where {I1, F1, F2 <: Real}

#     nSets = n_college_sets(a);
#     n = length(hsGpaPctV);
#     prob_jsM = Matrix{F1}(undef, n, nSets);
#     for j = 1 : n
#         prob_jsM[j, :] = prob_coll_sets(a, hsGpaPctV[j]);
#     end

#     @assert all_at_least(prob_jsM, a.switches.minCollSetProb)
#     @assert all_at_most(prob_jsM, 1.0)
#     @check all(isapprox.(sum(prob_jsM, dims = 2), 1.0, atol = 1e-6))
#     return prob_jsM
# end

# ------------------