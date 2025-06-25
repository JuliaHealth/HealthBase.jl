using DrWatson
using HealthBase
using Test
using DataFrames
using OMOPCommonDataModel
using Dates
using Statistics
using Tables

@testset "Exceptions" begin
    include("exceptions.jl")
end

@testset "HealthBaseDrWatsonExt" begin
    include("drwatsonext.jl")
end

@testset "HealthBaseOMOPCDMExt" begin
    include("omopcdmext.jl")
end
