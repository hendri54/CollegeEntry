check_prob_array(m :: AbstractArray{F1}) where F1 <: Real =
    check_float_array(m, zero(F1), one(F1));

function validate_percentiles(pctM)
    isValid = true;
    pMin, pMax = extrema(pctM);
    if (pMin < 0.0)  ||  (pMax > 1.0)
        isValid = false;
        @warn "Invalid percentiles in range $pMin to $pMax";
    end
    return isValid
end


"""
    $(SIGNATURES)

Given an array of probabilities: ensure that all are in [0, 1]. 
Error if bounds violation larger than rounding errors.
Make sure that sum does not exceed an upper bound.
"""
function make_valid_probs!(m :: AbstractArray{F1}; maxSum :: F1 = one(F1)) where F1 <: Real

    fSmall = F1(.0000001);
    pSum = sum(m);
    @assert (pSum < one(F1) + fSmall)  "Sum too large: $pSum"
    @assert all_at_least(m, -fSmall)  "Negative probabilities"
    @assert all_at_most(m, one(F1) + fSmall)  "Probabilities above 1"

    if any(x -> x < zero(F1), m)
        m[findall(x -> x < zero(F1), m)] .= zero(F1);
    end
    if pSum > maxSum
        m .*= ((maxSum - fSmall) / pSum);
    end
end


# Make a `Vector` into an `n x 1` Matrix.
# Don't use `reshape` b/c that produces a reshaped array instead.
matrix_from_vector(v :: AbstractVector{F1}) where F1 =
    repeat(v, outer = (1,1));


## ----------  Choice without pref shocks

# Given value work, value of colleges, vector of admitted colleges, return max value and college index (not among admitted ones)
function max_choice(vWork :: F1, vCollegeV :: AbstractVector{F1},
    admitV :: AbstractVector{Bool}) where {F1 <: Real}

    v, idx = findmax(vcat(vWork, vCollegeV .- (.!admitV) .* F1(1e8)));
    ic = idx - 1;
    return v, ic
end

# The same with an index vector as `admitV`
function max_choice(vWork :: F1, vCollegeV :: AbstractVector{F1},
    admitIdxV :: AbstractVector{I1}) where {F1 <: Real, I1 <: Integer}

    admitV = falses(size(vCollegeV));
    admitV[admitIdxV] .= true;
    return max_choice(vWork, vCollegeV, admitV)
end

# The same for many agents
function max_choices(vWork_jV :: AbstractVector{F1}, 
    vCollege_jcM :: AbstractMatrix{F1},
    admitV :: AbstractVector{I1}) where {F1 <: Real, I1}

    J = length(vWork_jV);
    valV = zeros(F1, J);
    icV = zeros(Int, J);
    for j = 1 : J
        valV[j], icV[j] = max_choice(vWork_jV[j], vec(vCollege_jcM[j,:]), 
            admitV);
    end
    return valV, icV
end


function find_class(x :: F1, cutoffV) where F1 <: Real
    if x > last(cutoffV)
        j = length(cutoffV) + 1;
    elseif x < first(cutoffV)
        j = 1;
    else
        j = findfirst(cutoff -> x < cutoff, cutoffV);
    end
    return j
end


# ---------------