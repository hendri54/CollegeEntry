using Test
using ModelObjectsLH
using CollegeEntry

ce = CollegeEntry;

function adm_prob_test(switches)
    @testset "$switches" begin
        af = init_admprob_fct(switches);
        @test ce.validate_admprob_fct(af);
        @test get_object_id(af) isa ObjectId;
        @test get_object_id(switches) isa ObjectId;

        if af isa AdmProbFctLogistic
            ce.by_college!(switches, :pMinV);
            @test ce.by_college(switches, :pMinV);
            ce.not_by_college!(switches, :pMinV);
            @test !ce.by_college(switches, :pMinV);
        end

        xV = 0.01 : 0.1 : 0.99;
        for ic = 1 : n_colleges(af)
            f = make_admprob_function(af, ic);
            probV = f.(xV);
            @test size(probV) == size(xV);
            @test all(0.0 .<= probV .<= 1.0);
            @test all(diff(probV) .>= 0.0);

            prob2V = prob_admit(af, ic, xV);
            @test isapprox(probV, prob2V);
        end
    end
end


@testset "Admission probs" begin
    nc = 4;
    for switches in (
        ce.make_test_admprob_fct_logistic_switches(nc),
        AdmProbFctOpenSwitches{Float64}(ObjectId(:test), nc)
        )
        adm_prob_test(switches);
    end
end

# ----------------