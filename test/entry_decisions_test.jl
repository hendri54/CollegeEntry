using Random, Test
using LatexLH, ModelParams, CollegeEntry

ce = CollegeEntry;


# The code uses the fact that reshape undoes vec. This is tested here.
function reshape_test()
    @testset "reshape" begin
        rng = MersenneTwister(123);
        sizeV = (4,3,2);
        x = rand(rng, sizeV...);
        v = vec(x);
        @test isapprox(x, reshape(v, sizeV...))
    end
end


function best_available_test()
    @testset "best available" begin
        nc = 4;
        nl = 3;
        avail_clM = falses(nc, nl);
        avail_clM[1,2] = true;
        @test ce.best_available(avail_clM) == 1
        avail_clM[nc, nl] = true;
        @test ce.best_available(avail_clM) == nc
        avail_clM[1 : (nc-1),:] .= true;
        @test ce.best_available(avail_clM) == nc
	end
end


function entry_decisions_test(switches :: AbstractEntrySwitches{F1},
    admissionS, prefShocks :: Bool; takeSubset :: Bool = false) where F1

    rng = MersenneTwister(12);
    println("\n------------------------");
    println(switches);
    objId = ObjectId(:entryOneStep);
    st = ce.make_test_symbol_table();
    entryS = init_entry_decision(objId, switches, st);
    println(entryS, "  Pref shocks: $prefShocks");

    if takeSubset
        idxV = 1 : 3 : n_types(switches);
        subset_types!(entryS, idxV);
        @test n_types(entryS) == length(idxV)
        @test validate_es(entryS.switches)
    end

    nc = n_colleges(switches);
    J = n_types(switches);
    nl = n_locations(switches)
    vWork_jV, vCollege_jcM = CollegeEntry.values_for_test(rng, J, nc, nl);
    hsGpaPctV = collect(range(0.1, 0.9, length = J));
    rank_jV = vcat(2 : 2 : J, 1 : 2 : J);

    er = entry_decisions(entryS, admissionS,
        vWork_jV, vCollege_jcM, hsGpaPctV, rank_jV; prefShocks = prefShocks);
    @test validate_er(er; validateFracLocal = prefShocks)
    entryProb_jcM = entry_probs_jc(er);
    eValM = expected_values_jl(er);
    # Need interior entry probs. Otherwise adjust values.
    # Unless there are no pref shocks - then probs are always 0 and 1
    if all(entry_probs_j(er) .< 0.2)  &&  prefShocks
        @warn "Entry probs too low:  $(entry_probs_j(er))"
        @test false
    end
    @test any(entry_probs_j(er) .< 0.8)

    # Switching off preference shocks should not affect entry
    if prefShocks
        er2 = entry_decisions(entryS, admissionS,
            vWork_jV, vCollege_jcM, hsGpaPctV, rank_jV; prefShocks = false);
        @test isapprox(enrollment_cl(er2), enrollment_cl(er), rtol = 0.005);
        @test isapprox(frac_local_c(er2), frac_local_c(er), atol = 0.005);
    end

    # # Computing fracLocal across colleges and across types should give the same answer
    # fracLocal = frac_local(er);
    # fracLocal2 = sum(frac_local_c(er) .* enrollment_c(er)) / sum(enrollment_c(er));
    # @test isapprox(fracLocal, fracLocal2)
    # entryMass_jV = entry_probs_j(er, :all) .* type_mass_j(er);
    # fracLocal3 = sum(frac_local_j(er) .* entryMass_jV) / sum(entryMass_jV);
    # @test isapprox(fracLocal3, fracLocal)

    # Entry results methods
    if n_locations(er) == 1
        @test frac_local(er) == 1.0
        @test all(frac_local_j(er) .== 1.0)
        @test all(frac_local_c(er) .== 1.0)
    elseif prefShocks
        @test 0.0 < frac_local(er) < 1.0
        @test all(0.0 .< frac_local_j(er) .< 1.0)
        # Frac local can be 1 when a college is local only
        @test all(0.0 .< frac_local_c(er) .<= 1.0)        
    end

    # Check implied properties
    totalMass = sum(type_mass_jl(er));
    
    # Solving one student at a time should give the same answer IF no colleges are full.
    for j = 1 : J
        if nl == 1
            entryProb_cV, eVal, entryProbBest_clM = ce.entry_decisions_one_student(
                entryS, admissionS,
                vWork_jV[j], vCollege_jcM[j,:], hsGpaPctV[j], fill(false, nc);
                prefShocks = prefShocks);
            @test sum(entryProb_cV) .<= 1.0
            # Not having full colleges should increase value
            @test eVal >= eValM[j]
            # And it should increase entry - unless we have no pref shocks
            if prefShocks
                @test sum(entryProb_cV) > sum(entryProb_jcM[j,:] .- 1e-5)
            end
            if !any(colleges_full(er))
                @test isapprox(entryProb_cV, entryProb_jcM[j,:])
                @test isapprox(eVal, eValM[j])
            end

        else
            # Solver for student in one location
            for l = 1 : nl
                entryProb_clM, eVal, entryProbBest_clM = ce.entry_decisions_one_student(
                    entryS, admissionS,  vWork_jV[j], vCollege_jcM[j,:], 
                    hsGpaPctV[j], fill(false, nc, nl), l;
                    prefShocks = prefShocks);
                @test all(sum(entryProb_clM, dims = 2) .<= 1.0)
                # Not having full colleges should increase value
                @test eVal >= eValM[j, l]
            end
        end
    end
