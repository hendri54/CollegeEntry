function access_test(switches)
    @testset "Access routines" begin
        println("\n--------------------------")
        println(switches);
        objId = ObjectId(:entryDecision);
        e = init_entry_decision(objId, switches);
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
        @test all(typeMass_jlM .> 0.0)
        for j = 1 : J
            @test isapprox(typeMass_jlM[j,:], type_mass_jl(e, j))
        end

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


# Test `entry_probs` which has no notion of locations
function entry_test(switches)
    @testset "Entry probs" begin
        F1 = Float64;
        e = init_entry_decision(ObjectId(:entry), switches);
        println("\n------------")
        println(e);

        J = n_types(e);
        nc = n_colleges(e);
        vWork_jV = collect(range(-0.1, 2.2, length = J));
        vCollege_jcM = range(1.0, 2.0, length = J) * 
            collect(range(-0.5, 1.5, length = nc))';
        admitV = [1, 3];
        rejectV = [2];
        prob_jcM, eVal_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV);
        @test all(prob_jcM .>= 0.0)
        @test all(prob_jcM .<= 1.0)
        @test size(prob_jcM) == (J, nc)
        @test size(eVal_jV) == (J,)
        @test all(prob_jcM[:, rejectV] .== 0.0)

        # One person at a time
        for j = 1 : J
            prob_cV, eVal = 
                entry_probs(e, vWork_jV[j], vCollege_jcM[j,:], admitV);
            @test isapprox(prob_cV, prob_jcM[j,:])
            @test isapprox(eVal, eVal_jV[j])
        end

        # Increasing a value should increase probability
        # Not for limited capacities, though
        if !limited_capacity(e)
            idx = admitV[end];
            otherAdmitV = admitV[1 : (end-1)];
            vCollege_jcM[:, idx] .+= 0.1;
            prob2_jcM, eVal2_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV);
            @test all(prob2_jcM[:, idx] .> prob_jcM[:, idx])
            @test all(prob2_jcM[:, otherAdmitV] .< prob_jcM[:, otherAdmitV])
            @test all(eVal2_jV .> eVal_jV)
        end

        # Empty admission set
        prob_jcM, eVal_jV = entry_probs(e, vWork_jV, vCollege_jcM, []);
        @test size(prob_jcM) == (J, nc)
        @test all(prob_jcM .== 0.0)
        # if !isa(e, EntryTwoStep)
            @test isapprox(eVal_jV, vWork_jV)
        # end
    end
end

@testset "All" begin
    J = 8; nc = 3;
    for switches in test_entry_switches(J, nc)
        access_test(switches);
        entry_test(switches);
    end
end

# --------------