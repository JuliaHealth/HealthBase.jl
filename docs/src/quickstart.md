# Quickstart

Welcome to the **Quickstart** guide for [`HealthBase.jl`](https://github.com/JuliaHealth/HealthBase.jl)!  
This guide walks you through setting up your Julia environment, creating example OMOP CDM data, validating it, and applying preprocessing steps using the `HealthTable` system.

## Getting Started

### Launch Julia and Enter Your Project Environment

To get started:

1. Open your terminal or Julia REPL.
2. Navigate to your project folder (where `Project.toml` is located):

```sh
cd path/to/your/project
```

3. Activate the project:

```julia
julia --project=.
```

4. (Optional for docs) For working on documentation:

```sh
julia --project=docs
```

## 1. Load Packages

Before loading `HealthBase`, you must first load some **trigger packages**.  
These packages enable HealthBase's extensions, which power important features like type validation and concept mapping.

> ⚠️ **Important:** Load the following packages **before** `using HealthBase`.  
> Otherwise, some functions may not be available due to missing extensions.

```julia
# First, load the trigger packages
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Dates, FeatureTransforms, DBInterface, DuckDB

# Then, load HealthBase
using HealthBase
```

## 2. Create Example DataFrames

We'll create two `DataFrame`s:

- `good_df` - a minimal, valid slice of the OMOP _person_ table.
- `wrong_df` - intentionally invalid (wrong types & extra column) so you can see the constructor’s validation in action.

```julia
good_df = DataFrame(
    person_id = 1:6,
    gender_concept_id = [8507, 8507, 8532, 8532, 8507, 8532],
    year_of_birth = [1980, 1995, 1990, 1975, 1988, 2001],
    race_concept_id = [8527, 8515, 8527, 8516, 8527, 8516]
)

# Invalid DataFrame to test validation
wrong_df = DataFrame(
    person_id = ["1", "2"],            # Should be Int64
    gender_concept_id = [8507, 8532],
    year_of_birth = [1990, 1985],
    race_concept_id = [8527, 8516],
    extra_col = [true, false],         # Extra column not in the OMOP schema
)

ht = HealthTable(good_df; omop_cdm_version="v5.4.1")

# OMOP CDM version metadata
metadata(ht.source, "omop_cdm_version")

# Will give column-specific metadata
colmetadata(ht.source, :gender_concept_id)

# This will throw an error (strict enforcement)
ht = HealthTable(wrong_df; omop_cdm_version="v5.4.1", disable_type_enforcement = false)

# If you want to *load anyway* and just receive warnings, disable type enforcement:
ht_relaxed = HealthTable(wrong_df; omop_cdm_version="v5.4.1", disable_type_enforcement = true)
```

## 3. Preprocessing Pipeline

Now, we'll apply a series of transformations to clean and prepare the data.

### Mapping Concepts

Convert concept codes (e.g., gender ID) into readable or binary columns using a DuckDB connection.

```julia
conn = DBInterface.connect(DuckDB.DB, "synthea_1M_3YR.duckdb")

# Single column, auto-suffixed column name (gender_concept_id_mapped)
ht_mapped = map_concepts(ht, :gender_concept_id, conn; schema = "dbt_synthea_dev")

# Multiple columns, custom new column names
ht_mapped2 = map_concepts(ht, [:gender_concept_id, :race_concept_id], conn; new_cols = ["gender", "race"], schema = "dbt_synthea_dev", drop_original=true)

# In-place variant
map_concepts!(ht, [:gender_concept_id], conn; schema = "dbt_synthea_dev")
```

### Manual Concept Mapping (Without DB)

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

### Compress sparse categories

Group rare values into an "Other" category so they don’t overwhelm your model.

```julia
ht_compressed = apply_vocabulary_compression(ht_mapped; cols = [:race_concept_id], min_freq = 2, other_label = "Other")
```

### One-hot encode categorical columns

Convert categorical codes into binary indicator columns (true/false).

```julia
ht_ohe = one_hot_encode(ht_compressed; cols=[:gender_concept_id, :race_concept_id])
```

### For Developers: Interactive Use in the REPL

When working interactively in the REPL during development:

- Always load the **trigger packages first**
- Then load `HealthBase`
- Only after that, use extension functions like `one_hot_encode`, `map_concepts`, etc.

```julia
# Correct load order for extensions to work:
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Dates, FeatureTransforms, DBInterface, DuckDB
using HealthBase

# Now this will work:
# ht_ohe = one_hot_encode(ht; cols=[:gender_concept_id])
```

Happy experimenting with `HealthBase.jl`! 🎉  
Feel free to explore more advanced workflows in the other guide sections.
