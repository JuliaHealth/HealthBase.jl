"""
    get_fhir_access_token(smart_result) -> AbstractString
"""
function get_fhir_access_token end

"""
    has_fhir_patient_id(smart_result) -> Bool
"""
function has_fhir_patient_id end

has_fhir_patient_id(smart_result) = false

"""
    get_fhir_patient_id(smart_result) -> AbstractString
"""
function get_fhir_patient_id end

"""
    has_fhir_encounter_id(smart_result) -> Bool
"""
function has_fhir_encounter_id end

has_fhir_encounter_id(smart_result) = false

"""
    get_fhir_encounter_id(smart_result) -> AbstractString
"""
function get_fhir_encounter_id end
