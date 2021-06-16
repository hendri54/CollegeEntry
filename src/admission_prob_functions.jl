# Admission probability functions

abstract type AbstractAdmProbFctSwitches{F1 <: Real} <: ModelSwitches end
abstract type AbstractAdmProbFct{F1 <: Real} <: ModelObject end

"""
	$(SIGNATURES)

Initialize admission probability functions for all colleges (as a set).
Still need to make the function for each college.
"""
function init_admprob_fct(switches :: AbstractAdmProbFctSwitches{F1}) where F1 end

Lazy.@forward AbstractAdmProbFct.switches (
    ModelParams.has_pvector
    );

## -----------  Open admission

struct AdmProbFctOpenSwitches{F1} <: AbstractAdmProbFctSwitches{F1} end

"""
	$(SIGNATURES)

This is really a dummy for cases where an admission probability function is not needed.
"""
struct AdmProbFctOpen{F1} <: AbstractAdmProbFct{F1} 
    objId :: ObjectId
    switches :: AdmProbFctOpenSwitches{F1}
end

ModelParams.has_pvector(switches :: AdmProbFctOpenSwitches{F1}) where F1 = false;
# ModelParams.has_pvector(switches :: AdmProbFctOpen{F1}) where F1 = false;

init_admprob_fct(switches :: AdmProbFctOpenSwitches{F1}) where F1 = 
    AdmProbFctOpen{F1}(ObjectId(:admProbFctOpen), switches);



## -----------  Logistic

"""
	$(SIGNATURES)

Admission probability = pMin + (pMax - pMin) / (1 + Q exp(-B (x - M))).

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

## -------  Constructors

# nc: total no of colleges
function make_test_admprob_fct_logistic_switches(nc)
    init_admprob_fct_logistic_switches(ObjectId(:test), nc);
end

"""
	$(SIGNATURES)

Set up switches for logistic admission probability functions.
"""
function init_admprob_fct_logistic_switches(
    objId :: ObjectId,  nc :: Integer;
    byCollegeV :: Vector{Symbol} = [:mV]
    )
    nOpen = 1;
    pvecV = Vector{Param}();
    for pName in [:pMinV, :pMaxV, :qV, :bV, :mV]
        init_f = init_function(AdmProbFctLogisticSwitches, pName);
        nColl = pvec_length(nc, nOpen, byCollegeV, pName);
        push!(pvecV, init_f(nColl));
    end
    pvec = ParamVector(objId, pvecV);
    switches = AdmProbFctLogisticSwitches{Float64}(pvec, nc, nOpen);
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

# notation from symbol table +++++
# Input is no of colleges that need parameters.
function init_pmin(nc :: Integer)
    sz = (nc, );
    return Param(:pMinV, "Min prob", "pMinV", 
        fill(0.0, sz), fill(0.0, sz),
        fill(0.0, sz), fill(0.4, sz), false);
end

function init_pmax(nc :: Integer)
    sz = (nc, );
    return Param(:pMaxV, "Max prob", "pMaxV", 
        fill(1.0, sz), fill(1.0, sz),
        fill(0.5, sz), fill(1.0, sz), false);
end

function init_q(nc :: Integer)
    sz = (nc, );
    pName = :qV;
    v = fill(1.0, sz);
    return Param(pName, "Logistic $pName", string(pName), v, v,
        0.1 .* v, 10.0 .* v, false);
end

function init_b(nc :: Integer)
    sz = (nc, );
    pName = :bV;
    v = fill(1.0, sz);
    return Param(pName, "Logistic $pName", string(pName), v, v,
        0.1 .* v, 10.0 .* v, false);
end

function init_m(nc :: Integer)
    sz = (nc, );
    pName = :mV;
    v = fill(0.4, sz);
    sz = size(v);
    Param(pName, "Logistic $pName", string(pName), v, v,
        fill(-0.8, sz), fill(0.8, sz), true);
end

function init_function(::Type{AdmProbFctLogisticSwitches}, pName) where F1
    if pName == :pMinV
        return init_pmin;
    elseif pName == :pMaxV
        return init_pmax;
    elseif pName == :mV
        return init_m;
    elseif pName == :bV
        return init_b;
    elseif pName == :qV
        return init_q;
    else
        error("Invalid: $pName");
    end
end


# stub ++++++
function validate_admprob_fct_switches(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    isValid = true;
    return isValid;
end

# Initializes the `AdmProbFctLogistic` object. 
# The function for each college still needs to be made with `make_admprob_function`.
function make_test_admprob_fct_logistic(nc)
    switches = make_test_admprob_fct_logistic_switches(nc);
    af = init_admprob_fct(switches);
    @assert validate_admprob_fct(af);
    return af
end


"""
	$(SIGNATURES)

