using CollegeEntry, ModelParams
using Test

function entry_test()
    @testset "Entry probs" begin
        F1 = Float64;
        for switches in [EntryOneStepSwitches{F1}()]
            println(switches);
            objId = ObjectId(:entry);
            e = init_entry_decision(objId, switches);
            println(e);

            @test 0.0 < min_entry_prob(e) < max_entry_prob(e) < 1.0
            @test entry_pref_scale(e) > 0.0

            J = 5; nc = 3;
            vWork_jV = collect(range(-0.1, 2.2, length = J));
            vCollege_jcM = range(1.0, 2.0, length = J) * 
                collect(range(-0.5, 1.5, length = nc))';
            admitV = [1, 3];
            rejectV = [2];
            prob_jcM, eVal_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV);
            @test all(prob_jcM .>= 0.0)
            @test all(prob_jcM .<= 1.0)
            @test size(prob_jcM) == (J, nc)
            @test size(eVal_jV) == (J,)
            @test all(prob_jcM[:, rejectV] .== 0.0)

            # Increasing a value should increase probability
            idx = admitV[end];
            otherAdmitV = admitV[1 : (end-1)];
            vCollege_jcM[:, idx] .+= 0.1;
            prob2_jcM, eVal2_jV = entry_probs(e, vWork_jV, vCollege_jcM, admitV);
            @test all(prob2_jcM[:, idx] .> prob_jcM[:, idx])
            @test all(prob2_jcM[:, otherAdmitV] .< prob_jcM[:, otherAdmitV])
            @test all(eVal2_jV .> eVal_jV)
        end
    end
end

@testset "All" begin
    entry_test()
end

# ----------