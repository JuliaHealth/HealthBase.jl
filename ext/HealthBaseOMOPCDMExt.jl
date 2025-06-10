module HealthBaseOMOPCDMExt

using HealthBase
using DataFrames
using OMOPCommonDataModel
using OMOPCommonDataModel: OMOPCDM_VERSIONS

function __init__()
    @info "OMOP CDM extension for HealthBase has been loaded!"
end

"""
    HealthTable(df::DataFrame; omop_cdm_version="5.4", disable_type_enforcement=false)

Constructs a `HealthTable` for an OMOP CDM dataset by validating the given `DataFrame`.

This constructor validates the `DataFrame` against the specified OMOP CDM version. It checks that
column names are valid OMOP CDM fields and that their data types are compatible. It then
attaches all available metadata from the OMOP CDM specification to the DataFrame's columns.

If `disable_type_enforcement` is true, type mismatches will emit warnings instead of errors.

Returns a `HealthTable` object wrapping the validated DataFrame.
"""
function HealthBase.HealthTable(df::DataFrame; omop_cdm_version::String="5.4", disable_type_enforcement=false)
    if !haskey(OMOPCDM_VERSIONS, omop_cdm_version)
        throw(ArgumentError("OMOP CDM version '$(omop_cdm_version)' is not supported. Available versions: $(keys(OMOPCDM_VERSIONS))"))
    end

    omop_fields = OMOPCDM_VERSIONS[omop_cdm_version][:fields]

    for col in names(df)
        col_symbol = Symbol(col)
        if haskey(omop_fields, col_symbol)
            fieldinfo = omop_fields[col_symbol]
            expected_type = get(fieldinfo, :type, Any)
            actual_type = eltype(df[!, col_symbol])

            if !(actual_type <: expected_type)
                msg = "Column '$(col)' has type $(actual_type), but expected a subtype of $(expected_type)"
                if disable_type_enforcement
                    @warn msg
                else
                    throw(ArgumentError(msg))
                end
            end

            for (key, val) in fieldinfo
                if !isnothing(val) 
                    colmetadata!(df, col_symbol, String(key), string(val); style=:note)
                end
            end
        end
    end

    return HealthBase.HealthTable(source=df, omopcdm_version=omop_cdm_version)
end

end