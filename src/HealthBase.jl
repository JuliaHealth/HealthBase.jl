module HealthBase

"""
    AbstractHealthServer
"""
abstract type AbstractHealthServer
end

"""
    AbstractFHIRServer <: AbstractHealthServer
"""
abstract type AbstractFHIRServer <: AbstractHealthServer
end

"""
    AbstractHealthClient

An `AbstractHealthClient` connects to a server.

Generally, when constructing an instance of an `AbstractHealthClient`, you
will pass the URL of the server's endpoint as an argument.

Note: A single `AbstractHealthClient` connects to a single server. If you
want to connect to multiple servers simultaneously, you will need to
construct a different `AbstractHealthClient` for each server.
"""
abstract type AbstractHealthClient
end

"""
    AbstractFHIRClient <: AbstractHealthClient

An `AbstractFHIRClient` connects to a FHIR server.

Generally, when constructing an instance of an `AbstractFHIRClient`, you will
pass the URL of the server's endpoint as an argument.

Note: A single `AbstractFHIRClient` connects to a single FHIR server. If you
want to connect to multiple FHIR servers simultaneously, you will need to
construct a different `AbstractFHIRClient` for each FHIR server.
"""
abstract type AbstractFHIRClient <: AbstractHealthClient
end

"""
    AbstractHealthInformationModel
"""
abstract type AbstractHealthInformationModel
end

"""
    AbstractFHIRModel <: AbstractHealthInformationModel
"""
abstract type AbstractFHIRModel <: AbstractHealthInformationModel
end

end # module
