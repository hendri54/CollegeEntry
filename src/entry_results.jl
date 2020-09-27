# function make_test_entry_results(switches :: AbstractEntrySwitches{F1}) where F1
# 	J = n_types(switches);
# 	nc = n_colleges(switches);
# 	eVal_jV = collect(range(-0.5, 1.5, length = J));
#     probEnter_jcM = range(0.1, 0.2, length = J) * range(1.0, 1.2, length = nc)';
# 	enrollV = college_enrollment(switches, probEnter_jcM);
# 	return EntryResults(switches, probEnter_jcM, eVal_jV, enrollV);
# end

## -------------  Construction

"""
	$(SIGNATURES)

Object that holds results of sequential entry protocol. If there is only one location, all students are considered "local."
"""
function EntryResults(switches :: EntryDecisionSwitches{F1}) where F1
	J = n_types(switches);
	nc = n_colleges(switches);
	nl = n_locations(switches);
	return EntryResults(switches,  
		zeros(F1, J, nl, nc), zeros(F1, J, nl, nc), zeros(F1, J, nl, nc),
		zeros(F1, J, nl),  
		zeros(F1, nc, nl), zeros(F1, nc, nl), zeros(F1, nc, nl))
end


"""
	$(SIGNATURES)

Validate `EntryResults`.
For subsetted `EntryResults`, do not `validateFracLocal`.
"""
function validate_er(er :: EntryResults{F1}; validateFracLocal :: Bool = true) where F1
	isValid = true
	isValid = isValid  &&  check_prob_array(er.fracEnter_jlcM);
	isValid = isValid  &&  check_prob_array(er.fracLocal_jlcM);
	isValid = isValid  &&  all(er.fracLocal_jlcM .< er.fracEnter_jlcM .+ 1e-5);
	isValid = isValid  &&  check_prob_array(sum(er.fracEnter_jlcM, dims = 3));
	if any(er.enrollLocal_clM .> er.enroll_clM .+ 1e-5)
		isValid = false;
		@warn "$er: Local enrollment > total enrollment"
	end

	nc = size(er.enroll_clM, 1);
	if any(er.enroll_clM .< er.enrollBest_clM .- 0.001)
		@warn "Total enrollment should be larger than best enrollment"
		isValid = false;
	end
	if !isapprox(er.enroll_clM[nc,:], er.enrollBest_clM[nc,:])
		@warn "For top college, total enrollment should equal best enrollment"
		isValid = false;
	end
	if any(map((x,y) -> x > y + 0.001,  er.fracEnterBest_jlcM, er.fracEnter_jlcM))
		maxGap, maxIdx = findmax(er.fracEnterBest_jlcM .- er.fracEnter_jlcM);
		j = maxIdx[1];
		@warn """
			More students in best college than total.
			Max gap: $maxGap for index $maxIdx
			fracEnterBest: $(er.fracEnterBest_jlcM[j,:,:])
			fracEnter:     $(er.fracEnter_jlcM[j,:,:])
			"""
		isValid = false;
	end
	if !isapprox(er.fracEnterBest_jlcM[:,:,nc], er.fracEnter_jlcM[:,:,nc])
		@warn "For top college, total entry should equal best entry"
		isValid = false;
	end

	# Computing fracLocal across colleges and across types should give the same answer
	if validateFracLocal
		fracLocal = frac_local(er);
		fracLocal2 = sum(frac_local_c(er) .* enrollment_c(er)) / sum(enrollment_c(er));
		entryMass_jV = entry_probs_j(er, :all) .* type_mass_j(er);
		fracLocal3 = sum(frac_local_j(er) .* entryMass_jV) / sum(entryMass_jV);
		if !isapprox(fracLocal, fracLocal2)  ||  !isapprox(fracLocal3, fracLocal)
			@warn "Fraction local not consistent: $fracLocal, $fracLocal2, $fracLocal3"
			isValid = false;
		end
	end
	return isValid
