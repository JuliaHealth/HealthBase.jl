module HealthBaseDrWatsonExt

using HealthBase
using DrWatson

__init__() = @info "DrWatson.jl extension for HealthBase has been loaded!"

"""
```julia
cohortsdir(args...)
```

Return the directory path of the cohort definitions for the currently active project.

# Arguments

`args...` - other subdirectory or file names to add to the directory path.

# Returns

- A path representing the location of the directory of cohort definitions for the currently active project.

# Examples

```julia-repl
julia> cohortsdir()
"/home/User/MyCurrentProject/data/cohorts"

julia> cohortsdir("under_review")
"/home/User/MyCurrentProject/data/cohorts/under_review"

julia> cohortsdir("under_review", "stroke.json")
"/home/User/MyCurrentProject/data/cohorts/under_review/stroke.json"
```

"""
function HealthBase.cohortsdir(args...)
    joinpath(datadir("cohorts"), args...)
end

STUDY_DEFAULTS = Dict(
    :default => (
        template = DrWatson.DEFAULT_TEMPLATE,
        folders_to_gitignore = ["data", "videos", "plots", "notebooks", "_research"],
    ),
    :observational => (
        template = [
            "_research",
            "src",
            "scripts",
            "data",
            "plots",
            "notebooks",
            "papers",
            "data" => ["cohorts", "exp_raw", "exp_pro"],
        ],
        folders_to_gitignore = ["data/exp_raw", "data/exp_pro"],
    ),
)

"""
```julia
study_template(tpl::Symbol)
```

Check and return an available study template.

# Arguments

- `tpl::Symbol` - A study template option. Available values are:

    - `:default` - `DrWatson.DEFAULT_TEMPLATE`

    - `:observational` - Study template for an observational health study

# Returns

- A named tuple with specification information about the template used.
"""
function HealthBase.study_template(tpl::Symbol)
    if !in(tpl, keys(STUDY_DEFAULTS))
        @error "`$tpl` is not a valid template."

        println("\nCheck the docstring for valid template options by running:\n")
        printstyled("@doc(study_template)\n", color = :cyan, bold = true)
        println("\nin your REPL or code.")
    else
        return STUDY_DEFAULTS[tpl]
    end
end

"""
```julia
initialize_study(path, authors = nothing; template = :default)
```

Initialize a JuliaHealth study.
The study environment remains activated for you to immediately add packages.

> **NOTE:** This a simplifying wrapper for `DrWatson.initialize_project`. 
> For additional configuration options, check `initialize_project`. 

# Arguments

- `path` - A directory where you want the study to be initialized. If the directory does not exist, it will be created.

- `authors = nothing` - A string or vector of strings listing author names. If no names are given, no author information will be added in the study. 

# Keyword Arguments

- `template::Symbol` - A template option specifying the structure of the the study. Available templates can be found by running `@doc(study_template)`.

"""
function HealthBase.initialize_study(path, authors = nothing; template::Symbol = :default)
    tpl = study_template(template).template
    ftg = study_template(template).folders_to_gitignore

    initialize_project(path; authors = authors, template = tpl, folders_to_gitignore = ftg)
    cd(path)
end

end
