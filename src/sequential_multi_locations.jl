# Sequential assignment. Multiple locations

## ------------- Switches

"""
    $(SIGNATURES)

Constructor for `EntryDecisionSwitches`: One location. Equal type mass. No capacity constraints by default.
"""
function make_entry_switches_oneloc(J, nc; entryPrefScale = 1.0,
    typeMass = 1.0, capacity_cV = nothing)

    F1 = typeof(entryPrefScale);
    if isnothing(capacity_cV)
        capacity_clM = fill(F1(CapacityInf), nc, 1);
    else
        capacity_clM = matrix_from_vector(capacity_cV);
    end
    switches = EntryDecisionSwitches{F1}(
        nTypes = J, nColleges = nc, nLocations = 1, 
        typeMass_jlM = fill(F1(typeMass), J, 1), 
        capacity_clM = capacity_clM, 
        entryPrefScale = entryPrefScale, 
        valueLocal = zero(F1), calValueLocal = false);
    @assert validate_es(switches)
    return switches
end


function validate_es(switches :: EntryDecisionSwitches{F1}) where F1
    isValid = true;
    J = n_types(switches);
    nc = n_colleges(switches);
    nl = n_locations(switches);
    if nl == 1
        if switches.calValueLocal  ||  !(switches.valueLocal == zero(F1))
            isValid = false;
            @warn  "Cannot have local value with one location"
        end
    end
    return isValid
end


## ---------------  Entry Decision constructor

function init_entry_decision(objId :: ObjectId, 
    switches :: EntryDecisionSwitches{F1}) where F1

    pEntryPref = init_entry_prefscale(switches);
    pValueLocal = init_value_local(switches);
    pvec = ParamVector(objId, [pEntryPref, pValueLocal]);
    return EntryDecision(objId, pvec, ModelParams.value(pEntryPref), 
        ModelParams.value(pValueLocal), switches)
end

function init_value_local(switches :: EntryDecisionSwitches{F1}) where F1
    if n_locations(switches) == 1
        # Cannot have local value
        valueLocal = zero(F1);
        calValueLocal = false;
    else
        valueLocal = switches.valueLocal;
        calValueLocal = switches.calValueLocal;
    end

    ub = max(F1(5.0), valueLocal + 2.0);
    pEntryPref = Param(:valueLocal, "Value of local college",
        "vLocal", valueLocal, valueLocal, F1(0.0), ub, 
        calValueLocal);
    return pEntryPref
end



## ------------  Entry decisions

"""
    $(SIGNATURES)

Compute entry probabilities and expected values at entry from admission rule and entry decision objects.

It is possible to solve for a subset of types. Only those listed in `rank_jV` will be solved. But keep in mind that capacity constraints may then not bind.

The type dimension of the `EntryResults` object matches that of the `EntryDecision`.

Optional: solve each student's entry decision without preference shocks, but continue to update enrollments with preference shocks. This is useful to diagnose how important preference shocks are.

Note that multiple locations only matter if they are not identical. If all colleges are available in all locations (and not full), the fraction going local (conditional on entry) is only a function of the number of locations and the value of going local. `vCollege_jcM` and `vWork_jV` do not matter. This is easy to check analytically.
"""
function entry_decisions(entryS :: EntryDecision{F1}, 
    admissionS :: AbstractAdmissionsRule{I1, F1}, 
    vWork_jV :: Vector{F1}, vCollege_jcM :: Matrix{F1}, 
    endowPctV :: Vector{F1},
    rank_jV :: Vector{I2};
    prefShocks :: Bool = true) where {I1, I2 <: Integer, F1}

    # nTypes = n_types(entryS);
    nc = n_colleges(entryS);
    nl = n_locations(entryS);
    er = EntryResults(entryS.switches);

    # Loop over students in order of ranking
    for j in rank_jV
        # Loop over student locations in ascending order
        # We are now processing student (j, l)
        for l = 1 : nl
            full_clM = (enrollment_cl(er) .>= capacities(entryS));

            # This is the standard one-step entry decision, but with colleges from all locations stacked.
            entryProb_clM, er.eVal_jlM[j, l], entryProbBest_clM = 
                entry_decisions_one_student(
                    entryS, admissionS, vWork_jV[j], vCollege_jcM[j,:],
                    endowPctV[j], full_clM, l; prefShocks = true);

            # Record enrollment
            typeMass = type_mass_jl(entryS, j, l);
            er.enroll_clM .+= typeMass .* entryProb_clM;
            er.enrollLocal_clM[:,l] .+= typeMass .* entryProb_clM[:,l];
            er.enrollBest_clM .+= typeMass .* entryProbBest_clM;

            if !prefShocks 
                # Solve again without pref shocks
                # But enrollment is determined by original problem
                entryProb_clM, er.eVal_jlM[j, l], entryProbBest_clM = 
                    entry_decisions_one_student(
                        entryS, admissionS, vWork_jV[j], vCollege_jcM[j,:],
                        endowPctV[j], full_clM, l; prefShocks = false);
            end    
    
            # Record entry probs
            entryProb_cV = vec(sum(entryProb_clM, dims = 2));
            make_valid_probs!(entryProb_cV);
            # Fraction entering any `c` college; local or not.
            er.fracEnter_jlcM[j,l,:] .= entryProb_cV;
            
            # Probability of entering college `c` as the best college
            entryProbBest_cV = vec(sum(entryProbBest_clM, dims = 2));
            make_valid_probs!(entryProbBest_cV);
            er.fracEnterBest_jlcM[j,l,:] .= entryProbBest_cV;
            # Fraction entering a local `c` college.
            er.fracLocal_jlcM[j,l,:] = entryProb_clM[:,l];
        end
    end

    @assert validate_er(er; validateFracLocal = prefShocks)
    return er
end


# # College enrollments of student `j` in `l`
# function enrollment_cl(entryS :: EntryDecision{F1}, 
#     entryProb_clM :: Matrix{F1}, j :: Integer, l :: Integer) where F1

#     return entryProb_clM .* type_mass_jl(entryS, j, l)
# end

# --------------