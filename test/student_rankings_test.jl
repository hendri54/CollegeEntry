using Test
using LatexLH, StructLH, ModelObjectsLH, ModelParams, CollegeEntry

ce = CollegeEntry;

make_test_endowment_draws(J :: Integer) = 
    range(1.0, 2.0, length = J) * range(0.5, 1.5, length = 4)';

function CollegeEntry.retrieve_draws(draws :: Matrix{Float64}, eName)
    switches = CollegeEntry.make_test_endowpct_switches(4, true);
    eIdx = findfirst(eName .== endow_names(switches));
    return draws[:, eIdx]
end

CollegeEntry.n_draws(draws :: Matrix{Float64}) = size(draws, 1);


# Input: No of endowments to rank on.
function student_rankings_test(n :: Integer, highDrawsFirst :: Bool)
    @testset "Student rankings $n, $highDrawsFirst" begin
        switches = CollegeEntry.make_test_endowpct_switches(n, highDrawsFirst);
        # println(switches)
        @test StructLH.describe(switches) isa Matrix{String};
        @test validate_ranking_switches(switches)

        if n > 1
            nameV = endow_names(switches);
            wtV = ce.fixed_weights(switches);
            set_bounds!(switches, nameV[2], wtV[2] - 2.0, wtV[2] + 2.0);
            @test validate_ranking_switches(switches);
            @test isapprox(switches.lbV[1], wtV[2] - 2.0)
        end

        st = ce.make_test_symbol_table();
        e = make_student_ranking(ObjectId(:ranking), switches, st);
        # println(e);
        @test validate_ranking(e)

        J = 5;
        draws = make_test_endowment_draws(J);
        rank_jV = rank_students(e, draws);
        @test isa(rank_jV, Vector{<: Integer})
        @test sort(rank_jV) == collect(1 : J)
	end
end


function construct_ranking_test(n :: Integer, highDrawsFirst :: Bool)
    @testset "Construct rankings $n, $highDrawsFirst" begin
        eNameV = [Symbol("endow$j")  for j = 1 : n];
        st = SymbolTable();
        for eName ∈ eNameV
            add_symbol!(st, SymbolInfo(eName, "$eName", "$eName", "Group"));
        end
        add_symbol!(st, SymbolInfo(:rankWt, "omega", "Ranking weight", "Group"));

        switches = EndowPctRankingSwitches(eNameV; highDrawsFirst = highDrawsFirst);
        @test validate_ranking_switches(switches);
        r = make_student_ranking(ObjectId(:ranking), switches, st);
        @test validate_ranking(r)
	end
end


@testset "Student rankings" begin
    for n = 1 : 3
        for highDrawsFirst ∈ (true, false)
            student_rankings_test(n, highDrawsFirst);
            construct_ranking_test(n, highDrawsFirst);
        end
    end
end

# -------------