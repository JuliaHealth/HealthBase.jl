module HealthBaseOMOPCDMExt

using HealthBase
using DataFrames
using OMOPCommonDataModel
using Serialization
using InlineStrings
using Dates
using Statistics
import FeatureTransforms: 
    OneHotEncoding, apply_append

# NOTE: In the future, replace this with OMOP CDM version info directly from OMOPCommonDataModel.jl dependencies.
const OMOPCDM_VERSIONS = deserialize(joinpath(@__DIR__, "..", "assets", "version_info"))

# Mapping OMOP CDM datatypes to Julia types
const datatype_map = Dict(
    "integer" => Int64, "Integer" => Int64, "bigint" => BigInt,
    "float" => Float64,
    "date" => Date, "datetime" => DateTime,
    "varchar(1)" => String, "varchar(2)" => String, "varchar(3)" => String,
    "varchar(9)" => String, "varchar(10)" => String, "varchar(20)" => String,
    "varchar(25)" => String, "varchar(50)" => String, "varchar(80)" => String,
    "varchar(250)" => String, "varchar(255)" => String, "varchar(1000)" => String,
    "varchar(2000)" => String, "varchar(MAX)" => String
)

function __init__()
    @info "OMOP CDM extension for HealthBase has been loaded!"
end

"""
    HealthTable(df::DataFrame; omop_cdm_version="v5.4.0", disable_type_enforcement=false, collect_errors=true)

Constructs a `HealthTable` for an OMOP CDM dataset by validating the given `DataFrame`.

This constructor validates the `DataFrame` against the specified OMOP CDM version. It checks that
column names are valid OMOP CDM fields and that their data types are compatible. It then
attaches all available metadata from the OMOP CDM specification to the `DataFrame`'s columns.

By default, it checks all columns and then throws a single `ArgumentError` that lists all
columns with type mismatches. This behavior can be modified with the keyword arguments below.

## Arguments
- `df::DataFrame`: The `DataFrame` to wrap. It should contain columns corresponding to an OMOP CDM table.

## Keyword Arguments
- `omop_cdm_version::String="v5.4.0"`: The OMOP CDM version to validate against.
- `disable_type_enforcement::Bool=false`: If `true`, type mismatches will emit a single comprehensive warning instead of throwing an error.
- `collect_errors::Bool=true`: If `false`, the constructor will throw an error immediately upon finding the first column with a type mismatch. If `true` (the default), it will collect all errors and report them in a single message.

## Returns
- `HealthTable`: A new `HealthTable` instance with validated data and attached metadata.

## Examples

1. Loading a DataFrame from scratch:
```julia
using DataFrames, HealthBase
person_df = DataFrame(
    person_id = [1, 2],
    gender_concept_id = [8507, 8532],
    year_of_birth = [1990, 1985],
    month_of_birth = [1, 5],
    day_of_birth = [1, 15],
    birth_datetime = [DateTime(1990,1,1), DateTime(1985,5,15)],
    race_concept_id = [8527, 8515],
    ethnicity_concept_id = [38003563, 38003564]
)
ht = HealthTable(person_df; omop_cdm_version="v5.4.0")
```

2. Loading a DataFrame from a database query:
```julia
using DBInterface, DuckDB, DataFrames, HealthBase
# db = DuckDB.DB("synthea.duckdb") # Example database file
# person_df = DBInterface.execute(db, "SELECT * FROM person") |> DataFrame
# ht = HealthTable(person_df; omop_cdm_version="v5.4.0")
```

3. Accessing column metadata:
```julia
# After constructing ht as above:
colnames = names(ht.source)
coltypes = eltype.(eachcol(ht.source))
# OMOP metadata can be accessed from ht or its source columns if attached
```

4. Quick-fail/warning for bad data:
# TODO: Will finalize the implementation soon and then add an example
"""
function HealthBase.HealthTable(
    df::DataFrame; 
    omop_cdm_version::String="v5.4.0", 
    disable_type_enforcement=false, 
    collect_errors=true
)
    if !haskey(OMOPCDM_VERSIONS, omop_cdm_version)
        throw(ArgumentError("OMOP CDM version '$(omop_cdm_version)' is not supported. Available versions: $(keys(OMOPCDM_VERSIONS))"))
    end

    omop_fields = OMOPCDM_VERSIONS[omop_cdm_version][:fields]
    @assert !isempty(omop_fields) "OMOP CDM version $(omop_cdm_version) has no registered fields."
    failed_columns = Vector{NamedTuple{(:colname, :type, :expected), Tuple{String, Any, Any}}}()
    extra_columns = String[]

    for col in names(df)
        col_symbol = Symbol(col)
        
        if !haskey(omop_fields, col_symbol)
            push!(extra_columns, col)
            continue
        end

        fieldinfo = omop_fields[col_symbol]
        actual_type = eltype(df[!, col_symbol])

        if !haskey(fieldinfo, :cdmDatatype)
            if !collect_errors
                throw(ArgumentError("Column '$(col)' is missing :cdmDatatype information in the schema."))
            end
            push!(failed_columns, (colname=col, type=actual_type, expected="<missing from schema>"))
        else
            expected_string = fieldinfo[:cdmDatatype]

            if !haskey(datatype_map, expected_string)
                push!(failed_columns, (colname=col, type=actual_type, expected="Unrecognized OMOP datatype: $(expected_string)"))
            else
                expected_type = datatype_map[expected_string]

                if !(actual_type <: Union{expected_type, Missing})
                    if !collect_errors
                        throw(ArgumentError("Column '$(col)' has type $(actual_type), but expected a subtype of $(expected_type)."))
                    end
                    push!(failed_columns, (colname=col, type=actual_type, expected=expected_type))
                end
            end

            for (key, val) in fieldinfo
                if !ismissing(val)
                    colmetadata!(df, col_symbol, String(key), string(val))
                end
            end
        end
    end
        
    validation_msgs = String[]

    if !isempty(extra_columns)
        push!(validation_msgs, "DataFrame contains columns not present in OMOP CDM schema: $(extra_columns)")
    end

    if !isempty(failed_columns)
        error_details = join(["Column '$(err.colname)': has type $(err.type), expected $(err.expected)" for err in failed_columns], "\n")
        push!(validation_msgs, "OMOP CDM type validation failed for the following columns:\n" * error_details)
    end

    if !isempty(validation_msgs)
        full_message = join(validation_msgs, "\n\n") * "\n"
        if disable_type_enforcement
            @warn full_message * "\nType enforcement is disabled. Unexpected behavior may occur."
        else
            throw(ArgumentError(full_message))
        end
    end

    DataFrames.metadata!(df, "omop_cdm_version", omop_cdm_version)

    return HealthBase.HealthTable(df, omop_cdm_version)
