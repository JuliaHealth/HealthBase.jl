using Statistics

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

    @testset "Preprocessing Utilities" begin
        df = DataFrame(
            id = 1:4,
            cat = ["a", "b", "a", "c"],
            num1 = [1.0, 2.5, missing, 4.0],
            num2 = [10.0, missing, 30.0, 40.0]
        )
        base_ht = HealthTable(df)
    
        @testset "one_hot_encode - drop_original=true" begin
            ht_oh = one_hot_encode(base_ht; cols=[:cat], drop_original=true)
            @test "cat" ∉ names(ht_oh.source)
            expected_cols = Set([:cat_a, :cat_b, :cat_c])
            @test expected_cols ⊆ Set(Symbol.(names(ht_oh.source)))
            @test ht_oh.source.cat_a == [true, false, true, false]
            @test ht_oh.source.cat_b == [false, true, false, false]
            @test ht_oh.source.cat_c == [false, false, false, true]
        end
        
        @testset "one_hot_encode - drop_original=false" begin
            ht_oh = one_hot_encode(base_ht; cols=[:cat], drop_original=false)
            @test "cat" in names(ht_oh.source)
            expected_cols = Set([:cat_a, :cat_b, :cat_c])
            @test expected_cols ⊆ Set(Symbol.(names(ht_oh.source)))
        end               
    
        @testset "impute_missing - mean" begin
            ht_imp = impute_missing(base_ht; cols=[:num1, :num2], strategy=:mean)
            @test all(!ismissing, ht_imp.source.num1)
            @test all(!ismissing, ht_imp.source.num2)
            @test ht_imp.source.num1[3] ≈ mean(skipmissing(base_ht.source.num1))
            @test ht_imp.source.num2[2] ≈ mean(skipmissing(base_ht.source.num2))
        end
    
        @testset "normalize_column - standard" begin
            ht_imp = impute_missing(base_ht; cols=[:num1, :num2])
            ht_norm = normalize_column(ht_imp; cols=[:num1, :num2])
            @test isapprox(mean(ht_norm.source.num1), 0.0; atol=1e-8)
            @test isapprox(std(ht_norm.source.num1), 1.0; atol=1e-8)
            @test isapprox(mean(ht_norm.source.num2), 0.0; atol=1e-8)
            @test isapprox(std(ht_norm.source.num2), 1.0; atol=1e-8)
            @test all(x -> x isa Float64, vec(Matrix(ht_norm.source[:, [:num1, :num2]])))
        end
    end

end