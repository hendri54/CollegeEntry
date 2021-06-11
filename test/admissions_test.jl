using Test
using CollegeEntry, StructLH

function common_test(a :: T1) where T1 <: AbstractAdmissionsRule
    @testset "$a" begin
        println("\n------------------");
        println(a);

        # Want these increasing
        hsGpaPctV = 0.01 : 0.2 : 0.99;
        J = length(hsGpaPctV);

        @test validate_admissions(a)
        # println(a);
        println(StructLH.describe(a));
        nSets = n_college_sets(a);
        @test nSets >= 1
        @test n_colleges(a) > 1

        prob_jsM = zeros(J, nSets);
        for (iSet, cs) in enumerate(a)
            @test isa(collect(cs), Vector{<: Integer})
            @test isequal(cs,  college_set(a, iSet))
            setProbV = prob_coll_set(a, iSet, hsGpaPctV);
            @test all(setProbV .>= 0.0)
            @test all(setProbV .<= 1.0)
            # Cannot compare size b/c the size of a scalar is `nothing`
            @test length(setProbV) == length(hsGpaPctV)
            prob_jsM[:, iSet] = setProbV;

            # for j = 1 : J
            #     prob = CollegeStrat.prob_coll_set(a, iSet, hsGpaPctV[j]);
            #     @test isapprox(setProbV[j], prob, atol = 1e-6)
            # end
        end
        @test all(isapprox.(sum(prob_jsM, dims = 2), 1.0, atol = 1e-6))

        prob_jcM = admission_probs(a, hsGpaPctV);
        @test all(prob_jcM .>= 0.0)  &&  all(prob_jcM .<= 1.0)
        # Higher GPA students should be more likely to get into each college
        @test all(diff(prob_jcM, dims = 1) .>= -1e-8)
        # Better colleges should be harder to get into
        @test all(diff(prob_jcM, dims = 2) .<= 1e-8)
    end
end


function gpa_cutoff_test(a :: AdmissionsCutoff)
    @testset "GPA cutoff" begin
        println("\n----------------------");
        println(a);
        
        # a = CollegeStrat.make_test_admissions_gpa(4);
        hsGpaPctV = 0.01 : 0.3 : 0.99;
        highV = CollegeEntry.highest_college(a, hsGpaPctV);
        @test isa(highV, Vector{<: Integer})
        @test all(diff(highV) .>= 0)
        @test highV[1] == 1
        @test highV[end] == n_colleges(a);

        # Better students should have higher prob of "better" college set
        nSets = n_college_sets(a);
        probV = prob_coll_set(a, nSets, hsGpaPctV);
        @test all(diff(probV) .>= 0)
        @test probV[end] > probV[1]
    end
end


@testset "Admission Rules" begin
    nc = 4;
    for a in [CollegeEntry.make_test_admissions_open(nc),
        CollegeEntry.make_test_admissions_cutoff(nc),
        CollegeEntry.make_test_admissions_onevar(nc)]

        common_test(a);

        if isa(a, AdmissionsCutoff)
            gpa_cutoff_test(a);
        end
    end
end

# --------------