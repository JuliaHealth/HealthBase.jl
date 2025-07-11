using PrettyTables
using DataFrames

"""
    Base.show(io::IO, ht::HealthTable)

Pretty-print a `HealthTable` to any IO stream (REPL, file, etc.).

- If the underlying table is empty, prints a friendly message.
- Otherwise prints the full table using **PrettyTables.jl** with left-aligned columns.
- Displays the OMOP-CDM version (from metadata) beneath the table when available.

This method is purely for display; it returns `nothing`.
"""
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
