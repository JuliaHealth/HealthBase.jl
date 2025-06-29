# HealthTable: Tables.jl Interface (General)

## The `HealthTable` Struct

The core of the interface is the `HealthTable` struct. 

```julia
@kwdef struct HealthTable <: Tables.AbstractTable
    source::DataFrame
    omopcdm_version::String
    function HealthTable(source)
        # code goes here
        return new(source, omopcdm_version)
    end
end
```

## `Tables.jl` API Implementation

The `HealthTable` wrapper types will implement key `Tables.jl` methods:

- `Tables.istable`
- `Tables.rowaccess`
- `Tables.rows`
- `Tables.columnaccess`
- `Tables.columns`
- `Tables.schema`
- `Tables.materializer`

Source: https://tables.juliadata.org/stable/implementing-the-interface/
