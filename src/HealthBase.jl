module HealthBase

"""
    AbstractHealthServer
"""
abstract type AbstractHealthServer end

"""
    AbstractFHIRServer <: AbstractHealthServer
"""
abstract type AbstractFHIRServer <: AbstractHealthServer end

"""
    AbstractHealthClient
"""
abstract type AbstractHealthClient end

"""
    AbstractFHIRClient <: AbstractHealthClient
"""
abstract type AbstractFHIRClient <: AbstractHealthClient end

"""
    AbstractHealthInformationModel
"""
abstract type AbstractHealthInformationModel end

"""
    AbstractFHIRModel <: AbstractHealthInformationModel
"""
abstract type AbstractFHIRModel <: AbstractHealthInformationModel end

end # end module HealthBase
