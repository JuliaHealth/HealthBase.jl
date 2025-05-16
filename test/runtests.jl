using DrWatson
using HealthBase
using Pkg
using Test

@testset "Exceptions" begin
    include("exceptions.jl")
end

@testset "HealthBaseDrWatsonExt" begin
    include("drwatsonext.jl")
end
