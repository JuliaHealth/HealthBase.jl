using Tables
using Base: @kwdef

@kwdef struct HealthTable{T}
    source::T
    omop_cdm_version::String
end

export HealthTable