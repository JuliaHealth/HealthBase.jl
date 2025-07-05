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
using DuckDB               
using DBInterface: execute

# NOTE: In the future, replace this with OMOP CDM version info directly from OMOPCommonDataModel.jl dependencies.
const OMOPCDM_VERSIONS = deserialize(joinpath(@__DIR__, "..", "assets", "version_info"))

# Mapping OMOP CDM datatypes to Julia types
const DATATYPE_MAP = Dict(
    "integer" => Int64, "Integer" => Int64, "bigint" => Int64,
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
    HealthTable(df::DataFrame; omop_cdm_version=nothing, disable_type_enforcement=false, collect_errors=true)

Constructs a `HealthTable` for an OMOP CDM dataset by validating the given `DataFrame`.

This constructor validates the `DataFrame` against the OMOP CDM schema. If `omop_cdm_version` is not provided, it will try to read the version from `metadata(df, "omop_cdm_version")`; if that is absent it defaults to "v5.4.0". It checks that
column names are valid OMOP CDM fields and that their data types are compatible. It then
attaches all available metadata from the OMOP CDM specification to the `DataFrame`'s columns.

By default, it checks all columns and then throws a single `ArgumentError` that lists all
columns with type mismatches. This behavior can be modified with the keyword arguments below.

## Arguments
- `df::DataFrame`: The `DataFrame` to wrap. It should contain columns corresponding to an OMOP CDM table.

## Keyword Arguments
- `omop_cdm_version::Union{Nothing,String}=nothing`: Optional. Pass a specific version or leave `nothing` to auto-detect from the DataFrame metadata (falls back to "v5.4.0").
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
    omop_cdm_version::Union{Nothing,String}=nothing, 
    disable_type_enforcement=false, 
    collect_errors=true
)
    if omop_cdm_version === nothing
        omop_cdm_version = haskey(metadata(df), "omop_cdm_version") ? metadata(df, "omop_cdm_version") : "v5.4.0"
    end

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

            if !haskey(DATATYPE_MAP, expected_string)
                push!(failed_columns, (colname=col, type=actual_type, expected="Unrecognized OMOP datatype: $(expected_string)"))
            else
                expected_type = DATATYPE_MAP[expected_string]

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

    return HealthBase.HealthTable{typeof(df)}(df)
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

    return return_features_only ? df : HealthBase.HealthTable{typeof(df)}(df)
end

"""
    map_concepts(ht::HealthTable, col::Symbol, new_col::String, conn::DuckDB.DB; drop_original::Bool = false, concept_table::String = "concept", schema::String = "main")

Map concept IDs in a column to their corresponding concept names using the OMOP `concept` table.

# Arguments
- `ht::HealthTable`: The input table containing OMOP data.
- `col::Symbol`: Column name in the HealthTable containing concept IDs (e.g. `:gender_concept_id`).
- `new_col::String`: Name of the new column to store the mapped concept names (e.g. `"gender_name"`).
- `conn::DuckDB.DB`: Active DuckDB connection to the OMOP database.
- `drop_original::Bool`: If `true`, the original column (`col`) is dropped after mapping.
- `concept_table::String`: Table name for OMOP concepts (default `"concept"`).
- `schema::String`: Schema where the concept table resides (default `"main"`).

# Returns
- A new `HealthTable` with the concept names added in `new_col`.

# Notes
- Only direct mappings using concept IDs are supported.
- If no matching concept names are found, `missing` is used.
- For hierarchical mappings (e.g., via `concept_ancestor`), need to implement.

# Example
```julia
conn = DBInterface.connect(DuckDB.DB, "path/to/db/.duckdb")

# Map gender_concept_id to concept_name
ht_mapped = map_concepts(ht, :gender_concept_id, "gender_name", conn; schema = "dbt_synthea_dev")
```
"""

function HealthBase.map_concepts(
    ht::HealthTable,
    cols::Union{Symbol, Vector{Symbol}},
    conn::DuckDB.DB;
    new_cols::Union{Nothing, String, Vector{String}} = nothing,
    drop_original::Bool = false,
    suffix::String = "_mapped",
    concept_table::String = "concept",
    schema::String = "main"
)
    df = copy(ht.source)
    _map_concepts!(df, cols, conn; new_cols, drop_original, suffix, concept_table, schema)

    return HealthBase.HealthTable{typeof(df)}(df)
end


function HealthBase.map_concepts!(
    ht::HealthTable,
    cols::Union{Symbol, Vector{Symbol}},
    conn::DuckDB.DB;
    new_cols::Union{Nothing, String, Vector{String}} = nothing,
    drop_original::Bool = false,
    suffix::String = "_mapped",
    concept_table::String = "concept",
    schema::String = "main"
)
    _map_concepts!(
        ht.source,
        cols,
        conn;
        new_cols = new_cols,
        drop_original = drop_original,
        suffix = suffix,
        concept_table = concept_table,
        schema = schema
    )
    return ht
end


function _map_concepts!(
    df::DataFrame,
    cols::Union{Symbol, Vector{Symbol}},
    conn::DuckDB.DB;
    new_cols::Union{Nothing, String, Vector{String}} = nothing,
    drop_original::Bool = false,
    suffix::String = "_mapped",
    concept_table::String = "concept",
    schema::String = "main"
)
    cols = isa(cols, Symbol) ? [cols] : cols

    if isnothing(new_cols)
        new_cols = [string(col, suffix) for col in cols]
    elseif isa(new_cols, String)
        new_cols = [new_cols]
    end

    @assert length(cols) == length(new_cols) "Length of `cols` and `new_cols` must match."

    for (col, new_col) in zip(cols, new_cols)
        @assert col in propertynames(df) "Column '$col' not found in table."

        ids = unique(skipmissing(df[!, col]))
        if isempty(ids)
            @warn "No concept_ids found in column $col; skipping."
            continue
        end

        id_list_str = join(ids, ", ")
        query = """
            SELECT concept_id, concept_name
            FROM $schema.$concept_table
            WHERE concept_id IN ($id_list_str)
        """

        result_df = DataFrame(execute(conn, query))
        if isempty(result_df)
            @warn "Concept mapping for $col returned empty result. Check table, schema, and values."
            continue
        end

        mapping = Dict((cid => cname) for (cid, cname) in zip(result_df.concept_id, result_df.concept_name))
        df[!, new_col] = map(x -> get(mapping, x, missing), df[!, col])

        if drop_original
            select!(df, Not(col))
        end
    end
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
    min_freq::Integer = 10,
    other_label::AbstractString = "Other",
    new_cols::Union{Nothing,Symbol,Vector{Symbol}} = nothing,
    suffix::AbstractString = "_compressed",
    drop_original::Bool = false,
)
    df = copy(ht.source)

    for col in cols
        @assert col in propertynames(df) "Column '$(col)' not found in table."
        dest_col = Symbol(string(col), "_compressed")
        counts = combine(groupby(df, col), nrow => :freq)
        to_compress = counts[counts.freq .< min_freq, col]
        if !isempty(to_compress)
            df[!, dest_col] = map(x -> in(x, to_compress) ? other_label : string(x), df[!, col])
        end
    end

    if drop_original
        select!(df, Not(cols))
    end

    return HealthBase.HealthTable{typeof(df)}(df)
end

end

