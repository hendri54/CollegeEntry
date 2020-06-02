check_prob_array(m :: Array{F1}) where F1 <: AbstractFloat =
    check_float_array(m, zero(F1), one(F1));
