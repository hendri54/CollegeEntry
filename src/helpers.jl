check_prob_array(m :: AbstractArray{F1}) where F1 <: AbstractFloat =
    check_float_array(m, zero(F1), one(F1));

# Make a `Vector` into an `n x 1` Matrix.
# Don't use `reshape` b/c that produces a reshaped array instead.
matrix_from_vector(v :: AbstractVector{F1}) where F1 =
    repeat(v, outer = (1,1));

# ---------------