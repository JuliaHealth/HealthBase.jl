"""
Constant which provides `DrWatson.jl` project templates.
"""
const STUDY_TEMPLATES = Dict(
    :default => (
        template = DrWatson.DEFAULT_TEMPLATE,
        folders_to_gitignore = ["data", "videos", "plots", "notebooks", "_research"],
    ),
    :observational => (
        template = [
            "_research",
            "src",
            "scripts",
            "plots",
            "notebooks",
            "papers",
            "data" => ["cohorts", "exp_raw", "exp_pro"],
        ],
        folders_to_gitignore = ["data/exp_raw", "data/exp_pro"],
    ),
    :llm => (
        template = [
            "_research",
            "src",
            "scripts",
            "plots",
            "notebooks",
            "papers",
            "data" => ["corpus", "models", "config"],
        ],
        folders_to_gitignore = ["data/models", "data/corpus"],
    ),
)
