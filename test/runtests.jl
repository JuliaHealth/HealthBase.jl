using HealthBase
using Test

struct Foo end

@testset "HealthBase.jl" begin
    include("smart_authorization.jl")
end
