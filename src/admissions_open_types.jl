## -----------  Open admission

"""
	$(SIGNATURES)

Switches governing open admissions protocol.
"""
mutable struct AdmissionsOpenSwitches{I1, F1} <: AbstractAdmissionsSwitches{I1, F1}
    nColleges :: I1
    # The variable that holds the individual percentiles (here for interface consistency)
    # pctVar :: Symbol
end


"""
	$(SIGNATURES)

Open admissions. Any student may attend any college.
"""
struct AdmissionsOpen{I1, F1} <: AbstractAdmissionsRule{I1, F1}
    switches :: AdmissionsOpenSwitches{I1, F1}
end


Base.show(io :: IO, a :: AdmissionsOpen) = print(io, typeof(a));

StructLH.describe(a :: AdmissionsOpenSwitches) = ["College admissions"  "open"];

n_college_sets(a :: AdmissionsOpen) = 1;
college_set(a :: AdmissionsOpen, j :: Integer) = 1 : n_colleges(a);
# open_admission(a :: AdmissionsOpen) = true;
open_admission(a :: AdmissionsOpenSwitches) = true;
# percentile_var(switches :: AdmissionsOpenSwitches) = switches.pctVar;
validate_admissions(a :: AdmissionsOpen) = true;

# Prob of each college set.
# Returns 0-dim array if `kwargs` are scalar.
# Keyword args could be hsGpaPct; this way the same args can be passed to all admissions rules
function prob_coll_set(a :: AdmissionsOpen{I1, F1}, admProbFct :: AF1,
    j :: Integer, pctV :: AbstractVector{F2}) where 
    {AF1 <: AbstractAdmProbFct{<: Real}, I1, F1, F2 <: Real}
    if (j==1) 
        return ones(F1, length(pctV));
    else error("Invalid j: $j");
    end
end

prob_coll_set(a :: AdmissionsOpen{I1, F1}, admProbFct :: AF1, 
    j :: Integer, hsGpaPct :: F2) where 
    {AF1 <: AbstractAdmProbFct{<: Real}, I1, F1 <: Real, F2 <: Number}  =  one(F1);

function prob_coll_sets(a :: AdmissionsOpen{I1, F1}, 
    admProbFct :: AF1, 
    pctV :: AbstractVector) where {AF1 <: AbstractAdmProbFct{<: Real}, I1, F1}
    return ones(F1, length(pctV), 1);
end

make_admissions(switches :: AdmissionsOpenSwitches{I1, F1}) where {I1, F1} = 
    AdmissionsOpen{I1, F1}(switches);

make_test_admissions_open(nc :: I1) where I1 = 
    AdmissionsOpen{I1, Float64}(AdmissionsOpenSwitches{I1, Float64}(nc));


# ----------------