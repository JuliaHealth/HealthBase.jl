# Sketch: Tables.jl Interface for OMOP Common Data Model in HealthBase.jl

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

## Typical Workflow

The envisioned process for working with OMOP CDM data using these `HealthBase.jl` components typically follows these steps:

1.  **Data Loading**:
    Raw data is loaded into a suitable tabular structure, most commonly a `DataFrame`.

2.  **Validation and Conformance with `HealthTable`:**
    The raw `DataFrame` is then processed by the `HealthBase.HealthTable` function. This function takes the `DataFrame` and an OMOP CDM version string (example: "5.4") as arguments, validating its structure and column types against the general OMOP CDM schema for that version.
    *   It checks if the data types in those columns are compatible with the official OMOP CDM types (as defined in `OMOPCommonDataModel.jl`).
    *   It can warn about discrepancies or, if `disable_type_enforcement=false`, potentially error or attempt safe conversions.
    *   Crucially, it attaches metadata to the columns, indicating their official OMOP CDM types.
    *   The output is a `DataFrame` that is now validated and conformed to the specified OMOP CDM table structure.

3.  **Wrapping with `OMOPCDMTable`:**
    The validated and conformed `DataFrame` (output from `HealthTable`) is then wrapped using the `OMOPCDMTable` to provide a schema-aware `Tables.jl` interface. This wrapper uses the same `OMOPCommonDataModel.jl` type to ensure consistency.

4.  **Interacting via `Tables.jl`:**
    Once wrapped, the `OMOPCDMTable` instance can be seamlessly used with any `Tables.jl`-compatible tools and standard `Tables.jl` functions

5.  **Applying Preprocessing Utilities:**
    Once the data is an `OMOPCDMTable`, common preprocessing steps essential for analysis or predictive modeling can be applied. These methods, built upon the `Tables.jl` interface, include:
    *   One-hot encoding.
    *   Handling of high-cardinality categorical variables.
    *   Concept mapping utilities to group related codes (example: SNOMED conditions).
    *   Normalization, missing value imputation, etc.
    These utilities would typically return a new (or modified) `OMOPCDMTable` or a materialized `DataFrame`, ready for further use.


## OMOP CDM Table Wrapper Types

We could define a generic wrapper or specific types for each OMOP CDM table:

```julia
# A possible generic wrapper:
# T_CDM is the ::Type object from OMOPCommonDataModel, example: OMOPCommonDataModel.Person
# S is the type of the data source, example: a DataFrame
struct OMOPCDMTable{T_CDM <: OMOPCommonDataModel.CDMType, S} <: Tables.AbstractTable
    source::S 
end

# Example of how it might be constructed:
# person_df = DataFrame(...) # Data loaded into a DataFrame
# omop_person_table = OMOPCDMTable{OMOPCommonDataModel.Person}(person_df)

# Alternatively, specific types might be more discoverable for users:
struct PersonTable{S} <: Tables.AbstractTable
    source::S
end
# Constructor: PersonTable(source_df)
# Internally, PersonTable would know it corresponds to OMOPCommonDataModel.Person.

# Similar structs could be defined for ConditionOccurrenceTable, DrugExposureTable, etc.
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

## Example Usage (Conceptual)

```julia
using HealthBase # (once the OMOP Tables interface is part of it)
using OMOPCommonDataModel
using DataFrames # an example source

# Assume 'condition_occurrence_df' is a DataFrame loaded from a CSV/database
condition_occurrence_df = DataFrame(
    condition_occurrence_id = [1, 2, 3],
    person_id = [101, 102, 101],
    condition_concept_id = [201826, 433736, 317009],
    condition_start_date = [Date(2010,1,1), Date(2012,5,10), Date(2011,3,15)]
    # ... other fields
)

# Wrap it with the schema-aware OMOPCDMTable
# Here, OMOPCommonDataModel.ConditionOccurrence is the specific OMOP CDM type
omop_conditions = OMOPCDMTable{OMOPCommonDataModel.ConditionOccurrence}(condition_occurrence_df)
# Or, if using specific types:
# omop_conditions = ConditionOccurrenceTable(condition_occurrence_df)


# 1. Schema Inspection
sch = Tables.schema(omop_conditions)
println("Schema Names: ", sch.names)
println("Schema Types: ", sch.types)
# This should output names and types corresponding to OMOPCommonDataModel.ConditionOccurrence

# 2. Iteration (Rows)
for row in Tables.rows(omop_conditions)
    # 'row' would be a NamedTuple or similar, with fields matching the OMOP schema
    println("Person ID: $(row.person_id), Condition: $(row.condition_concept_id)")
end

# 3. Integration with other packages (example: MLJ.jl)
# 4. Materialization
...
# and so on
```

## Preprocessing and Utilities Sketch

Preprocessing utilities can operate on `OMOPCDMTable` objects (or their materialized versions), leveraging the `Tables.jl` interface and schema awareness derived via `Tables.schema`. Examples include:

- `one_hot_encode(table::OMOPCDMTable, column_symbol::Symbol; drop_original=true)`
- `normalize_column(table::OMOPCDMTable, column_symbol::Symbol; method=:z_score)`
- `apply_vocabulary_compression(table::OMOPCDMTable, column_symbol::Symbol, mapping_dict::Dict)`
- `map_concepts(table::OMOPCDMTable, column_symbol::Symbol, concept_map::AbstractDict)`

These functions would align with the principle of optional, user triggered transformations, possibly controlled by keyword arguments.

