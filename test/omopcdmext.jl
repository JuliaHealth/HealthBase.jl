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
                gender_concept_id = "another_string"  # Wrong type  
            )
            @test_throws ArgumentError HealthBase.HealthTable(df_multiple_errors; omop_cdm_version="v5.4.1", collect_errors=true)
        end
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
            person_id = 1:4,
            gender_concept_id = [8507, 8507, 8532, 8532], 
            condition_source_value = ["Diabetes", "Hypertension", "Diabetes", "RareCondition"],
            bool_column = [true, false, true, false]
        )
        ht = HealthBase.HealthTable(df; omop_cdm_version="v5.4.1")

        @testset "one_hot_encode function" begin
            # Test basic functionality
            result = HealthBase.one_hot_encode(ht; cols=[:gender_concept_id], return_features_only=true)
            expected_cols = ["gender_concept_id_8507", "gender_concept_id_8532"]
            @test all(col in string.(names(result)) for col in expected_cols)
            
            # Test with HealthTable return
            result_ht = HealthBase.one_hot_encode(ht; cols=[:gender_concept_id], return_features_only=false)
            @test result_ht isa HealthBase.HealthTable
            
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
            
            # Test with custom other_label
            compressed_custom = HealthBase.apply_vocabulary_compression(ht; cols=[:condition_source_value], min_freq=2, other_label="RARE")
            @test "RARE" in unique(compressed_custom.source.condition_source_value_compressed)
            
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
            
            # Test error cases
            @test_throws AssertionError HealthBase.map_concepts(ht, :nonexistent_column, db)
            
            # Close the database
            DuckDB.close(db)
        end
    end
    
    @testset "Edge Cases and Error Handling" begin
        @testset "HealthTable Constructor Error Paths" begin
            @test_throws ArgumentError HealthBase.HealthTable(person_df_good; omop_cdm_version="v999.0")
            
            # Test with disable_type_enforcement=true for warning path
            @test_logs (:warn, r"Type enforcement is disabled") HealthBase.HealthTable(person_df_bad; disable_type_enforcement=true)
        end
        
        @testset "Internal Schema Validation Coverage" begin
            # Get the extension to access internal constants
            ext = Base.get_extension(HealthBase, :HealthBaseOMOPCDMExt)
            
            if !isnothing(ext)
                # Access the OMOPCDM_VERSIONS constant from the extension
                omop_versions = getfield(ext, :OMOPCDM_VERSIONS)
                
                # Create a test scenario by making a copy and corrupting it temporarily
                if haskey(omop_versions, "v5.4.1")
                    original_fields = omop_versions["v5.4.1"][:fields]
                    
                    # Create a corrupted version for testing
                    corrupted_fields = copy(original_fields)
                    if haskey(corrupted_fields, :person_id)
                        # Remove cdmDatatype from person_id field to trigger 
                        original_person_field = corrupted_fields[:person_id]
                        corrupted_person_field = Dict{Symbol, Any}()
                        for (k, v) in original_person_field
                            if k != :cdmDatatype  # Skip cdmDatatype to trigger the error
                                corrupted_person_field[k] = v
                            end
                        end
                        corrupted_fields[:person_id] = corrupted_person_field
                        
                        # Temporarily replace the schema
                        corrupted_version = Dict{Symbol, Any}(:fields => corrupted_fields)
                        omop_versions["v5.4.1"] = corrupted_version
                        
                        # Test the missing cdmDatatype error path 
                        df_test = DataFrame(person_id=1)
                        @test_throws ArgumentError HealthBase.HealthTable(df_test; omop_cdm_version="v5.4.1", collect_errors=false)
                        
                        # Test the missing cdmDatatype with collect_errors=true
                        @test_throws ArgumentError HealthBase.HealthTable(df_test; omop_cdm_version="v5.4.1", collect_errors=true)
                        
                        # Restore original schema
                        omop_versions["v5.4.1"] = Dict{Symbol, Any}(:fields => original_fields)
                    end
                    
                    # Now test unrecognized datatype (line 141)
                    corrupted_fields_2 = copy(original_fields)
                    if haskey(corrupted_fields_2, :person_id)
                        # Add an unrecognized datatype to trigger line 141
                        corrupted_person_field_2 = copy(corrupted_fields_2[:person_id])
                        corrupted_person_field_2[:cdmDatatype] = "INVALID_DATATYPE_XYZ"
                        corrupted_fields_2[:person_id] = corrupted_person_field_2
                        
                        # Temporarily replace the schema
                        corrupted_version_2 = Dict{Symbol, Any}(:fields => corrupted_fields_2)
                        omop_versions["v5.4.1"] = corrupted_version_2
                        
                        # Test the unrecognized datatype error path 
                        df_test2 = DataFrame(person_id=1)
                        @test_throws ArgumentError HealthBase.HealthTable(df_test2; omop_cdm_version="v5.4.1", collect_errors=true)
                        
                        # Restore original schema
                        omop_versions["v5.4.1"] = Dict{Symbol, Any}(:fields => original_fields)
                    end
                end
            end
        end
        
        @testset "map_concepts Edge Cases" begin
            # Set up test database with concept table
            db = DuckDB.DB()
            DuckDB.execute(db, "CREATE TABLE concept (concept_id INTEGER, concept_name VARCHAR)")
            DuckDB.execute(db, "INSERT INTO concept VALUES (8507, 'Male')")
            
            df_empty = DataFrame(empty_col=[missing, missing])
            ht_empty = HealthBase.HealthTable(df_empty; omop_cdm_version="v5.4.1")
            
            @test_logs (:warn, r"No concept_ids found") HealthBase.map_concepts!(ht_empty, :empty_col, db; new_cols="mapped_empty")
            
            df_nonexistent = DataFrame(nonexistent_ids=[99999])
            ht_nonexistent = HealthBase.HealthTable(df_nonexistent; omop_cdm_version="v5.4.1")
            
            # When mapping fails, the column is NOT added (the function continues/skips)
            HealthBase.map_concepts!(ht_nonexistent, :nonexistent_ids, db; new_cols="mapped_nonexistent")
            @test !("mapped_nonexistent" in names(ht_nonexistent.source))  # Column should NOT be added when mapping fails
            
            # Test drop_original=true for map_concepts!
            df_drop = DataFrame(concept_col=[8507])
            ht_drop = HealthBase.HealthTable(df_drop; omop_cdm_version="v5.4.1")
            HealthBase.map_concepts!(ht_drop, :concept_col, db; new_cols="mapped_col", drop_original=true)
            @test !("concept_col" in names(ht_drop.source))  # Original column should be dropped
            @test "mapped_col" in names(ht_drop.source)
            
            DuckDB.close(db)
        end
        
        @testset "apply_vocabulary_compression drop_original" begin
            df_compress = DataFrame(
                col1=["A", "A", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"],
                col2=["X", "X", "X", "Y", "Z", "Z", "Z", "Z", "Z", "Z", "Z", "Z", "Z"]
            )
            ht_compress = HealthBase.HealthTable(df_compress; omop_cdm_version="v5.4.1")
            
            # Apply compression with drop_original=true
            ht_result = HealthBase.apply_vocabulary_compression(ht_compress; cols=[:col1, :col2], min_freq=3, drop_original=true)
            
            # Original columns should be dropped
            @test !("col1" in names(ht_result.source))
            @test !("col2" in names(ht_result.source))
            # Compressed columns should exist
            @test "col1_compressed" in names(ht_result.source)
            @test "col2_compressed" in names(ht_result.source)
        end
    end
end
