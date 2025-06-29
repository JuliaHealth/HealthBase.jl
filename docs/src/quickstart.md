# Quickstart: Preprocessing OMOP Data

This guide demonstrates a practical, end-to-end workflow for cleaning and transforming raw patient data into a format suitable for machine learning using the `HealthBase.jl` preprocessing utilities.

### 1. Load Packages

First, start a Julia session in your project environment and load the necessary packages.

NOTE: For the workflow to work, we need to load the trigger packages `DataFrames`, `OMOPCommonDataModel`, `InlineStrings`, `Serialization`, `Statistics`, and `Dates` before loading `HealthBase.jl`. See the "For Developers" section below for more information.

```julia
# First, load the trigger packages
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Statistics, Dates

# Then, load HealthBase
using HealthBase
```

### 2. Create a Sample Dataset

We'll start with a sample `DataFrame` that mimics raw data from a clinical database. It includes missing values, categorical data, and different data types.

```julia
raw_df = DataFrame(
    person_id = 101:108,
    gender_concept_id = [8507, 8532, 8507, 8532, 8507, 8532, 8507, 8507],
    year_of_birth = [1985, 1992, 1985, 1978, 2000, 2001, 1992, 1988],
    race_concept_id = [8527, 8515, 8527, 8516, 8527, 8515, 8516, 8527],
    cholesterol = [189, 210, 240, missing, 195, 220, missing, 205.0]
)

ht = HealthTable(source=raw_df, omop_cdm_version="v5.4.1")
```

### 3. Preprocessing Pipeline

Now, we'll apply a series of transformations to clean and prepare the data.

#### Step A: Impute Missing Values

First, we'll fill in the `missing` values for `cholesterol` using the mean of each column.

```julia
ht_imputed = impute_missing(ht; cols=[:cholesterol], strategy=:mean)
```

#### Step B: One-Hot Encode Categorical Features

Next, we convert the categorical `gender_concept_id` and `race_concept_id` columns into numerical, binary columns.

```julia
ht_onehot = one_hot_encode(ht_imputed; cols=[:gender_concept_id, :race_concept_id])
```

#### Step C: Normalize Numerical Features

Finally, we scale the `cholesterol` column to have a mean of 0 and a standard deviation of 1. This helps many machine learning algorithms perform better.

```julia
ht_final = normalize_column(ht_onehot; cols=[:cholesterol])

println("--- Final model-ready data ---")
println(ht_final.source)
```

After these steps, `ht_final` contains a fully preprocessed, numerical dataset that is ready to be used for model training.

### For Developers: Interactive Use in the REPL

When working with `HealthBase.jl` interactively in the Julia REPL, especially during development, it's important to load packages in the correct order to ensure that package extensions are activated.

If you try to call a function from an extension (like `impute_missing`) and get a `MethodError`, it's likely because the extension was not loaded. To fix this, make sure you load the "trigger packages" **before** you load `HealthBase`.

For the OMOP CDM extension, the trigger packages are `DataFrames`, `OMOPCommonDataModel`, `InlineStrings`, `Serialization`, `Statistics`, and `Dates`.

**Correct Loading Order:**
```julia
# First, load the trigger packages
using DataFrames, OMOPCommonDataModel, InlineStrings, Serialization, Statistics, Dates

# Then, load HealthBase
using HealthBase

# Now, functions from the extension will be available
# ht_imputed = impute_missing(ht; cols=[:cholesterol], strategy=:mean) # This will now work
```
