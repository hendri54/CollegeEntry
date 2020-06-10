using Random, Test
using CollegeEntry

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
    helpers_test()
end

# -------------