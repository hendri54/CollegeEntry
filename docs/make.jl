Pkg.activate("./docs")

using Documenter, CollegeEntry, FilesLH

makedocs(
    modules = [CollegeEntry],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "hendri54",
    sitename = "CollegeEntry.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

pkgDir = rstrip(normpath(@__DIR__, ".."), '/');
@assert endswith(pkgDir, "CollegeEntry")
deploy_docs(pkgDir);

Pkg.activate(".")

# deploydocs(
#     repo = "github.com/hendri54/CollegeEntry.jl.git",
#     push_preview = true
# )
