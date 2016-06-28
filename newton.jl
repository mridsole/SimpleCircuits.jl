# i couldn't find any available packages for implementing Newton-Raphson - 
# so here it is
function newton(f::Function, J::Function, x0::Vector{Float64})
    
    x = copy(x0)
    fx = zeros(length(x))

    Jx = zeros((length(x), length(x)))

    # TODO: generalise tolerance
    tolerance = 1e-9

    for i = 1:20000

        # i don't know if the type annotations help here,
        # cause we're not using the return values

        # updates fx
        f(x, fx)::Vector{Float64}

        if norm(fx) < tolerance
            return x
        end

        # updates Jx
        J(x, Jx)::Matrix{Float64}

        # updates x
        x = x + (Jx \ (-fx))

    end

    return x
end


