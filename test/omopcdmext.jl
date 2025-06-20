@testset "Simple HealthTable OMOP CDM Extension Test" begin
    person_df = DataFrame(
        person_id=1,
        gender_concept_id=8507,
        year_of_birth=1990,
        month_of_birth=1,
        day_of_birth=1,
        birth_datetime=DateTime(1990, 1, 1),
        race_concept_id=0,
        ethnicity_concept_id=0
    )

    ht = HealthTable(person_df; omop_cdm_version="5.4")

    @test ht isa HealthBase.HealthTable
    @test ht.omopcdm_version == "5.4"
end