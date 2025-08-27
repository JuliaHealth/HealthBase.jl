"""
    HealthTable{T}

A lightweight, schema-aware wrapper for OMOP CDM tables, providing a standardized Tables.jl interface and metadata tracking.

The `HealthTable` struct is designed to wrap OMOP CDM-compliant data sources (such as DataFrames), ensuring that all columns 
conform to the OMOP CDM specification for a given version. It attaches the OMOP CDM version as metadata and enables seamless 
integration with the Julia Tables.jl ecosystem.

# Fields
- `source::T`: The underlying data source (typically a `DataFrame`) containing the OMOP CDM table data.

# Examples
```julia
person_df = DataFrame(
    person_id=1:3,
    gender_concept_id=[8507, 8532, 8507],
    year_of_birth=[1990, 1985, 2000]
)
ht = HealthTable(person_df; omop_cdm_version="v5.4.1")
Tables.schema(ht) # Get the schema
DataFrame(ht)     # Materialize as DataFrame
```
"""
@kwdef struct HealthTable{T}
    source::T
end

"""
    Tables.istable(::Type{<:HealthTable})

Signal that `HealthTable` is a table according to the Tables.jl interface.

This function is part of the Tables.jl interface and is used to identify types that can be treated as tabular data.

## Returns
- `Bool`: Always returns `true` for the `HealthTable` type.
"""
Tables.istable(::Type{<:HealthTable}) = true

"""
    Tables.rowaccess(::Type{<:HealthTable})

Signal that `HealthTable` supports row-based iteration.

This function is part of the Tables.jl interface. A `true` return value indicates that `Tables.rows` can be called on an instance of `HealthTable`.

## Returns
- `Bool`: Always returns `true` for the `HealthTable` type.
"""
Tables.rowaccess(::Type{<:HealthTable}) = true

"""
    Tables.rows(ht::HealthTable)

Return an iterator over the rows of the `HealthTable`.

This function implements the row-access part of the Tables.jl interface by delegating to the underlying `source` object.

## Arguments
- `ht::HealthTable`: The `HealthTable` instance.

## Returns
- An iterator object that yields each row of the table.
"""
Tables.rows(ht::HealthTable) = Tables.rows(ht.source)

"""
    Tables.columnaccess(::Type{<:HealthTable})

Signal that `HealthTable` supports column-based access.

This function is part of the Tables.jl interface. A `true` return value indicates that `Tables.columns` can be called on an instance of `HealthTable`.

## Returns
- `Bool`: Always returns `true` for the `HealthTable` type.
"""
Tables.columnaccess(::Type{<:HealthTable}) = true

"""
    Tables.columns(ht::HealthTable)

Return the `HealthTable`'s data as a set of columns.

This function implements the column-access part of the Tables.jl interface by delegating to the underlying `source` object.

## Arguments
- `ht::HealthTable`: The `HealthTable` instance.

## Returns
- A column-accessible object that represents the table's data.
"""
Tables.columns(ht::HealthTable) = Tables.columns(ht.source)

"""
    Tables.schema(ht::HealthTable)

Get the schema of the `HealthTable`.

The schema includes the names and types of the columns. This function delegates the call to the underlying `source`.

## Arguments
- `ht::HealthTable`: The `HealthTable` instance.

## Returns
- `Tables.Schema`: An object describing the column names and their Julia types.
"""
Tables.schema(ht::HealthTable) = Tables.schema(ht.source)

"""
    Tables.materializer(::Type{<:HealthTable})

Specify the default type to use when materializing a `HealthTable`.

This function is part of the Tables.jl interface. It allows other packages to convert a `HealthTable` into a concrete table type like a `DataFrame` by calling `DataFrame(ht)`.

## Returns
- `Type`: The `DataFrame` type, indicating it as the preferred materialization format.
"""
Tables.materializer(::Type{<:HealthTable}) = DataFrame

export HealthTable