# CollegeEntry

```@meta
CurrentModule = CollegeEntry
```

This package contains various college entry or assignment models. The general idea is to map the values of working and of attending various colleges together with student characteristics, such as test scores, into college entry probabilities.

Once the user has set up an `AbstractEntryDecision` and an `AbstractAdmissionsRule`, calling [`entry_decisions`](@ref) yields entry probabilities and expected utilities for students with given payoffs from attending each college. The results are returned as an `AbstractEntryResults` object.

For sequential entry mechanisms, students need to be ranked to determine the order in which they get to choose colleges. This is done using `AbstractRanking`s.

## Admission rules

An `AbstractAdmissionsRule` determines the probability that a student may attend a particular college as a function of the students characteristics. Special cases are:

* [`AdmissionsOpen`](@ref): open admissions.
* [`AdmissionsCutoff`](@ref): admissions are determined by cutoff values for a single indicator, such as test scores.

Admission rules are constructed from "switches," such as `AdmissionsCutoffSwitches` using [`make_admissions`](@ref).

```@docs
AbstractAdmissionsRule
AdmissionsOpen
AdmissionsCutoff
make_admissions
```

## Entry decisions

An `AbstractEntryDecision` provides a structure according to which students make entry decisions, given a set of available colleges. Special cases are:

* [`EntryOneStep`](@ref): Students jointly decide whether and which college to attend, subject to Gumbel preference shocks.
* [`EntryTwoStep`](@ref): Students first decide whether or not to attend college. Then they decide which college. This is not fully implemented.
* [`EntrySequential`](@ref): Colleges have capacity constraints. Students are ordered in some given way. The best students decide first, subject to colleges admitting them and not being full.

Useful generic methods are listed below.


```@docs
AbstractEntryDecision
EntryOneStep
EntryTwoStep
EntrySequential
init_entry_decision
entry_decisions
entry_probs
scale_entry_probs!
type_mass
capacities
college_enrollment
```

## Student Rankings

For sequential admissions protocols, students need to be ranked. All colleges agree on the ranking which determines the order in which students get to choose colleges.

Steps:

1. Define an object that holds endowment draws.
2. Extend [`retrieve_draws`](@ref) and [`n_draws`](@ref) for this object. 
3. Set up switches that govern the ranking, such as [`EndowPctRankingSwitches`](@ref).
4. Call [`make_student_ranking`](@ref) to initialize an `AbstractRanking`.
5. Call [`entry_decisions`](@ref) to compute entry probabilities by type and college and expected values at college entry. This accepts the endowment draws object as input and call `retrieve_draws` to retrieve named endowments.

```@docs
AbstractRanking
AbstractRankingSwitches
EndowPctRanking
EndowPctRankingSwitches
retrieve_draws
n_draws
make_student_ranking
```

## Sequential entry decisions

The idea is to implement an assignment mechanism similar to Hendricks, Herrington, and Schoellman (2020 AEJM). The ingredients are:

1. There is a set of colleges with fixed qualities and capacities.
2. A student ranking that determines the order in which students choose colleges. This is provided simply as an ordinal student ranking from outside of the package.
3. An `AbstractAdmissionsRule` that determines whether a given student can attend a given college, assuming the college is not full. This could be probabilistic.

The algorithm then proceeds as follows:

1. Start with all colleges empty.
2. Loop over students in order of their ranking.
3. For each student, determine the set of colleges that admit the student (according to the `AbstractAdmissionsRule`) and that are not full.
4. Calculate the probability that each student attends each available college.
5. Record the increment in each college's enrollment. For the next student, colleges that are full are no longer available.
6. Continue to the next student in the ranking.

### Extension: Diversity preferences.

Colleges' preferences for diversity may be modeled by imposing quotas on students with certain characteristics. For example, high quality colleges may only admit a certain fraction of students in each income quartile. Once the quota is filled, such colleges are removed from the admissions set for students in those quartiles.

## Results

[`entry_decisions`](@ref) returns an `AbstractEntryResults` object. This can be queried using a unified interface, even though different entry protocols produce information in different ways. For example, only some protocols have locations.

```@docs
AbstractEntryResults
EntryResults
n_locations
n_colleges
n_types
capacities
enrollments
enrollment
type_entry_probs
expected_values
frac_local
frac_local_by_type
frac_local_by_college
```

-----------