end   

"""
    one_hot_encode(ht::HealthTable; cols, drop_original=true, return_features_only=false)

One-hot encode the categorical columns in `ht` using **FeatureTransforms.jl**.

For every requested column the function appends Boolean indicator columns — one per
unique (non-missing) level.  New columns are named `col__value`, e.g.
`gender_concept_id__8507`.

Boolean source columns are detected and skipped automatically with a warning.

# Arguments
- `ht::HealthTable`: Table to transform (schema-aware).

# Keyword Arguments
- `cols::Vector{Symbol}`: Categorical columns to encode.
- `drop_original::Bool=true`: Drop the source columns after encoding.
- `return_features_only::Bool=false`: If `true` return a **DataFrame** containing only the
  encoded data; if `false` wrap the result in a `HealthTable` with
  `disable_type_enforcement=true` (because the output is no longer standard OMOP CDM).

# Returns
`DataFrame` or `HealthTable` depending on `return_features_only`.

# Example
```julia
ht_ohe = one_hot_encode(ht; cols = [:gender_concept_id, :race_concept_id])
X     = one_hot_encode(ht; cols = [:gender_concept_id], return_features_only = true) # ML features
```
"""
function HealthBase.one_hot_encode(
    ht::HealthTable;
    cols::Vector{Symbol},
    drop_original::Bool = true,
    return_features_only::Bool = false
)
    df = copy(ht.source)
    missing = setdiff(cols, Symbol.(names(df)))
    @assert isempty(missing) "Columns $(missing) not found."

    for col in cols
        if eltype(df[!, col]) <: Bool
            @warn "Column $col is already Boolean; skipping one-hot."
            continue
        end

        cats = unique(skipmissing(df[!, col]))
        enc = OneHotEncoding(cats)
        header = Symbol.(string(col, "__", c) for c in cats)
        df = apply_append(df, enc; cols=[col], header=header)
    end

    drop_original && select!(df, Not(cols))

    return return_features_only ? df : HealthBase.HealthTable(
        df; omop_cdm_version = ht.omop_cdm_version, disable_type_enforcement=true
    )
