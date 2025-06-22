@testset "HealthBaseOMOPCDMExt" begin
    # This DataFrame is compliant with the OMOP CDM v5.4.0 PERSON table schema.
    person_df_good = DataFrame(
        person_id=1,
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

    @testset "Constructor and Type Validation" begin
        @testset "Valid DataFrame" begin
            ht = HealthTable(person_df_good; omop_cdm_version="v5.4.0")
            @test ht isa HealthBase.HealthTable
            @test ht.omop_cdm_version == "v5.4.0"
        end

        @testset "Invalid DataFrame - Single Error" begin
            @test_throws ArgumentError HealthTable(person_df_bad; omop_cdm_version="v5.4.0")
        end
    end
end