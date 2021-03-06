
function MLJBase.fit(model::EvoTypes, verbosity::Int, X, y)
    Xmatrix = MLJBase.matrix(X)
    fitresult, cache = init_evotree(model, Xmatrix, y, verbosity = verbosity)
    grow_evotree!(fitresult, cache, verbosity = verbosity)
    report = nothing
    return fitresult, cache, report
end

function okay_to_continue(new, old)
    new.nrounds - old.nrounds >= 0 &&
    new.loss == old.loss &&
    new.λ == old.λ &&
    new.γ == old.γ &&
    new.max_depth  == old.max_depth &&
    new.min_weight == old.min_weight &&
    new.rowsample ==  old.rowsample &&
    new.colsample ==  old.colsample &&
    new.nbins ==  old.nbins &&
    new.α ==  old.α &&
    new.metric ==  old.metric
end

function MLJBase.update(model::EvoTypes, verbosity,
    fitresult, cache, X, y)

    if okay_to_continue(model, cache.params)
        grow_evotree!(fitresult, cache, verbosity = verbosity)
    else
        Xmatrix = MLJBase.matrix(X)
        fitresult, cache = init_evotree(model, Xmatrix, y, verbosity = verbosity)
        grow_evotree!(fitresult, cache, verbosity = verbosity)
    end
    report = nothing
    return fitresult, cache, report
end

function predict(model::EvoTypes, fitresult, Xnew)
    Xnew = MLJBase.matrix(Xnew)
    pred = predict(fitresult, Xnew)
    return pred
end

function predict(model::EvoTreeClassifier, fitresult, Xnew)
    Xnew = MLJBase.matrix(Xnew)
    pred = predict(fitresult, Xnew)
    return [MLJBase.UnivariateFinite(fitresult.levels, pred[i,:]) for i in 1:size(pred,1)]
end

function predict(model::EvoTreeCount, fitresult, Xnew)
    Xnew = MLJBase.matrix(Xnew)
    λ = predict(fitresult, Xnew)
    return [Distributions.Poisson(λᵢ) for λᵢ ∈ λ]
end

function predict(model::EvoTreeGaussian, fitresult, Xnew)
    Xnew = MLJBase.matrix(Xnew)
    pred = predict(fitresult, Xnew)
    return [Distributions.Normal(pred[i]...) for i in 1:size(pred,1)]
end

# MLJBase.predict_mean(model::Union{EvoTreeRegressor, EvoTreeCount, EvoTreeGaussian}, fitresult, Xnew) =
#     mean.(MLJBase.predict(model, fitresult, Xnew))
#
# MLJBase.predict_mode(model::Union{EvoTreeRegressor, EvoTreeClassifier,EvoTreeCount, EvoTreeGaussian}, fitresult, Xnew) =
#     mode.(MLJBase.predict(model, fitresult, Xnew))
#
# MLJBase.predict_median(model::Union{EvoTreeRegressor, EvoTreeCount, EvoTreeGaussian}, fitresult, Xnew) =
#     median.(MLJBase.predict(model, fitresult, Xnew))

# shared metadata
MLJBase.package_name(::Type{<:EvoTypes}) = "EvoTrees"
MLJBase.package_uuid(::Type{<:EvoTypes}) = "f6006082-12f8-11e9-0c9c-0d5d367ab1e5"
MLJBase.package_url(::Type{<:EvoTypes}) = "https://github.com/Evovest/EvoTrees.jl"
MLJBase.is_pure_julia(::Type{<:EvoTypes}) = true

MLJBase.load_path(::Type{<:EvoTreeRegressor}) = "EvoTrees.EvoTreeRegressor"
MLJBase.input_scitype(::Type{<:EvoTreeRegressor}) = MLJBase.Table(MLJBase.Continuous)
MLJBase.target_scitype(::Type{<:EvoTreeRegressor}) = AbstractVector{<:MLJBase.Continuous}

MLJBase.load_path(::Type{<:EvoTreeCount}) = "EvoTrees.EvoTreeCount"
MLJBase.input_scitype(::Type{<:EvoTreeCount}) = MLJBase.Table(MLJBase.Continuous)
MLJBase.target_scitype(::Type{<:EvoTreeCount}) = AbstractVector{<:MLJBase.Count}

MLJBase.load_path(::Type{<:EvoTreeClassifier}) = "EvoTrees.EvoTreeClassifier"
MLJBase.input_scitype(::Type{<:EvoTreeClassifier}) = MLJBase.Table(MLJBase.Continuous)
MLJBase.target_scitype(::Type{<:EvoTreeClassifier}) = AbstractVector{<:MLJBase.Finite}

MLJBase.load_path(::Type{<:EvoTreeGaussian}) = "EvoTrees.EvoTreeGaussian"
MLJBase.input_scitype(::Type{<:EvoTreeGaussian}) = MLJBase.Table(MLJBase.Continuous)
MLJBase.target_scitype(::Type{<:EvoTreeGaussian}) = AbstractVector{<:MLJBase.Continuous}

# function MLJ.clean!(model::EvoTreeRegressor)
#     warning = ""
#     if model.nrounds < 1
#         warning *= "Need nrounds ≥ 1. Resetting nrounds=1. "
#         model.nrounds = 1
#     end
#     if model.λ < 0
#         warning *= "Need λ ≥ 0. Resetting λ=0. "
#         model.λ = 0.0
#     end
#     if model.γ < 0
#         warning *= "Need γ ≥ 0. Resetting γ=0. "
#         model.γ = 0.0
#     end
#     if model.η <= 0
#         warning *= "Need η > 0. Resetting η=0.001. "
#         model.η = 0.001
#     end
#     if model.max_depth < 1
#         warning *= "Need max_depth ≥ 0. Resetting max_depth=0. "
#         model.max_depth = 1
#     end
#     if model.min_weight < 0
#         warning *= "Need min_weight ≥ 0. Resetting min_weight=0. "
#         model.min_weight = 0.0
#     end
#     if model.rowsample < 0
#         warning *= "Need rowsample ≥ 0. Resetting rowsample=0. "
#         model.rowsample = 0.0
#     end
#     if model.rowsample > 1
#         warning *= "Need rowsample <= 1. Resetting rowsample=1. "
#         model.rowsample = 1.0
#     end
#     if model.colsample < 0
#         warning *= "Need colsample ≥ 0. Resetting colsample=0. "
#         model.colsample = 0.0
#     end
#     if model.colsample > 1
#         warning *= "Need colsample <= 1. Resetting colsample=1. "
#         model.colsample = 1.0
#     end
#     if model.nbins > 250
#         warning *= "Need nbins <= 250. Resetting nbins=250. "
#         model.nbins = 250
#     end
#     return warning
# end
