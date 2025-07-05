module HealthBase

using Base: get_extension, @kwdef
using Base.Experimental: register_error_hint
using Tables

include("exceptions.jl")

function __init__()
    register_error_hint(MethodError) do io, exc, argtypes, kwargs
        if exc.f == cohortsdir
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", cohortsdir, io)
            end
        elseif exc.f == HealthTable
            if isnothing(get_extension(HealthBase, :HealthBaseOMOPCDMExt))
                _extension_message("OMOPCommonDataModel, DataFrames", HealthTable, io)
            end
        elseif exc.f == corpusdir
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", corpusdir, io)
            end
        elseif exc.f == modelsdir
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", modelsdir, io)
            end
        elseif exc.f == configdir
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", configdir, io)
            end
        elseif exc.f == initialize_study
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", initialize_study, io)
            end
        elseif exc.f == study_template
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", study_template, io)
            end
        end
    end
end

include("healthtable_interface.jl")
include("drwatson_stub.jl")
include("omopcdm_stub.jl")
include("show.jl")

end
