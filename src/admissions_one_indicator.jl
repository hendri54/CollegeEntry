# Admission prob is a function of a single indicator

"""
	$(SIGNATURES)

Switches governing admissions that are function of a single indicator.
"""
mutable struct AdmissionsOneVarSwitches{I1, F1 <: Real} <: AbstractAdmissionsSwitches{I1, F1}
    nColleges :: I1
    # Name of the variable that determines admissions probability
    # pctVar :: Symbol
    # Minimum probability of all college sets
    minCollSetProb :: F1
end

"""
	$(SIGNATURES)

Admissions are governed by a single indicator, such as a test score. 
For each college, admissions probability is an increasing function of that indicator.
The function is stored elsewhere.
Students may be allowed to attend other colleges with a fixed probability.

College sets are of the form `1 : n`.
Probability of being admitted to all colleges = admissions probability at top college.
Probability of being admitted to `1 : n` = admissions probablity of college `n` times 1 minus admission probability at `n+1` or higher.
"""
mutable struct AdmissionsOneVar{I1, F1 <: Real} <: AbstractAdmissionsRule{I1, F1}
    switches :: AdmissionsOneVarSwitches{I1, F1}
    # admissionProbFctV :: Vector
end

function Base.show(io :: IO, a :: AdmissionsOneVar)
    nc = n_colleges(a);
    # rankVar = percentile_var(a);
    print(io, typeof(a));  # , " with ranking variable $rankVar");
end

function StructLH.describe(a :: AdmissionsOneVarSwitches)
    # rankVar = percentile_var(a);
    return [
        "Admission rule"  "based on one indicator";
        # "Admission probability determined by"  "$rankVar";
    ];
end

function validate_admissions(a :: AdmissionsOneVar{I1, F1}) where {I1, F1}
    isValid = true;
    isValid  ||  println(a)
    return isValid
end

make_admissions(switches :: AdmissionsOneVarSwitches{I1, F1}) where {I1, F1} = 
    AdmissionsOneVar(switches);

make_test_adm_onevar_switches(nc) = 
    AdmissionsOneVarSwitches(nc, 0.05);

# By default: With the admission prob functions inside
function make_test_admissions_onevar(nc)
    a = make_admissions(make_test_adm_onevar_switches(nc));
    return a
end

function test_admission_prob_fct(x :: Real, ic :: Integer)
    if ic == 1
        prob = 1.0;
    else
        prob = 0.7 / (1.0 + 0.2 * exp(-x));
    end
    return prob
end


## ----------  Probability of being admitted to each college set

function prob_coll_set(a :: AdmissionsOneVar{I1, F1}, 
    admProbFct :: AF1,
    iSet :: Integer, hsGpaPct :: F2) where 
    {AF1 <: AbstractAdmProbFct{<: Real}, I1, F1, F2 <: Real}

    return prob_coll_sets(a, admProbFct, hsGpaPct)[iSet];
end

function prob_coll_sets(a :: AdmissionsOneVar{I1, F1}, 
    admProbFct :: AF1,
    hsGpaPct :: F2) where 
    {AF1 <: AbstractAdmProbFct{<: Real}, I1, F1, F2 <: Real}

    probAdmitV = [prob_admit(admProbFct, iCollege, hsGpaPct)  
        for iCollege = 1 : n_colleges(a)];
    @assert all(0.0 .<= probAdmitV .<= 1.0)  "Out of bounds: $probAdmitV"
    return prob_coll_sets_from_probs(a, probAdmitV)
end


# Compute prob of being admitted to each college set from probs of being admitted to each college.
function prob_coll_sets_from_probs(a :: AdmissionsOneVar{I1, F1}, 
    probAdmitV :: AbstractVector{F2}) where {I1, F1, F2 <: Real}

    nSets = n_college_sets(a);
    @assert nSets == length(probAdmitV)  "Assuming college sets are 1:n";
    @assert all(0.0 .<= probAdmitV .<= 1.0)  "Out of bounds";
    @assert probAdmitV[1] == 1.0  "Expecting everyone gets into lowest college";

    probV = zeros(nSets);
    # For top college: simply its admissions probability.
    probV[nSets] = probAdmitV[nSets];
    for iSet = (nSets-1) : -1 : 1
        # For lower colleges: (prob being admitted) * (prob not admitted higher).
        probAdmitHigher = sum(probV[(iSet+1) : nSets]);
        probV[iSet] = probAdmitV[iSet] * (1.0 - probAdmitHigher);
    end
    @check sum(probV) ≈ 1.0
    return probV
end


# ----------------