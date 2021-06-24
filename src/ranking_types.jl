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
    return sortperm(score_students(e, draws), rev = true);
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
    return scoreV
end


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