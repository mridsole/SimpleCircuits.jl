# contains the factory functions for generating the (non)-linear system as a
# vector function, and for generating the corresponding Jacobian matrix function

# sub-module for generated system/jacobian functions
module Generated

end

# generate the expressions for the system of equations for a circuit
# (used in gen_sys_F)
function gen_sys_exprs(circ::Circuit)

    nodes_vec = collect(circ.nodes)
    n_nodes = length(nodes_vec)

    # find all components that use dummy currents
    dummy_current_components = Set{Component}()
    for node in circ.nodes
        for port in node.ports
            if uses_dummy_current(port.component)
                push!(dummy_current_components, port.component)
            end
        end
    end
    
    # order the dummy current components
    dummy_current_components = collect(dummy_current_components)
    n_dummy_currents = length(dummy_current_components)

    # map from nodes to their voltage symbols
    nv_symbols = Dict{Node, Union{Symbol, Expr}}()
    for i = 1:n_nodes
        nv_symbols[nodes_vec[i]] = :(x[$(i)])
    end

    # map from components to their dummy current symbols
    dummy_current_symbols = Dict{Component, Union{Symbol, Expr}}()
    for i = 1:n_dummy_currents
        dummy_current_symbols[dummy_current_components[i]] = :(x[$(i + n_nodes)])
    end

    function get_dum_cur(comp::Component)
        if comp in keys(dummy_current_symbols)
            return dummy_current_symbols[comp]
        else # (if there's no dummy current for this component it doesn't matter)
            return :_
        end
    end

    # make the current expression for each node
    exprs = []
    for node in circ.nodes

        expr = 0.
        for port in node.ports
            
            # if the port on the other side is floating, we have to
            # set the current to zero (which is the same as doing nothing here)
            if !is_floating(other_port(port))
                expr = :($(expr) + $(dciv(port.component,
                    PortSyms(port => nv_symbols[port.node],
                        other_port(port) => nv_symbols[other_port(port).node]),
                    port, get_dum_cur(port.component)))
                )
            end
        end

        push!(exprs, expr)
    end

    # add in all the other relations to satisfy (each component may have arbitrarily many ..)
    # (eg there'll be one for each voltage source)
    for node in circ.nodes
        for port in node.ports
            if !is_floating(other_port(port))

                extra_eqns = dcsatisfy(port.component, 
                    PortSyms(port => nv_symbols[port.node],
                        other_port(port) => nv_symbols[other_port(port).node]),
                    get_dum_cur(port.component))
                
                append!(exprs, extra_eqns)
            end
        end
    end

    # add in one more expression for the ground node voltage (set it to zero)
    push!(exprs, :($(nv_symbols[circ.gnd])))

    return exprs
end

# generate the function describing the system of equations: F = 0
# place the function in a special sub-module 
function gen_sys_F(func_label::Symbol, circ::Circuit)

    # get the system expressions
    # sys_exprs = 

    n_vars = 3
    nv_exprs = [:(x[1] - x[2] + V), :(x[4]), :(x[5])]

    func_label = :testfunc

    func_expr = quote
        
        # x is the vector of node voltage and dummy current variables
        # nv is the memory to write the evaluated equations to
        function $(func_label)(x::Vector{Float64}, nv::Vector{Float64})
            
            $( ex = quote end;
            for i = 1:n_vars
                push!(ex.args, :(nv[$(i)] = $(nv_exprs[i])))
            end;
            ex )
        end
    end

    show(func_expr)
end
