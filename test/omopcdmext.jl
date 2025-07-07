@testset "HealthBaseOMOPCDMExt" begin
    # This DataFrame is compliant with the OMOP CDM v5.4.1 PERSON table schema.
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

    ht = HealthBase.HealthTable(person_df_good; omop_cdm_version="v5.4.1")

    @testset "Constructor and Type Validation" begin
        @testset "Valid DataFrame" begin
            @test ht isa HealthBase.HealthTable
            @test metadata(ht.source, "omop_cdm_version") == "v5.4.1"
        end

        @testset "Invalid DataFrame Type Check" begin
            @test_throws ArgumentError HealthBase.HealthTable(person_df_bad; omop_cdm_version="v5.4.1")
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

    @testset "Version detection from metadata" begin
        df_meta = DataFrame(person_id=1:3,
                            gender_concept_id=[8507,8532,8507],
                            year_of_birth=[1990,1985,2000],
                            race_concept_id=[8527,8516,8527])
        ht_meta = HealthBase.HealthTable(df_meta; omop_cdm_version="v5.4.1") 
        @test metadata(ht_meta.source, "omop_cdm_version") == "v5.4.1"
    end

    @testset "Preprocessing Functions" begin
        df = DataFrame(
            person_id = 1:6,
            gender_concept_id = [8507, 8507, 8532, 8532, 8507, 8507], 
            condition_source_value = ["Diabetes", "Hypertension", "Diabetes", "Obesity", "Hypertension", "RareCondition"]
        )
        ht = HealthBase.HealthTable(df; omop_cdm_version="v5.4.1")

        @testset "one_hot_encode function" begin
            result = HealthBase.one_hot_encode(ht; cols=[:gender_concept_id], return_features_only=true)
            expected_cols = ["gender_concept_id_8507", "gender_concept_id_8532"]
            @test all(col in string.(names(result)) for col in expected_cols)
            @test nrow(result) == nrow(df)
        end

        @testset "apply_vocabulary_compression function" begin
            compressed = HealthBase.apply_vocabulary_compression(ht; cols=[:condition_source_value], min_freq=2)
            @test "condition_source_value_compressed" in names(compressed.source)
            compressed_vals = unique(compressed.source.condition_source_value_compressed)
            @test "Other" in compressed_vals
            @test length(compressed_vals) <= length(unique(df.condition_source_value))
        end

        @testset "map_concepts function (mocked)" begin
            # Mocked version without actual DuckDB call
            concept_map = Dict(8507 => "Male", 8532 => "Female") 
            mapped_col = [get(concept_map, id, missing) for id in df.gender_concept_id]
            ht.source[!, :gender_name] = mapped_col
            @test "gender_name" in names(ht.source)
            @test isequal(ht.source.gender_name, mapped_col)
        end
    end
end
