using Base.Threads


function sum_non_atomic(N)
    acc = Ref(0)
    @threads for i in 1:N
        acc[] += 1
    end
    return acc[]
end

function sum_atomic(N)
    acc = Atomic{Int64}(0)
    @threads for i in 1:1000
        atomic_add!(acc, 1)
    end
    return acc[]
end

N = 1000
res1 = sum_non_atomic(N)
res2 = sum_atomic(N)

println("Sum non-atomic is $(res1)")
println("Sum atomic is $(res2)")