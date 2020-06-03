# function make_test_entry_results(switches :: AbstractEntrySwitches{F1}) where F1
# 	J = n_types(switches);
# 	nc = n_colleges(switches);
# 	eVal_jV = collect(range(-0.5, 1.5, length = J));
#     probEnter_jcM = range(0.1, 0.2, length = J) * range(1.0, 1.2, length = nc)';
# 	enrollV = college_enrollment(switches, probEnter_jcM);
# 	return EntryResults(switches, probEnter_jcM, eVal_jV, enrollV);
# end

function EntryResults(switches :: EntryDecisionSwitches{F1}) where F1
	J = n_types(switches);
	nc = n_colleges(switches);
	nl = n_locations(switches);
	return EntryResults(switches,  
		zeros(F1, J, nl, nc),  zeros(F1, J, nl, nc),
		zeros(F1, J, nl),  
		zeros(F1, nc, nl), zeros(F1, nc, nl))
end


function validate_er(er :: EntryResults{F1}) where F1
	isValid = true
	isValid = isValid  &&  check_prob_array(er.fracEnter_jlcM);
	isValid = isValid  &&  check_prob_array(er.fracLocal_jlcM);
	isValid = isValid  &&  all(er.fracLocal_jlcM .< er.fracEnter_jlcM .+ 1e-5);
	isValid = isValid  &&  check_prob_array(sum(er.fracEnter_jlcM, dims = 3));
	
	return isValid
end


function make_test_entry_results(switches :: EntryDecisionSwitches{F1}) where F1
	J = n_types(switches);
	nc = n_colleges(switches);
	nl = n_locations(switches);
	er = EntryResults(switches);
	for j = 1 : J
		for l = 1 : nl
			er.eVal_jlM[j, l] = 0.5 * j + 0.6 * l;
			for ic = 1 : nc
				er.fracEnter_jlcM[j, l, ic] = 0.01 * J + 0.02 * l + 0.015 * ic;
				er.fracLocal_jlcM[j, l, ic] = 0.5 * er.fracEnter_jlcM[j, l, ic];
			end
		end
	end
	for l = 1 : nl
		for ic = 1 : nc
			er.enroll_clM[ic, l] = 0.3 * ic + 0.2 * l;
			er.enrollLocal_clM[ic, l] = 0.3 * er.enroll_clM[ic, l];
		end
	end
	@assert validate_er(er)
	return er
end


Base.show(io :: IO, er :: AbstractEntryResults{F1}) where F1 =
	print(io, typeof(er))


## ----------  Helpers

# test this ++++++++
# Take the mean of a variable by (j,l,c) across locations, weighted by typeMass(j,l).
function mean_over_locations(e :: EntryResults{F1}, x_jlcM :: Array{F1, 3}) where F1
	J, nl, nc = size(x_jlcM);
	x_jcM = zeros(F1, J, nc);
	for ic = 1 : nc
		x_jcM[:, ic] = sum(x_jlcM[:,:,ic] .* type_mass_jl(e),  dims = 2) ./
			type_mass_j(e);
	end
	return x_jcM
end


## ----------  College enrollment

"""
	$(SIGNATURES)

College enrollments. By location (if any).
"""
function enrollment_cl(e :: AbstractEntryResults{F1}, univ :: Symbol = :all) where F1
	if univ == :all
		return e.enroll_clM;
	elseif univ == :local
		return e.enrollLocal_clM;
	elseif univ == :nonlocal
		return enrollment_cl(e, :all) .- enrollment_cl(e, :local);
	else
		error("Invalid $univ");
	end
end

"""
	$(SIGNATURES)

Enrollment of one college. By location (if any).
"""
enrollment_cl(e :: EntryResults{F1}, ic :: Integer, 
	univ :: Symbol = :all) where F1 = 
	enrollment_cl(e, univ)[ic,:];
enrollment_cl(e :: EntryResults{F1}, ic :: Integer, l, 
	univ = :all) where F1 = 
	enrollment_cl(e, univ)[ic,l];

# Total enrollment by college; across all locations
enrollment_c(e :: AbstractEntryResults{F1}, univ :: Symbol = :all) where F1 = 
	vec(sum(enrollment_cl(e, univ), dims = 2));


## ----------  Fraction local

"""
	$(SIGNATURES)

Fraction of students who attend local colleges.
"""
# frac_local(e :: AbstractEntryResults{F1}) where F1 = one(F1);

# Not enough info to compute this unless type mass does not differ by location ++++++
function frac_local(e :: EntryResults{F1}) where F1
	if n_locations(e) == 1
		fracLocal = one(F1);
	else
		fracLocal = sum(frac_local_c(e) .* enrollment_c(e)) /
			sum(enrollment_c(e));
	end
	return fracLocal
end

"""
	$(SIGNATURES)

Fraction of students of each type who attend local colleges.
"""
function frac_local_j(e :: EntryResults{F1}) where F1
	if n_locations(e) == 1
		fracLocalV = ones(F1, n_types(e));
	else
		fracLocalV = entry_probs_j(e, :local) ./ entry_probs_j(e, :all);
	end
	return fracLocalV
end

"""
	$(SIGNATURES)

Fraction of students at each college who are local. Across all locations.
"""
function frac_local_c(e :: EntryResults{F1}) where F1
	if n_locations(e) == 1
		fracLocalV = ones(F1, n_colleges(e));
	else
		fracLocalV = enrollment_c(e, :local) ./ enrollment_c(e, :all);
	end
	return fracLocalV
end


## --------------  Entry probabilities of types

"""
	$(SIGNATURES)

Entry probabilities by college for each type, location.
"""
function entry_probs_jlc(e :: EntryResults{F1}, univ :: Symbol = :all) where F1
	if univ == :local
		prob_jlcM = e.fracLocal_jlcM;
	elseif univ == :nonlocal
		prob_jlcM = e.fracEnter_jlcM .- e.fracLocal_jlcM;
	elseif univ == :all
		prob_jlcM = e.fracEnter_jlcM;
	else
		error("Invalid: $univ")
	end
end


"""
	$(SIGNATURES)

Fraction of each type entering each college; across all locations.
"""
function entry_probs_jc(e :: EntryResults{F1}, univ :: Symbol = :all) where F1
	mean_over_locations(e, entry_probs_jlc(e, univ));
end

"""
	$(SIGNATURES)

Entry probabilities by type, across all colleges.
"""
function entry_probs_j(er :: AbstractEntryResults{F1}, 
	univ :: Symbol = :all) where F1
	return sum(entry_probs_jc(er, univ), dims = 2);
end


## ----------------  Expected values

"""
	$(SIGNATURES)

Expected value at college entry stage, by type.
"""
expected_values_jl(e :: EntryResults{F1}) where F1 = e.eVal_jlM;


"""
	$(SIGNATURES)

Returns `Vector{Bool}` that indicates which colleges are full.
"""
colleges_full(e :: AbstractEntryResults{F1}) where F1 =
    enrollment_cl(e) .>= capacities(e);


# ---------------