using Distributed

macro my_time(ex)
    return quote
        local t0 = time_ns()
        local val = $ex
        local t1 = time_ns()
        Δt = (t1-t0)/1e9
        val, Δt
    end
end

@everywhere function darts_in_circle(N)
    n = 0
    for i in 1:N
        if rand()^2 + rand()^2 < 1
            n += 1
        end
    end
    return n
end

function pi_distributed(N, loops)
    n = sum(pmap((x)->darts_in_circle(N), 1:loops))
    4 * n / (loops * N)
end

function pi_serial(n)
    return 4 * darts_in_circle(n) / n
end

N = 20_000_000
loops = 100
pi_approx_ser, t_ser = @my_time pi_serial(N*loops)
pi_approx_ser, t_ser = @my_time pi_serial(N*loops)
pi_approx_par, t_dist = @my_time pi_distributed(N, loops)
pi_approx_par, t_dist = @my_time pi_distributed(N, loops)
println("Serial = $pi_approx_ser in $t_ser seconds")
println("Distributed = $pi_approx_par in $t_dist seconds")