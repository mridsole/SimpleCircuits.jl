# contains the factory functions for generating the (non)-linear system as a
# vector function, and for generating the corresponding Jacobian matrix function


# sub-module for generated system/jacobian functions
module Generated

using SimpleCircuits

end

using DataStructures
# unfortunately, can't do this because collect() fails if either of the 
# type parameters are unions ... should file an issue for this
# typealias SymbolMap OrderedDict{Union{Node, Component}, Union{Symbol, Expr}}
# have to do this instead:
typealias SymbolMap OrderedDict{Any, Any}

# turns out this is STILL a problem - have to do this hacky thing
# you'd think this conversion would already be the case?
# necessary in julia 0.4.5 - haven't tested higher versions
Base.convert{T1<:Any, T2<:Any}(t::Type{Pair{Any, Any}}, 
    x::Pair{T1, T2}) = Pair{Any, Any}(x.first, x.second)

# generate a node => symbol map for a circuit
# also maps components with dummy currents to their dummy current symbols
function gen_sym_map(circ::Circuit)

    # order the nodes
    nodes_vec = collect(circ.nodes)
    n_nodes = length(nodes_vec)

    # us an ordered dictionary to FIRST map all the nodes, THEN the 
    # dummy current components
    sym_map = SymbolMap()
    
    for i = 1:n_nodes
        sym_map[nodes_vec[i]] = :(x[$(i)])
    end

    # find all components that use dummy currents
    j = n_nodes + 1
    for node in circ.nodes
        for port in node.ports
            if uses_dummy_current(port.component)
                if !(port.component in keys(sym_map))
                    sym_map[port.component] = :(x[$(j)])
                    j += 1
                end
            end
        end
    end

    return sym_map
end

# generate the time differential (dt) symbol map for a given symbol map
function gen_dt_sym_map(sym_map::SymbolMap)
    
    dt_sym_map = SymbolMap()

    i = 1
    for (k, v) in sym_map
        dt_sym_map[k] = :(xp[$(i)])
        i += 1
    end

    return dt_sym_map
end

# given a symbol map (which contains an ordering of nodes) generate an
# ordering of circuit components
function get_components_ordered(sym_map::SymbolMap)
    
    components = OrderedSet{Component}()

    for (node, sym) in collect(sym_map)
        if typeof(node) != Node break end
        for port in node.ports
            push!(components, port.component)
        end
    end

    return components
end

# get an ordered set of all the parameters in the circuit
# given a symbol map, which provides the ordering
function parameters(sym_map::SymbolMap)

    params = OrderedSet{Parameter}()

    for (node, sym) in collect(sym_map)

        # the symbol map may contain both nodes and components ...
        if typeof(node) != Node break end

        for port in node.ports
            # OrderedSet takes care of duplicates ...
            for param in parameters(port.component)
                push!(params, param)
            end
        end
    end

    return params
end

# generate the expressions for the system of equations for a circuit
# (used in gen_sys_F)
function gen_sys_exprs(sym_map::SymbolMap, circ::Circuit,
    dt_sym_map=nothing)

    # if dt_sym_map is provided, then generate expressions for transient analysis
    trans_exprs = !(dt_sym_map == nothing)
    if trans_exprs @assert typeof(dt_sym_map) == SymbolMap end

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
        if comp in keys(sym_map)
            return sym_map[comp]
        else # (if there's no dummy current for this component it doesn't matter)
            return :_
        end
    end
    
    # the expressions that we're going to return
    exprs = []
    
    nodes_sym_map = collect(sym_map)[1:n_nodes]
    for (node, sym) in nodes_sym_map

        # if this is the ground node, then just set the voltage to zero
        if node == circ.gnd
            push!(exprs, :($(sym)))
            continue
        end

        # otherwise sum the currents going IN to the node
        expr = 0.
        for port in node.ports

            # if either port on the component is floating, set current to zero
            # (same as doing nothing ... since we sum currents)
            if typeof(port.component) <: TwoPortComponent && is_floating(other_port(port))
                continue
            end

            # ... if a port is floating on a component with more than two ports ...
            # what is the condition?

            # generate the port symbol map
            ps = PortSyms()
            for p in ports(port.component)
                ps[p] = sym_map[p.node]
            end
            
            if trans_exprs

                # generate the differential port symbol map
                dtps = PortSyms()
                for p in ports(port.component)
                    dtps[p] = dt_sym_map[p.node]
                end

                expr = :($(expr) + $(dtiv(port.component, ps, dtps, port,
                    get_dum_cur(port.component))))
            else
                expr = :($(expr) + $(dciv(port.component, ps, port, 
                    get_dum_cur(port.component))))
            end
        end

        push!(exprs, expr)
    end

    # need to get every component in the circuit, in an ordered fashion
    # do this based on the ordered set
    components = get_components_ordered(sym_map)

    for comp in components

        # add any extra relations - make sure neither port is floating
        if is_floating(p1(comp)) || is_floating(p2(comp))
            continue
        end

        ps = PortSyms()
        for p in ports(comp)
            ps[p] = sym_map[p.node]
        end

        if trans_exprs

            # generate the differential port symbol map
            dtps = PortSyms()
            for p in ports(comp)
                dtps[p] = dt_sym_map[p.node]
            end

            extra_eqns = dtsatisfy(comp, ps, dtps, get_dum_cur(comp))
        else
            extra_eqns = dcsatisfy(comp, ps, get_dum_cur(comp))
        end

        append!(exprs, extra_eqns)
    end

    return exprs
