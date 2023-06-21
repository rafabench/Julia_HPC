using CUDA, Images

function coloring(n)
    a = 0.1;
    return RGB(0.5 * sin(a * n) + 0.5, 
            0.5 * sin(a * n + 2.094) + 0.5,  
            0.5 * sin(a * n + 4.188) + 0.5)
end

# Image definitions
width, height = 301*2,241*2
width -= 1
height -= 1
xmin = -2.2
xmax = 0.8
ymin = -1.2
ymax = 1.2
h_x = (xmax-xmin)/width
h_y = (ymax-ymin)/height
xs = xmin:h_x:xmax
ys = ymin:h_y:ymax
xsize = length(xs)
ysize = length(ys)
maxiter = 1024;

# Serial function to compute the number of iterations
# necessary to the recurrence diverge
function get_steps(c::Complex, max_steps::Int64)
    z = Complex(0.0, 0.0) # 0 + 0im
    for i=1:max_steps
        # Calculate the recurrence
        z = z^2+c
        # Diverged, return the number of iterations
        if abs2(z) >= 400
            return i
        end
    end
    # The recurrence is bounded
    return max_steps+1
end

mandel(x,y) = get_steps(Complex(x, y), maxiter)
@time Z = [mandel(x,y) for y in ys, x in xs];
@time Z = [mandel(x,y) for y in ys, x in xs];

# GPU function to compute the number of iterations
# necessary to the recurrence diverge
function get_steps_gpu(c::CUDA.Complex, max_steps::Int64)
    z = CUDA.Complex(0.0, 0.0) # 0 + 0im
    for i=1:max_steps
        z = z^2+c
        if CUDA.abs2(z) >= 400
            return i
        end
    end
    return max_steps+1
end

Z = CUDA.CuArray([Complex(x,y) for y in ys, x in xs]);
cu_steps = CuArray(zeros(Int, (length(ys), length(xs))));
CUDA.@time CUDA.@sync cu_steps .= get_steps_gpu.(Z, maxiter);
CUDA.@time CUDA.@sync cu_steps .= get_steps_gpu.(Z, maxiter);
values = Array(cu_steps);
img = coloring.(collect(values))
save("mandelbrot_CUDA.png", img);