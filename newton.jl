# i couldn't find any available packages for implementing Newton-Raphson - 
# so here it is
function newton(f::Function, J::Function, x0::Vector{Float64})
    
    x = copy(x0)
    fx = zeros(length(x))

    Jx = zeros((length(x), length(x)))

    # TODO: convergence checks
    for i = 1:10

        # i don't know if the type annotations help here,
        # cause we're not using the return values

        # updates fx
        f(x, fx)#::Vector{Float64}

        # updates Jx
        J(x, Jx)::Matrix{Float64}

        # updates x
        x = x + (Jx \ (-fx))
    end

    return x
end


