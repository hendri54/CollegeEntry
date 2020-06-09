using Random, Test
using ModelParams

# Make test entryProb_jlcM with some zero entries
function make_test_entry_probs(rng, J, nc, nl)
    entryProb_jlcM = zeros(J, nl, nc);
    entryProb_jlM = rand(rng, J, nl);
    for j = 1 : J
        for l = 1 : nl
            prob_cV = rand(rng, nc);
            prob_cV[rand(rng, 1 : nc)] = 0.0;
            entryProb_jlcM[j, l, :] .= prob_cV .* 
                (entryProb_jlM[j, l] / sum(prob_cV));
        end
    end
    return entryProb_jlcM
end

function test_value_cl(rng, nc, nl)
    return 1.0 .+ 2.0 .* rand(rng, nc, nl);
end

# Set to get interior entry rates
function values_for_test(rng, J, nc, nl)
    # vWork_jV = (0.8 * nl) .+ 1.0 .* rand(rng, Float64, J);
    vCollege_jcM = 1.0 .+ 2.0 .* rand(rng, Float64, J, nc);
    vWork_jV = vec(sum(vCollege_jcM, dims = 2)) ./ nc .+ (0.6 * nl);
    return vWork_jV, vCollege_jcM
end

# Make type masses, setting some to 0
function type_masses_for_test(rng, J, nl)
    if nl == 1
        return 0.5 .+ rand(rng, J, nl);
    else
        typeMass_jlM = zeros(J, nl);
        for j = 1 : J
            typeMass_jlM[j, :] = 0.5 .+ rand(rng, nl);
            l = rand(rng, 1 : nl);
            typeMass_jlM[j, l] = 0.0;
        end
        return typeMass_jlM
    end
end

# College capacity matrix with given total capacity
# Some colleges do not occur in some places
function college_capacities_for_test(rng, nc, nl, totalCapacity)
    capacity_clM = rand(rng, nc, nl);
    if nl > 1
        for ic = 1 : nc
            l = rand(rng, 1 : nl);
            capacity_clM[ic, l] = 0.0;
        end
    end
    cSum  = sum(capacity_clM);
    capacity_clM .*= (totalCapacity / cSum);
    @assert isapprox(sum(capacity_clM), totalCapacity)
    return capacity_clM
end


function show_matrix(m :: Matrix{F1}; header = "Matrix:") where F1
    println(header);
    nr = size(m, 1);
    for ir = 1 : nr
        println(round.(m[ir,:], digits = 3));
    end
end

# Low capacity sequential ensures that there are full colleges
function test_entry_switches(J, nc)
    return [
        make_test_entry_sequ_multiloc(J, nc, nc + 1, 0.3 * J * nc),
        make_entry_switches_oneloc(J, nc)
    ];
end


# Inputs are
# - `totalCapacity` of all colleges; in multiples of  total `typeMass`
function make_test_entry_sequ_multiloc(J, nc, nl, totalCapacity)
    rng = MersenneTwister(45);
    typeMass_jlM = type_masses_for_test(rng, J, nl);
    totalMass = sum(typeMass_jlM);
    totalCapacity = 0.4 * totalMass;
    capacity_clM = college_capacities_for_test(rng, nc, nl, totalCapacity);
    if nl > 1
        valueLocal = 0.7;
        calValueLocal = true;
    else
        valueLocal = 0.0;
        calValueLocal = false;
    end

    switches = EntryDecisionSwitches(
        nTypes = J, nColleges = nc, nLocations = nl, valueLocal = valueLocal,
        typeMass_jlM = typeMass_jlM, capacity_clM = capacity_clM, 
        entryPrefScale = 1.2,
        calValueLocal = calValueLocal);
    @assert validate_es(switches)
    return switches
end


# Cannot make EntryResults without actually solving. At least its hard to maintain consistency.
function make_test_entry_results(switches :: EntryDecisionSwitches{F1}) where F1
    rng = MersenneTwister(34);

	nc = n_colleges(switches);
	J = n_types(switches);
	nl = n_locations(switches);

    admissionS = CollegeEntry.make_test_admissions_cutoff(nc);
    objId = ObjectId(:entryOneStep);
    entryS = init_entry_decision(objId, switches);

    vWork_jV, vCollege_jcM = values_for_test(rng, J, nc, nl);
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


# ---------------------