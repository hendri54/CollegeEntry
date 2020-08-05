using Random, Test
using CollegeEntry

ce = CollegeEntry;

function max_choice_test()
    rng = MersenneTwister(12);
    vWork = 1.0;
    vCollege_cV = [0.5, 3.0];
    v, ic = ce.max_choice(vWork, vCollege_cV, [true, true]);
    @test v == 3.0  &&  ic == 2
    v, ic = ce.max_choice(vWork, vCollege_cV, [true, false]);
    @test v == vWork  &&  ic == 0
    v, ic = ce.max_choice(vWork, vCollege_cV, [false, false]);
    @test v == vWork  &&  ic == 0

    J = 5;
    nc = 7;
    vWorkV = randn(rng, J);
    vCollege_jcM = rand(rng, J, nc);
    admitV = rand(rng, Bool, nc);
    vV, icV = ce.max_choices(vWorkV, vCollege_jcM, admitV);
    for j = 1 : J
        v, ic = ce.max_choice(vWorkV[j], vec(vCollege_jcM[j,:]), admitV);
        @test isapprox(vV[j], v)  &&  isequal(icV[j], ic)
    end
end

function helpers_test()
    @testset "Helpers" begin
        x = rand(4,3,2) ./ 5.0;
        x[2 : 2 : 8] .= -0.000000001;
        x ./= sum(x);
        x .+= 0.000000001;
        CollegeEntry.make_valid_probs!(x);
        @test sum(x) <= 1.0
        @test all(x .>= 0.0)
	end
end

@testset "Helpers" begin
    max_choice_test()
    helpers_test()
end

# -------------