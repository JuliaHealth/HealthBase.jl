# OMOP CDM Support for HealthTable

## Core Goals & Features

The `HealthTable` interface in `HealthBase.jl` is designed to make working with OMOP CDM data in Julia easy, robust, and compatible with the `Tables.jl` ecosystem. The key features include:

- **Schema-Aware Validation**: Instead of just wrapping your data, `HealthTable` actively validates it against the official OMOP CDM specification using `OMOPCommonDataModel.jl`. This includes:
    - **Column Type Enforcement**: Verifies that column types in the input `DataFrame` match the official OMOP schema (e.g., `person_id` is `Int64`, `condition_start_date` is `Date`).
    - **Clear Error Reporting**: If mismatches exist, the constructor returns detailed messages about all invalid columns or can emit warnings if type enforcement is disabled.
    - **Metadata Attachment**: Attaches OMOP metadata (like `cdmDatatype`, `standardConcept`, etc.) directly to each validated column.
    
- **Preprocessing Utilities**: Built-in tools for data preparation include:
    - `one_hot_encode`: One-hot encodes categorical variables using `FeatureTransforms.jl`.
    - `apply_vocabulary_compression`: Groups rare categorical values under a shared `"Other"` label.
    - `map_concepts`: Maps concept IDs to human-readable concept names using a DuckDB-backed `concept` table.
    - `map_concepts!`: An in-place variant of concept mapping that modifies the existing table.

- **Tables.jl Compatibility**: The `HealthTable` type implements the full `Tables.jl` interface so it can be used with any downstream package in the Julia data ecosystem.

- **JuliaHealth Integration**: Designed to interoperate seamlessly with current and future JuliaHealth tools and projects.

- **Extensible Foundation**: The core architecture is extensible future support could include streaming, direct DuckDB views, or remote OMOP datasets.


## `Tables.jl` Interface Sketch

The `HealthTable` type is the main interface for working with OMOP CDM tables. You construct it by passing in a `DataFrame` and optionally specifying a CDM version. The constructor will validate the schema and attach metadata. The resulting object:

- Is a wrapper over the validated DataFrame (`ht.source`),
- Provides schema-aware access to data,
- Can be used anywhere a `Tables.jl`-compatible table is expected.

This eliminates the need for a separate wrapping step the constructor itself ensures conformance and returns a ready-to-use tabular object.

In future extensions, similar wrappers could be created for other data sources, such as database queries or streaming sources. These types would implement the same `Tables.jl` interface to support composable workflows.