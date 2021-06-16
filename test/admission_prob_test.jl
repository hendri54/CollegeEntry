using Test
using ModelObjectsLH
using CollegeEntry

ce = CollegeEntry;

function adm_prob_test()
    @testset "Admission prob fct" begin
        nc = 4;
        switches = ce.make_test_admprob_fct_logistic_switches(nc);
        af = init_admprob_fct(switches);
        @test ce.validate_admprob_fct(af);

        @test !ce.by_college(switches, :pMinV);
        ce.by_college!(switches, :pMinV);
        @test ce.by_college(switches, :pMinV);
        ce.not_by_college!(switches, :pMinV);
        @test !ce.by_college(switches, :pMinV);

        xV = 0.01 : 0.1 : 0.99;
        for ic = 1 : nc
            f = make_admprob_function(af, ic);
            probV = f.(xV);
            @test size(probV) == size(xV);
            @test all(0.0 .<= probV .<= 1.0);
            @test all(diff(probV) .>= 0.0);
        end
    end
end


@testset "Admission probs" begin
    adm_prob_test();
end

# ----------------