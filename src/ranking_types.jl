## -------------  Ranking students for sequential college admissions

# """
# 	$(SIGNATURES)

# Abstract type for switches governing student ranking.
# """
# abstract type AbstractRankingSwitches{F1 <: Real} end

"""
	$(SIGNATURES)

Abstract student ranking type.
"""
abstract type AbstractRanking{F1 <: Real} <: ModelObject end

ModelParams.has_pvector(::AbstractRanking) = true;
ModelParams.param_loc(::AbstractRanking) = ParamsInObject();

StructLH.describe(switches :: AbstractRanking) = 
    ["Generic student ranking"];

# Lazy.@forward AbstractRanking.switches (
#     StructLH.describe, high_draws_first, calibrate_weights
# )


# """
# 	$(SIGNATURES)

# Initialize an `AbstractRanking` object from its switches.
# """
# function make_student_ranking end


"""
	$(SIGNATURES)

Retrieve draws for endowment `eName`. Needs to be defined for objects passed into ranking functions.
"""
retrieve_draws(draws, eName) =
    error("Caller must define `retrieve_draws` for input $(typeof(draws))");

"""
	$(SIGNATURES)

Number of individuals in endowment draws. Needs to be defined for objects passed into ranking functions.
"""
n_draws(draws) = 
    error("Caller must define `n_draws` for input $(typeof(draws))");


high_draws_first(e :: AbstractRanking) = e.highDrawsFirst;


"""
	$(SIGNATURES)

Rank students. Returns indices of students in rank order from best to worst.

# Arguments
- `draws`: must support `retrieve_draws`.
"""
function rank_students(e :: AbstractRanking{F1}, draws) where F1
    return sortperm(score_students(e, draws), rev = high_draws_first(e));
end


"""
	$(SIGNATURES)

Score students. Does not consider `highDrawsFirst`. Only ranking considers that.
Scores are simply weighted sums of endowment draws. 
Not scaled. Scores can be positive or negative.
"""
function score_students(e :: AbstractRanking{F1}, draws) where F1
    error("Must be defined for each ranking.");
    # scoreV = zeros(F1, n_draws(draws));
    # wtV = weights(e);
    # nameV = endow_names(e);
    # for (j, eName) in enumerate(nameV)
    #     scoreV .+= retrieve_draws(draws, eName) .* wtV[j];
    # end
    # # scaled  &&  scale_scores(e, scoreV);
    # return scoreV
end


"""
	$(SIGNATURES)

Range of scores, given ranges for the scoring variables.
"""
function range_of_scores(e :: AbstractRanking{F1}) where F1
    error("Must define this");
end
#     lbV = lower_bounds(e), ubV = upper_bounds(e)) where F1
#     error("Must be defined for each ranking.");
#     # wtV = weights(e);
#     # lb = sum(min.(wtV .* lbV, wtV .* ubV));
#     # ub = sum(max.(wtV .* lbV, wtV .* ubV));
#     # return lb, ub
# end


"""
	$(SIGNATURES)

Scale scores to lie in [0, 1].
"""
function scale_scores(e :: AbstractRanking{F1}, scoreV) where F1
    lb, ub = range_of_scores(e);
    scaledV = (scoreV .- lb) ./ (ub .- lb);
    return scaledV
end

# """
# 	$(SIGNATURES)

# Lower bounds of scoring variables.
# """
# function lower_bounds(e :: AbstractRanking{F1}) where F1 end

# """
# 	$(SIGNATURES)

# Upper bounds of scoring variables.
# """
# function upper_bounds(e :: AbstractRanking{F1}) where F1 end


"""
	$(SIGNATURES)

Return endowment names.
"""
endow_names(e :: AbstractRanking{F1}) where F1 = e.eNameV;


"""
	$(SIGNATURES)

Validate an `AbstractRanking`.
"""
function validate_ranking end

# """
# 	$(SIGNATURES)

# Validate switches for an `AbstractRanking`.
# """
# function validate_ranking_switches end


# -----------------