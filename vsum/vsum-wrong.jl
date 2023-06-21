using Base.Threads

function sum1(N)
    acc = Ref(0)
    @threads for i in 1:N
        acc[] += 1
    end
    return acc[]
end