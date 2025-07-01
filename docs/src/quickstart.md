# Quickstart: Preprocessing OMOP Data

## 1. Load Packages

First, start a Julia session in your project environment and load the necessary packages.

NOTE: For the workflow to work, we need to load the trigger packages `DataFrames`, `OMOPCommonDataModel`, `InlineStrings`, `Serialization`, `Statistics`, and `Dates` before loading `HealthBase.jl`. See the "For Developers" section below for more information.

```julia
# First, load the trigger packages
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Statistics, Dates

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

ht = HealthTable(good_df, omop_cdm_version="v5.4.1")

# This will throw an error
ht = HealthTable(wrong_df, omop_cdm_version="v5.4.1")
```

## 3. Preprocessing Pipeline

Now, we'll apply a series of transformations to clean and prepare the data.

### Step A: One-hot encode categorical columns

Convert categorical codes into binary indicator columns.

```julia
ht_ohe = one_hot_encode(ht; cols=[:gender_concept_id, :race_concept_id])
```

### Step B: Compress infrequent levels

Group rare `race_concept_id` values under a single "Other" label.

```julia
ht_small = apply_vocabulary_compression(ht_ohe; cols=[:race_concept_id], min_freq=2)
```

### For Developers: Interactive Use in the REPL

When working with `HealthBase.jl` interactively in the Julia REPL, especially during development, it's important to load packages in the correct order to ensure that package extensions are activated.

If you call a function from an extension (e.g. `one_hot_encode`) and get a `MethodError`, the extension probably wasn't loaded. To fix this, make sure you load the "trigger packages" **before** you load `HealthBase`.

For the OMOP CDM extension, the trigger packages are `DataFrames`, `OMOPCommonDataModel`, `InlineStrings`, `Serialization`, `Statistics`, and `Dates`.

**Correct Loading Order:**
```julia
# First, load the trigger packages
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Statistics, Dates

# Then, load HealthBase
using HealthBase

# Now, functions from the extension will be available
# ht_ohe = one_hot_encode(ht; cols=[:gender_concept_id]) # This will now work
```
