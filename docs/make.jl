import Pkg
Pkg.add(Pkg.PackageSpec(name = "Documenter",
                        rev = "master"))

import Documenter
import HealthBase

Documenter.makedocs(;
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

Documenter.deploydocs(;
    repo = "github.com/JuliaHealth/HealthBase.jl",
    branch = "gh-pages",
)
