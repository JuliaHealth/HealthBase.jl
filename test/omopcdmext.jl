using Statistics
using DataFrames

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

    @testset "Preprocessing Utilities (single example DataFrame)" begin
        df = DataFrame(
            person_id = 1:10,
            condition_source_value = [
                "Hypertension", "Diabetes", "Asthma", "Asthma", "Hypertension",
                "Fibromyalgia", "Hyperlipidemia", "RareDisease1", "RareDisease2", "RareDisease3"
            ],
            condition_concept_id = [
                316866,   # Hypertension
                201826,   # Diabetes
                317009,   # Asthma (mild)
                317010,   # Asthma (severe)
                316866,   # Hypertension
                317707,   # Fibromyalgia
                4329058,  # Hyperlipidemia
                1234567, 2345678, 3456789  # Rare
            ],
            systolic_bp = [140.0, 130.0, 110.0, missing, 150.0, 120.0, missing, 135.0, 128.0, 145.0],
            diastolic_bp = [90.0, 85.0, 70.0, missing, 95.0, 80.0, missing, 88.0, 82.0, 92.0]
        )
        base_ht = HealthTable(source=df; omop_cdm_version="v5.4.1")
    
        @testset "one_hot_encode - drop_original=true" begin
            ht_oh = one_hot_encode(base_ht; cols=[:condition_source_value], drop_original=true)
            @test :condition_source_value ∉ names(ht_oh.source)
            expected_cols = Set(Symbol.("condition_source_value_" .* ["Hypertension", "Diabetes", "Asthma", "Fibromyalgia", "Hyperlipidemia"]))
            @test expected_cols ⊆ Set(Symbol.(names(ht_oh.source)))
            @test ht_oh.source.condition_source_value_Hypertension == (df.condition_source_value .== "Hypertension")
            @test ht_oh.source.condition_source_value_Diabetes == (df.condition_source_value .== "Diabetes")
        end
        
        @testset "one_hot_encode - drop_original=false" begin
            ht_oh = one_hot_encode(base_ht; cols=[:condition_source_value], drop_original=false)
            @test :condition_source_value in Symbol.(names(ht_oh.source))
            expected_cols = Set(Symbol.("condition_source_value_" .* ["Hypertension", "Diabetes", "Asthma", "Fibromyalgia", "Hyperlipidemia"]))
            @test expected_cols ⊆ Set(Symbol.(names(ht_oh.source)))
        end               
    
        @testset "impute_missing - mean" begin
            ht_imp = impute_missing(base_ht; cols=[:systolic_bp, :diastolic_bp], strategy=:mean)
            @test all(!ismissing, ht_imp.source.systolic_bp)
            @test all(!ismissing, ht_imp.source.diastolic_bp)
            @test ht_imp.source.systolic_bp[4] ≈ mean(skipmissing(base_ht.source.systolic_bp))
            @test ht_imp.source.diastolic_bp[4] ≈ mean(skipmissing(base_ht.source.diastolic_bp))
        end
    
        @testset "normalize_column - standard" begin
            ht_imp = impute_missing(base_ht; cols=[:systolic_bp, :diastolic_bp])
            ht_norm = normalize_column(ht_imp; cols=[:systolic_bp, :diastolic_bp])
            @test isapprox(mean(ht_norm.source.systolic_bp), 0.0; atol=1e-8)
            @test isapprox(std(ht_norm.source.systolic_bp), 1.0; atol=1e-8)
            @test isapprox(mean(ht_norm.source.diastolic_bp), 0.0; atol=1e-8)
            @test isapprox(std(ht_norm.source.diastolic_bp), 1.0; atol=1e-8)
            @test all(x -> x isa Float64, vec(Matrix(ht_norm.source[:, [:systolic_bp, :diastolic_bp]])))
        end

        @testset "impute_missing - median" begin
            df_mid = DataFrame(num = [1.0, missing, 3.0, missing])
            ht_mid = HealthTable(df_mid)
            ht_imp = impute_missing(ht_mid; cols=[:num], strategy=:median)
            @test all(!ismissing, ht_imp.source.num)
            @test ht_imp.source.num[2] == median([1.0, 3.0])
        end

        @testset "impute_missing - mixed strategies" begin
            ht_mix = impute_missing(base_ht; cols=[:systolic_bp => :mean, :diastolic_bp => :median])
            @test ht_mix.source.systolic_bp[4] ≈ mean(skipmissing(base_ht.source.systolic_bp))
            @test ht_mix.source.diastolic_bp[4] == median(skipmissing(base_ht.source.diastolic_bp))
        end

        @testset "apply_vocabulary_compression" begin
            ht_comp = apply_vocabulary_compression(base_ht; cols=[:condition_source_value], min_freq=2, other_label="Other")
            @test ht_comp.source.condition_source_value == [
                "Hypertension", "Other", "Asthma", "Asthma", "Hypertension", "Other", "Other", "Other", "Other", "Other"
            ]
        end

        @testset "map_concepts" begin
            mapping = Dict(
                316866 => "Hypertension",
                201826 => "Diabetes",
                317009 => "Asthma",
                317010 => "Asthma"
            )
            ht_m1 = map_concepts(base_ht; col=:condition_concept_id, mapping=mapping, new_col=:condition_group)
            @test ht_m1.source.condition_group == [
                "Hypertension", "Diabetes", "Asthma", "Asthma", "Hypertension", 317707, 4329058, 1234567, 2345678, 3456789
            ]
            @test :condition_concept_id in Symbol.(names(ht_m1.source))
            ht_m2 = map_concepts(base_ht; col=:condition_concept_id, mapping=mapping, new_col=:condition_group, drop_original=true)
            @test :condition_concept_id ∉ names(ht_m2.source)
            @test ht_m2.source.condition_group[1] == "Hypertension"
        end
    end

end