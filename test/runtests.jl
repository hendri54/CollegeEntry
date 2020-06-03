using CollegeEntry, ModelParams
using Test

# Low capacity sequential ensures that there are full colleges
function test_entry_switches(J, nc)
    return [
    # CollegeEntry.make_test_entry_one_step(J, nc), 
    # CollegeEntry.make_test_entry_two_step(J, nc),
    # CollegeEntry.make_test_entry_sequential(J, nc, 3.0),
    # CollegeEntry.make_test_entry_sequential(J, nc, 0.2),
    CollegeEntry.make_test_entry_sequ_multiloc(J, nc, nc + 1, 0.3 * J * nc),
    CollegeEntry.make_test_entry_sequ_multiloc(J, nc, 1, 0.3 * J)
    ];
end

@testset "All" begin
    include("admissions_test.jl")
    include("student_rankings_test.jl")
    include("entry_test.jl");
    include("entry_decisions_test.jl")
    include("entry_results_test.jl")
end

# ----------