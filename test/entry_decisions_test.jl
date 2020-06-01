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

    # Check implied properties
    totalMass = sum(type_mass(entryS, 1 : J));
    enrollV = college_enrollment(entryS, entryProb_jcM);
    @test size(enrollV) == (nc,)
    @test all(enrollV .>= 0.0)
    @test sum(enrollV) < totalMass
    fullV = colleges_full(entryS, entryProb_jcM);
    @test size(fullV) == (nc,)
    capacityV = capacities(entryS);
    @test all((capacityV .< totalMass) .| .!fullV)

    # Solving one student at a time should give the same answer. But not for sequential entry, unless no colleges are full.
    for j = 1 : J
        entryProb_cV, eVal = CollegeEntry.entry_decisions_one_student(
            entryS, admissionS,
            vWork_jV[j], vCollege_jcM[j,:], hsGpaPctV[j], falses(nc));
        @test sum(entryProb_cV) .<= 1.0
        # Not having full colleges should increase value
        @test eVal >= v_jV[j]
        # And it should increase entry
        @test sum(entryProb_cV) >= sum(entryProb_jcM[j,:])
        if !any(fullV)
            @test isapprox(entryProb_cV, entryProb_jcM[j,:])
            @test isapprox(eVal, v_jV[j])
        end
    end

end

@testset "Entry decisions" begin
    J = 8;
    nc = 4;
    admissionS = CollegeEntry.make_test_admissions_cutoff(nc);
    # The last case ensures that some colleges are full
    for entryS in [CollegeEntry.make_test_entry_one_step(),
        CollegeEntry.make_test_entry_sequential(J, nc, 0.8),
        CollegeEntry.make_test_entry_sequential(J, nc, 0.2)]

        entry_decisions_test(entryS, admissionS);
    end
end

# -----------