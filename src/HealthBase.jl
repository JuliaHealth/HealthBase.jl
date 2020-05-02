module HealthBase

@noinline function _foo()
    return 10
end

"""
    fit
"""
function fit end

"""
    fit!
"""
function fit! end

"""
    predict
"""
function predict end

"""
    predict!
"""
function predict! end

"""
    predict_proba
"""
function predict_proba end

"""
    predict_proba!
"""
function predict_proba! end

end # module
