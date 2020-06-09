## -------------  Ranking students for sequential college admissions

"""
	$(SIGNATURES)

Abstract type for switches governing student ranking.
"""
abstract type AbstractRankingSwitches{F1 <: AbstractFloat} end

"""
	$(SIGNATURES)

Abstract student ranking type.
"""
abstract type AbstractRanking{F1 <: AbstractFloat} <: ModelObject end

## Rank is a weighted average of endowment percentiles

"""
	$(SIGNATURES)

Switches for linear endowment percentile weights. 
`eNameV` contains the endowments used for ranking. It must be possible to call `retrieve_draws(EndowmentDraws, eName)`.
`wtV` are the weights to be used if not calibrated. This omits the first weight, which is fixed at 1. This is empty when there is only one endowment to rank on.
`doCal` determines whether weights are calibrated or fixed.
"""
mutable struct EndowPctRankingSwitches{F1} <: AbstractRankingSwitches{F1}
    # Endowments to rank on
    eNameV :: Vector{Symbol}
    # Weights on those endowments, if fixed. First is omitted as fixed.
    wtV :: Vector{F1}
    # Calibrate weights? The first is always fixed (normalization).
    doCal :: Bool
end

"""
	$(SIGNATURES)

Rank students by a linear combination of endowment percentiles.
"""
mutable struct EndowPctRanking{F1} <: AbstractRanking{F1}
    objId :: ObjectId
    pvec :: ParamVector
    # Weights, excluding the first, normalized one.
    wtV :: Vector{F1}
    switches :: EndowPctRankingSwitches{F1}
end

# -----------------