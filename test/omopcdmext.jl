@testset "HealthBaseOMOPCDMExt" begin
    # Check if extension is loaded properly
    ext = Base.get_extension(HealthBase, :HealthBaseOMOPCDMExt)
    if isnothing(ext)
        @warn "HealthBaseOMOPCDMExt extension is not loaded. Skipping tests."
        return
    end
    
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
            
            # Test with default version
            ht_default = HealthBase.HealthTable(person_df_good)
            @test metadata(ht_default.source, "omop_cdm_version") == "v5.4.0" 
        end

        @testset "Invalid DataFrame Type Check" begin
            @test_throws ArgumentError HealthBase.HealthTable(person_df_bad; omop_cdm_version="v5.4.1")
        end
        
        @testset "Unsupported OMOP CDM Version" begin
            @test_throws ArgumentError HealthBase.HealthTable(person_df_good; omop_cdm_version="v999.0")
        end
        
        @testset "Type Enforcement Options" begin
            # Test with type enforcement disabled (should warn, not error)
            @test_logs (:warn, r"Type enforcement is disabled") HealthBase.HealthTable(person_df_bad; omop_cdm_version="v5.4.1", disable_type_enforcement=true)
            
            # Test with collect_errors=false (should fail on first error)
            @test_throws ArgumentError HealthBase.HealthTable(person_df_bad; omop_cdm_version="v5.4.1", collect_errors=false)
        end
        
        @testset "Extra Columns" begin
            df_extra = copy(person_df_good)
            df_extra[!, :extra_column] = ["extra_value"]

            ht_extra = HealthBase.HealthTable(df_extra; omop_cdm_version="v5.4.1")
            @test "extra_column" in names(ht_extra.source)
        end
        
        @testset "Schema Validation Edge Cases" begin
            
            # Test multiple validation errors collected
            df_multiple_errors = DataFrame(
                person_id = "invalid_string",  # Wrong type
                gender_concept_id = "another_string",  # Wrong type  
                year_of_birth = "also_wrong"  # Wrong type
            )
            @test_throws ArgumentError HealthBase.HealthTable(df_multiple_errors; omop_cdm_version="v5.4.1", collect_errors=true)
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
            condition_source_value = ["Diabetes", "Hypertension", "Diabetes", "Obesity", "Hypertension", "RareCondition"],
            bool_column = [true, false, true, false, true, false]
        )
        ht = HealthBase.HealthTable(df; omop_cdm_version="v5.4.1")

        @testset "one_hot_encode function" begin
            # Test basic functionality
            result = HealthBase.one_hot_encode(ht; cols=[:gender_concept_id], return_features_only=true)
            expected_cols = ["gender_concept_id_8507", "gender_concept_id_8532"]
            @test all(col in string.(names(result)) for col in expected_cols)
            @test nrow(result) == nrow(df)
            
            # Test with HealthTable return
            result_ht = HealthBase.one_hot_encode(ht; cols=[:gender_concept_id], return_features_only=false)
            @test result_ht isa HealthBase.HealthTable
            
            # Test with drop_original=false
            result_keep = HealthBase.one_hot_encode(ht; cols=[:gender_concept_id], drop_original=false, return_features_only=true)
            @test "gender_concept_id" in names(result_keep)
            
            # Test with Boolean column (should warn and skip)
            @test_logs (:warn, r"Column bool_column is already Boolean") HealthBase.one_hot_encode(ht; cols=[:bool_column], return_features_only=true)
            
            # Test with missing column
            @test_throws AssertionError HealthBase.one_hot_encode(ht; cols=[:nonexistent_column], return_features_only=true)
        end

        @testset "apply_vocabulary_compression function" begin
            # Test basic functionality
            compressed = HealthBase.apply_vocabulary_compression(ht; cols=[:condition_source_value], min_freq=2)
            @test "condition_source_value_compressed" in names(compressed.source)
            compressed_vals = unique(compressed.source.condition_source_value_compressed)
            @test "Other" in compressed_vals
            @test length(compressed_vals) <= length(unique(df.condition_source_value))
            
            # Test with custom other_label
            compressed_custom = HealthBase.apply_vocabulary_compression(ht; cols=[:condition_source_value], min_freq=2, other_label="RARE")
            @test "RARE" in unique(compressed_custom.source.condition_source_value_compressed)
            
            # Test with drop_original=true
            compressed_drop = HealthBase.apply_vocabulary_compression(ht; cols=[:condition_source_value], min_freq=2, drop_original=true)
            @test !("condition_source_value" in names(compressed_drop.source))
            
            # Test with missing column
            @test_throws AssertionError HealthBase.apply_vocabulary_compression(ht; cols=[:nonexistent_column], min_freq=2)
        end

        @testset "map_concepts function (mocked)" begin
            # Create a simple in-memory DuckDB for testing
            db = DuckDB.DB()
            
            # Create a mock concept table
            DBInterface.execute(db, """
                CREATE TABLE concept (
                    concept_id INTEGER,
                    concept_name VARCHAR
                )
            """)
            
            DBInterface.execute(db, """
                INSERT INTO concept VALUES 
                (8507, 'Male'),
                (8532, 'Female')
            """)
            
            # Test map_concepts (returns new HealthTable)
            ht_mapped = HealthBase.map_concepts(ht, :gender_concept_id, db; new_cols="gender_name")
            @test "gender_name" in names(ht_mapped.source)
            @test ht_mapped.source.gender_name[1] == "Male"
            
            # Test map_concepts! (modifies in place)
            ht_copy = HealthBase.HealthTable(copy(df); omop_cdm_version="v5.4.1")
            HealthBase.map_concepts!(ht_copy, :gender_concept_id, db; new_cols="gender_name_inplace")
            @test "gender_name_inplace" in names(ht_copy.source)
            
            # Test with vector of columns
            ht_multi = HealthBase.map_concepts(ht, [:gender_concept_id], db; suffix="_concept_name")
            @test "gender_concept_id_concept_name" in names(ht_multi.source)
            
            # Test with drop_original=true
            ht_dropped = HealthBase.map_concepts(ht, :gender_concept_id, db; new_cols="gender_name", drop_original=true)
            @test !("gender_concept_id" in names(ht_dropped.source))
            @test "gender_name" in names(ht_dropped.source)
            
            # Test with custom schema
            ht_schema = HealthBase.map_concepts(ht, :gender_concept_id, db; new_cols="gender_name", schema="main")
            @test "gender_name" in names(ht_schema.source)
            
            # Test error cases
            @test_throws AssertionError HealthBase.map_concepts(ht, :nonexistent_column, db)
            
            # Test with no matching concept IDs (should warn)
            df_no_match = DataFrame(gender_concept_id = [99999])  # Non-existent concept ID
            ht_no_match = HealthBase.HealthTable(df_no_match; omop_cdm_version="v5.4.1")
            @test_logs (:warn, r"Concept mapping.*returned empty result") HealthBase.map_concepts(ht_no_match, :gender_concept_id, db)
            
            # Test with empty column (should warn and skip)
            df_empty = DataFrame(gender_concept_id = Int[])
            ht_empty = HealthBase.HealthTable(df_empty; omop_cdm_version="v5.4.1")
            @test_logs (:warn, r"No concept_ids found") HealthBase.map_concepts(ht_empty, :gender_concept_id, db)
            
            # Close the database
            DuckDB.close(db)
        end
    end
end
