import HealthBase
import Test

Test.@testset "HealthBase.jl" begin
    Test.@test HealthBase._foo() == 1
end
