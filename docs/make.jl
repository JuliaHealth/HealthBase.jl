using HealthBase
using Documenter

DocMeta.setdocmeta!(HealthBase, :DocTestSetup, :(using HealthBase); recursive=true)

makedocs(;
    modules=[HealthBase],
    authors="Dilum Aluthge and contributors",
    repo="https://github.com/JuliaHealth/HealthBase.jl/blob/{commit}{path}#{line}",
    sitename="HealthBase.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaHealth.github.io/HealthBase.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API" => "api.md",
    ],
    strict=true,
)

deploydocs(;
    repo="github.com/JuliaHealth/HealthBase.jl",
)
