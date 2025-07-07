# HealthTable: Tables.jl Interface (General)

## The `HealthTable` Struct

The core of the interface is the `HealthTable` struct.

```@docs
HealthBase.HealthTable
```

## `Tables.jl` API Implementation

The `HealthTable` wrapper types will implement key `Tables.jl` methods:

`HealthTable` implements the `Tables.jl` interface to ensure compatibility with the Julia data ecosystem:

```@docs
Tables.istable(::Type{<:HealthBase.HealthTable})
Tables.rowaccess(::Type{<:HealthBase.HealthTable})
Tables.rows(::HealthBase.HealthTable)
Tables.columnaccess(::Type{<:HealthBase.HealthTable})
Tables.columns(::HealthBase.HealthTable)
Tables.schema(::HealthBase.HealthTable)
Tables.materializer(::Type{<:HealthBase.HealthTable})
```

Source: https://tables.juliadata.org/stable/implementing-the-interface/
