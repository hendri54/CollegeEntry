## -------------  Ranking students for sequential college admissions

"""
	$(SIGNATURES)

Abstract type for switches governing student ranking.
"""
abstract type AbstractRankingSwitches{F1 <: Real} end

"""
	$(SIGNATURES)

Abstract student ranking type.
"""
abstract type AbstractRanking{F1 <: Real} <: ModelObject end

# StructLH.describe(x :: AbstractRanking) = nothing;
StructLH.describe(switches :: AbstractRankingSwitches) = 
    ["Generic student ranking"];

Lazy.@forward AbstractRanking.switches (
    StructLH.describe, high_draws_first, calibrate_weights
)


"""
	$(SIGNATURES)

Initialize an `AbstractRanking` object from its switches.
"""
function make_student_ranking end


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

Score students. Higher scores are better.
Scores are simply weighted sums of endowment draws. 
Not scaled. Scores can be positive or negative.
"""
function score_students(e :: AbstractRanking{F1}, draws) where F1
    scoreV = zeros(F1, n_draws(draws));
    wtV = weights(e);
    nameV = endow_names(e);
    for (j, eName) in enumerate(nameV)
        scoreV .+= retrieve_draws(draws, eName) .* wtV[j];
    end
    # scaled  &&  scale_scores(e, scoreV);
    return scoreV
end


"""
	$(SIGNATURES)

Range of scores, given ranges for the scoring variables.
"""
function range_of_scores(e :: AbstractRanking{F1};
    lbV = lower_bounds(e), ubV = upper_bounds(e)) where F1
    wtV = weights(e);
    lb = sum(min.(wtV .* lbV, wtV .* ubV));
    ub = sum(max.(wtV .* lbV, wtV .* ubV));
    return lb, ub
end

"""
	$(SIGNATURES)

Scale scores to lie in [0, 1].
"""
function scale_scores(e :: AbstractRanking{F1}, scoreV;
    lbV = lower_bounds(e),
    ubV = upper_bounds(e)) where F1

    lb, ub = range_of_scores(e; lbV, ubV);
    scoreV = (scoreV .- lb) ./ (ub .- lb);
    return scoreV
end

"""
	$(SIGNATURES)

Lower bounds of scoring variables.
"""
function lower_bounds(e :: AbstractRanking{F1}) where F1 end

"""
	$(SIGNATURES)

Upper bounds of scoring variables.
"""
function upper_bounds(e :: AbstractRanking{F1}) where F1 end


"""
	$(SIGNATURES)

Return endowment names.
"""
endow_names(e :: AbstractRankingSwitches{F1}) where F1 = e.eNameV;

"""
	$(SIGNATURES)

Return endowment names.
"""
endow_names(e :: AbstractRanking{F1}) where F1 = endow_names(e.switches);

"""
	$(SIGNATURES)

Validate an `AbstractRanking`.
"""
function validate_ranking end

"""
	$(SIGNATURES)

Validate switches for an `AbstractRanking`.
"""
function validate_ranking_switches end


# -----------------