end

"""
    apply_vocabulary_compression(ht::HealthTable; cols, min_freq=10, other_label="Other")

Group infrequent categorical levels under a single *other* label.

# Arguments
- `ht::HealthTable`: Input table.

# Keyword Arguments
- `cols::Vector{Symbol}`: Columns to compress.
- `min_freq::Integer=10`: Minimum frequency a value must have to remain
  unchanged.
- `other_label::AbstractString="Other"`: Label used to replace rare
  values.

# Returns
- `HealthTable`: Table with compressed categorical levels.

# Examples
```julia
ht_small = apply_vocabulary_compression(ht; cols=[:condition_source_value], min_freq=5)
```
"""
function HealthBase.apply_vocabulary_compression(
    ht::HealthTable; 
    cols::Vector{Symbol}, 
    min_freq::Integer=10, 
    other_label::AbstractString="Other"
)
    df = copy(ht.source)
    for col in cols
        @assert col in propertynames(df) "Column '$(col)' not found in table."
        counts = combine(groupby(df, col), nrow => :freq)
        to_compress = counts[counts.freq .< min_freq, col]
        if !isempty(to_compress)
            mask = in(to_compress).(df[!, col])
            df[mask, col] .= other_label
        end
    end
    return HealthBase.HealthTable(df, omop_cdm_version=ht.omop_cdm_version)
end

"""
    map_concepts(ht::HealthTable; col, conn, new_col=nothing, drop_original=false, concept_table="concept")

Map OMOP `concept_id`s in `col` to their corresponding `concept_name`s by querying
the `concept` table of an OMOP CDM database using FunSQL.jl.

# Arguments
- `ht::HealthTable`: Input OMOP-compatible table.

# Keyword Arguments
- `col::Symbol`: Column in `ht` containing concept IDs.
- `conn`: A DBInterface-compatible connection (e.g., DuckDB.DB) to an OMOP database.
- `new_col::Union{Symbol,Nothing}=nothing`: Name for the new column. If `nothing`, overwrites `col`.
- `drop_original::Bool=false`: Drop the original column if `new_col` is provided.
- `concept_table::AbstractString="concept"`: Name of the OMOP concept table.

# Returns
- `HealthTable`: A new table with concept names mapped.

# Example
```julia
using DuckDB
conn = DuckDB.DB("omop.duckdb")

ht2 = map_concepts(ht; col=:condition_concept_id, conn=conn, new_col=:condition_name)
```
"""
function HealthBase.map_concepts(
    ht::HealthTable;
    col::Symbol,
    conn,
    new_col::Union{Symbol,Nothing}=nothing,
    drop_original::Bool=false,
    concept_table::AbstractString="concept"
)
    # TODO: Implement this function
end

end

