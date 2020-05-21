module CollegeEntry

using ArgCheck, DocStringExtensions
using EconLH, ModelParams

export AbstractEntryDecision, AbstractEntrySwitches
export init_entry_decision, entry_probs, scale_entry_probs!,
    min_entry_prob, max_entry_prob, entry_probs_fixed, entry_pref_scale
export EntryOneStep, EntryOneStepSwitches

include("types.jl")
include("generic.jl")
include("entry_one_step.jl")
include("entry_two_step.jl")

end # module
