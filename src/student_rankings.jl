# Student rankings

## -----------  Generic

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

# Score students. Higher scores are better
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


## ------------------------  EndowPctRanking

# ------  Constructing

function make_test_endowpct_switches(n ::Integer)
    eNameV = [:abilPct, :parentalPct, :hsGpaPct, :h0Pct];
    wtV = [0.3, 2.0, 3.0];
    e = EndowPctRankingSwitches(eNameV[1 : n], wtV[1 : (n-1)], true);
    @assert validate_ranking_switches(e);
    return e
end

function make_student_ranking(objId :: ObjectId, 
    switches :: EndowPctRankingSwitches{F1}) where F1
    # switches = make_test_endowpct_switches(n);
    # objId = make_child_id(parentId, :studentRanking);
    pWtV = init_endow_pct_weights(switches);
    pvec = ParamVector(objId, [pWtV]);
    return EndowPctRanking(objId, pvec, ModelParams.value(pWtV), switches)
end

function init_endow_pct_weights(switches :: EndowPctRankingSwitches{F1}) where F1
    wtV = switches.wtV;
    n = length(wtV);
    p = Param(:wtV, "Ranking weights", "wtV", 
        wtV, wtV, zeros(F1, n), fill(F1(10.0), n), switches.doCal);
    return p
end

function validate_ranking_switches(e :: EndowPctRankingSwitches{F1}) where F1
    isValid = true
    isValid = isValid && (length(endow_names(e)) == 1 + length(e.wtV));
    isValid = isValid &&  all(e.wtV .>= 0.0)  &&  !any(isinf.(e.wtV))
    return isValid
end

function validate_ranking(e :: EndowPctRanking{F1}) where F1
    isValid = true;
    isValid = isValid && (size(endow_names(e)) == size(weights(e)))
    return isValid
end


# ------  Access and show

Base.show(io :: IO,  e :: EndowPctRankingSwitches{F1}) where F1 =
    print(io, typeof(e), " with endowments ", endow_names(e));

Base.show(io :: IO,  e :: EndowPctRanking{F1}) where F1 =
    print(io, typeof(e), " with endowments ", endow_names(e),
        " and weights ",  round.(weights(e), digits = 2));


weights(e :: EndowPctRanking{F1}) where F1 = [one(F1), e.wtV...];


# ---------------