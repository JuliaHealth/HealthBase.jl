module HealthBaseOMOPCDMExt

using HealthBase
using DataFrames
using OMOPCommonDataModel
using Serialization
using InlineStrings
using Dates

const OMOPCDM_VERSIONS = Dict{Any, Any}()

# Mapping OMOP CDM datatypes to Julia types
const datatype_map = Dict(
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
    merge!(OMOPCDM_VERSIONS, deserialize(joinpath(@__DIR__, "..", "assets", "version_info")))
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
Examples will be added in a future update as more functionality is integrated.
"""
function HealthBase.HealthTable(df::DataFrame; omop_cdm_version::String="v5.4.0", disable_type_enforcement=false, collect_errors=true)
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

end
