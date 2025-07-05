# OMOP CDM Workflow with HealthTable

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

3.  **Wrapping with `HealthTable`:**
    The validated and conformed `DataFrame` (output from `HealthTable`) is then wrapped using the `HealthTable` to provide a schema-aware `Tables.jl` interface. This wrapper uses the same `OMOPCommonDataModel.jl` type to ensure consistency.

4.  **Interacting via `Tables.jl`:**
    Once wrapped, the `HealthTable` instance can be seamlessly used with any `Tables.jl`-compatible tools and standard `Tables.jl` functions

5.  **Applying Preprocessing Utilities:**
    Once the data is an `HealthTable`, common preprocessing steps essential for analysis or predictive modeling can be applied. These methods, built upon the `Tables.jl` interface, include:
    *   One-hot encoding.
    *   Handling of high-cardinality categorical variables.
    *   Concept mapping utilities to group related codes (example: SNOMED conditions).
    *   Normalization, missing value imputation, etc.
    These utilities would typically return a new (or modified) `HealthTable` or a materialized `DataFrame`, ready for further use.


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

# Validate and wrap the DataFrame with HealthTable
ht_conditions = HealthTable(condition_occurrence_df; omop_cdm_version="v5.4.0")


# 1. Schema Inspection
sch = Tables.schema(ht_conditions)
println("Schema Names: ", sch.names)
println("Schema Types: ", sch.types)
# This should output the names and types from the validated DataFrame

# 2. Iteration (Rows)
for row in Tables.rows(ht_conditions)
    # 'row' is a Tables.Row, with fields matching the OMOP schema
    println("Person ID: $(row.person_id), Condition: $(row.condition_concept_id)")
end

# 3. Integration with other packages (example: MLJ.jl)
# 4. Materialization
...
# and so on
```

## Preprocessing and Utilities Sketch

Preprocessing utilities can operate on `HealthTable` objects (or their materialized versions), leveraging the `Tables.jl` interface and schema awareness derived via `Tables.schema`. Examples include:

- `one_hot_encode(ht::HealthTable, column_symbol::Symbol; drop_original=true)`
- `normalize_column(ht::HealthTable, column_symbol::Symbol; method=:z_score)`
- `apply_vocabulary_compression(ht::HealthTable, column_symbol::Symbol, mapping_dict::Dict)`
- `map_concepts(ht::HealthTable, column_symbol::Symbol, concept_map::AbstractDict)`

These functions would align with the principle of optional, user triggered transformations, possibly controlled by keyword arguments.
