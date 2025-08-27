using DrWatson
using Test
using InlineStrings
using FeatureTransforms
using Serialization
using DataFrames
using OMOPCommonDataModel
using Dates
using DBInterface
using DuckDB
using Tables
using HealthBase

@testset "Exceptions" begin
    include("exceptions.jl")
end

@testset "HealthTable Interface" begin
    include("healthtable_interface.jl")
end

@testset "HealthTable Show Method" begin
    include("show.jl")
end

@testset "HealthBaseDrWatsonExt" begin
    include("drwatsonext.jl")
end

@testset "HealthBaseOMOPCDMExt" begin
    include("omopcdmext.jl")
end
