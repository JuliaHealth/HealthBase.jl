using Documenter, HealthBase

makedocs(;
    modules=[HealthBase],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/JuliaHealth/HealthBase.jl/blob/{commit}{path}#L{line}",
    sitename="HealthBase.jl",
    authors="JuliaHealth",
    assets=String[],
)

deploydocs(;
    repo="github.com/JuliaHealth/HealthBase.jl",
)
