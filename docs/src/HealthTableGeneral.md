# HealthTable: Tables.jl Interface (General)

## The `HealthTable` Struct

The core of the interface is the `HealthTable` struct. 

```julia
@kwdef struct HealthTable{T}
    source::T
end
```

## `Tables.jl` API Implementation

The `HealthTable` wrapper types will implement key `Tables.jl` methods:

`HealthTable` implements the `Tables.jl` interface to ensure compatibility with the Julia data ecosystem:

- `Tables.istable(::Type{HealthTable}) = true`
- `Tables.rowaccess(::Type{HealthTable}) = true`
- `Tables.rows(ht::HealthTable)`
- `Tables.columnaccess(::Type{HealthTable}) = true`
- `Tables.columns(ht::HealthTable)`
- `Tables.schema(ht::HealthTable)`
- `Tables.materializer(::Type{HealthTable}) = DataFrame`

Source: https://tables.juliadata.org/stable/implementing-the-interface/
