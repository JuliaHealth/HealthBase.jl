@testset "HealthTable Interface" begin
    df = DataFrame(
        person_id = 1:5,
        gender_concept_id = [8507, 8532, 8507, 8532, 8507],
        year_of_birth = [1990, 1985, 2000, 1975, 1988],
    )

    @testset "Constructor" begin
        # Test basic constructor
        ht = HealthBase.HealthTable(df)
        @test ht isa HealthBase.HealthTable
        @test ht.source === df

        # Test keyword constructor
        ht_kw = HealthBase.HealthTable(source = df)
        @test ht_kw isa HealthBase.HealthTable
        @test ht_kw.source === df
    end

    @testset "Tables.jl Interface" begin
        ht = HealthBase.HealthTable(df)

        # Test istable
        @test Tables.istable(HealthBase.HealthTable) == true
        @test Tables.istable(typeof(ht)) == true

        # Test rowaccess
        @test Tables.rowaccess(HealthBase.HealthTable) == true
        @test Tables.rowaccess(typeof(ht)) == true

        # Test columnaccess
        @test Tables.columnaccess(HealthBase.HealthTable) == true
        @test Tables.columnaccess(typeof(ht)) == true

        # Test schema
        schema_ht = Tables.schema(ht)
        schema_df = Tables.schema(df)
        @test schema_ht.names == schema_df.names
        @test schema_ht.types == schema_df.types

        # Test rows
        rows_ht = collect(Tables.rows(ht))
        rows_df = collect(Tables.rows(df))
        @test length(rows_ht) == length(rows_df)
        @test rows_ht[1].person_id == rows_df[1].person_id

        # Test columns
        cols_ht = Tables.columns(ht)
        cols_df = Tables.columns(df)
        @test Tables.columnnames(cols_ht) == Tables.columnnames(cols_df)

        # Test materializer
        @test Tables.materializer(HealthBase.HealthTable) == DataFrame

        # Test DataFrame materialization
        df_materialized = DataFrame(ht)
        @test df_materialized == df
    end

    @testset "Different data types" begin
        # Test with different Tables.jl compatible types

        # Test with named tuple
        nt = [(person_id = 1, name = "Alice"), (person_id = 2, name = "Bob")]
        ht_nt = HealthBase.HealthTable(nt)
        @test Tables.istable(typeof(ht_nt))
        @test length(collect(Tables.rows(ht_nt))) == 2

        # Test with empty DataFrame
        empty_df = DataFrame(person_id = Int[], name = String[])
        ht_empty = HealthBase.HealthTable(empty_df)
        @test Tables.istable(typeof(ht_empty))
        @test length(collect(Tables.rows(ht_empty))) == 0
    end
end
