## --------------  Generic
# One location

# test all of this +++++++++

"""
	$(SIGNATURES)

Fraction of students who attend local colleges.
"""
frac_local(e :: AbstractEntryResults{F1}) where F1 = one(F1);

"""
	$(SIGNATURES)

Fraction of students of each type who attend local colleges.
"""
frac_local_by_type(e :: AbstractEntryResults{F1}) where F1 = ones(F1, n_types(e));

"""
	$(SIGNATURES)

Fraction of students at each college who are local.
"""
frac_local_by_college(e :: AbstractEntryResults{F1}) where F1 = 
    ones(F1, n_colleges(e));

"""
	$(SIGNATURES)

Number of locations
"""
n_locations(e :: AbstractEntryResults{F1}) where F1 = 1;

"""
	$(SIGNATURES)

Number of colleges
"""
n_colleges(e :: AbstractEntryResults{F1}) where F1 = size(e.probEnter_jcM, 2);

"""
	$(SIGNATURES)

Number of student types.
"""
n_types(e :: AbstractEntryResults{F1}) where F1 = size(e.probEnter_jcM, 1);

"""
	$(SIGNATURES)

College capacities.
"""
capacities(e :: AbstractEntryResults{F1}) where F1 = capacities(e.switches);

"""
	$(SIGNATURES)

College enrollments.
"""
enrollments(e :: AbstractEntryResults{F1}) where F1 = e.enrollV;

"""
	$(SIGNATURES)

Enrollment of one college.
"""
enrollment(e :: AbstractEntryResults{F1}, ic) where F1 = e.enrollV[ic];

"""
	$(SIGNATURES)

Entry probabilities by college for each type.
"""
entry_probs(e :: AbstractEntryResults{F1}) where F1 = e.probEnter_jcM;

"""
	$(SIGNATURES)

Expected value at college entry stage, by type.
"""
expected_values(e :: AbstractEntryResults{F1}) where F1 = e.eVal_jV;

"""
	$(SIGNATURES)

Entry probabilities by type, across all colleges.
"""
type_entry_probs(e :: AbstractEntryResults{F1}) where F1 = 
    sum(e.probEnter_jcM, dims = 2);

"""
	$(SIGNATURES)

Returns `Vector{Bool}` that indicates which colleges are full.
"""
colleges_full(e :: AbstractEntryResults{F1}) where F1 =
    enrollments(e) .>= capacities(e);

"""
	$(SIGNATURES)

Validate `EntryResults`.
"""
function validate_er(er :: EntryResults{F1}) where F1
    isValid = true;
    nc = n_colleges(er);
    J = n_types(er);
    isValid = isValid && (size(entry_probs(er)) == (J, nc));
    isValid = isValid && check_prob_array(entry_probs(er));
    isValid = isValid && check_prob_array(type_entry_probs(er));
    return isValid
end

# ---------------