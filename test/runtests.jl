using CollegeEntry, ModelObjectsLH, ModelParams
using Test, TestSetExtensions

include("test_helpers.jl")

@testset "All" begin
    include("helpers_test.jl")
    include("admissions_test.jl");
    include("admission_prob_test.jl");
    include("student_rankings_test.jl")
    include("entry_test.jl");
    include("entry_decisions_test.jl")
    include("entry_results_test.jl")
end

# ----------