Make the object that holds the admission probability functions for a set of colleges.
"""
function init_admprob_fct(switches :: AdmProbFctLogisticSwitches{F1}) where F1
    af = AdmProbFctLogistic(get_object_id(switches), switches, 
        param_default_value(switches, :pMinV), param_default_value(switches, :pMaxV), 
        param_default_value(switches, :qV), param_default_value(switches, :bV), 
        param_default_value(switches, :mV)); 
    @assert validate_admprob_fct(af);
    return af
end


function validate_admprob_fct(switches :: AdmProbFctLogistic{F1}) where F1
    isValid = true;
    return isValid;
end


## ----------  Access

Lazy.@forward AdmProbFctLogistic.switches (
    by_college, n_colleges, n_open_colleges, college_index
    );

ModelParams.get_object_id(switches :: AdmProbFctLogisticSwitches{F1}) where F1 = 
    get_object_id(switches.pvec);

n_colleges(switches :: AdmProbFctLogisticSwitches{F1}) where F1 = 
    switches.nColleges;

"""
	$(SIGNATURES)

Does the parameter `pName` vary by college?
"""
function by_college(switches :: AdmProbFctLogisticSwitches{F1}, pName) where F1
    v = param_value(switches, pName);
    @assert !isnothing(v)  "Not found: $pName";
    return length(v) > 1
end


"""
	$(SIGNATURES)

Switch a parameter to vary by college.
"""
function by_college!(switches :: AdmProbFctLogisticSwitches{F1}, pName) where F1
    by_college(switches, pName)  &&  (return nothing);
    nColl = n_colleges(switches) - n_open_colleges(switches);
    p = init_function(AdmProbFctLogisticSwitches, pName)(nColl);
    ModelParams.replace!(get_pvector(switches), p);
end

"""
	$(SIGNATURES)

Switch a parameter NOT to vary by college.
"""
function not_by_college!(switches :: AdmProbFctLogisticSwitches{F1}, pName) where F1
    by_college(switches, pName)  ||  (return nothing);
    p = init_function(AdmProbFctLogisticSwitches, pName)(1);
    ModelParams.replace!(get_pvector(switches), p);
end

n_open_colleges(switches :: AdmProbFctLogisticSwitches{F1}) where F1 = 
    switches.nOpenColleges;

# Index into parameters that vary by college.
function college_index(switches :: AdmProbFctLogisticSwitches{F1}, iCollege) where F1
    return iCollege .- n_open_colleges(switches);
end


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
        pMin = get_param(af, :pMinV, iCollege);
        pMax = get_param(af, :pMaxV, iCollege);
        q = get_param(af, :qV, iCollege);
        b = get_param(af, :bV, iCollege);
        m = get_param(af, :mV, iCollege);
        fct = x -> logistic(x, pMin, pMax, q, b, m);
    end
    return fct
end

logistic(x, pMin, pMax, q, b, m) = 
    pMin .+ (pMax .- pMin) / (1.0 .+ q .+ exp(-b .* (x .- m)));

# function get_pMin(af :: AdmProbFctLogistic{F1}, iCollege :: Integer) where F1
#     get_param(af, :pMin, iCollege)
# end

"""
	$(SIGNATURES)

Get a parameter that may or may not vary by college for college `iCollege`.
For college 1, throw an error.
"""
function get_param(af :: AdmProbFctLogistic{F1}, pName, 
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



# -------------