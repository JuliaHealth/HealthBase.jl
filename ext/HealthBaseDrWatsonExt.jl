module HealthBaseDrWatsonExt

using HealthBase
using DrWatson

__init__() = @info "DrWatson.jl extension for HealthBase has been loaded!"

include("constants.jl")

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

"""
```julia
corpusdir(args...)
```

Return the directory path of the training corpus for the currently active project.

# Arguments

`args...` - other subdirectory or file names to add to the directory path.

# Returns

- A path representing the location of the training corpus for the currently active project.

# Examples

```julia-repl
julia> corpusdir()
"/home/User/MyCurrentProject/data/corpus"

julia> corpusdir("sample")
"/home/User/MyCurrentProject/data/corpus/sample"

julia> corpusdir("sample", "text.txt")
"/home/User/MyCurrentProject/data/corpus/sample/text.txt"
```

"""
function HealthBase.corpusdir(args...)
    joinpath(datadir("corpus"), args...)
end

"""
```julia
modelsdir(args...)
```

Return the directory path of downloaded LLM models for the currently active project.

# Arguments

`args...` - other subdirectory or file names to add to the directory path.

# Returns

- A path representing the location of downloaded LLM models for the currently active project.

# Examples

```julia-repl
julia> modelsdir()
"/home/User/MyCurrentProject/data/models"

julia> modelsdir("model.gguf")
"/home/User/MyCurrentProject/data/models/model.gguf"
```

"""
function HealthBase.modelsdir(args...)
    joinpath(datadir("models"), args...)
end

"""
```julia
configdir(args...)
```

Return the directory path of LLM model and tool configuration files for the currently active project.

# Arguments

`args...` - other subdirectory or file names to add to the directory path.

# Returns

- A path representing the location of LLM model and tool configuration files for the currently active project.

# Examples

```julia-repl
julia> configdir()
"/home/User/MyCurrentProject/config/models"

julia> configdir("sample.modelfile")
"/home/User/MyCurrentProject/data/config/sample.modelfile"
```

"""
function HealthBase.configdir(args...)
    joinpath(datadir("config"), args...)
end

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
    try
        return STUDY_TEMPLATES[tpl]
    catch e
        println("\n`:$tpl` is not a valid template.")
        println("\nCheck the docstring for valid template options by running:\n")
        printstyled("@doc(study_template)\n", color = :cyan, bold = true)
        println("\nin your REPL or code.\n")
        return e
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

- `github_name::String` - the GitHub account you intend to host documentation at. You will need to manually enable the `gh-pages` deployment by going to settings/pages of the GitHub study repo, and choosing as "Source" the `gh-pages` branch. If a name is not specified, a prompt will appear.

# Example

```julia-repl
julia> initialize_study("Cardiooncology", "Jacob S. Zelko, Jakub Mitura"; github_name = "TheCedarPrince", template=:observational)
```
"""
function HealthBase.initialize_study(path, authors = nothing; github_name = "PutYourGitHubNameHere", template::Symbol = :default)
    tpl = study_template(template).template
    ftg = study_template(template).folders_to_gitignore

    if github_name == "PutYourGitHubNameHere"
        @warn """
        `github_name` is not specified. Docs will not be deployed.

        To host the docs online, set the keyword `github_name` with the name of the GitHub account
        you plan to upload at, and then manually enable the `gh-pages` deployment by going to
        settings/pages of the GitHub repo, and choosing as "Source" the `gh-pages` branch.

        You can skip this prompt by specifying `github_name` in the function call. For example:
        `initialize_study("MyStudy", "Carlos", github_name = "JuliaHealth")`
        """

        print("Enter the name of your GitHub account (leave empty to skip): ")
        input = readline()

        github_name = isempty(input) ? github_name : input
    end

    initialize_project(
        path;
        authors = authors,
        template = tpl,
        folders_to_gitignore = ftg,
        force = true,
        add_docs = true,
        github_name = github_name
    )
    cd(path)
end

end
