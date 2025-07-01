@testset "HealthBaseOMOPCDMExt" begin
    # This DataFrame is compliant with the OMOP CDM v5.4.0 PERSON table schema.
    person_df_good = DataFrame(
        person_id=BigInt(1),
        gender_concept_id=8507,
        year_of_birth=1990,
        month_of_birth=1,
        day_of_birth=1,
        birth_datetime=DateTime(1990, 1, 1),
        race_concept_id=0,
        ethnicity_concept_id=0
    )

    # This DataFrame has an incorrect type for the `year_of_birth` column.
    person_df_bad = DataFrame(
        person_id=1,
        gender_concept_id=8507,
        year_of_birth="1990", # Incorrect: Should be an Int
        month_of_birth=1,
        day_of_birth=1,
        birth_datetime=DateTime(1990, 1, 1),
        race_concept_id=0,
        ethnicity_concept_id=0
    )

    ht = HealthTable(person_df_good; omop_cdm_version="v5.4.0")
    @testset "Constructor and Type Validation" begin
        @testset "Valid DataFrame" begin
            @test ht isa HealthBase.HealthTable
            @test ht.omop_cdm_version == "v5.4.0"
        end

        @testset "Invalid DataFrame - Single Error" begin
            @test_throws ArgumentError HealthTable(person_df_bad; omop_cdm_version="v5.4.0")
        end
    end

    @testset "HealthTable Tables.jl interface" begin
        @test Tables.istable(typeof(ht)) == true
    
        # Test schema matches DataFrame
        sch_ht = Tables.schema(ht)
        sch_df = Tables.schema(person_df_good)
        @test sch_ht.names == sch_df.names
        @test sch_ht.types == sch_df.types
    
        # Test rows
        rows_ht = collect(Tables.rows(ht))
        rows_df = collect(Tables.rows(person_df_good))
        @test length(rows_ht) == length(rows_df)
        @test rows_ht[1].person_id == rows_df[1].person_id
    
        # Test DataFrame materialization
        df2 = DataFrame(ht)
        @test df2 == person_df_good
    end
end