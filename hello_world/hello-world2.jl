using Base.Threads

N = 10

a = zeros(10)
function paralelize()
    Threads.@threads for i = 1:N
        a[i] = Threads.threadid() 
    end
end
paralelize()
println(a)