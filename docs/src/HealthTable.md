# Tables.jl Interface for OMOP Common Data Model in HealthBase.jl

## Core Goals & Features

The proposed interface aims to provide:

- Schema-Aware Access: Standardized and schema-aware access to core OMOP CDM tables (example: `PERSON`, `CONDITION_OCCURRENCE`, `DRUG_EXPOSURE`, `OBSERVATION_PERIOD` etc). Schema awareness will be derived from `OMOPCommonDataModel.jl`.
- Preprocessing Utilities: Built-in or easily integrable support for common preprocessing tasks, including:
    - One-hot encoding.
    - Normalization.
    - Handling missing values.
    - Vocabulary compression for high-cardinality categorical variables.
- Concept Mapping: Utilities to aggregate or map related medical codes (example: grouping SNOMED conditions).
- JuliaHealth Integration: Seamless interoperability with existing and future JuliaHealth tools, such as:
    - `OMOPCDMCohortCreator.jl`
    - `MLJ.jl` (for machine learning pipelines)
    - `OHDSICohortExpressions.jl`
- Foundation for Interoperability: Serve as a foundational layer for broader interoperability across the JuliaHealth ecosystem, supporting researchers working with OMOP CDM-styled data.

## Proposed `Tables.jl` Interface Sketch

Before data is wrapped by the `Tables.jl` interface described below, it's generally expected to undergo initial validation and preparation. This is typically handled by the `HealthBase.HealthTable` function (itself an extension within `HealthBase.jl` that uses `OMOPCommonDataModel.jl`). `HealthTable` takes a source (like a `DataFrame`), validates its structure and column types against the specific OMOP CDM table schema, attaches relevant metadata, and returns a conformed `DataFrame`.

The `OMOPCDMTable` wrappers discussed next would then ideally consume this validated `DataFrame` (the output of `HealthTable`) to provide a standardized, schema-aware `Tables.jl` view for further operations and interoperability.

The core idea is to define wrapper types around OMOP CDM data sources. Initially, we can focus on in-memory `DataFrame`s, but the design should be extensible to database connections or other `Tables.jl`-compatible sources. These wrapper types will implement the `Tables.jl` interface.

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

The `OMOPCDMTable` wrapper types will implement key `Tables.jl` methods:

- `Tables.istable`
- `Tables.rowaccess`
- `Tables.rows`
- `Tables.columnaccess`
- `Tables.columns`
- `Tables.schema`
- `Tables.materializer`

Source: https://tables.juliadata.org/stable/implementing-the-interface/
