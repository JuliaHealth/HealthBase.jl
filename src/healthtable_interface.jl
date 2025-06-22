using Tables
using Base: @kwdef

@kwdef struct HealthTable{T}
    source::T
    omop_cdm_version::String
end

Tables.istable(::Type{<:HealthTable}) = true
Tables.rowaccess(::Type{<:HealthTable}) = true
Tables.rows(ht::HealthTable) = Tables.rows(ht.source)
Tables.columns(ht::HealthTable) = Tables.columns(ht.source)
Tables.schema(ht::HealthTable) = Tables.schema(ht.source)
Tables.materializer(::Type{<:HealthTable}) = DataFrame

export HealthTable