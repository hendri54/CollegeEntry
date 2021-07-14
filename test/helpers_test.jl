using Random, Test
using CollegeEntry

mdl = CollegeEntry;

function max_choice_test()
    rng = MersenneTwister(12);
    vWork = 1.0;
    vCollege_cV = [0.5, 3.0];
    v, ic = mdl.max_choice(vWork, vCollege_cV, [true, true]);
    @test v == 3.0  &&  ic == 2
    v, ic = mdl.max_choice(vWork, vCollege_cV, [true, false]);
    @test v == vWork  &&  ic == 0
    v, ic = mdl.max_choice(vWork, vCollege_cV, [false, false]);
    @test v == vWork  &&  ic == 0

    J = 5;
    nc = 7;
    vWorkV = randn(rng, J);
    vCollege_jcM = rand(rng, J, nc);
    admitV = rand(rng, Bool, nc);
    vV, icV = mdl.max_choices(vWorkV, vCollege_jcM, admitV);
    for j = 1 : J
        v, ic = mdl.max_choice(vWorkV[j], vec(vCollege_jcM[j,:]), admitV);
        @test isapprox(vV[j], v)  &&  isequal(icV[j], ic)
    end
end

function helpers_test()
    @testset "Helpers" begin
        x = rand(4,3,2) ./ 5.0;
        x[2 : 2 : 8] .= -0.000000001;
        x ./= sum(x);
        x .+= 0.000000001;
        mdl.make_valid_probs!(x);
        @test sum(x) <= 1.0
        @test all(x .>= 0.0)
	end
end


function find_class_test()
    @testset "find_class" begin
        cutoffV = [0.1, 0.5, 0.9];
        @test mdl.find_class(0.09, cutoffV) == 1
        @test mdl.find_class(0.11, cutoffV) == 2
        @test mdl.find_class(0.49, cutoffV) == 2
        @test mdl.find_class(0.51, cutoffV) == 3
        @test mdl.find_class(0.94, cutoffV) == 4
    end
end


@testset "Helpers" begin
    max_choice_test()
    helpers_test();
    find_class_test();
end

# -------------