end

# generate the function describing the system of equations: F = 0
# place the function in a special sub-module 
function gen_sys_F(func_label::Symbol, sym_map::SymbolMap, circ::Circuit)

    # get the system expressions
    # sys_exprs = 

    nv_exprs = gen_sys_exprs(sym_map, circ)
    n_exprs = length(nv_exprs)

    # now, consider that all the parameters are known at "compile" time
    # (their symbols - not their numerical values, obviously)
    params = parameters(sym_map)

    sym1 = :A
    sym_sym1 = :($(sym1))

    func_expr = quote

        # x is the vector of node voltage and dummy current variables
        # nv is the memory to write the evaluated equations to
        function $(func_label)(x::Vector{Float64}, nv::Vector{Float64}, 
            param_vals::Dict{Parameter, Float64} = Dict{Parameter, Float64}())

            # first, sub all parameter symbols with their numerical values
            $( ex = quote end;
            for param in params
                # send help
                push!(ex.args, :($(symbol(param)) = param_vals[$(Meta.quot(param))]))
            end;
            ex )
            
            # now put the equations in
            $( ex = quote end;
            for i = 1:n_exprs
                push!(ex.args, :(nv[$(i)] = $(nv_exprs[i])))
            end;
            ex )

            return nv
        end
    end

    Generated.eval(func_expr)
    return getfield(Generated, func_label)
end

