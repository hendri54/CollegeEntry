## -----------  Logistic

"""
	$(SIGNATURES)

Admission probability = pMin + (pMax - pMin) / (1 + Q exp(-B (x - M))).

`M` is essentially a left-right shifter.
`B` is a slope parameter. Needs to be high b/c logistic maps [-Inf, Inf] -> [0, 1].
`Q` is mostly redundant and can be fixed.

Parameters may vary by college (as indicated by switches). But some colleges are open admission. They have no parameters.

All students get into the lowest college. Parameters only need to be set for colleges 2+.
"""
mutable struct AdmProbFctLogisticSwitches{F1} <: AbstractAdmProbFctSwitches{F1}
    pvec :: ParamVector
    nColleges :: Int
    nOpenColleges :: Int
end

mutable struct AdmProbFctLogistic{F1} <: AbstractAdmProbFct{F1}
    objId :: ObjectId
    switches :: AdmProbFctLogisticSwitches{F1}
    pMinV :: Vector{F1}
    pMaxV :: Vector{F1}
    qV :: Vector{F1}
    bV :: Vector{F1}
    mV :: Vector{F1}
end

# The order matters here!
param_names(af :: AdmProbFctLogisticSwitches{F1}) where F1 = 
    param_names(typeof(af));
param_names(::Type{AdmProbFctLogisticSwitches{F1}}) where F1 = 
    [:pMinV, :pMaxV, :qV, :bV, :mV];

logistic(x, pMin, pMax, q, b, m) = 
    pMin .+ (pMax .- pMin) ./ (1.0 .+ q .* exp.(-b .* (x .- m)));

# Lazy.@forward AdmProbFctLogistic.switches (
#     by_college, by_college!, college_index, get_param, get_params, param_names
#     );
    
    
## -------  Constructors

# nc: total no of colleges
function make_test_admprob_fct_logistic_switches(nc)
    init_admprob_fct_logistic_switches(ObjectId(:test), nc);
end

function make_test_admprob_fct_logistic(nc)
    switches = make_test_admprob_fct_logistic_switches(nc);
    af = init_admprob_fct(switches);
    @assert validate_admprob_fct(af);
    return af
end


"""
	$(SIGNATURES)

Set up switches for logistic admission probability functions.
"""
function init_admprob_fct_logistic_switches(
    objId :: ObjectId,  nc :: Integer;
    byCollegeV :: Vector{Symbol} = [:bV, :mV],
    calibratedV :: Vector{Symbol} = [:bV, :mV]
    )
    nOpen = 1;
    make_admprob_fct_switches(objId, AdmProbFctLogisticSwitches{Float64}, 
        nc, nOpen, byCollegeV, calibratedV);
end



# notation from symbol table +++++
# Min admission prob for each college.
# Input is no of colleges that need parameters.
function init_pmin(nc :: Integer, isCalibrated :: Bool)
    sz = (nc, );
    return Param(:pMinV, "Min prob", "pMinV", 
        fill(0.05, sz), fill(0.01, sz),
        fill(0.005, sz), fill(0.45, sz), isCalibrated);
end

function init_pmax(nc :: Integer, isCalibrated :: Bool)
    sz = (nc, );
    return Param(:pMaxV, "Max prob", "pMaxV", 
        fill(0.95, sz), fill(0.99, sz),
        fill(0.5, sz), fill(0.995, sz), isCalibrated);
end

# Q is equivalent to M. So can be set to 1.
function init_q(nc :: Integer, isCalibrated :: Bool)
    sz = (nc, );
    pName = :qV;
    v = fill(1.0, sz);
    return Param(pName, "Logistic $pName", string(pName), v, v,
        0.1 .* v, 10.0 .* v, isCalibrated);
end

# Slope
# Logistic maps [-Inf, Inf] -> [0, 1]. So B must be large.
function init_b(nc :: Integer, isCalibrated :: Bool)
    sz = (nc, );
    pName = :bV;
    v = fill(5.0, sz);
    return Param(pName, "Logistic $pName", string(pName), v, v,
        fill(0.1, sz), fill(20.0, sz), isCalibrated);
end

# The input is a percentile. So M should also be on the order of [0, 1].
# This can vary across colleges (shifts curve left/right).
function init_m(nc :: Integer, isCalibrated :: Bool)
    sz = (nc, );
    pName = :mV;
    if nc > 1
        v = collect(LinRange(-0.4, 0.4, nc));
    else
        v = fill(0.4, sz);
    end
    sz = size(v);
    Param(pName, "Logistic $pName", string(pName), v, v,
        fill(-0.8, sz), fill(0.8, sz), isCalibrated);
end

function init_param(::Type{AdmProbFctLogisticSwitches{F1}}, pName, nc, isCalibrated) where F1
    if pName == :pMinV
        return init_pmin(nc, isCalibrated);
    elseif pName == :pMaxV
        return init_pmax(nc, isCalibrated);
    elseif pName == :mV
        return init_m(nc, isCalibrated);
    elseif pName == :bV
        return init_b(nc, isCalibrated);
    elseif pName == :qV
        return init_q(nc, isCalibrated);
    else
        error("Invalid: $pName");
    end
end


"""
	$(SIGNATURES)

Make the object that holds the admission probability functions for a set of colleges.
"""
function init_admprob_fct(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    pV = [param_default_value(switches, pName)  for pName in param_names(switches)];
    af = AdmProbFctLogistic(get_object_id(switches), switches, pV...);
        # param_default_value(switches, :pMinV), param_default_value(switches, :pMaxV), 
        # param_default_value(switches, :qV), param_default_value(switches, :bV), 
        # param_default_value(switches, :mV)); 
    @assert validate_admprob_fct(af);
    return af
end


# stub ++++++
function validate_admprob_fct_switches(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    isValid = true;
    return isValid;
end


function validate_admprob_fct(switches :: AdmProbFctLogistic{F1}) where F1
    isValid = true;
    return isValid;
end


## ----------  Access



# Maps a parameter name such as `:pMinV` into "pMin"
# function sym_from_name(pName)
#     pStr = string(pName);
#     @assert last(pStr) == 'V'  "Should end in V: $pName";
#     pStr2 = pStr[1 : (end-1)];
#     return pStr2
# end


## ---------  Admission prob for one college


"""
	$(SIGNATURES)

Make admission probability function for one college. Maps endowment percentile into [0, 1].
"""
function make_admprob_function(af :: AdmProbFctLogistic{F1}, 
    iCollege :: Integer) where F1

    if iCollege <= n_open_colleges(af)
        fct = x -> 1.0;
    else
        paramV = get_params(af, iCollege);
        fct = x -> logistic(x, paramV...);
    end
    return fct
end

"""
	$(SIGNATURES)

Probability of being admitted into a specific college (just based on its admissions prob function).
"""
function prob_admit(af :: AdmProbFctLogistic{F1}, iCollege :: Integer, hsGpa) where F1
    if iCollege <= n_open_colleges(af)
        probV = prob_admit_open(hsGpa);
    else
        probV = logistic(hsGpa, get_params(af, iCollege)...);
    end
    return probV
end


# --------------------