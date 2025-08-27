# OMOP CDM Workflow with HealthTable

## Typical Workflow

The envisioned process for working with OMOP CDM data using the `HealthBase.jl` components typically follows these steps:

1. **Data Loading**  
   Raw data is loaded into a suitable tabular structure, most commonly a `DataFrame`.

2. **Validation and Wrapping with `HealthTable`**  
   The raw `DataFrame` is then wrapped using `HealthBase.HealthTable`. This function takes the `DataFrame` and uses the attached OMOP CDM version (e.g., "v5.4.1") to validate its structure and column types against the OMOP CDM schema.

   - It checks if the column types are compatible with the expected OMOP CDM types (from `OMOPCommonDataModel.jl`).
   - If `disable_type_enforcement = false`, it will throw errors on mismatches or attempt safe conversions.
   - It attaches metadata to columns indicating their OMOP CDM types.
   - The result is a `HealthTable` instance that wraps the validated `DataFrame` and exposes the `Tables.jl` interface.

3. **Interacting via `Tables.jl`**  
   Once wrapped, the `HealthTable` instance can be seamlessly used with any `Tables.jl`-compatible tools and standard `Tables.jl` functions.

4. **Applying Preprocessing Utilities**  
   After wrapping, you can apply preprocessing steps essential for analysis or modeling. These include:

   - One-hot encoding
   - Handling of high-cardinality categorical variables
   - Concept mapping utilities

   These utilities usually return a modified `HealthTable` or a materialized `DataFrame` ready for downstream use.

## Example Usage

```julia
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Dates, FeatureTransforms, DBInterface, DuckDB
using HealthBase

# Assume 'condition_occurrence_df' is a DataFrame loaded from a CSV/database
condition_occurrence_df = DataFrame(
    condition_occurrence_id = [1, 2, 3],
    person_id = [101, 102, 101],
    condition_concept_id = [201826, 433736, 317009],
    condition_start_date = [Date(2010,1,1), Date(2012,5,10), Date(2011,3,15)]
    # ... other fields
)

# Validate and wrap the DataFrame with HealthTable
ht_conditions = HealthTable(condition_occurrence_df; omop_cdm_version="v5.4.1")

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
# DataFrame(ht_conditions)
```

## Preprocessing and Utilities

Preprocessing utilities can operate on `HealthTable` objects (or their materialized versions), leveraging the `Tables.jl` interface and schema awareness derived via `Tables.schema`.

Examples include:

- `one_hot_encode(ht::HealthTable, column_symbol::Symbol; drop_original=true)`
- `apply_vocabulary_compression(ht::HealthTable, column_symbol::Symbol, mapping_dict::Dict)`
- `map_concepts(ht::HealthTable, column_symbol::Symbol, concept_map::AbstractDict)`
- `map_concepts!(ht::HealthTable, column_symbol::Symbol, concept_map::AbstractDict)` *(in-place version)*

These functions follow the principle of user-triggered, optional transformations configurable via keyword arguments.
