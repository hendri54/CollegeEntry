using Random, Test
using LatexLH, ModelParams, CollegeEntry

ce = CollegeEntry;

function constructor_test()
    @testset "Constructors" begin
        J = 8; nc = 3;
        switches = make_entry_switches_oneloc(J, nc);
        @test validate_es(switches)
    end
end

function access_test(switches)
    @testset "Access routines" begin
        println("\n--------------------------")
        println(switches);
        objId = ObjectId(:entryDecision);
        st = ce.make_test_symbol_table();
        e = init_entry_decision(objId, switches, st);
        println(e);

        J = n_types(e);
        nc = n_colleges(e);
        nl = n_locations(e);

        @test 0.0 < min_entry_prob(e) < max_entry_prob(e) < 1.0
        @test entry_pref_scale(e) > 0.0

        @test isa(CollegeEntry.value_local(e), Float64)
        
        capacityV = capacities(e);
        if any(capacityV .< 1e6)
            @test CollegeEntry.limited_capacity(e)
        else
            @test !CollegeEntry.limited_capacity(e)
        end

        typeMass_jlM = type_mass_jl(e);
        @test size(typeMass_jlM) == (J, nl)
        @test all(typeMass_jlM .>= 0.0)
        for j = 1 : J
            @test isapprox(typeMass_jlM[j,:], type_mass_jl(e, j))
            @test isapprox(sum(typeMass_jlM[j,:]),  type_mass_j(e, j))
        end
        @test type_mass_jl(e, J, nl) == typeMass_jlM[J, nl]

        capacity_clM = capacities(e);
        @test size(capacity_clM) == (nc, nl)
        for ic = 1 : nc
            @test isapprox(capacity_clM[ic,:], CollegeEntry.capacity(e, ic))
        end

        if nl == 1
            @test CollegeEntry.value_local(e) == 0.0
        end
    end
end


function subset_switches_test(switches)
    @testset "Subset switches" begin
        idxV = 2 : 2 : n_types(switches);
        CollegeEntry.subset_types!(switches, idxV);
        @test validate_es(switches)
        @test n_types(switches) == length(idxV)
	end
end


# Test `entry_probs` which has no notion of locations
function entry_test(switches, prefShocks :: Bool)
    rng = MersenneTwister(49);
    @testset "Entry probs" begin
        F1 = Float64;
        st = ce.make_test_symbol_table();
        e = init_entry_decision(ObjectId(:entry), switches, st);
        println("\n------------")
        println(e);
        println("Preference shocks: $prefShocks");

        J = n_types(e);
        nc = n_colleges(e);
        nl = n_locations(e);
        vWork_jV, vCollege_jcM = CollegeEntry.values_for_test(rng, J, nc, nl);
        admitV = [1, 3];
        rejectV = [2];
        prob_jcM, eVal_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV;
            prefShocks = prefShocks);
        @test all(prob_jcM .>= 0.0)
        @test all(prob_jcM .<= 1.0)
        @test size(prob_jcM) == (J, nc)
        @test size(eVal_jV) == (J,)
        @test all(prob_jcM[:, rejectV] .== 0.0)

        # One person at a time
        for j = 1 : J
            prob_cV, eVal = 
                entry_probs(e, vWork_jV[j], vCollege_jcM[j,:], admitV;
                    prefShocks = prefShocks);
            @test isapprox(prob_cV, prob_jcM[j,:])
            @test isapprox(eVal, eVal_jV[j])
        end

        # Increasing a value should increase probability
        # Not for limited capacities, though
        # Also not without pref shocks
        if !limited_capacity(e)  &&  prefShocks
            idx = admitV[end];
            otherAdmitV = admitV[1 : (end-1)];
            vCollege_jcM[:, idx] .+= 0.1;
            prob2_jcM, eVal2_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV;
                prefShocks = prefShocks);
            @test all(prob2_jcM[:, idx] .> prob_jcM[:, idx])
            @test all(prob2_jcM[:, otherAdmitV] .< prob_jcM[:, otherAdmitV])
            @test all(eVal2_jV .> eVal_jV)
        end

        # Empty admission set
        prob_jcM, eVal_jV = entry_probs(e, vWork_jV, vCollege_jcM, [];
            prefShocks = prefShocks);
        @test size(prob_jcM) == (J, nc)
        @test all(prob_jcM .== 0.0)
        # if !isa(e, EntryTwoStep)
            @test isapprox(eVal_jV, vWork_jV)
        # end
    end
