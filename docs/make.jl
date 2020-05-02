import Pkg
Pkg.add(Pkg.PackageSpec(rev = "dpa/previews-repo-branch",
                        url = "https://github.com/aluthge-forks/Documenter.jl"))

using Documenter, HealthBase

makedocs(;
    modules = [HealthBase],
    format = Documenter.HTML(),
    pages = [
        "Home" => "index.md",
    ],
    repo = "https://github.com/JuliaHealth/HealthBase.jl/blob/{commit}{path}#L{line}",
    sitename = "HealthBase.jl",
    authors = "JuliaHealth",
    assets = String[],
)

deploydocs(;
    repo = "github.com/JuliaHealth/HealthBase.jl",
    branch = "gh-pages",

    push_preview = true,
    repo_previews = "github.com/JuliaHealth/HealthBase.jl-previews",
    branch_previews = "gh-pages",
)