end


Base.show(io :: IO, er :: AbstractEntryResults{F1}) where F1 =
	print(io, typeof(er))


# Cannot make EntryResults without actually solving. At least its hard to maintain consistency.
function make_test_entry_results(switches :: EntryDecisionSwitches{F1};
	typicalValue :: F1 = 1.0) where F1
    rng = MersenneTwister(34);

	st = make_test_symbol_table();
	nc = n_colleges(switches);
	J = n_types(switches);
	nl = n_locations(switches);

    admissionS = make_test_admissions_cutoff(nc);
    objId = ObjectId(:entryOneStep);
    entryS = init_entry_decision(objId, switches, st);

	vWork_jV, vCollege_jcM = values_for_test(rng, J, nc, nl; 
		typicalValue = typicalValue);
    hsGpaPctV = collect(range(0.1, 0.9, length = J));
    rank_jV = vcat(2 : 2 : J, 1 : 2 : J);

    er = entry_decisions(entryS, admissionS,
        vWork_jV, vCollege_jcM, hsGpaPctV, rank_jV);
	# er = EntryResults(switches);
	# for j = 1 : J
	# 	for l = 1 : nl
	# 		er.eVal_jlM[j, l] = 0.5 * j + 0.6 * l;
	# 		for ic = 1 : nc
	# 			er.fracEnter_jlcM[j, l, ic] = 0.01 * J + 0.02 * l + 0.015 * ic;
	# 			er.fracLocal_jlcM[j, l, ic] = 0.5 * er.fracEnter_jlcM[j, l, ic];
	# 		end
	# 	end
	# end
	# for l = 1 : nl
	# 	for ic = 1 : nc
	# 		er.enroll_clM[ic, l] = 0.3 * ic + 0.2 * l;
	# 		er.enrollLocal_clM[ic, l] = 0.3 * er.enroll_clM[ic, l];
	# 	end
	# end
	@assert validate_er(er)
	return er
end


## ----------  Helpers

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

function mean_over_locations(e :: EntryResults{F1}, x_jlM :: Matrix{F1}) where F1
	x_jV = sum(x_jlM .* type_mass_jl(e),  dims = 2) ./
		type_mass_j(e);
	return x_jV
end


"""
	$(SIGNATURES)

Return a copy of the `EntryDecision` object for a subset of types.
College enrollments are not updated. There is not enough info to compute local enrollments.
"""
function subset_types(er :: EntryResults{F1}, idxV :: AbstractVector) where F1
	newSwitches = deepcopy(er.switches);
	subset_types!(newSwitches, idxV);
	erOut = EntryResults(newSwitches, er.fracEnter_jlcM[idxV,:,:],
		er.fracLocal_jlcM[idxV,:,:], er.fracEnterBest_jlcM[idxV,:,:], 
		er.eVal_jlM[idxV,:], 
		er.enroll_clM, er.enrollLocal_clM, er.enrollBest_clM);
	@assert validate_er(erOut; validateFracLocal = false)
	return erOut
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

enrollment_cl(e :: EntryResults{F1}, ic :: Integer, 
	univ :: Symbol = :all) where F1 = 
	enrollment_cl(e, univ)[ic,:];

enrollment_cl(e :: EntryResults{F1}, ic :: Integer, l, 
	univ = :all) where F1 = 
	enrollment_cl(e, univ)[ic,l];

"""
	$(SIGNATURES)

Total enrollment by college; across all locations.
"""
enrollment_c(e :: AbstractEntryResults{F1}, univ :: Symbol = :all) where F1 = 
	vec(sum(enrollment_cl(e, univ), dims = 2));

# Mass of students in each college for who this is the best college
enroll_best_c(e :: AbstractEntryResults{F1}) where F1 =
	vec(sum(e.enrollBest_clM, dims = 2));


