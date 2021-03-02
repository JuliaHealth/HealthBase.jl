@testset "smart_authorization.jl" begin
    smart_result = Foo()
    @test !has_fhir_patient_id(smart_result)
    @test !has_fhir_encounter_id(smart_result)
end
