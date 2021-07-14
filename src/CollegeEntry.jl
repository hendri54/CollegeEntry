module CollegeEntry

# Distributions only needed for simulations.
using ModelParams: get_object_id
using ArgCheck, Distributions, DocStringExtensions, Lazy, Random
using CommonLH, EconLH, LatexLH, StructLH, ModelObjectsLH, ModelParams

# Entry decisions
export AbstractEntryDecision, AbstractEntrySwitches, 
    EntryDecision, EntryDecisionSwitches
export init_entry_decision, entry_probs, fix_entry_probs!, scale_entry_probs!,
    fix_entry_pref_scale!,
    min_entry_prob, max_entry_prob, entry_probs_fixed, entry_pref_scale, subset_types, subset_types!


# Admissions rules
export AbstractAdmissionsRule, AbstractAdmissionsSwitches, AdmissionsOpenSwitches, AdmissionsOpen, AdmissionsCutoffSwitches, AdmissionsCutoff, AdmissionsOneVarSwitches, AdmissionsOneVar
export n_colleges, n_college_sets, college_set, open_admission, admission_probs, prob_coll_set, prob_coll_sets, make_admissions, validate_admissions

# Admission probabilities
export AbstractAdmProbFctSwitches, AbstractAdmProbFct, 
    AdmProbFctLogisticSwitches, AdmProbFctLogistic,
    AdmProbFctOpenSwitches, AdmProbFctOpen,
    AdmProbFctLinearSwitches, AdmProbFctLinear,
    AdmProbFctStepSwitches, AdmProbFctStep
export init_admprob_fct_logistic_switches, init_admprob_fct_step_switches, init_admprob_fct, make_admprob_function,  prob_admit
export by_college, by_college!

# Complete entry decisions
export entry_decisions
export colleges_full, capacities, capacities_c, limited_capacity, n_locations, n_types, total_mass
export set_capacities!, increase_capacity!, increase_capacities!, set_local_only_colleges!

# Student rankings
export AbstractRankingSwitches, AbstractRanking, EndowPctRankingSwitches, EndowPctRanking
export make_entry_switches_oneloc, validate_es, set_bounds!
export rank_students, score_students, scale_scores, range_of_scores, make_student_ranking, validate_ranking, validate_ranking_switches, retrieve_draws, n_draws, endow_names

# Results
export AbstractEntryResults, EntryResults, validate_er
export frac_local, frac_local_j, frac_local_c, n_locations, n_colleges, n_types, type_mass_jl, type_mass_j, capacities, enrollment_cl, enrollment_c, entry_probs_jlc, entry_probs_jc, entry_probs_j, expected_values_jl, frac_best_c
export make_test_entry_results

include("helpers.jl")
include("test_helpers.jl")

# Student rankings
include("ranking_types.jl");
include("ranking_endow_pct.jl");

# Admission probabilities
include("admission_prob_functions.jl");

# Admissions rules
include("admissions_types.jl");
include("admissions_open_types.jl");
include("admissions_cutoff_types.jl");
include("admissions_one_indicator.jl");

# Entry decisions
include("types.jl")
include("access_routines.jl")
include("generic.jl")
# include("entry_one_step.jl")
# include("entry_two_step.jl")
# Sequential assignment
# include("sequential.jl")
include("sequential_multi_locations.jl")
include("simulations.jl")

include("entry_results.jl")


end # module
