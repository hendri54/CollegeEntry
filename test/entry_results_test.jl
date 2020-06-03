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

        entryProbLocal_jcM = entry_probs_jc(er, :local);
        entryProbNonLocal_jcM = entry_probs_jc(er, :nonlocal);
        entryProb_jcM = entry_probs_jc(er);
        @test all(0.0 .<= entryProbLocal_jcM .<= 1.0)
        @test all(0.0 .<= entryProbNonLocal_jcM .<= 1.0)
        @test all(0.0 .<= entryProb_jcM .<= 1.0)
        @test isapprox(entryProb_jcM, entryProbLocal_jcM .+ entryProbNonLocal_jcM)
        
        entryProbLocal_jV = entry_probs_j(er, :local);
        @test isapprox(entryProbLocal_jV,  sum(entryProbLocal_jcM, dims = 2))
        entryProbNonLocal_jV = entry_probs_j(er, :nonlocal);
        @test isapprox(entryProbNonLocal_jV,  sum(entryProbNonLocal_jcM, dims = 2))
        @test isapprox(entry_probs_j(er), 
            entryProbLocal_jV .+ entryProbNonLocal_jV)

        typeMasses = type_mass_jl(er);
        @test all(typeMasses .> 0.0)
        @test size(typeMasses) == (J, nl)

        @test size(expected_values_jl(er)) == (J, nl)
        @test size(colleges_full(er)) == (nc, nl)

        @test size(enrollment_cl(er)) == (nc, nl)
        enroll_clM = enrollment_cl(er);
        for ic = 1 : nc
            @test isapprox(enroll_clM[ic,:], enrollment_cl(er, ic))
        end

        if nl == 1
            @test length(capacities(er)) == nc

            @test frac_local(er) == one(F1);
            @test frac_local_j(er) == ones(F1, J)
            @test frac_local_c(er) == ones(F1, nc)
            # This may not hold in test data
            # @test all(0.0 .<= enrollments(er) .< capacities(er) .* 1.2)
            # enroll_cV = enrollments(er);
            # for ic = 1 : nc
            #     @test isapprox(enroll_cV[ic], CollegeEntry.enrollment(er, ic))
            # end
            
        else
            @test 0.0 < frac_local(er) < 1.0
            @test all(0.0 .< frac_local_j(er) .< one(F1))
            @test length(frac_local_j(er)) == J
            @test all(0.0 .< frac_local_c(er) .< one(F1))
            @test length(frac_local_c(er)) == nc
        end
	end
end

@testset "Entry Results" begin
    for switches in test_entry_switches(8, 3)
        entry_results_test(switches)
    end
end

# --------------