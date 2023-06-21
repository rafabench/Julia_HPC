using Base.Threads

macro my_time(ex)
    return quote
        local t0 = time_ns()
        local val = $ex
        local t1 = time_ns()
        Δt = (t1-t0)/1e9
        val, Δt
    end
end

function selectionsort!(arr::Vector{<:Real})
    len = length(arr)
    if len < 2 return arr end
    for i in 1:len-1
        lmin, j = findmin(arr[i+1:end])
        if lmin < arr[i]
            arr[i+j] = arr[i]
            arr[i] = lmin
        end
    end
    return arr
end

function selectionsortparallel!(arr::Vector{<:Real})
    len = length(arr)
    if len < 2 return arr end
    @threads for i in 1:len-1
        lmin, j = findmin(arr[i+1:end])
        if lmin < arr[i]
            arr[i+j] = arr[i]
            arr[i] = lmin
        end
    end
    return arr
end

v = rand(50000)
val_ser, Δt_ser = @my_time selectionsort!(v)
val_ser, Δt_ser = @my_time selectionsort!(v)
println("Serial:   time = ",Δt_ser, " seconds")
val_par, Δt_par = @my_time selectionsortparallel!(v)
val_par, Δt_par = @my_time selectionsortparallel!(v)
println("Parallel: time = ",Δt_par, " seconds")
@assert val_ser == val_par