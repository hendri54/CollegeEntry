# CollegeEntry

```@meta
CurrentModule = CollegeEntry
```

This package contains a generic college entry or assignment model. The general idea is to map the values of working and of attending various colleges together with student characteristics, such as test scores, into college entry probabilities.

Once the user has set up an `AbstractEntryDecision` and an `AbstractAdmissionsRule`, calling [`entry_decisions`](@ref) yields entry probabilities and expected utilities for students with given payoffs from attending each college. The results are returned as an `AbstractEntryResults` object.

For sequential entry mechanisms, students need to be ranked to determine the order in which they get to choose colleges. This is done using `AbstractRanking`s.

Entry is always represented as sequential choice in the rank order of the students. Without capacity constraints, sequential choice and simultaneous choice are the same, so this representation is without loss of generality. Without capacity constraints, the rank order does not matter.

*Example:*

```
# There are `nc` colleges
nc = 4;

# Set up admission rules
# Students are ranked by the endowment named `hsGpa`.
# The cutoff for each college that grants admission ranges from 0.0 to 0.8.
admissionS = AdmissionsCutoffSwitches(nc, :hsGpa, 
        collect(range(0.0, 0.8, length = nc)), 0.05);

# Set up entry decision structure
# There are `J` types
J = 200;
# and `nl` locations
nl = 3;
# Total college capacity as multiple of type mass is
totalCapacity = J * nl * 0.4;
switches = make_test_entry_sequ_multiloc(J, nc, nl, totalCapacity);
# Initialize the entry decision
entryS = init_entry_decision(ObjectId(:test), switches, st);

# From model solution, get values of working and of studying
# Provide the ranking of each student according to the indicator that determines the order in which students get to decide (rank_jV).
# Provide the `hsGpa` of each student that is used in admissions.
# The result `er` is an `AbstractEntryResult`
er = entry_decisions(entryS, admissionS,
        vWork_jV, vCollege_jcM, hsGpaPctV, rank_jV);
```

Notational note: Several functions have suffixes that indicate the dimensions of the objects to be returned. For example, `type_mass_jl` returns the mass of types by (type, location), whereas `type_mass_j` returns the total mass of each type across locations.

Notation (Latex symbols) are provided into object constructors as `LatexLH.SymbolTable` objects. `make_test_symbol_table()` contains all the objects that need to be defined for all variations of entry scenarios.

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

An `AbstractEntryDecision` provides a structure according to which students make entry decisions, given a set of available colleges. The only concrete type right now is [`EntryDecision`](@ref), which can be set up for one location or for multiple with and without capacity constraints.

The idea is to implement an assignment mechanism similar to Hendricks, Herrington, and Schoellman (2021 AEJM). The ingredients are:

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

Useful generic methods are listed below.


```@docs
AbstractEntryDecision
EntryDecision
init_entry_decision
entry_decisions
entry_probs
scale_entry_probs!
set_local_only_colleges!
increase_capacities!
increase_capacity!
```

### Extension: Diversity preferences.

Colleges' preferences for diversity may be modeled by imposing quotas on students with certain characteristics. For example, high quality colleges may only admit a certain fraction of students in each income quartile. Once the quota is filled, such colleges are removed from the admissions set for students in those quartiles.

## Student Rankings

For sequential admissions protocols, students need to be ranked. All colleges agree on the ranking which determines the order in which students get to choose colleges.

Steps:

1. Define an object that holds endowment draws.
2. Extend [`retrieve_draws`](@ref) and [`n_draws`](@ref) for this object. 
3. Set up switches that govern the ranking, such as [`EndowPctRankingSwitches`](@ref).
4. Call [`make_student_ranking`](@ref) to initialize an `AbstractRanking`.
5. Call [`entry_decisions`](@ref) to compute entry probabilities by type and college and expected values at college entry. This accepts the endowment draws object as input and call `retrieve_draws` to retrieve named endowments.

If student rankings and admissions are supposed to operate on the same object, that object needs to be a single endowment. For example, students can be admitted based on expected abiity given GPA and parental. This is constructed as an endowment draw.

Random student rankings can be achieved by simply generating a random endowment draw.

```@docs
AbstractRanking
AbstractRankingSwitches
EndowPctRanking
EndowPctRankingSwitches
retrieve_draws
n_draws
make_student_ranking
```

## Results

[`entry_decisions`](@ref) returns an `AbstractEntryResults` object. This can be queried using a unified interface, even though different entry protocols produce information in different ways. For example, only some protocols have locations.

```@docs
AbstractEntryResults
EntryResults
n_locations
n_colleges
n_types
capacities
enrollment_cl
enrollment_c
entry_probs_jlc
entry_probs_jc
entry_probs_j
expected_values_jl
frac_local
frac_local_j
frac_local_c
```

-----------