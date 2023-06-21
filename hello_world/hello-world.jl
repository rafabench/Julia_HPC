using Base.Threads

Threads.@threads for thread = 1:nthreads()
    println("$(Threads.threadid()) of $(nthreads()) - Hello World!")
end

"$(id)"