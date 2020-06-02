module CollegeEntry

using ArgCheck, DocStringExtensions
using CommonLH, EconLH, ModelParams

# Entry decisions
export AbstractEntryDecision, AbstractEntrySwitches
export init_entry_decision, entry_probs, fix_entry_probs!, scale_entry_probs!,
    min_entry_prob, max_entry_prob, entry_probs_fixed, entry_pref_scale
export EntryOneStep, EntryOneStepSwitches, EntryTwoStep, EntryTwoStepSwitches, EntrySequential, EntrySequentialSwitches

# Admissions rules
export AbstractAdmissionsRule, AbstractAdmissionsSwitches, AdmissionsOpenSwitches, AdmissionsOpen, AdmissionsCutoffSwitches, AdmissionsCutoff
export n_colleges, n_college_sets, percentile_var, college_set, open_admission, admission_probs, prob_coll_set, prob_coll_sets, make_admissions, validate_admissions

# Complete entry decisions
export entry_decisions
export college_enrollment, type_mass, colleges_full, capacities

# Student rankings
export AbstractRankingSwitches, AbstractRanking, EndowPctRankingSwitches, EndowPctRanking
export rank_students, make_student_ranking, validate_ranking, validate_ranking_switches, retrieve_draws, n_draws, endow_names

# Results
export AbstractEntryResults, EntryResults
export frac_local, frac_local_by_type, frac_local_by_college, n_locations, n_colleges, n_types, capacities, enrollments, enrollment, entry_probs, expected_values, type_entry_probs, validate_er

include("helpers.jl")

include("ranking_types.jl")
include("admissions_types.jl")
include("types.jl")

# Entry decisions
include("generic.jl")
include("entry_one_step.jl")
include("entry_two_step.jl")
# Sequential assignment
include("sequential.jl")

# Admissions rules
include("admissions_rules.jl")

# Student rankings
include("student_rankings.jl")

include("entry_results.jl")


end # module
