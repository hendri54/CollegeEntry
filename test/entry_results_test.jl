function entry_results_test(switches)
    @testset "Entry results" begin
        F1 = Float64;
        println("\n----------");
        println(switches);

        er = CollegeEntry.make_test_entry_results(switches);

        J = n_types(switches);
        nc = n_colleges(switches);
        nl = n_locations(switches);

        @test all(capacities(er) .>= 0.0)

        entryProbLocal_jcM = entry_probs(er, :local);
        entryProbNonLocal_jcM = entry_probs(er, :nonlocal);
        entryProb_jcM = entry_probs(er);
        @test all(0.0 .<= entryProbLocal_jcM .<= 1.0)
        @test all(0.0 .<= entryProbNonLocal_jcM .<= 1.0)
        @test all(0.0 .<= entryProb_jcM .<= 1.0)
        @test isapprox(entryProb_jcM, entryProbLocal_jcM .+ entryProbNonLocal_jcM)
        
        entryProbLocal_jV = type_entry_probs(er, :local);
        @test isapprox(entryProbLocal_jV,  sum(entryProbLocal_jcM, dims = 2))
        entryProbNonLocal_jV = type_entry_probs(er, :nonlocal);
        @test isapprox(entryProbNonLocal_jV,  sum(entryProbNonLocal_jcM, dims = 2))
        @test isapprox(type_entry_probs(er), 
            entryProbLocal_jV .+ entryProbNonLocal_jV)

        typeMasses = type_masses(er);
        @test all(typeMasses .> 0.0)
        @test size(typeMasses) == (J, nl)

        @test size(expected_values(er)) == (J, nl)
        @test size(colleges_full(er)) == (nc, nl)

        @test size(enrollments(er)) == (nc, nl)
        enroll_clM = enrollments(er);
        for ic = 1 : nc
            @test isapprox(enroll_clM[ic,:], CollegeEntry.enrollment(er, ic))
        end

        if nl == 1
            @test length(capacities(er)) == nc

            @test frac_local(er) == one(F1);
            @test frac_local_by_type(er) == ones(F1, J)
            @test frac_local_by_college(er) == ones(F1, nc)
            # This may not hold in test data
            # @test all(0.0 .<= enrollments(er) .< capacities(er) .* 1.2)
            # enroll_cV = enrollments(er);
            # for ic = 1 : nc
            #     @test isapprox(enroll_cV[ic], CollegeEntry.enrollment(er, ic))
            # end
            
        else
            @test 0.0 < frac_local(er) < 1.0
            @test all(0.0 .< frac_local_by_type(er) .< one(F1))
            @test length(frac_local_by_type(er)) == J
            @test all(0.0 .< frac_local_by_college(er) .< one(F1))
            @test length(frac_local_by_college(er)) == nc
        end
	end
end

@testset "Entry Results" begin
    for switches in test_entry_switches(8, 3)
        entry_results_test(switches)
    end
end

# --------------