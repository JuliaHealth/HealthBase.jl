using HealthBase
using Documenter

DocMeta.setdocmeta!(HealthBase, :DocTestSetup, :(using HealthBase); recursive = true)

makedocs(;
    modules = [HealthBase],
    authors = "Jacob S. Zelko, Dilum Aluthge and contributors",
    repo = "https://github.com/JuliaHealth/HealthBase.jl/blob/{commit}{path}#{line}",
    sitename = "HealthBase.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://JuliaHealth.github.io/HealthBase.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Quickstart" => "quickstart.md",

        "Workflow Guides" => [
            "Observational Template Workflow" => "observational_template_workflow.md",
            "OMOP CDM Workflow" => "OMOPCDMWorkflow.md",
        ],

        "HealthTable System" => [
            "HealthTable: General Tables.jl Interface" => "HealthTableGeneral.md",
            "HealthTable: OMOP CDM Support" => "HealthTableOMOPCDM.md",
        ],
        "API" => "api.md",
    ],
    # TODO: Update and configure doctests before next release
    # TODO: Add doctests to testing suite
    doctest = false,
)

deploydocs(; repo = "github.com/JuliaHealth/HealthBase.jl")