# generate the matrix of expressions representing the jacobian
function gen_J_exprs(sym_map::SymbolMap, circ::Circuit)
    
    # number of equations we have (= number of variables)
    n_exprs = length(sym_map)

    # the expression matrix - the ordering is how it usually is for a Jacobian:
    # (expr_m)_{i, j} = ∂F_i/∂x_j
    expr_m = zeros(Float64, (n_exprs, n_exprs)) |> Array{Any, 2}

    sym_map_pairs = collect(sym_map)

    # get just the ordered nodes
    n_nodes = length(circ.nodes)
    nodes_sym_pairs = sym_map_pairs[1:n_nodes]

    # wrapper around sym_map for dummy currents
    function get_dum_cur(comp::Component)
        if comp in keys(sym_map)
            return sym_map[comp]
        else # (if there's no dummy current for this component it doesn't matter)
            return :_
        end
    end

    # now the equation ordering is: all the node equations, THEN all the
    # extra relations from each component, in the order specified by 
    # the sym_map OrderedDict
    # so the Jacobian must follow this order (and obviously use the variable
    # ordering specified by the order of the keys of sym_map)
    
    # fill it in - first, do the derivatives of the node current equations
    # (so the first n_node rows of the matrix)
    for i = 1:n_nodes
        for j = 1:n_exprs

            (node, sym) = nodes_sym_pairs[i]

            # if this is the ground node, then zeros in every column EXCEPT 
            # for the ground voltage symbol column, where there's a 1
            if node == circ.gnd
                j_ = 1
                for (_, sym_) in sym_map_pairs
                    expr_m[i, j_] = sym_ == sym_map[circ.gnd] ? 1. : 0.
                    j_ += 1
                end
                continue
            end

            for port in node.ports

                # if other port floating, continue
                if typeof(port.component) <: TwoPortComponent && 
                    is_floating(other_port(port)) continue end

                # for each connected component add the derivative expression
                ps = PortSyms()
                for p in ports(port.component)
                    ps[p] = sym_map[p.node]
                end

                expr_m[i, j] = :($(expr_m[i, j]) + $(dciv_diff(port.component,
                    ps, port, sym_map_pairs[j].second, get_dum_cur(port.component)))
                )
            end
        end
    end

    comps_ordered = get_components_ordered(sym_map)

    # for each variable, differentiate each equation of each component
    # (so we're working columnwise in the Jacobian) - for each column:
    for var_idx in 1:n_exprs
        
        # move back to the first not-node equation
        i = n_nodes + 1

        for comp in comps_ordered
            
            # if either port floating, the corresponding equation is 0
            # (currently - this isn't actually correct! TODO)
            if is_floating(p1(comp)) || is_floating(p2(comp))
                continue
            end

            ps = PortSyms(p1(comp) => sym_map[p1(comp).node],
            p2(comp) => sym_map[p2(comp).node])

            diff_eqns = dcsatisfy_diff(comp, ps, sym_map_pairs[var_idx].second,
                get_dum_cur(comp))
            
            for k = 1:length(diff_eqns)
                expr_m[i + k - 1, var_idx] = :($(expr_m[i + k - 1, var_idx])
                    + $(diff_eqns[k]))
            end

            i += length(diff_eqns)
        end
    end

    return expr_m
end

# generate the function returning the Jacobian of the above system
function gen_sys_J(func_label::Symbol, sym_map::SymbolMap, circ::Circuit)
    
    # generate a function that computes the jacobian based on generated exprs
    # (and given a mapping from nodes/comps to voltage/dummy current symbols)

    # get the expressions
    exprs = gen_J_exprs(sym_map, circ)

    # now, consider that all the parameters are known at "compile" time
    # (their symbols - not their numerical values, obviously)
    params = parameters(sym_map)

    # make the function
    func_expr = quote
        function ($(func_label))(x::Vector{Float64}, J::Matrix{Float64},
            param_vals::Dict{Parameter, Float64} = Dict{Parameter, Float64}())

            # set the parameters equal to their numerical values
            $( ex = quote end;
            for param in params
                # send help
                push!(ex.args, :($(symbol(param)) = param_vals[$(Meta.quot(param))]))
            end;
            ex )
            
            # put the equations in
            $(expr = quote end;
            for i in eachindex(exprs)
                push!(expr.args, :(J[$(i)] = $(exprs[i])))
            end;
            expr)

            return J
        end
    end

    # place the function in the Generated submodule
    # this is a bit of a hack - but apparently anonymous functions 
    # aren't very fast (FastAnonymous.jl ??)
    Generated.eval(func_expr)
    return getfield(Generated, func_label)
end

# generate the residuals function for transient analysis
function gen_sys_residuals_F(func_label::Symbol, sym_map::SymbolMap, 
    dt_sym_map::SymbolMap, circ::Circuit)
        
    # passing a dt_sym_map indicates expression generation for transient analysis
    exprs = gen_sys_exprs(sym_map, circ, dt_sym_map)

    # make the function
    # TODO: how do we incorporate parameters here?
    # I have an idea that's better than the way we're doing it for operating point
    # analysis: place the variables in the 'Generated' module scope and
    # access them directly, using type assertions in the generated expressions
    # this is the ideal way of doing it but i don't have much time left
    func_expr = quote
        function ($(func_label))(t::Float64, x::Vector{Float64}, 
            xp::Vector{Float64}, r::Vector{Float64})

            # just set the residuals equal to the expressions
            $(expr = quote end;
            for i in eachindex(exprs)
                push!(expr.args, :(r[$(i)] = $(exprs[i])))
            end;
            expr)

            # don't need to return anything
        end
    end

    Generated.eval(func_expr)
    return getfield(Generated, func_label)
end
