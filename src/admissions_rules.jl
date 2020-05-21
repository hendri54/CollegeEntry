# Admissions Rules
#=
All college sets have positive probability in each case. This ensures that we can observe each type in each college.
=#

## ----------  Generic functions

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


## -----------  Open admissions

# AdmissionOpenSwitches(nc :: Integer, pctVar :: Symbol)

Base.show(io :: IO, a :: AdmissionsOpen) = print(io, typeof(a));

n_college_sets(a :: AdmissionsOpen) = 1;
college_set(a :: AdmissionsOpen, j :: Integer) = 1 : n_colleges(a);
open_admission(a :: AdmissionsOpen) = true;
open_admission(a :: AdmissionsOpenSwitches) = false;
percentile_var(a :: AdmissionsOpen) = a.switches.pctVar;
validate_admissions(a :: AdmissionsOpen) = true;

# Prob of each college set.
# Returns 0-dim array if `kwargs` are scalar.
# Keyword args could be hsGpaPct; this way the same args can be passed to all admissions rules
prob_coll_set(a :: AdmissionsOpen{I1, F1}, j :: Integer, pctV :: AbstractVector) where {I1, F1} =    (j==1) ? ones(F1, length(pctV)) : error("Invalid j: $j");

prob_coll_set(a :: AdmissionsOpen{I1, F1}, j :: Integer, hsGpaPct :: F2) where 
    {I1, F1 <: AbstractFloat, F2 <: Number}  =  one(F1);

prob_coll_sets(a :: AdmissionsOpen{I1, F1}, pctV :: AbstractVector) where {I1, F1} =
    ones(F1, length(pctV), 1);

make_admissions(switches :: AdmissionsOpenSwitches{I1, F1}) where {I1, F1} = 
    AdmissionsOpen{I1, F1}(switches);

make_test_admissions_open(nc :: I1) where I1 = 
    AdmissionsOpen{I1, Float64}(AdmissionsOpenSwitches{I1, Float64}(nc, :hsGpaPct));


## --------------------------  HS GPA or other endowment cutoff
# Type 1 colleges admit everyone
# College sets are: 1, 1:2, ... 1:nc

function Base.show(io :: IO, a :: AdmissionsCutoff)
    nc = n_colleges(a);
    print(io, typeof(a), " with cutoff percentiles",
        round.(min_percentiles(a), digits = 2));
end

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

function highest_college(a :: AdmissionsCutoff{I1, F1}, endowPctV :: AbstractVector{F2}) where {I1, F1, F2 <: AbstractFloat}

    highV = Vector{Int}(undef, length(endowPctV));
    for (j, endowPct) in enumerate(endowPctV)
        highV[j] = highest_college(a, endowPct);
    end
    return highV
end


# Prob of each college set.
function prob_coll_set(a :: AdmissionsCutoff{I1, F1}, iSet :: Integer, 
    hsGpaPctV :: AbstractVector{F2}) where {I1, F1, F2 <: AbstractFloat}

    # _, hsGpaPctV = get_draws(endowDraws, percentile_var(a));
    J = length(hsGpaPctV);
    probV = Vector{F1}(undef, J);
    for j = 1 : J
        probV[j] = prob_coll_set(a, iSet, hsGpaPctV[j]);
    end
    return probV
end


# Probability that one student draws one college set
function prob_coll_set(a :: AdmissionsCutoff{I1, F1}, iSet :: Integer, endowPct :: F2) where {I1, F1, F2 <: Real}

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


function prob_coll_sets(a :: AdmissionsCutoff{I1, F1}, hsGpaPctV :: AbstractVector{F2}) where {I1, F1, F2 <: AbstractFloat}

    nSets = n_college_sets(a);
    # _, hsGpaPctV = get_draws(endowDraws, percentile_var(a));
    n = length(hsGpaPctV);
    prob_jsM = Matrix{F1}(undef, n, nSets);
    for j = 1 : n
        prob_jsM[j, :] = prob_coll_sets(a, hsGpaPctV[j]);
    end
    if dbgHigh
        @assert all_at_least(prob_jsM, a.switches.minCollSetProb)
        @assert all_at_most(prob_jsM, 1.0)
        @check all(isapprox.(sum(prob_jsM, dims = 2), 1.0, atol = 1e-6))
    end
    return prob_jsM
end


# ------------