end


# Check that small preference shocks give about the same answer as no preference shocks
function small_pref_entry_test(switches)
    rng = MersenneTwister(49);
    @testset "Entry probs" begin
        F1 = Float64;
        ce.set_pref_scale!(switches, 0.001);
        st = ce.make_test_symbol_table();
        e = init_entry_decision(ObjectId(:entry), switches, st);
        println("\n------------")
        println(e);

        J = n_types(e);
        nc = n_colleges(e);
        nl = n_locations(e);
        vWork_jV, vCollege_jcM = CollegeEntry.values_for_test(rng, J, nc, nl);
        admitV = [1, 3];
        rejectV = [2];

        prob_jcM, eVal_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV;
            prefShocks = true);
        @test all(prob_jcM .>= 0.0)
        @test all(prob_jcM .<= 1.0)
        @test size(prob_jcM) == (J, nc)
        @test size(eVal_jV) == (J,)
        @test all(prob_jcM[:, rejectV] .== 0.0)

        prob2_jcM, eVal2_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV;
            prefShocks = false);
        @test isapprox(prob_jcM, prob2_jcM, atol = 0.01)
        @test isapprox(eVal_jV, eVal2_jV, rtol = 0.01)
    end
end


function sim_entry_test(switches)
    @testset "Simulate Entry probs" begin
        rng = MersenneTwister(123);
        F1 = Float64;
        st = ce.make_test_symbol_table();
        e = init_entry_decision(ObjectId(:entry), switches, st);
        println("\n------------")
        println(e);

        J = n_types(e);
        nc = n_colleges(e);
        nl = n_locations(e);
        vCollege_clM = test_value_cl(rng, nc, nl);
        vWork = 1.0 .+ sum(vCollege_clM) / length(vCollege_clM);
        avail_clM = rand(rng, Bool, nc, nl);
        # Make sure one college is available
        avail_clM[1,1] = true;

        prob_clV, eVal = entry_probs(e, vWork, vec(vCollege_clM), vec(avail_clM));
        prob_clM = reshape(prob_clV, nc, nl);
        @test !any(prob_clM[.!avail_clM] .> 0.0)

        nSim = Int(1e5);
        prob2_clM, eVal2 = CollegeEntry.sim_entry_probs(e, 
            vWork, vCollege_clM, avail_clM, 
            nSim, rng);
        @test !any(prob2_clM[.!avail_clM] .> 0.0)

        @test isapprox(eVal, eVal2, atol = 0.05)
        @test isapprox(prob_clM, prob2_clM, atol = 0.02)
    end
end


function scale_entry_probs_test()
    rng = MersenneTwister(123);
    @testset "Scale entry probs" begin
        J = 30; nl = 4; nc = 5;
        entryProb_jlcM = make_test_entry_probs(rng, J, nc, nl);
        minEntryProb = 0.03;
        maxEntryProb = 0.8;
        scale_entry_probs!(entryProb_jlcM, minEntryProb, maxEntryProb);
        entryProb_jlM = sum(entryProb_jlcM, dims = 3);
        @test all(entryProb_jlM .< maxEntryProb + 0.01)
        @test all(entryProb_jlcM .> 0.0)

        # With probs in range, nothing should change
        entryProb_jlcM = fill(minEntryProb + 0.01, J, nl, nc);
        entryProb2_jlcM = copy(entryProb_jlcM);
        scale_entry_probs!(entryProb_jlcM, minEntryProb, maxEntryProb);
        @test isapprox(entryProb_jlcM, entryProb2_jlcM)
	end
end


@testset "All" begin
    constructor_test()
    scale_entry_probs_test();
    
    J = 8; nc = 3;
    for switches in test_entry_switches(J, nc)
        access_test(switches);
        subset_switches_test(switches);
        for prefShocks ∈ (true, false)
            entry_test(switches, prefShocks);
            small_pref_entry_test(switches);
        end
        sim_entry_test(switches);
    end
end

# --------------