module HealthBase

export get_fhir_access_token
export get_fhir_encounter_id
export get_fhir_patient_id
export has_fhir_encounter_id
export has_fhir_patient_id

include("smart_authorization.jl")

end # module
