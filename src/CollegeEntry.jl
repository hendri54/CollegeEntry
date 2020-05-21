module CollegeEntry

using ArgCheck, DocStringExtensions
using EconLH, ModelParams

# Entry decisions
export AbstractEntryDecision, AbstractEntrySwitches
export init_entry_decision, entry_probs, fix_entry_probs!, scale_entry_probs!,
    min_entry_prob, max_entry_prob, entry_probs_fixed, entry_pref_scale
export EntryOneStep, EntryOneStepSwitches

# Admissions rules
export AbstractAdmissionsRule, AbstractAdmissionsSwitches, AdmissionsOpenSwitches, AdmissionsOpen, AdmissionsCutoffSwitches, AdmissionsCutoff
export n_colleges, n_college_sets, percentile_var, college_set, open_admission, admission_probs, prob_coll_set, prob_coll_sets, make_admissions, validate_admissions

# Complete entry decisions
export entry_decisions

include("types.jl")
include("admissions_types.jl")

# Entry decisions
include("generic.jl")
include("entry_one_step.jl")
include("entry_two_step.jl")

# Admissions rules
include("admissions_rules.jl")

end # module
