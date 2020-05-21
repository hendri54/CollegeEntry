# CollegeEntry

```@meta
CurrentModule = CollegeEntry
```


Packages various college entry or assignment models. The general idea is to map the values of working and of attending various colleges together with student characteristics, such as test scores, into college entry probabilities.

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

Once the user has set up an `AbstractEntryDecision` and an `AbstractAdmissionsRule`, calling [`entry_decisions`](@ref) yields entry probabilities and expected utilities for students with given payoffs from attending each college.

```@docs
AbstractEntryDecision
EntryOneStep
entry_decisions
```


-----------