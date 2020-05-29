# Entry decision

abstract type AbstractEntryDecision{F1 <: AbstractFloat} <: ModelObject end
abstract type AbstractEntrySwitches{F1 <: AbstractFloat} end



## ------------  One step entry decision
# Simply decide between no college and all open colleges subject to Gumbel preference shocks.

"""
	$(SIGNATURES)

Switches for `EntryOneStep`.
"""
Base.@kwdef mutable struct EntryOneStepSwitches{F1} <: AbstractEntrySwitches{F1}
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

Base.@kwdef mutable struct EntryTwoStepSwitches{F1} <: AbstractEntrySwitches{F1}
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


mutable struct EntryTwoStep{F1} <: AbstractEntryDecision{F1}
    objId :: ObjectId
    pvec :: ParamVector
    entryPrefScale :: F1
    collPrefScale :: F1
    switches :: EntryTwoStepSwitches{F1}
end


## ------------  Sequential assignment

Base.@kwdef mutable struct EntrySequentialSwitches{F1} <: AbstractEntrySwitches{F1}
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
    typeMass :: F1 = 1.0
    # College capacity (in units of typeMass)
    capacityV :: Vector{F1}
end

mutable struct EntrySequential{F1} <: AbstractEntryDecision{F1}
    objId :: ObjectId
    pvec :: ParamVector
    entryPrefScale :: F1
    switches :: EntrySequentialSwitches{F1}
end


mutable struct AssignmentResults{F1 <: AbstractFloat}
    # Probability that student j chooses college c
    probEnter_jcM :: Matrix{F1}
    # Mass of enrollment in each college
    enrollV :: Vector{F1}
end


# ----------------------