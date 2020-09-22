# Entry decision

# When capacities are not constrained, set to this value
const CapacityInf = 1e8;

"""
	$(SIGNATURES)

Abstract type for entry decision protocols.
"""
abstract type AbstractEntryDecision{F1 <: AbstractFloat} <: ModelObject end

"""
	$(SIGNATURES)

Abstract type for switches governing entry decision protocols.
"""
abstract type AbstractEntrySwitches{F1 <: AbstractFloat} end


## ------------  Sequential assignment

"""
	$(SIGNATURES)

Switches governing default entry protocol. This has multiple locations, capacity constraints, and sequential entry decisions (simultaneous with work/study decisions).

`valueLocal` must be fixed at zero if there is only one location.
"""
Base.@kwdef mutable struct EntryDecisionSwitches{F1} <: AbstractEntrySwitches{F1}
    nTypes :: Int
    nColleges :: Int
    nLocations :: Int
    # Min entry prob for each (feasible) college
    minEntryProb :: F1 = 0.01
    # Max entry prob for all colleges jointly
    maxEntryProb :: F1 = 0.99
    "Fix entry rates to match data?"
    fixEntryProbs :: Bool = false
    "Preference shock scale parameter"
    entryPrefScale :: F1 = 1.0
    "Calibrate preference shock scale parameter?"
    calEntryPrefScale :: Bool = true
    # Value of attending local college
    valueLocal :: F1 = 1.0
    calValueLocal :: Bool = true
    # Each student has this mass
    typeMass_jlM :: Matrix{F1}
    # College capacity (in units of typeMass)
    capacity_clM :: Matrix{F1}
    # Indices of colleges that can only be attended locally
    localOnlyIdxV :: Vector{Int} = Vector{Int}()
end

"""
	$(SIGNATURES)

Sequential entry protocol.
"""
mutable struct EntryDecision{F1} <: AbstractEntryDecision{F1}
    objId :: ObjectId
    pvec :: ParamVector
    entryPrefScale :: F1
    valueLocal :: F1
    switches :: EntryDecisionSwitches{F1}
end


## ----------------  Results object

"""
	$(SIGNATURES)

Abstract type for results from entry decisions.
"""
abstract type AbstractEntryResults{F1 <: AbstractFloat} end

"""
	$(SIGNATURES)

Entry results for multiple locations. Records:
- `fracEnter_jlcM`: Fraction of students in (j,l) who attend college `c`
- `fracLocal_jlcM`: The same, but for the local college `c` (if any).
- `fracEnterBest_jlcM`: Fraction of students in (j,l) who attend college `c` and for who this is the best available college.
- `enroll_clM`: total enrollment at college (c, l).
- `enrollLocal_clM`: local enrollment at college (c, l).
- `enrollBest_clM`: enrollment of students for who this is the best available college.
- `eVal_jlM`: expected value of students in (j,l) at the start of the process.
"""
struct EntryResults{F1} <: AbstractEntryResults{F1}
    switches :: AbstractEntrySwitches{F1}
    fracEnter_jlcM :: Array{F1, 3}
    fracLocal_jlcM :: Array{F1, 3}
    fracEnterBest_jlcM :: Array{F1, 3}
    # Expected values of types
    eVal_jlM :: Matrix{F1}
    # Mass of enrollment in each college
    enroll_clM :: Matrix{F1}
    enrollLocal_clM :: Matrix{F1}
    enrollBest_clM :: Matrix{F1}
end


# ----------------------