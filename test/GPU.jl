# using CUDA
using CUDAnative
using CuArrays
# using Flux
# using GeometricFlux

# CPU
function hist_cpu!(hist, δ, idx)
    Threads.@threads for j in 1:size(idx,2)
        @inbounds for i in 1:size(idx,1)
            hist[idx[i], j] += δ[i,j]
        end
    end
    return
end

# GPU
function hist_gpu!(h::CuMatrix{T}, x::CuArray{T}, id::CuArray{Int}; MAX_THREADS=256) where {T<:AbstractFloat}
    function kernel!(h::CuDeviceArray{T}, x::CuDeviceArray{T}, id)
        i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
        j = threadIdx().y + (blockIdx().y - 1) * blockDim().y
        @inbounds if i <= size(id, 1) && j <= size(h, 2)
            k = Base._to_linear_index(h, id[i,j], j)
            CUDAnative.atomic_add!(pointer(h, k), x[i,j])
        end
        return
    end
    thread_i = min(MAX_THREADS, size(id, 1))
    thread_j = min(MAX_THREADS ÷ thread_i, size(h, 2))
    threads = (thread_i, thread_j)
    blocks = ceil.(Int, (size(id, 1), size(h, 2)) ./ threads)
    CuArrays.@cuda blocks=blocks threads=threads kernel!(h, x, id)
    return h
end

nbins = 20
ncol = 100
items = Int(1e6)
hist = zeros(Float32, nbins, ncol)
δ = rand(Float32, items, ncol)
idx = rand(1:nbins, items, ncol)

hist_gpu = CuArray(hist)
δ_gpu = CuArray(δ)
idx_gpu = CuArray(idx)

@time hist_cpu!(hist, δ, idx)
@CuArrays.time hist_gpu!(hist_gpu, δ_gpu, idx_gpu, MAX_THREADS=1024)