## -----------  linear

"""
	$(SIGNATURES)

Admission probability = linear around point (score = 0.5, prob = prob50).

Parameters may vary by college (as indicated by switches). But some colleges are open admission. They have no parameters.

All students get into the lowest college. Parameters only need to be set for colleges 2+.

Change: A lot of code is repeated from the logistic case. +++
    The more general approach is a function with named params (e.g. prob50V, slopeV).
"""
mutable struct AdmProbFctLinearSwitches{F1} <: AbstractAdmProbFctSwitches{F1}
    pvec :: ParamVector
    nColleges :: Int
    nOpenColleges :: Int
end

mutable struct AdmProbFctLinear{F1} <: AbstractAdmProbFct{F1}
    objId :: ObjectId
    switches :: AdmProbFctLinearSwitches{F1}
    prob50V :: Vector{F1}
    slopeV :: Vector{F1}
end

# The order matters here!
param_names(af :: AdmProbFctLinearSwitches{F1}) where F1 = 
    param_names(typeof(af));
param_names(::Type{AdmProbFctLinearSwitches{F1}}) where F1 = [:prob50V, :slopeV];

linear_adm_prob(x, p50, slope) = max.(0.0001, min.(0.999, p50 .+ (x .- 0.5) .* slope));


## -------  Constructors

# nc: total no of colleges
function make_test_admprob_fct_linear_switches(nc)
    init_admprob_fct_linear_switches(ObjectId(:test), nc);
end

function make_test_admprob_fct_linear(nc)
    switches = make_test_admprob_fct_linear_switches(nc);
    af = init_admprob_fct(switches);
    @assert validate_admprob_fct(af);
    return af
end


"""
	$(SIGNATURES)

Set up switches for linear admission probability functions.
"""
function init_admprob_fct_linear_switches(
    objId :: ObjectId,  nc :: Integer;
    byCollegeV :: Vector{Symbol} = [:prob50V, :slopeV],
    calibratedV :: Vector{Symbol} = [:prob50V, :slopeV]
    )

    nOpen = 1;
    make_admprob_fct_switches(objId, AdmProbFctLinearSwitches{Float64}, 
        nc, nOpen, byCollegeV, calibratedV);
end


# notation from symbol table +++++
# Min admission prob for each college.
# Input is no of colleges that need parameters.
function init_prob50(nc :: Integer, isCalibrated :: Bool)
    sz = (nc, );
    return Param(:prob50V, "Adm prob at score = 0.5", "prob50V", 
        fill(0.5, sz), fill(0.5, sz),
        fill(0.05, sz), fill(0.85, sz), isCalibrated);
end

function init_slope(nc :: Integer, isCalibrated :: Bool)
    sz = (nc, );
    return Param(:slopeV, "Adm prob function slope", "slopeV", 
        fill(0.35, sz), fill(0.35, sz),
        fill(0.0, sz), fill(4.0, sz), isCalibrated);
end


function init_param(::Type{AdmProbFctLinearSwitches{F1}}, pName, nc, isCalibrated) where F1
    if pName == :prob50V
        return init_prob50(nc, isCalibrated);
    elseif pName == :slopeV
        return init_slope(nc, isCalibrated);
    else
        error("Invalid: $pName");
    end
end


# stub ++++++
function validate_admprob_fct_switches(switches :: AdmProbFctLinearSwitches{F1}) where F1
    isValid = true;
    return isValid;
end


"""
	$(SIGNATURES)

Make the object that holds the admission probability functions for a set of colleges.
"""
function init_admprob_fct(switches :: AdmProbFctLinearSwitches{F1}) where F1
    pV = [param_default_value(switches, pName)  for pName in param_names(switches)];
    af = AdmProbFctLinear(get_object_id(switches), switches, pV...);
        # param_default_value(switches, :prob50V), 
        # param_default_value(switches, :slopeV)); 
    @assert validate_admprob_fct(af);
    return af
end


function validate_admprob_fct(switches :: AdmProbFctLinear{F1}) where F1
    isValid = true;
    return isValid;
end


## ---------  Admission prob for one college


"""
	$(SIGNATURES)

Make admission probability function for one college. Maps endowment percentile into [0, 1].
"""
function make_admprob_function(af :: AdmProbFctLinear{F1}, 
    iCollege :: Integer) where F1

    if iCollege <= n_open_colleges(af)
        fct = x -> 1.0;
    else
        paramV = get_params(af, iCollege);
        fct = x -> linear_adm_prob(x, paramV...);
    end
    return fct
end

"""
	$(SIGNATURES)

Probability of being admitted into a specific college (just based on its admissions prob function).
"""
function prob_admit(af :: AdmProbFctLinear{F1}, iCollege :: Integer, hsGpa) where F1
    if iCollege <= n_open_colleges(af)
        probV = prob_admit_open(hsGpa);
    else
        probV = linear_adm_prob(hsGpa, get_params(af, iCollege)...);
    end
    return probV
end


# --------------------