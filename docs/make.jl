using HealthBase
using Documenter
using Tables
using DataFrames
using OMOPCommonDataModel
using FeatureTransforms
using DuckDB

DocMeta.setdocmeta!(
    HealthBase,
    :DocTestSetup,
    :(using HealthBase, Tables);
    recursive = true,
)

makedocs(;
    modules = [
        HealthBase,
        isdefined(Base, :get_extension) ?
        Base.get_extension(HealthBase, :HealthBaseOMOPCDMExt) :
        HealthBase.HealthBaseOMOPCDMExt,
    ],
    checkdocs = :none,
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
            "HealthTable: Preprocessing Functions" => "HealthTablePreprocessing.md",
        ],
        "API" => "api.md",
    ],
    # TODO: Update and configure doctests before next release
    # TODO: Add doctests to testing suite
    doctest = false,
)

deploydocs(; repo = "github.com/JuliaHealth/HealthBase.jl")
