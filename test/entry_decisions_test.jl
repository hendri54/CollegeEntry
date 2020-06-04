using Test
using CollegeEntry

# The code uses the fact that reshape undoes vec. This is tested here.
function reshape_test()
    @testset "reshape" begin
        sizeV = (4,3,2);
        x = zeros(sizeV...);
        for i1 = 1 : sizeV[1]
            for i2 = 1 : sizeV[2]
                for i3 = 1 : sizeV[3]
                    x[i1,i2,i3] = 0.1 * i1 + 0.2 * i2 - 0.3 * i3;
                end
            end
        end
        v = vec(x);
        @test isequal(x, reshape(v, sizeV...))
    end
end


function entry_decisions_test(switches :: AbstractEntrySwitches{F1},
    admissionS) where F1

    println("\n------------------------");
    println(switches);
    objId = ObjectId(:entryOneStep);
    entryS = init_entry_decision(objId, switches);
    println(entryS);

    nc = n_colleges(switches);
    J = n_types(switches);
    nl = n_locations(switches)
    vWork_jV = collect(range(-0.5, 1.5, length = J));
    vCollege_jcM = range(-0.2, 1.2, length = J) * range(1.0, 2.0, length = nc)';
    hsGpaPctV = collect(range(0.1, 0.9, length = J));
    rank_jV = vcat(2 : 2 : J, 1 : 2 : J);

    er = entry_decisions(entryS, admissionS,
        vWork_jV, vCollege_jcM, hsGpaPctV, rank_jV);
    @test validate_er(er)
    entryProb_jcM = entry_probs_jc(er);
    eValM = expected_values_jl(er);

    # Entry results methods
    if n_locations(er) == 1
        @test frac_local(er) == 1.0
        @test all(frac_local_j(er) .== 1.0)
        @test all(frac_local_c(er) .== 1.0)
    else
        @test 0.0 < frac_local(er) < 1.0
        @test all(0.0 .< frac_local_j(er) .< 1.0)
        @test all(0.0 .< frac_local_c(er) .< 1.0)        
    end

    # Check implied properties
    totalMass = sum(type_mass_jl(er));
    
    # Solving one student at a time should give the same answer IF no colleges are full.
    for j = 1 : J
        if nl == 1
            entryProb_cV, eVal = CollegeEntry.entry_decisions_one_student(
                entryS, admissionS,
                vWork_jV[j], vCollege_jcM[j,:], hsGpaPctV[j], fill(false, nc));
            @test sum(entryProb_cV) .<= 1.0
            # Not having full colleges should increase value
            @test eVal >= eValM[j]
            # And it should increase entry
            @test sum(entryProb_cV) > sum(entryProb_jcM[j,:] .- 1e-5)
            if !any(colleges_full(er))
                @test isapprox(entryProb_cV, entryProb_jcM[j,:])
                @test isapprox(eVal, eValM[j])
            end

        else
            # Solver for student in one location
            for l = 1 : nl
                entryProb_clM, eVal = CollegeEntry.entry_decisions_one_student(
                    entryS, admissionS,  vWork_jV[j], vCollege_jcM[j,:], 
                    hsGpaPctV[j], fill(false, nc, nl), l);
                @test all(sum(entryProb_clM, dims = 2) .<= 1.0)
                # Not having full colleges should increase value
                @test eVal >= eValM[j, l]
            end
        end
    end
end

@testset "Entry decisions" begin
    J = 8;
    nc = 4;
    admissionS = CollegeEntry.make_test_admissions_cutoff(nc);
    # The last case ensures that some colleges are full
    for switches in test_entry_switches(J, nc)
        entry_decisions_test(switches, admissionS);
    end

    reshape_test()
end

# -----------