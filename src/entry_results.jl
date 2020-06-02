function make_test_entry_results(switches :: AbstractEntrySwitches{F1}) where F1
	J = n_types(switches);
	nc = n_colleges(switches);
	eVal_jV = collect(range(-0.5, 1.5, length = J));
    probEnter_jcM = range(0.1, 0.2, length = J) * range(1.0, 1.2, length = nc)';
	enrollV = college_enrollment(switches, probEnter_jcM);
	return EntryResults(switches, probEnter_jcM, eVal_jV, enrollV);
end

function make_test_entry_results(switches :: EntrySequMultiLocSwitches{F1}) where F1
	J = n_types(switches);
	nc = n_colleges(switches);
	nl = n_locations(switches);
	eVal_jlM = range(-0.5, 1.5, length = J) * range(1.0, 0.9, length = nl)';
	probEnter_jcM = range(0.1, 0.2, length = J) * range(1.0, 1.2, length = nc)';
	probLocal_jcM = 0.3 .* probEnter_jcM;
	probNonLocal_jcM = 0.7 .* probEnter_jcM;
	enroll_clM = J .* nl .* 
		range(1.0, 1.5, length = nc) * range(1.0, 0.9, length = nl)';
	return EntryResultsMultiLoc(switches, probLocal_jcM, probNonLocal_jcM, 
		eVal_jlM, enroll_clM);
end


Base.show(io :: IO, er :: AbstractEntryResults{F1}) where F1 =
	print(io, typeof(er))


## ----------  Access

type_masses(e :: AbstractEntryResults{F1}) where F1 = 
	type_masses(e.switches);


## ----------  Implied statistics

"""
	$(SIGNATURES)

Fraction of students who attend local colleges.
"""
frac_local(e :: AbstractEntryResults{F1}) where F1 = one(F1);

# Not enough info to compute this unless type mass does not differ by location
frac_local(e :: EntryResultsMultiLoc{F1}) where F1 =
	sum(frac_local_by_college(e) .* enrollments(e)) / sum(enrollments(e));

"""
	$(SIGNATURES)

Fraction of students of each type who attend local colleges.
"""
frac_local_by_type(e :: AbstractEntryResults{F1}) where F1 = ones(F1, n_types(e));

# not correct; not enough info to compute this ++++++++
# unless mass does not differ by location
function frac_local_by_type(e :: EntryResultsMultiLoc{F1}) where F1
	return type_entry_probs(e, :local) ./ type_entry_probs(e, :all);
end

"""
	$(SIGNATURES)

Fraction of students at each college who are local.
"""
frac_local_by_college(e :: AbstractEntryResults{F1}) where F1 = 
	ones(F1, n_colleges(e));
	
# Not enough info to compute this unless type mass does not differ by location +++++
function frac_local_by_college(e :: EntryResultsMultiLoc{F1}) where F1
	typeMassV = sum(type_masses(e), dims = 2);
	flV = sum(entry_probs(e, :local) .* typeMassV, dims = 1) ./ 
		sum(entry_probs(e, :all) .* typeMassV, dims = 1);
	return vec(flV)
end


"""
	$(SIGNATURES)

Number of locations
"""
n_locations(e :: AbstractEntryResults{F1}) where F1 = 1;
n_locations(e :: EntryResultsMultiLoc{F1}) where F1 = size(e.eVal_jlM, 2);

"""
	$(SIGNATURES)

Number of colleges
"""
n_colleges(er :: AbstractEntryResults{F1}) where F1 = n_colleges(er.switches);
# n_colleges(e :: EntryResultsMultiLoc{F1}) where F1 = size(e.probLocal_jcM, 2);

"""
	$(SIGNATURES)

Number of student types.
"""
n_types(er :: AbstractEntryResults{F1}) where F1 = n_types(er.switches);
# n_types(e :: EntryResultsMultiLoc{F1}) where F1 = size(e.probLocal_jcM, 1);

"""
	$(SIGNATURES)

College capacities.
"""
capacities(e :: AbstractEntryResults{F1}) where F1 = capacities(e.switches);

"""
	$(SIGNATURES)

College enrollments. By location (if any).
"""
enrollments(e :: AbstractEntryResults{F1}) where F1 = e.enrollV;
enrollments(e :: EntryResultsMultiLoc{F1}) where F1 = e.enroll_clM;

"""
	$(SIGNATURES)

Enrollment of one college. By location (if any).
"""
enrollment(e :: AbstractEntryResults{F1}, ic :: Integer) where F1 = e.enrollV[ic];
enrollment(e :: EntryResultsMultiLoc{F1}, ic :: Integer) where F1 = 
	e.enroll_clM[ic,:];

"""
	$(SIGNATURES)

Entry probabilities by college for each type. All locations.
"""
entry_probs(e :: AbstractEntryResults{F1}) where F1 = e.probEnter_jcM;
entry_probs(e :: EntryResultsMultiLoc{F1}) where F1 = entry_probs(e, :all);

function entry_probs(e :: AbstractEntryResults{F1}, univ :: Symbol) where F1
	if univ == :local
		return e.probEnter_jcM;
	elseif univ == :nonlocal
		return zeros(F1, size(e.probEnter_jcM));
	elseif univ == :all
		return e.probEnter_jcM;
	else
		error("Invalid: $univ")
	end
end

function entry_probs(e :: EntryResultsMultiLoc{F1}, univ :: Symbol) where F1
	if univ == :local
		return e.probLocal_jcM;
	elseif univ == :nonlocal
		return e.probNonLocal_jcM;
	elseif univ == :all
		return e.probNonLocal_jcM .+ e.probLocal_jcM;
	else
		error("Invalid: $univ")
	end
end

"""
	$(SIGNATURES)

Expected value at college entry stage, by type.
"""
expected_values(e :: AbstractEntryResults{F1}) where F1 = e.eVal_jV;
expected_values(e :: EntryResultsMultiLoc{F1}) where F1 = e.eVal_jlM;

"""
	$(SIGNATURES)

Entry probabilities by type, across all colleges.
	Assumes type mass does not vary across locations +++++++
"""
type_entry_probs(er :: AbstractEntryResults{F1}) where F1 = 
	type_entry_probs(er, :all);
# type_entry_probs(e :: EntryResultsMultiLoc{F1}) where F1 = type_entry_probs(e, :all);

function type_entry_probs(er :: AbstractEntryResults{F1}, univ :: Symbol) where F1
	return sum(entry_probs(er, univ), dims = 2);
end

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

function validate_er(er :: EntryResultsMultiLoc{F1}) where F1
	isValid = true
	# stub +++
	return isValid
end



# ---------------