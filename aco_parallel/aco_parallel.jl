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

@everywhere using LinearAlgebra, Random, StatsBase

# Make a path based on the Probability Matrix
@everywhere function travel(
        P::Matrix{Float64},
        start_node::Int
    )
    n_nodes = size(P,1)
    not_visited = collect(1:n_nodes)
    path = [start_node]
    P_copy = copy(P)

    node = start_node

    for i in 2:n_nodes
        # Sample a new node 
        next_node = sample(1:n_nodes,Weights(P_copy[node,:]))
        # You can't revisit the node
        P_copy[:,1:end .== node] .= 0.0
        # Normalize the other nodes probabilities, to sum 1
        P_copy ./= sum(P_copy,dims=2)
        # Go to the next node
        node = next_node
        push!(path, node)
    end
    return path
end

# Calculate the distances from a path
@everywhere function edge_distances(
        dist_mat::AbstractMatrix{<:Number},
        path::AbstractArray{Int}
    )
    [dist_mat[to, from] for (from, to) in edges(path)]
end

# Return a array of all edges in a path
@everywhere function edges(path::AbstractArray{Int})
    path_len = length(path)
    [(path[i], path[mod1(i + 1, path_len)]) for i in 1:path_len]
end

# Calculate the Serial Ant Colony Optimization Algorithm
function ACO(dist_mat,max_iter=50,nants=5;
    β=2,α=1,Q=1,ρ = 0.5,verbose = true)
    
    # Attractiveness of the move, calculated a priori
    η = (1 ./dist_mat) .^ β
    # Trail level
    τ = ones(size(dist_mat)) .^ α

    best_path = nothing
    best_cost = Inf
    no_improv = 0
    n_nodes = size(dist_mat,1)
    
    for i in 1:max_iter

        solutions = []
        # Create the probability matrix
        P = η.*τ
        P ./= sum(P,dims=2)

        # Run all ants in serial
        for k in 1:nants
            # Start randomly in a node
            start_node = rand(1:n_nodes)
            # Need to return to the same node
            end_node = start_node
            # Calculate path and costs
            path = travel(P, start_node)
            cost = sum(edge_distances(dist_mat, path))
            push!(solutions, (cost, path))
        end

        # Sort solutions
        sort!(solutions)
        best_local_cost, best_local_path = solutions[1]
        # Check if found a better cost path
        if best_local_cost < best_cost
            if verbose
                println("Better solution found with cost 
                $(best_local_cost) at iteration $(i)")
            end
            best_path = best_local_path
            best_cost = best_local_cost
            no_improv = 0
        else
            no_improv += 1
        end

        # deposit pheromones
        τ .*= (1-ρ)
        for (cost, path) in solutions
            Δτ = Q / cost
            for (from, to) in edges(path)
                τ[to, from] += Δτ
            end
        end
    end
    best_path,best_cost
end

# Calculate the Parallel Ant Colony Optimization Algorithm
function ACO_parallel(dist_mat,max_iter=50,nants=5;
    β=2,α=1,Q=1,ρ = 0.5,verbose = true)
    
    # Attractiveness of the move, calculated a priori
    η = (1 ./dist_mat) .^ β
    # Trail level
    τ = ones(size(dist_mat)) .^ α

    best_path = nothing
    best_cost = Inf
    no_improv = 0
    n_nodes = size(dist_mat,1)
    
    for i in 1:max_iter

        solutions = []
        # Create the probability matrix
        P = η.*τ
        P ./= sum(P,dims=2)

        # Create a dictionary with Process and Future
        # to fetch later
        par_results = Dict{Int,Future}()
        @sync for k in 1:nants
            # Choose which process will calculate this path
            w = mod1(k, nprocs())
            # Spawn the call at `w` process
            @async par_results[k] = @spawnat w begin 
                start_node = rand(1:n_nodes)
                end_node = start_node
                path = travel(P, start_node)
                cost = sum(edge_distances(dist_mat, path))
                path,cost
            end
        end
        
        for k in 1:nants
            w = mod1(k, nprocs())
            # Retrieve the call from `w` process calculated earlier
            path,cost = fetch(par_results[k])
            push!(solutions, (cost,path))
        end

        # Sort solutions
        sort!(solutions)
        best_local_cost, best_local_path = solutions[1]
        # Check if found a better cost path
        if best_local_cost < best_cost
            if verbose
                println("Better solution found with cost 
                $(best_local_cost) at iteration $(i)")
            end
            best_path = best_local_path
            best_cost = best_local_cost
            no_improv = 0
        else
            no_improv += 1
        end

        # deposit pheromones
        τ .*= (1-ρ)
        for (cost, path) in solutions
            Δτ = Q / cost
            for (from, to) in edges(path)
                τ[to, from] += Δτ
            end
        end
    end
    best_path,best_cost
end

# Fix Random seed
Random.seed!(123)

# Create weights of the graph
n = 50
dist_mat = rand(n, n)
for i in 1:n
    # No self loop (1/Inf = 0.0)
    dist_mat[i,i] = Inf
end
max_iter = 50;
nants = 100;
verbose = false

(best_path_ser,best_cost_ser),Δt_ser = @my_time ACO(dist_mat,max_iter,nants,verbose=false)
(best_path_ser,best_cost_ser),Δt_ser = @my_time ACO(dist_mat,max_iter,nants,verbose=false)
println("Serial:   best_cost = ",best_cost_ser)
println("Serial:   time = ",Δt_ser)
(best_path_par,best_cost_par),Δt_par = @my_time ACO_parallel(dist_mat,max_iter,nants,verbose=false)
(best_path_par,best_cost_par),Δt_par = @my_time ACO_parallel(dist_mat,max_iter,nants,verbose=false)
println("Parallel: best_cost = ",best_cost_par)
println("Parallel: time = ",Δt_par)


