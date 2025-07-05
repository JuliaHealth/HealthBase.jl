using PrettyTables
using DataFrames

function Base.show(io::IO, ht::HealthTable)
    df = ht.source

    if nrow(df) == 0
        pretty_table(io, ["HealthTable is empty"]; header = [""])
    else
        pretty_table(io, df; alignment = :l)
    end

    if haskey(metadata(df), "omop_cdm_version")
        println(io, "\nOMOP CDM version: ", metadata(df, "omop_cdm_version"))
    end

    return nothing
end
