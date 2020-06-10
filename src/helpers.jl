check_prob_array(m :: AbstractArray{F1}) where F1 <: AbstractFloat =
    check_float_array(m, zero(F1), one(F1));

"""
    $(SIGNATURES)

Given an array of probabilities: ensure that all are in [0, 1]. 
Error if bounds violation larger than rounding errors.
Make sure that sum does not exceed an upper bound.
"""
function make_valid_probs!(m :: AbstractArray{F1}; maxSum :: F1 = one(F1)) where F1 <: AbstractFloat

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

# ---------------