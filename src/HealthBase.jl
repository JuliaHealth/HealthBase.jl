module HealthBase

using Base: get_extension

using Base.Experimental: register_error_hint

include("drwatson_stub.jl")
include("exceptions.jl")

function __init__()
    register_error_hint(MethodError) do io, exc, argtypes, kwargs
        if exc.f == cohortsdir
            if isnothing(get_extension(HealthBase, :HealthBaseDrWatsonExt))
                _extension_message("DrWatson", cohortsdir, io)
            end
        end
    end
end

end
