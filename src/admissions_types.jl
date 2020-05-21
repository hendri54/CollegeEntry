abstract type AbstractAdmissionsRule{I1, F1 <: AbstractFloat} end
abstract type AbstractAdmissionsSwitches{I1, F1 <: AbstractFloat} end

## -----------  Open admission

mutable struct AdmissionsOpenSwitches{I1, F1} <: AbstractAdmissionsSwitches{I1, F1}
    nColleges :: I1
    # The variable that holds the individual percentiles (here for interface consistency)
    pctVar :: Symbol
end


"""
	$(SIGNATURES)

Open admissions. Any student may attend any college.
"""
struct AdmissionsOpen{I1, F1} <: AbstractAdmissionsRule{I1, F1}
    switches :: AdmissionsOpenSwitches{I1, F1}
end


## ----------  HS GPA or other endowment percentile cutoff

mutable struct AdmissionsCutoffSwitches{I1, F1 <: AbstractFloat} <: AbstractAdmissionsSwitches{I1, F1}
    nColleges :: I1
    # The variable that holds the individual percentiles
    pctVar :: Symbol
    # Minimum HS GPA percentile required for each college; should be increasing
    minPctV :: Vector{F1}
    # Minimum probability of all college sets
    minCollSetProb :: F1
end

"""
	$(SIGNATURES)

Admissions are governed by a single indicator, such as a test score. Students can attend colleges for which they qualify in the sense that their indicator exceeds the college's cutoff value. Students may be allowed to attend other colleges with a fixed probability.
"""
struct AdmissionsCutoff{I1, F1 <: AbstractFloat} <: AbstractAdmissionsRule{I1, F1}
    switches :: AdmissionsCutoffSwitches{I1, F1}
end

# ----------