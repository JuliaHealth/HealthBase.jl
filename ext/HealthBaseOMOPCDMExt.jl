module HealthBaseOMOPCDMExt

using HealthBase
using DataFrames
using OMOPCommonDataModel
using Serialization
using InlineStrings
using Dates
using Statistics

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
    df::DataFrame; omop_cdm_version::String="v5.4.0", 
    disable_type_enforcement=false, 
    collect_errors=true
)
    if !haskey(OMOPCDM_VERSIONS, omop_cdm_version)
        throw(ArgumentError("OMOP CDM version '$(omop_cdm_version)' is not supported. Available versions: $(keys(OMOPCDM_VERSIONS))"))
    end

    omop_fields = OMOPCDM_VERSIONS[omop_cdm_version][:fields]
    failed_columns = []

    for col in names(df)
        col_symbol = Symbol(col)
        if haskey(omop_fields, col_symbol)
            fieldinfo = omop_fields[col_symbol]
            actual_type = eltype(df[!, col_symbol])

            if !haskey(fieldinfo, :cdmDatatype)
                if !collect_errors
                    throw(ArgumentError("Column '$(col)' is missing :cdmDatatype information in the schema."))
                end
                push!(failed_columns, (colname=col, type=actual_type, expected="<missing from schema>"))
            else
                expected_string = fieldinfo[:cdmDatatype]
                expected_type = get(datatype_map, expected_string, Any)

                if !(actual_type <: expected_type)
                    if !collect_errors
                        throw(ArgumentError("Column '$(col)' has type $(actual_type), but expected a subtype of $(expected_type)."))
                    end
                    push!(failed_columns, (colname=col, type=actual_type, expected=expected_type))
                end
            end

            for (key, val) in fieldinfo
                if !ismissing(val)
                    colmetadata!(df, col_symbol, String(key), string(val); style=:note)
                end
            end
        end
    end

    if !isempty(failed_columns)
        error_details = join(["Column '$(err.colname)': Has type $(err.type), expected subtype of $(err.expected)" for err in failed_columns], "\n")
        full_message = "OMOP CDM type validation failed for the following columns:\n" * error_details

        if disable_type_enforcement
            @warn full_message * "\nType enforcement is disabled. Unexpected behavior may occur."
        else
            throw(ArgumentError(full_message))
        end
    end

    return HealthBase.HealthTable(source=df, omop_cdm_version=omop_cdm_version)

end

# TODO: Add Documentation
function HealthBase.one_hot_encode(
    ht::HealthTable; 
    cols::Vector{Symbol}, 
    drop_original::Bool=true
)
    df = copy(ht.source)
    for col in cols
        unique_vals = unique(skipmissing(df[!, col]))
        for val in unique_vals
            new_col = Symbol("$(col)_", string(val))
            df[!, new_col] = df[!, col] .== val
        end
        if drop_original
            select!(df, Not(col))
        end
    end
    return HealthBase.HealthTable(df; omop_cdm_version=ht.omop_cdm_version)
end

# TODO: Add Documentation
function HealthBase.impute_missing(
    ht::HealthTable;
    cols::Union{Vector{Symbol}, Vector{Pair{Symbol,Symbol}}},
    strategy::Symbol=:mean,
)
    df = copy(ht.source)

    strat_pairs = cols isa Vector{Symbol} ? [c => strategy for c in cols] : cols

    for (col, strat) in strat_pairs
        @assert col in propertynames(df) "Column '$(col)' not found in table."
        vals = df[!, col]
        nonmiss = collect(skipmissing(vals))
        if isempty(nonmiss)
            throw(ArgumentError("Column '$(col)' has only missing values – cannot impute."))
        end

        replacement = begin
            if strat == :mean
                mean(nonmiss)
            elseif strat == :median
                median(nonmiss)
            elseif strat == :mode
                mode_val = nothing
                counts = Dict{Any,Int}()
                for v in nonmiss
                    counts[v] = get(counts,v,0)+1
                    if mode_val === nothing || counts[v] > counts[mode_val]
                        mode_val = v
                    end
                end
                mode_val
            else
                throw(ArgumentError("Unsupported imputation strategy '$(strat)'. Supported: :mean, :median, :mode."))
            end
        end
        df[!, col] = coalesce.(vals, replacement)
    end

    return HealthBase.HealthTable(source=df, omop_cdm_version=ht.omop_cdm_version)
end

# TODO: Add Documentation
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
    return HealthBase.HealthTable(source=df, omop_cdm_version=ht.omop_cdm_version)
end

# TODO: Add Documentation
function HealthBase.map_concepts(
    ht::HealthTable;
    col::Symbol,
    mapping::AbstractDict,
    new_col::Union{Symbol,Nothing}=nothing,
    drop_original::Bool=false,
)
    @assert col in propertynames(ht.source) "Column '$(col)' not found in table."
    df = copy(ht.source)

    target_col = isnothing(new_col) ? col : new_col
    df[!, target_col] = get.(Ref(mapping), df[!, col], df[!, col])

    if drop_original && !isnothing(new_col)
        select!(df, Not(col))
    end

    return HealthBase.HealthTable(source=df, omop_cdm_version=ht.omop_cdm_version)
end

# TODO: Add Documentation
function HealthBase.normalize_column(ht::HealthTable; cols::Vector{Symbol}, method::Symbol=:standard)
    df = copy(ht.source)
    for col in cols
        values = skipmissing(df[!, col])
        if method == :standard
            mean_val = mean(values)
            std_val = std(values)
            if std_val == 0
                throw(ArgumentError("Column '$col' has zero standard deviation."))
            end
            df[!, col] = (df[!, col] .- mean_val) ./ std_val
        else
            throw(ArgumentError("Unsupported normalization method: $method"))
        end
    end
    return HealthBase.HealthTable(df; omop_cdm_version=ht.omop_cdm_version)
end

end