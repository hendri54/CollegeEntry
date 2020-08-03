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


# ---------------------