"""
	$(SIGNATURES)

The ranking function of multiple endowments. The resulting score lies in (lb, ub). The score is simply `rankFct(draws)`.
The `rankFct` may be a `ModelObject` with calibrated parameters.
"""
mutable struct RankingByFunction{F1, F2} <: AbstractRanking{F1}
    objId :: ObjectId
    eNameV :: Vector{Symbol}
    lb :: F1
    ub :: F1
    rankFct :: F2
    highDrawsFirst :: Bool
end

ModelParams.has_pvector(::RankingByFunction) = false;

# ------  Access and show

endow_names(e :: RankingByFunction) = e.eNameV;
range_of_scores(e :: RankingByFunction) = (e.lb, e.ub);

Base.show(io :: IO,  e :: RankingByFunction) =
    print(io, "Ranking by function of endowments ", endow_names(e));

function StructLH.describe(e :: RankingByFunction)
    return [
        "Ranking for sequential entry"  "by function";
        "Ranking based on"  "$(endow_names(e))"
    ]
end

function score_students(e :: RankingByFunction{F1}, draws) where F1
    scoreV = e.rankFct(draws);
    @assert check_float_array(scoreV, e.lb, e.ub; msg = "Scores out of bounds.");
    return scoreV
end

# function scale_scores(e :: RankingByFunction{F1}, scoreV) where F1
#     scaledV = (scoreV .- e.lb) ./ (e.ub .- e.lb);
#     return scaledV
# end


# ------------  Constructors

function make_ranking_by_fct(objId :: ObjectId, eNames :: Vector{Symbol}, 
        rankFct, lb :: F1, ub :: F1;   highDrawsFirst :: Bool = true) where F1
    e = RankingByFunction(objId, eNames, lb, ub, rankFct, highDrawsFirst);
    @assert validate_ranking(e);
    return e
end

function validate_ranking(e :: RankingByFunction)
    isValid = true;
    if !(e.lb < e.ub)
        isValid = false;
        @warn "Wrong ordering of bounds";
    end
    return isValid
end

function make_test_ranking_by_fct(highDrawsFirst :: Bool)
    e = make_ranking_by_fct(ObjectId(:rankByFct), test_endow_names(), 
        test_rank_fct, 0.0, 1.0;   highDrawsFirst)
    @assert validate_ranking(e);
    return e
end

function test_rank_fct(draws)
    return (retrieve_draws(draws, first(test_endow_names())) .+ 
        retrieve_draws(draws, last(test_endow_names()))) .* 0.5;
end

test_endow_names() = [:hsGpa, :abilPct];


# -----------------