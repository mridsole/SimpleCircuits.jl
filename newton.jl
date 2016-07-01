# i couldn't find any available packages for implementing Newton-Raphson - 
# so here it is
function newton(f::Function, J::Function, x0::Vector{Float64}, 
    params::Parameters = Parameters())
    
    x = copy(x0)
    fx = zeros(length(x))

    Jx = zeros((length(x), length(x)))

    # TODO: generalise tolerance
    # (some kind of non-dimensionalization procedure?)
    tolerance = 1e-11

    for i = 1:20000

        # i don't know if the type annotations help here,
        # cause we're not using the return values

        # updates fx
        f(x, fx, params)::Vector{Float64}

        if norm(fx) < tolerance
            return x
        end

        # updates Jx
        J(x, Jx, params)::Matrix{Float64}

        # println(x)
        # println(fx)
        # println(Jx)

        # updates x
        x = x + (Jx \ (-fx))

    end
    
    error("Newton-Raphson failed to converge after 20000 iterations.")
    return x
end


