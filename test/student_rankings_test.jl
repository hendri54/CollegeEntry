using Test
using LatexLH, StructLH, ModelObjectsLH, ModelParams, CollegeEntry

mdl = CollegeEntry;


# Scale in [0, 1] consistent with percentiles
function make_test_endowment_draws(J :: Integer)
    n = length(mdl.test_endow_names());
    drawM = range(0.0, 1.0, length = J) * range(0.05, 0.95, length = n)';
    return drawM
end

function CollegeEntry.retrieve_draws(draws :: Matrix{Float64}, eName)
    eIdx = findfirst(eName .== mdl.test_endow_names());
    return draws[:, eIdx]
end

CollegeEntry.n_draws(draws :: Matrix{Float64}) = size(draws, 1);


# Input: No of endowments to rank on.
function student_rankings_test(e)
    @testset "$e" begin
        @test StructLH.describe(e) isa Matrix{String};
        @test validate_ranking(e);

        # if n > 1
        #     nameV = endow_names(switches);
        #     wtV = ce.fixed_weights(switches);
        #     ce.set_bounds!(switches, nameV[2], wtV[2] - 2.0, wtV[2] + 2.0);
        #     @test validate_ranking_switches(switches);
        #     @test isapprox(switches.lbV[1], wtV[2] - 2.0)
        # end

        # st = ce.make_test_symbol_table();
        # e = make_student_ranking(ObjectId(:ranking), switches, st);
        # # println(e);
        # @test validate_ranking(e)

        J = 5;
        draws = make_test_endowment_draws(J);
        rank_jV = rank_students(e, draws);
        @test isa(rank_jV, Vector{<: Integer})
        @test sort(rank_jV) == collect(1 : J)

        scoreV = score_students(e, draws);
        if mdl.high_draws_first(e)
            @test all(diff(scoreV[rank_jV]) .< 0.0);
        else
            @test all(diff(scoreV[rank_jV]) .> 0.0);
        end

        lb, ub = range_of_scores(e);
        @test all(lb .<= scoreV .<= ub);
        scaledV = scale_scores(e, scoreV);
        @test all(0.0 .<= scaledV .<= 1.0);
	end
end


# function construct_ranking_test(n :: Integer, highDrawsFirst :: Bool)
#     @testset "Construct rankings $n, $highDrawsFirst" begin
#         eNameV = [Symbol("endow$j")  for j = 1 : n];
#         st = SymbolTable();
#         for eName ∈ eNameV
#             add_symbol!(st, SymbolInfo(eName, "$eName", "$eName", "Group"));
#         end
#         add_symbol!(st, SymbolInfo(:rankWt, "omega", "Ranking weight", "Group"));

#         switches = EndowPctRankingSwitches(eNameV; highDrawsFirst = highDrawsFirst);
#         @test validate_ranking_switches(switches);
#         r = make_student_ranking(ObjectId(:ranking), switches, st);
#         @test validate_ranking(r)
# 	end
# end


@testset "Student rankings" begin
    objId = ObjectId(:ranking);
    eName = first(mdl.test_endow_names());
    # rankFct(draws) = 
    for highDrawsFirst ∈ (true, false)
        for e in [
            mdl.make_test_ranking_one_endow(highDrawsFirst),
            mdl.make_test_ranking_by_fct(highDrawsFirst)
            ]
            student_rankings_test(e);
        end
    end
end

# -------------