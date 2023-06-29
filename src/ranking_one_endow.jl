"""
	$(SIGNATURES)

Rank by a single, bounded endowment that lies in (lb, ub) (so that it can be scaled into [0,1]).
"""
mutable struct RankingOneEndow{F1} <: AbstractRanking{F1}
    objId :: ObjectId
    eName :: Symbol
    lb :: F1
    ub :: F1
    highDrawsFirst :: Bool
end

ModelParams.has_pvector(::RankingOneEndow) = false;

# ------  Access and show

endow_name(e :: RankingOneEndow) = e.eName;
endow_names(e :: RankingOneEndow) = [e.eName];
range_of_scores(e :: RankingOneEndow) = (e.lb, e.ub);

Base.show(io :: IO,  e :: RankingOneEndow{F1}) where F1 =
    print(io, "Ranking by endowment ", endow_name(e));

function StructLH.describe(e :: RankingOneEndow{F1}) where F1
    eNameStr = string(endow_name(e));
    return [
        "Ranking for sequential entry"  " ";
        "Ranking based on"  eNameStr
    ]
end

function score_students(e :: RankingOneEndow{F1}, draws) where F1
    scoreV = copy(retrieve_draws(draws, endow_name(e)));
    return scoreV
end

function scale_scores(e :: RankingOneEndow{F1}, scoreV) where F1
    scoreV = (scoreV .- e.lb) ./ (e.ub .- e.lb);
    return scoreV
end


# ------------  Constructors

function make_ranking_one_endow(objId :: ObjectId, eName :: Symbol, lb :: F1, ub :: F1;
        highDrawsFirst :: Bool = true) where F1
    e = RankingOneEndow(objId, eName, lb, ub, highDrawsFirst);
    @assert validate_ranking(e);
    return e
end

function validate_ranking(e :: RankingOneEndow)
    isValid = true;
    if !(e.lb < e.ub)
        isValid = false;
        @warn "Wrong ordering of bounds";
    end
    return isValid
end

function make_test_ranking_one_endow(highDrawsFirst :: Bool)
    e = make_ranking_one_endow(ObjectId(:rankOneEndow), :hsGpaPct, 0.0, 1.0; 
        highDrawsFirst)
    @assert validate_ranking(e);
    return e
end


# -----------------