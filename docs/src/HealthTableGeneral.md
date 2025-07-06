# HealthTable: Tables.jl Interface (General)

## The `HealthTable` Struct

The core of the interface is the `HealthTable` struct. 

```julia
@kwdef struct HealthTable 
    source::DataFrame
    function HealthTable(source)
        # code goes here
        return new(source)
    end
end
```

## `Tables.jl` API Implementation

The `HealthTable` wrapper types will implement key `Tables.jl` methods:

```@docs
HealthTable
Tables.istable
Tables.rowaccess
Tables.rows
Tables.columnaccess
Tables.columns
Tables.schema
Tables.materializer
```

Source: https://tables.juliadata.org/stable/implementing-the-interface/
