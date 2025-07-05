using DrWatson
using Test
using InlineStrings
using FeatureTransforms
using Serialization
using DataFrames
using OMOPCommonDataModel
using Dates
using Statistics
using Tables
using HealthBase

@testset "Exceptions" begin
    include("exceptions.jl")
end

@testset "HealthBaseDrWatsonExt" begin
    include("drwatsonext.jl")
end

@testset "HealthBaseOMOPCDMExt" begin
    include("omopcdmext.jl")
end
