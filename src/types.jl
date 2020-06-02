# Entry decision

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



## ------------  One step entry decision
# Simply decide between no college and all open colleges subject to Gumbel preference shocks.

"""
	$(SIGNATURES)

Switches for `EntryOneStep`.
"""
Base.@kwdef mutable struct EntryOneStepSwitches{F1} <: AbstractEntrySwitches{F1}
    nTypes :: Int
    nColleges :: Int
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
end


"""
	$(SIGNATURES)

College entry decisions.
Students choose whether to attend college and which college to attend simultaneously.
"""
Base.@kwdef mutable struct EntryOneStep{F1} <: AbstractEntryDecision{F1}
    objId :: ObjectId
    pvec :: ParamVector
    entryPrefScale :: F1
    switches :: EntryOneStepSwitches{F1}
end




## --------------  Two step entry decision

"""
	$(SIGNATURES)

Switches governing two step entry protocol. Students first choose whether to enter college or work. Then they choose a college.
"""
Base.@kwdef mutable struct EntryTwoStepSwitches{F1} <: AbstractEntrySwitches{F1}
    nTypes :: Int
    nColleges :: Int
    # Min entry prob for each (feasible) college
    minEntryProb :: F1 = 0.01
    # Max entry prob for all colleges jointly
    maxEntryProb :: F1 = 0.99
    "Fix entry rates to match data by [gpa, p]?"
    fixEntryProbs :: Bool = false
    "Preference shock scale parameter"
    entryPrefScale :: F1 = 1.0
    "Calibrate preference shock scale parameter?"
    calEntryPrefScale :: Bool = true
    "Scale parameter for preference shock at college choice"
    collPrefScale :: F1 = 1.0
    calCollPrefScale :: Bool = true
end

"""
	$(SIGNATURES)

Two step entry protocol object.
"""
mutable struct EntryTwoStep{F1} <: AbstractEntryDecision{F1}
    objId :: ObjectId
    pvec :: ParamVector
    entryPrefScale :: F1
    collPrefScale :: F1
    switches :: EntryTwoStepSwitches{F1}
end


## ------------  Sequential assignment

"""
	$(SIGNATURES)

Switches governing sequential entry protocol.
"""
Base.@kwdef mutable struct EntrySequentialSwitches{F1} <: AbstractEntrySwitches{F1}
    nTypes :: Int
    nColleges :: Int
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
    # Each student has this mass
    typeMass_jV :: Vector{F1}
    # College capacity (in units of typeMass)
    capacityV :: Vector{F1}
end

"""
	$(SIGNATURES)

Sequential entry protocol.
"""
mutable struct EntrySequential{F1} <: AbstractEntryDecision{F1}
    objId :: ObjectId
    pvec :: ParamVector
    entryPrefScale :: F1
    switches :: EntrySequentialSwitches{F1}
end


## ------------  Sequential assignment

"""
	$(SIGNATURES)

Switches governing sequential entry protocol.
"""
Base.@kwdef mutable struct EntrySequMultiLocSwitches{F1} <: AbstractEntrySwitches{F1}
    nTypes :: Int
    nColleges :: Int
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
end

"""
	$(SIGNATURES)

Sequential entry protocol.
"""
mutable struct EntrySequMultiLoc{F1} <: AbstractEntryDecision{F1}
    objId :: ObjectId
    pvec :: ParamVector
    entryPrefScale :: F1
    valueLocal :: F1
    switches :: EntrySequMultiLocSwitches{F1}
end


## ----------------  Results object

abstract type AbstractEntryResults{F1 <: AbstractFloat} end

"""
	$(SIGNATURES)

Entry results with one location.
"""
struct EntryResults{F1} <: AbstractEntryResults{F1}
    switches :: AbstractEntrySwitches{F1}
    # Probability that student j chooses college c
    probEnter_jcM :: Matrix{F1}
    # Expected values of types
    eVal_jV :: Vector{F1}
    # Mass of enrollment in each college
    enrollV :: Vector{F1}
end

"""
	$(SIGNATURES)

Entry results for multiple locations.
"""
struct EntryResultsMultiLoc{F1} <: AbstractEntryResults{F1}
    switches :: AbstractEntrySwitches{F1}
    # Probability that student j chooses local college c
    probLocal_jcM :: Matrix{F1}
    # Probability that student j chooses non-local college c
    probNonLocal_jcM :: Matrix{F1}
    # Expected values of types
    eVal_jlM :: Matrix{F1}
    # Mass of enrollment in each college
    enroll_clM :: Matrix{F1}
end


# ----------------------