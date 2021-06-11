# Admission probability functions

abstract type AbstractAdmProbFctSwitches{F1 <: Real} end
abstract type AbstractAdmProbFct{F1 <: Real} end

## -----------  Logistic

"""
	$(SIGNATURES)

Admission probability = pMin + (pMax - pMin) / (1 + Q exp(-B (x - M)))
"""
Base.@kwdef mutable struct AdmProbFctLogisticSwitches{F1} <: AbstractAdmProbFctSwitches{F1}
    nColleges :: Int
    nOpenColleges :: Int = 1
    # pMin
    pMinV :: Vector{F1} = [0.0]
    pMinByCollege :: Bool = false
    pMinCalibrated :: Bool = false
    # pMax
    pMaxV :: Vector{F1} = [1.0]
    pMaxByCollege :: Bool = false
    pMaxCalibrated :: Bool = false
    # Q
    qV :: Vector{F1} = [1.0]
    qByCollege :: Bool = false
    qCalibrated :: Bool = false
    # B
    bV :: Vector{F1} = [1.0]
    bByCollege :: Bool = false
    bCalibrated :: Bool = false
    # M - higher for better colleges
    mV :: Vector{F1} = [0.0]
    mByCollege :: Bool = false
    mCalibrated :: Bool = false
end

mutable struct AdmProbFctLogistic{F1} <: AbstractAdmProbFct{F1}
    objId :: ObjectId
    switches :: AdmProbFctLogisticSwitches{F1}
    pvec :: ParamVector
    pMinV
    pMaxV
    qV
    bV
    mV
end

## -------  Constructors

function make_test_admprob_fct_logistic_switches(nc)
    mV = LinRange(0.0, 0.5, nc);
    switches = AdmProbFctLogisticSwitches{Float64}(nColleges = nc, 
        mV = mV, mByCollege = true, mCalibrated = true);
    @assert validate_admprob_fct_switches(switches);
    return switches
end

function validate_admprob_fct_switches(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    isValid = true;
    return isValid;
end


"""
	$(SIGNATURES)

Make the object that holds the admission probability functions for a set of colleges.
"""
function init_admprob_fct(objId, switches :: AdmProbFctLogisticSwitches{F1}) where F1
    pv_pMin = init_pmin(switches);
    pv_pMax = init_pmax(switches);
    pv_q = init_q(switches);
    pv_b = init_b(switches);
    pv_m = init_m(switches);
    pvec = ParamVector(objId, [pv_pMin, pv_pMax, pv_q, pv_b, pv_m]);
    af = AdmProbFctLogistic(objId, switches, pvec, 
        ModelParams.value(pv_pMin), ModelParams.value(pv_pMax), 
        ModelParams.value(pv_q), ModelParams.value(pv_b), 
        ModelParams.value(pv_m));
    @assert validate_admprob_fct(af);
    return af
end

# notation from symbol table +++++
function init_pmin(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    sz = size(switches.pMinV);
    return Param(:pMinV, "Min prob", "pMinV", switches.pMinV, switches.pMinV,
        fill(0.0, sz), fill(0.4, sz), switches.pMinCalibrated);
end

function init_pmax(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    sz = size(switches.pMaxV);
    return Param(:pMaxV, "Max prob", "pMaxV", switches.pMaxV, switches.pMaxV,
        fill(0.5, sz), fill(1.0, sz), switches.pMaxCalibrated);
end

function init_q(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    pName = :qV;
    v = switches.qV;
    return Param(pName, "Logistic $pName", string(pName), v, v,
        0.1 .* v, 10.0 .* v, switches.qCalibrated);
end

function init_b(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    pName = :bV;
    v = switches.bV;
    return Param(pName, "Logistic $pName", string(pName), v, v,
        0.1 .* v, 10.0 .* v, switches.bCalibrated);
end

function init_m(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    pName = :mV;
    v = switches.mV;
    sz = size(v);
    Param(pName, "Logistic $pName", string(pName), v, v,
        fill(-0.8, sz), fill(0.8, sz), switches.mCalibrated);
end

function validate_admprob_fct(switches :: AdmProbFctLogistic{F1}) where F1
    isValid = true;
    return isValid;
end


## ----------  Access

Lazy.@forward AdmProbFctLogistic.switches (
    by_college
    );

function by_college(switches :: AdmProbFctLogisticSwitches{F1}, pName) where F1
    pSym = sym_from_name(pName);
    return getproperty(switches, Symbol(pSym * "ByCollege"))
end

# Maps a parameter name such as `:pMinV` into "pMin"
function sym_from_name(pName)
    pStr = string(pName);
    @assert last(pStr) == 'V'  "Should end in V: $pName";
    pStr2 = pStr[1 : (end-1)];
    return pStr2
end


## ---------  Admission prob for one college


"""
	$(SIGNATURES)

Make admission probability function for one college. Maps endowment percentile into [0, 1].
"""
function make_admprob_function(af :: AdmProbFctLogistic{F1}, iCollege :: Integer) where F1
    pMin = get_param(af, :pMinV, iCollege);
    pMax = get_param(af, :pMaxV, iCollege);
    q = get_param(af, :qV, iCollege);
    b = get_param(af, :bV, iCollege);
    m = get_param(af, :mV, iCollege);
    return x -> logistic(x, pMin, pMax, q, b, m)
end

logistic(x, pMin, pMax, q, b, m) = 
    pMin .+ (pMax .- pMin) / (1.0 .+ q .+ exp(-b .* (x .- m)));

# function get_pMin(af :: AdmProbFctLogistic{F1}, iCollege :: Integer) where F1
#     get_param(af, :pMin, iCollege)
# end

function get_param(af :: AdmProbFctLogistic{F1}, pName, 
    iCollege :: Integer) where F1
    if by_college(af, pName)
        idx = iCollege;
    else
        idx = 1;
    end
    return getproperty(af, pName)[idx]
end


# -------------