end


# function subset_types_test(admissionS)
#     @testset "Subset types" begin
#         J = 8; nc = 3; nl = 4;

#         vWork_jV = collect(range(-0.5, 1.5, length = J));
#         vCollege_jcM = range(-0.2, 1.2, length = J) * range(1.0, 2.0, length = nc)';
#         hsGpaPctV = collect(range(0.1, 0.9, length = J));
#         rank_jV = vcat(2 : 2 : J, 1 : 2 : J);

#         # solve for all
#         e = CollegeEntry.make_test_entry_sequ_multiloc(J, nc, nl, Float64(1e8));
#         er = entry_decisions(e, admissionS,
#             vWork_jV, vCollege_jcM, hsGpaPctV, rank_jV);
#         @test validate_er(er)
#         entryProb_jcM = entry_probs_jc(er);
#         eValM = expected_values_jl(er);

#         # solve for subset; should yield same solution without capacity constraints
#         typeV = collect(2 : 2 : J);
#         e2 = copy_for_subset_of_types(e, typeV);
#         er2 = entry_decisions(e2, admissionS,
#             vWork_jV[typeV], vCollege_jcM[typeV], hsGpaPctV[typeV], 
#             1 : length(typeV));

#         @test isapprox(entryProb_jcM[typeV,:], entry_probs_jc(e2))
#         @test isapprox(eValM[typeV,:], expected_values_jl(e2))
# 	end
# end


function sim_entry_one_test(switches :: AbstractEntrySwitches{F1},
    admissionS) where F1

    rng = MersenneTwister(32);
	@testset "Simulate entry decision one student" begin
        println("\n------------------------");
        println(switches);
        objId = ObjectId(:entryOneStep);
        st = ce.make_test_symbol_table();
        entryS = init_entry_decision(objId, switches, st);
        println(entryS);

        nSim = Int(1e5);
        nc = n_colleges(switches);
        J = n_types(switches);
        nl = n_locations(switches)
        vWork_jV, vCollege_jcM = CollegeEntry.values_for_test(rng, J, nc, nl);
        vWork = vWork_jV[1];
        vCollege_cV = vCollege_jcM[1,:];
        endowPct = 0.7;
        full_clM = rand(rng, Bool, nc, nl);
        full_clM[1,1] = false;
        l = nl;

        prob_clM, eVal, entryProbBest_clM = ce.entry_decisions_one_student(
            entryS, admissionS, vWork, vCollege_cV, 
            endowPct, full_clM, l);
        # Check that bounded away from 0, 1
        @test sum(prob_clM) < 0.85
        @test sum(prob_clM) > 0.15

        @test CollegeEntry.check_prob_array(prob_clM)
        # If all corners, nothing to be tested
        @test all(prob_clM .< 0.9)

        probSim_clM, eValSim = CollegeEntry.sim_one_student(
            entryS, admissionS, vWork, vCollege_cV, 
            endowPct, full_clM, l, nSim, rng);
        
        probGap = maximum(abs.(probSim_clM .- prob_clM));
        println("Max prob_cl gap:  ", probGap);
        if probGap > 1e-2
            show_matrix(probSim_clM; header = "Simulated");
            show_matrix(prob_clM; header = "Solved");
        end
        @test isapprox(probSim_clM, prob_clM, atol = 1e-2)
        @test isapprox(eValSim, eVal, rtol = 2e-2)
    end
end

@testset "Entry decisions" begin
    J = 8;
    nc = 4;
    admissionS = CollegeEntry.make_test_admissions_cutoff(nc);
    # The last case ensures that some colleges are full
    for switches in test_entry_switches(J, nc)
        for prefShocks ∈ [true, false]
            entry_decisions_test(switches, admissionS, prefShocks);
        end
        sim_entry_one_test(switches, admissionS);
    end

    # Test with subsetting
    J = 21;
    switches = make_test_entry_sequ_multiloc(J, nc, nc + 1, 0.3 * J * nc);
    entry_decisions_test(switches, admissionS, true; takeSubset = true);

    reshape_test()
    # subset_types_test(admissionS)
end

# -----------