using Test
using LatexLH, StructLH, ModelParams, CollegeEntry

ce = CollegeEntry;

make_test_endowment_draws(J :: Integer) = 
    range(1.0, 2.0, length = J) * range(0.5, 1.5, length = 4)';

function CollegeEntry.retrieve_draws(draws :: Matrix{Float64}, eName)
    switches = CollegeEntry.make_test_endowpct_switches(4);
    eIdx = findfirst(eName .== endow_names(switches));
    return draws[:, eIdx]
end

CollegeEntry.n_draws(draws :: Matrix{Float64}) = size(draws, 1);


# Input: No of endowments to rank on.
function student_rankings_test(n :: Integer)
    @testset "Student rankings" begin
        println("\n-----------");
        switches = CollegeEntry.make_test_endowpct_switches(n);
        println(switches)
        println(StructLH.describe(switches));
        # StructLH.describe(switches)
        @test validate_ranking_switches(switches)

        st = ce.make_test_symbol_table();
        e = make_student_ranking(ObjectId(:ranking), switches, st);
        println(e);
        @test validate_ranking(e)

        J = 5;
        draws = make_test_endowment_draws(J);
        rank_jV = rank_students(e, draws);
        @test isa(rank_jV, Vector{<: Integer})
        @test sort(rank_jV) == collect(1 : J)
	end
end

@testset "Student rankings" begin
    for n = 1 : 3
        student_rankings_test(n);
    end
end

# -------------