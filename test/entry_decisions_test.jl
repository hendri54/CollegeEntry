using Test
using CollegeEntry

function entry_decisions_test(entryS :: AbstractEntryDecision{F1},
    admissionS) where F1

    println("\n------------------------");
    println(entryS);

    nc = n_colleges(admissionS);
    J = 8;
    vWork_jV = collect(range(-0.5, 1.5, length = J));
    vCollege_jcM = range(-0.2, 1.2, length = J) * range(1.0, 2.0, length = nc)';
    hsGpaPctV = collect(range(0.1, 0.9, length = J));
    rank_jV = vcat(2 : 2 : J, 1 : 2 : J);

    entryProb_jcM, v_jV = entry_decisions(entryS, admissionS,
        vWork_jV, vCollege_jcM, hsGpaPctV, rank_jV);

    @test size(entryProb_jcM) == (J, nc)
    @test size(v_jV) == (J, )
    @test all(entryProb_jcM .>= 0.0)
    @test all(entryProb_jcM .< 1.0)
    @test all(sum(entryProb_jcM, dims = 2) .< 1.0)

    enrollV = college_enrollment(entryS, entryProb_jcM);
    @test size(enrollV) == (nc,)
    @test all(enrollV .>= 0.0)
    @test sum(enrollV) < J * type_mass(entryS)
    fullV = colleges_full(entryS, entryProb_jcM);
    @test size(fullV) == (nc,)
    capacityV = capacities(entryS);
    @test all((capacityV .< J * type_mass(entryS)) .| .!fullV)
end

@testset "Entry decisions" begin
    nc = 4;
    admissionS = CollegeEntry.make_test_admissions_cutoff(nc);
    # The last case ensures that some colleges are full
    for entryS in [CollegeEntry.make_test_entry_one_step(),
        CollegeEntry.make_test_entry_sequential(nc, 3.0),
        CollegeEntry.make_test_entry_sequential(nc, 0.5)]

        entry_decisions_test(entryS, admissionS);
    end
end

# -----------