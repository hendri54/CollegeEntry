using Test
using CollegeEntry

function entry_decisions_test()
    nc = 4;
    entryS = CollegeEntry.make_test_entry_one_step();
    admissionS = CollegeEntry.make_test_admissions_cutoff(nc);

    J = 8;
    vWork_jV = collect(range(-0.5, 1.5, length = J));
    vCollege_jcM = range(-0.2, 1.2, length = J) * range(1.0, 2.0, length = nc)';
    hsGpaPctV = collect(range(0.1, 0.9, length = J));

    entryProb_jcM, v_jV = entry_decisions(entryS, admissionS,
        vWork_jV, vCollege_jcM, hsGpaPctV);

    @test size(entryProb_jcM) == (J, nc)
    @test size(v_jV) == (J, )
    @test all(entryProb_jcM .> 0.0)
    @test all(entryProb_jcM .< 1.0)
    @test all(sum(entryProb_jcM, dims = 2) .< 1.0)
end

@testset "Entry decisions" begin
    entry_decisions_test()
end

# -----------