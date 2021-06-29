## -----------  Open admission

struct AdmProbFctOpenSwitches{F1} <: AbstractAdmProbFctSwitches{F1} 
    objId :: ObjectId
    nColleges :: Int
end

"""
	$(SIGNATURES)

This is really a dummy for cases where an admission probability function is not needed.
"""
struct AdmProbFctOpen{F1} <: AbstractAdmProbFct{F1} 
    objId :: ObjectId
    switches :: AdmProbFctOpenSwitches{F1}
end

param_names(af :: AdmProbFctOpenSwitches{F1}) where F1 = nothing;
param_names(::Type{AdmProbFctOpenSwitches{F1}}) where F1 = nothing;


ModelParams.has_pvector(switches :: AdmProbFctOpenSwitches{F1}) where F1 = false;
ModelParams.get_object_id(switches :: AdmProbFctOpenSwitches{F1}) where F1 = 
    switches.objId;

init_admprob_fct(switches :: AdmProbFctOpenSwitches{F1}) where F1 = 
    AdmProbFctOpen{F1}(get_object_id(switches), switches);

n_open_colleges(switches :: AdmProbFctOpenSwitches{F1}) where F1 = 
    n_colleges(switches);

make_admprob_function(af :: AdmProbFctOpen{F1}, ic) where F1 = 
    x -> one(F1);

prob_admit(af :: AdmProbFctOpen{F1}, iCollege :: Integer, hsGpa) where {I1, F1} = 
    prob_admit_open(hsGpa);

# prob_admit(af :: AdmProbFctOpen{F1}, iCollege :: Integer, 
#     hsGpa :: AbstractArray{F1}) where {I1, F1} = ones(F1, size(hsGpa));

prob_admit_open(hsGpa :: F1) where F1 <: Real = one(F1);
prob_admit_open(hsGpa :: AbstractArray{F1}) where F1 <: Real = 
    ones(F1, size(hsGpa));

    
validate_admprob_fct(af :: AdmProbFctOpen{F1}) where F1 = true;

make_test_admprob_fct_open_switches(nc) = 
    AdmProbFctOpenSwitches{Float64}(ObjectId(:admProbFctOpen), nc);
make_test_admprob_fct_open(nc) = 
    init_admprob_fct(make_test_admprob_fct_open_switches(nc));

# -------