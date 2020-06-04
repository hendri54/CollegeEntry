using CollegeEntry, ModelParams
using Test

include("test_helpers.jl")

@testset "All" begin
    include("admissions_test.jl")
    include("student_rankings_test.jl")
    include("entry_test.jl");
    include("entry_decisions_test.jl")
    include("entry_results_test.jl")
end

# ----------