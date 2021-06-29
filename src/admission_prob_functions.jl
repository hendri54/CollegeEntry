# Admission probability functions

abstract type AbstractAdmProbFctSwitches{F1 <: Real} <: ModelSwitches end
abstract type AbstractAdmProbFct{F1 <: Real} <: ModelObject end

"""
	$(SIGNATURES)

Initialize admission probability functions for all colleges (as a set).
Still need to make the function for each college.
"""
function init_admprob_fct(switches :: AbstractAdmProbFctSwitches{F1}) where F1 end

n_colleges(switches :: AbstractAdmProbFctSwitches{F1}) where F1 = 
    switches.nColleges;


Lazy.@forward AbstractAdmProbFct.switches (
    ModelParams.has_pvector, n_colleges, n_open_colleges,
    by_college, by_college!, college_index, param_names
    );

Base.show(io :: IO, af :: AbstractAdmProbFct{F1}) where F1 = 
    print(io, typeof(af));
Base.show(io :: IO, af :: AbstractAdmProbFctSwitches{F1}) where F1 = 
    print(io, typeof(af));

ModelParams.has_pvector(switches :: AbstractAdmProbFctSwitches{F1}) where F1 = true;

ModelParams.get_object_id(switches :: AbstractAdmProbFctSwitches{F1}) where F1 = 
    get_object_id(switches.pvec);
    
# function prob_admit(admProbFct :: AF1,
#     iCollege :: Integer, hsGpa) where {AF1 <: AbstractAdmProbFct{<: Real}, I1, F1}

#     # This is expensive, but hard to avoid. Need to ensure that current parameters are used when admission prob fct is constructed.
#     prob_fct = make_admprob_function(admProbFct, iCollege);
#     return prob_fct.(hsGpa)
# end


function make_admprob_fct_switches(objId :: ObjectId, switchType :: DataType, 
    nc, nOpen, byCollegeV, calibratedV)

    pvecV = Vector{Param}();
    for pName in param_names(switchType)
        nColl = pvec_length(nc, nOpen, byCollegeV, pName);
        isCalibrated = any(isequal.(pName, calibratedV));
        push!(pvecV, init_param(switchType, pName, nColl, isCalibrated));
    end
    pvec = ParamVector(objId, pvecV);

    switches = switchType(pvec, nc, nOpen);
    @assert validate_admprob_fct_switches(switches);
    return switches
end


# Returns the no of colleges with parameters for a parameter.
# Exammple: `pvec_length(4, 1, [:mV], :bV) == 1`.
function pvec_length(nc, nOpen, byCollegeV, pName)
    if any(isequal.(byCollegeV, pName))
        return nc - nOpen;
    else
        return 1;
    end
end


## ------------  Access

# Index into parameters that vary by college.
function college_index(switches :: AbstractAdmProbFctSwitches{F1}, iCollege) where F1
    return iCollege .- n_open_colleges(switches);
end


"""
	$(SIGNATURES)

Does the parameter `pName` vary by college?
"""
function by_college(switches :: AbstractAdmProbFctSwitches{F1}, pName) where F1
    v = param_value(switches, pName);
    @assert !isnothing(v)  "Not found: $pName";
    return length(v) > 1
end

"""
	$(SIGNATURES)

Switch a parameter to vary by college.
"""
function by_college!(switches :: AbstractAdmProbFctSwitches{F1}, pName) where F1
    set_by_college!(switches, pName, true);
end

"""
	$(SIGNATURES)

Switch a parameter NOT to vary by college.
"""
function not_by_college!(switches :: AbstractAdmProbFctSwitches{F1}, pName) where F1
    set_by_college!(switches, pName, false);
end

function set_by_college!(switches :: AbstractAdmProbFctSwitches{F1}, 
    pName, byCollege :: Bool) where F1

    # Check if we need to make a change
    (by_college(switches, pName) == byCollege)  &&  (return nothing);
    if byCollege
        nColl = n_colleges(switches) - n_open_colleges(switches);
    else
        nColl = 1;
    end
    isCalibrated = is_calibrated(switches, pName);
    p = init_param(typeof(switches), pName, nColl, isCalibrated);
    ModelParams.replace!(get_pvector(switches), p);
end

n_open_colleges(switches :: AbstractAdmProbFctSwitches{F1}) where F1 = 
    switches.nOpenColleges;


"""
	$(SIGNATURES)

Get a parameter that may or may not vary by college for college `iCollege`.
For college 1, throw an error.
"""
function get_param(af :: AbstractAdmProbFct{F1}, pName, 
    iCollege :: Integer) where F1

    @assert (iCollege > n_open_colleges(af))  "No parameters for college $iCollege";
    if by_college(af, pName)
        # There are no parameters for the first college
        idx = college_index(af, iCollege);
    else
        idx = 1;
    end
    return getproperty(af, pName)[idx]
end

get_params(af :: AbstractAdmProbFct{F1}, iCollege :: Integer) where F1 = 
    [get_param(af, varName, iCollege)  for varName in param_names(af)];


include("admprob_fct_open.jl");
include("admprob_fct_logistic.jl");
include("admprob_fct_linear.jl");

# -------------