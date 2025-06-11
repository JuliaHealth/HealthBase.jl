module HealthBase

using Base: get_extension

# GIVING AN PRECOMPILING ERROR, if we do Tables in here
# Issue regarding the dependencies i believe

# using DataFrames
# using Tables
# using Base: @kwdef
using Base.Experimental: register_error_hint

# @kwdef struct HealthTable <: Tables.AbstractTable
#     source::DataFrame
#     omopcdm_version::String
# end

include("drwatson_stub.jl")
include("exceptions.jl")
include("omopcdm_stub.jl")

function __init__()
    register_error_hint(MethodError) do io, exc, argtypes, kwargs
        if exc.f == cohortsdir
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", cohortsdir, io)
            end
        elseif exc.f == HealthTable
            if isnothing(get_extension(HealthBase, :HealthBaseOMOPCDMExt))
                _extension_message("OMOPCommonDataModel and DataFrames", HealthTable, io)
            end
        end
    end
end

end
