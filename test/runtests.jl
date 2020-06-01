using CollegeEntry, ModelParams
using Test

@testset "All" begin
    include("entry_test.jl");
    include("admissions_test.jl")
    include("entry_decisions_test.jl")
    include("student_rankings_test.jl")
end

# ----------