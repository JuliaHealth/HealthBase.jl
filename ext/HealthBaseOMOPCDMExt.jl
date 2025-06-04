module HealthBaseOMOPExt

using HealthBase
using DataFrames
using OMOPCommonDataModel

__init__() = @info "OMOP CDM extension for HealthBase has been loaded!"

"""
    HealthTable(df::DataFrame, omop_cdm_version="5.4"; disable_type_enforcement=false)

Validate a DataFrame against the OMOP CDM specification for the given version.

Checks column names/types, attaches OMOP metadata to columns, and returns the DataFrame.

If `disable_type_enforcement` is true, type mismatches emit warnings instead of errors.
"""
function HealthBase.HealthTable(df::DataFrame, omop_cdm_version="5.4"; disable_type_enforcement=false)
    # TODO: have to add logic for version specific fields types
    omop_fields = Dict{String, Dict{Symbol, Any}}() 

    for t in subtypes(OMOPCommonDataModel.CDMType)
        for f in fieldnames(t)
            actual_field_type = fieldtype(t, f)
            omop_fields[string(f)] = Dict(:type => actual_field_type)
        end
    end

    for col in names(df)
        if haskey(omop_fields, col)
            fieldinfo = omop_fields[col]
            expected_type = get(fieldinfo, :type, Any)
            actual_type = eltype(df[!, col])

            if !(actual_type <: expected_type)
                msg = "Column '$(col)' has type $(actual_type), expected $(expected_type)"
                if disable_type_enforcement
                    @warn msg
                else
                    throw(ArgumentError(msg))
                end
            end

            for (key, val) in fieldinfo
                colmetadata!(df, col, string(key), string(val), style=:note)
            end
        end
    end

    return df
end