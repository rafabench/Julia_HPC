using Base.Threads

N = 1000
acc1 = Ref(0) # Pointer with value 0
@threads for i in 1:N
    acc1[] += 1 # Add 1 with race condition
end
println("Sum wrong is $(acc1[])")

acc2 = Atomic{Int64}(0) # Atomic pointer with value 0
@threads for i in 1:1000
    atomic_add!(acc2, 1) # Add 1 thread safely
end
println("Sum atomic is $(acc2[])")

N = 1000
acc3 = Ref(0) # Pointer with value 0
l = Threads.ReentrantLock()
@threads for i in 1:N
    Threads.lock(l)
    acc3[] += 1 # Add 1 without race condition
    Threads.unlock(l)
end
println("Sum barrier is $(acc3[])")
