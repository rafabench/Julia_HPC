using CUDA
using Base.Threads
using BenchmarkTools


function sequential_add!(y, x)
    for i in eachindex(y, x)
        @inbounds y[i] += x[i]
    end
    return nothing
end

function parallel_add!(y, x)
    Threads.@threads for i in eachindex(y, x)
        @inbounds y[i] += x[i]
    end
    return nothing
end

function gpu_add!(y, x)
    CUDA.@sync y .+= x
    return
end


N = 2^23
x = fill(1.0f0, N)
y = fill(2.0f0, N)  

println("Sequential Add:")
bench1 = @benchmark sequential_add!(x,y)
display(bench1)
println()

x = fill(1.0f0, N)  
y = fill(2.0f0, N)  

println("Parallel Add:")
bench2 = @benchmark parallel_add!($x,$y)
display(bench2)
println()

x_d = CUDA.fill(1.0f0, N)  # a vector stored on the GPU filled with 1.0 (Float32)
y_d = CUDA.fill(2.0f0, N)  # a vector stored on the GPU filled with 2.0

println("GPU Add:")
bench3 = @benchmark gpu_add!($x_d,$y_d)
display(bench3)
println()

