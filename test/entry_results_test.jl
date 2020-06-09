using Random, Test

function entry_results_test(switches)
    @testset "Entry results" begin
        F1 = Float64;
        println("\n----------");
        println(switches);

        er = make_test_entry_results(switches);

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
        @test isapprox(entryProbLocal_jV,  vec(sum(entryProbLocal_jcM, dims = 2)))
        @test isa(entryProbLocal_jV, Vector)
        entryProbNonLocal_jV = entry_probs_j(er, :nonlocal);
        @test isa(entryProbNonLocal_jV, Vector)
        @test isapprox(entryProbNonLocal_jV,  sum(entryProbNonLocal_jcM, dims = 2))
        @test isapprox(entry_probs_j(er), 
            entryProbLocal_jV .+ entryProbNonLocal_jV)

        typeMasses = type_mass_jl(er);
        @test all(typeMasses .>= 0.0)
        @test size(typeMasses) == (J, nl)

        @test size(expected_values_jl(er)) == (J, nl)
        @test size(colleges_full(er)) == (nc, nl)

        @test size(enrollment_cl(er)) == (nc, nl)
        enroll_clM = enrollment_cl(er);
        for ic = 1 : nc
            @test isapprox(enroll_clM[ic,:], enrollment_cl(er, ic))
        end

        fracLocal_jV = frac_local_j(er);
        fracLocal_cV = frac_local_c(er);
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
            @test all(0.0 .< fracLocal_jV .< one(F1))
            @test isa(fracLocal_jV, Vector)
            @test length(fracLocal_jV) == J

            @test all(0.0 .< fracLocal_cV .< one(F1))
            @test isa(fracLocal_cV, Vector)
            @test length(fracLocal_cV) == nc
        end
	end
end


function subset_er_test(switches)
    @testset "Subset entry results" begin
        er = make_test_entry_results(switches);
        idxV = 2 : 2 : n_types(er);
        er2 = CollegeEntry.subset_types(er, idxV);
        @test validate_er(er2; validateFracLocal = false)
        @test n_types(er2) == length(idxV)
    end
end


function fix_type_probs_test(switches)
    rng = MersenneTwister(95);
	@testset "Fix type entry probs" begin
        er = make_test_entry_results(switches);
        fracLocal_jV = frac_local_j(er);

        J = n_types(er);
        typeTotalV = 0.3 .+ 0.6 .* rand(rng, J);
        CollegeEntry.fix_type_entry_probs!(er, typeTotalV);

        @test isapprox(entry_probs_j(er, :all),  typeTotalV)
        @test isapprox(frac_local_j(er), fracLocal_jV)
    end
end

@testset "Entry Results" begin
    for switches in test_entry_switches(8, 3)
        entry_results_test(switches)
        subset_er_test(switches)
        fix_type_probs_test(switches)
    end
end

# --------------