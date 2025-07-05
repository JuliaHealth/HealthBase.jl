# Quickstart: Preprocessing OMOP Data

## 1. Load Packages

First, start a Julia session in your project environment and load the necessary packages.

NOTE: For the workflow to work, we need to load the trigger packages `DataFrames`, `OMOPCommonDataModel`, `InlineStrings`, `Serialization`, `Statistics`, and `Dates` before loading `HealthBase.jl`. See the "For Developers" section below for more information.

```julia
# First, load the trigger packages
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Statistics, Dates, FeatureTransforms, DBInterface, DuckDB

# Then, load HealthBase
using HealthBase
```

## 2. Create Example DataFrames

We'll create two `DataFrame`s:

* `good_df` — a minimal, valid slice of the OMOP *person* table.
* `wrong_df` — intentionally invalid (wrong types & extra column) so you can see the constructor’s validation in action.

```julia
good_df = DataFrame(
    person_id = 1:6,
    gender_concept_id = [8507, 8507, 8532, 8532, 8507, 8532],
    year_of_birth = [1980, 1995, 1990, 1975, 1988, 2001],
    race_concept_id = [8527, 8515, 8527, 8516, 8527, 8516]
)

# Invalid DataFrame to test validation
wrong_df = DataFrame(
    person_id = ["1", "2"],
    gender_concept_id = [8507, 8532],
    year_of_birth = [1990, 1985],
    race_concept_id = [8527, 8516],
    illegal_extra_col = [true, false],
)

metadata!(good_df, "omop_cdm_version", "v5.4.1")
ht = HealthTable(good_df)

# OMOP CDM version metadata
metadata(ht.source, "omop_cdm_version")

# Will give column-specific metadata
colmetadata(ht.source, :gender_concept_id)

# This will throw an error (strict enforcement)
metadata!(wrong_df, "omop_cdm_version", "v5.4.1")
ht = HealthTable(wrong_df; disable_type_enforcement = false)

# If you want to *load anyway* and just receive warnings, disable type enforcement:
ht_relaxed = HealthTable(wrong_df; omop_cdm_version="v5.4.1", disable_type_enforcement = true)
```

## 3. Preprocessing Pipeline

Now, we'll apply a series of transformations to clean and prepare the data.

### Mapping Concepts

Convert categorical codes into binary indicator columns.

```julia
conn = DBInterface.connect(DuckDB.DB, "synthea_1M_3YR.duckdb")

# Single column, auto-suffixed column name (gender_concept_id_mapped)
ht_mapped = map_concepts(ht, :gender_concept_id, conn; schema = "dbt_synthea_dev")

# Multiple columns, custom new column names
ht_mapped2 = map_concepts(ht, [:gender_concept_id, :race_concept_id], conn; new_cols = ["gender", "race"], schema = "dbt_synthea_dev", drop_original=true)

# In-place variant
map_concepts!(ht, [:gender_concept_id], conn; schema = "dbt_synthea_dev")
```

### Custom Concept Mapping (Manual, Without DB)
Sometimes, you may want to map concept IDs using a custom dictionary instead of querying the database.

```julia
# Define custom mapping manually
custom_map = Dict(8507 => "Male", 8532 => "Female")

# Option 1: Add a new column using `Base.map`
ht.source.gender_label = map(x -> get(custom_map, x, "Unknown"), ht.source.gender_concept_id)

# Option 2: Use `Base.map!` with a new destination vector
gender_labels = Vector{String}(undef, length(ht.source.gender_concept_id))
map!(x -> get(custom_map, x, "Unknown"), gender_labels, ht.source.gender_concept_id)
ht.source.gender_label = gender_labels
```

### Compress sparse categories (optional)

Group infrequent levels into a single label (e.g. "Other") so downstream models aren’t overwhelmed by very rare categories.

```julia
ht_compressed = apply_vocabulary_compression(ht_mapped; cols = [:race_concept_id], min_freq = 2, other_label = "Other")
```

### One-hot encode categorical columns

Convert categorical codes into binary indicator columns.

```julia
ht_ohe = one_hot_encode(ht_compressed; cols=[:gender_concept_id, :race_concept_id])
```

### For Developers: Interactive Use in the REPL

When working with `HealthBase.jl` interactively in the Julia REPL, especially during development, it's important to load packages in the correct order to ensure that package extensions are activated.

If you call a function from an extension (e.g. `one_hot_encode`) and get a `MethodError`, the extension probably wasn't loaded. To fix this, make sure you load the "trigger packages" **before** you load `HealthBase`.

For the OMOP CDM extension, the trigger packages are `DataFrames`, `OMOPCommonDataModel`, `InlineStrings`, `Serialization`, `Statistics`, and `Dates`.

**Correct Loading Order:**
```julia
# First, load the trigger packages
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Statistics, Dates, FeatureTransforms, DBInterface, DuckDB

# Then, load HealthBase
using HealthBase

# Now, functions from the extension will be available
# ht_ohe = one_hot_encode(ht; cols=[:gender_concept_id]) # This will now work
```
