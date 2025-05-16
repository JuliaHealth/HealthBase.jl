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

end
