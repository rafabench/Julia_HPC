using Base.Threads

function sum2(N)
    acc = Atomic{Int64}(0)
    @threads for i in 1:1000
        atomic_add!(acc, 1)
    end
    return acc[]
end