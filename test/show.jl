@testset "HealthTable Show Methods" begin
    # Test with basic HealthTable
    df = DataFrame(
        person_id = 1:3,
        gender_concept_id = [8507, 8532, 8507],
        year_of_birth = [1990, 1985, 2000],
    )
    ht = HealthBase.HealthTable(df)

    @testset "Basic show functionality" begin
        # Test that show returns nothing
        output = show(IOBuffer(), ht)
        @test output === nothing

        # Test show output contains table data
        io = IOBuffer()
        show(io, ht)
        output_str = String(take!(io))
        @test contains(output_str, "person_id")
        @test contains(output_str, "gender_concept_id")
        @test contains(output_str, "year_of_birth")
    end

    @testset "Empty HealthTable show" begin
        empty_df = DataFrame(person_id = Int[], gender_concept_id = Int[])
        empty_ht = HealthBase.HealthTable(empty_df)

        io = IOBuffer()
        show(io, empty_ht)
        output_str = String(take!(io))
        @test contains(output_str, "HealthTable is empty")
    end

    @testset "Show with OMOP CDM metadata" begin
        # Check if OMOP extension is available for metadata test
        ext = Base.get_extension(HealthBase, :HealthBaseOMOPCDMExt)
        if !isnothing(ext)
            ht_omop = HealthBase.HealthTable(df; omop_cdm_version = "v5.4.1")

            io = IOBuffer()
            show(io, ht_omop)
            output_str = String(take!(io))
            @test contains(output_str, "OMOP CDM version: v5.4.1")
        else
            @warn "HealthBaseOMOPCDMExt not available, skipping OMOP metadata test"
        end
    end

    @testset "Show with regular metadata" begin
        df_with_meta = copy(df)
        DataFrames.metadata!(df_with_meta, "omop_cdm_version", "v5.4.0")
        ht_meta = HealthBase.HealthTable(df_with_meta)

        io = IOBuffer()
        show(io, ht_meta)
        output_str = String(take!(io))
        @test contains(output_str, "OMOP CDM version: v5.4.0")
    end
end