"""
	$(SIGNATURES)

Fraction of students in each college type for who this is the best available college (across all locations). For the top college, this is 1 by construction.
"""
frac_best_c(e :: AbstractEntryResults{F1}) where F1 =
	enroll_best_c(e) ./ enrollment_c(e);


## ----------  Fraction local

"""
	$(SIGNATURES)

Fraction of students who attend local colleges.
"""
function frac_local(e :: EntryResults{F1}) where F1
	if n_locations(e) == 1
		fracLocal = one(F1);
	else
		fracLocal = sum(frac_local_c(e) .* enrollment_c(e)) /
			sum(enrollment_c(e));
		# Prevent rounding errors
		fracLocal = min(fracLocal, one(F1));
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
		fracLocalV = min.(fracLocalV, ones(F1));
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
		fracLocalV = min.(fracLocalV, ones(F1));
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
	return vec(sum(entry_probs_jc(er, univ), dims = 2));
end


## ----------------  Expected values

"""
	$(SIGNATURES)

Expected value at college entry stage, by type.
"""
expected_values_jl(e :: EntryResults{F1}) where F1 = e.eVal_jlM;


"""
	$(SIGNATURES)

Expected values at college entry by type; averaged across locations.
"""
expected_values_j(e :: EntryResults{F1}) where F1 = 
	mean_over_locations(e, expected_values_jl(e));

expected_values_j(e :: EntryResults{F1}, l :: Integer) where F1 = 
	e.eVal_jlM[:, l];

"""
	$(SIGNATURES)

Returns `Vector{Bool}` that indicates which colleges are full.
"""
colleges_full(e :: AbstractEntryResults{F1}) where F1 =
    enrollment_cl(e) .>= capacities(e);



## -----------  Modify

"""
	$(SIGNATURES)

Scale entry probs to bound within `min_entry_prob` and `max_entry_prob`.
"""
function scale_entry_probs!(er :: AbstractEntryResults{F1}) where F1
    minEntryProb = min_entry_prob(er.switches);
	maxEntryProb = max_entry_prob(er.switches);
	# This creates the risk that `fracEnterBest` may no longer be consistent with `fracEnter`. To avoid this, `fracEnterBest` is scaled the complicated way.
	# The `min.(one, ...)` deals with numerical inaccuracies.
	bestToAll_jlcM = min.(one(F1), 
		er.fracEnterBest_jlcM ./ max.(minEntryProb, er.fracEnter_jlcM));
	# Reach into object to ensure that we don't get a copy
	scale_entry_probs!(er.fracEnter_jlcM, minEntryProb, maxEntryProb);
	scale_entry_probs!(er.fracLocal_jlcM, minEntryProb, maxEntryProb);
	er.fracEnterBest_jlcM .= er.fracEnter_jlcM .* bestToAll_jlcM;

	@assert all_less(er.fracEnterBest_jlcM, er.fracEnter_jlcM; atol = 0.0001)
	return nothing
end


"""
	$(SIGNATURES)

Scale entry probs to match given total entry probs by type.
Respect the fraction of each type that goes to each (l, c). Also adjust `fracLocal_jlcM` to ensure that the ratio of local to total entry is unchanged.

`EntryResults` are no longer internally consistent after scaling. Only meant for testing / fixing poor outcomes during an optimization.
"""
function fix_type_entry_probs!(er :: AbstractEntryResults{F1}, typeTotalV :: AbstractVector{F1}) where F1 <: AbstractFloat

    @assert all_at_most(typeTotalV, one(F1))
	@assert length(typeTotalV) == n_types(er)
	
	# Ratio local/total entry
	fracEnter_jV = entry_probs_j(er, :all);

	J = n_types(er);
	for j = 1 : J
		er.fracEnter_jlcM[j, :, :] .*= (typeTotalV[j] / fracEnter_jV[j]);
		er.fracLocal_jlcM[j, :, :] .*= (typeTotalV[j] / fracEnter_jV[j]);
	end
	
	return nothing
end



# ---------------