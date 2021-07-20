"""
	$(SIGNATURES)

Step function for admission probabilities.

There are `n` endowment groups (e.g. GPA quartiles) defined by upper bounds for a score.
There are `nc` colleges.
For each college / endowment pair, some entry probs are fixed (e.g. close to 0 or 1); others are calibrated.
"""
mutable struct AdmProbFctStepSwitches{F1} <: AbstractAdmProbFctSwitches{F1}
    pvec :: ParamVector
    nColleges :: Int
    nOpenColleges :: Int
    # nGroups :: Int
    cutoffV :: Vector{F1}
    # caSwitches :: CalibratedArraySwitches{F1, 2}
end

mutable struct AdmProbFctStep{F1} <: AbstractAdmProbFct{F1}
    objId :: ObjectId
    switches :: AdmProbFctStepSwitches{F1}
    # calArray :: CalibratedArray{F1, 2}
    probMatrix :: Matrix{F1}
end

Lazy.@forward  AdmProbFctStepSwitches.pvec (
    ModelParams.get_object_id
    );
Lazy.@forward AdmProbFctStep.switches (
    ModelParams.get_pvector, ModelParams.has_pvector
    );

# ModelParams.get_object_id(switches :: AdmProbFctStepSwitches{F1}) where F1 = 
#     get_object_id(switches.pvec);
ModelParams.has_pvector(switches :: AdmProbFctStepSwitches{F1}) where F1 = true;

param_names(switches :: AdmProbFctStepSwitches{F1}) where F1 = nothing;

# Cutoffs: group upper bounds (there is another group with cutoff Inf)
function step_adm_prob(x :: F1, cutoffV, probV) where F1 <: Real
    return probV[find_class(x, cutoffV)]
end

step_adm_prob(xV, cutoffV, probV) = [step_adm_prob(x, cutoffV, probV)  for x in xV];



## ----------  Constructors

# defaultProbM by [group, college]
function init_admprob_fct_step_switches(
    objId :: ObjectId, cutoffV :: AbstractVector{F1},
    defaultProbM :: Matrix{F1},  isCalM :: Matrix{Bool}
    ) where F1

    @assert length(cutoffV) == (size(defaultProbM, 1) - 1);
    @assert all_at_least(defaultProbM, zero(F1));
    @assert all_at_most(defaultProbM, one(F1));

    lbM = fill(0.01, size(defaultProbM));
    ubM = fill(0.99, size(defaultProbM));
    pCA = CalArray(:probMatrix, "Admission probabilities", "admProb",
        copy(defaultProbM), defaultProbM, lbM, ubM, isCalM);
    pvec = ParamVector(objId, [pCA]);
    # caSwitches = CalibratedArraySwitches(
    #     make_child_id(objId, :probMatrix),
    #     defaultProbM, lbM, ubM, isCalM);

    nc = size(defaultProbM, 2);
    nOpen = 1;
    return AdmProbFctStepSwitches(pvec, nc, nOpen, cutoffV)
    # return AdmProbFctStepSwitches(objId, nc, nOpen, cutoffV, caSwitches)
end

function make_test_admprob_fct_step_switches(nc)
    rng = MersenneTwister(43);
    ng = nc + 1;
    cutoffV = collect(LinRange(0.2, 0.9, ng-1));
    isCalM = Matrix{Bool}(rand(rng, ng, nc) .> 0.5);
    defaultProbM = LinRange(0.1, 0.8, ng) .+ LinRange(0.0, 0.1, nc)';
    # Open college
    isCalM[:, 1] .= false;
    defaultProbM[:, 1] .= 0.99;
    switches = 
        init_admprob_fct_step_switches(ObjectId(:test), cutoffV, defaultProbM, isCalM);
    @assert validate_admprob_fct_switches(switches);
    return switches
end

function init_admprob_fct(switches :: AdmProbFctStepSwitches{F1}) where F1
    # calArray = CalibratedArray(switches.caSwitches);
    probM = copy(param_value(switches, :probMatrix));
    af = AdmProbFctStep(get_object_id(switches), switches, probM);
    @assert validate_admprob_fct(af);
    return af
end

function make_test_admprob_fct_step(nc)
    switches = make_test_admprob_fct_step_switches(nc);
    return init_admprob_fct(switches)
end

function validate_admprob_fct_switches(switches :: AdmProbFctStepSwitches{F1}) where F1
    isValid = true;
    return isValid;
end

function validate_admprob_fct(af :: AdmProbFctStep{F1}) where F1
    isValid = true;
    return isValid;
end


## ------------  Adm prob for one college

function make_admprob_function(af :: AdmProbFctStep{F1}, 
    iCollege :: Integer) where F1

    if iCollege <= n_open_colleges(af)
        fct = x -> 1.0;
    else
        # prob_gcM = ModelParams.values(af.calArray);
        prob_gcM = af.probMatrix;
        fct = x -> step_adm_prob(x, af.switches.cutoffV, prob_gcM[:, iCollege]);
    end
    return fct
end


function prob_admit(af :: AdmProbFctStep{F1}, iCollege :: Integer, hsGpa) where F1
    if iCollege <= n_open_colleges(af)
        probV = prob_admit_open(hsGpa);
    else
        prob_gcM = af.probMatrix; #  ModelParams.values(af.calArray);
        probV = step_adm_prob(hsGpa, af.switches.cutoffV, prob_gcM[:, iCollege]);
    end
    return probV
end


# ----------------
