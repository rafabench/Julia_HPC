@everywhere function fast(x::Float64)
    return x^2+1.0
end

@everywhere function fast_distributed(arr::StepRangeLen)
    @distributed for i in arr
        a = fast(i)
        fetch(a)
    end
end

@everywhere function slow(x::Float64)
    a = 1.0
    for i in 1:1000
        for j in 1:5000
            a+=asinh(i+j)
        end
    end
    return a
end

@info "Precompilation" 
map(fast,range(1,1000,1000))
pmap(fast,range(1,1000,1000))
map(slow,range(1,1000,10)) 
pmap(slow,range(1,1000,10))
fast_distributed(range(1,1000,1000))

@info "Testing slow function"
@time map(slow,range(1,1000,10))
@time pmap(slow,range(1,1000,10))
@info "Testing fast function"
@time map(fast,range(1,1000,1000))
@time pmap(fast,range(1,1000,1000))
@info "Testing @distributed fast function"
@time fast_distributed(range(1,1000,1000))
