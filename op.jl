using Sundials

# contains the numerical values for a circuit operating point
type CircuitOP{T}
    
    node_voltages::Dict{Node, T}
    dcvs_currents::Dict{Component, T}

    CircuitOP() = new(Dict{Node, T}(), Dict{Component, T}())
end

import Base.setindex!, Base.getindex

function Base.setindex!{T}(cop::CircuitOP{T}, val::T, node::Node)
    cop.node_voltages[node] = val 
end

function Base.setindex!{T}(cop::CircuitOP{T}, val::T, dcvs::Component) 
    cop.dcvs_currents[dcvs] = val 
end

Base.getindex(cop::CircuitOP, node::Node) = cop.node_voltages[node]
Base.getindex(cop::CircuitOP, dcvs::Component) = cop.dcvs_currents[dcvs]

# get voltage at ports (uses the connected node)
Base.getindex(cop::CircuitOP, port::Port) = cop.node_voltages[port.node]

Base.keys(cop::CircuitOP) = append!(keys(cop.node_voltages), keys(cop.dcvs_currents))

function show(io::IO, cop::CircuitOP)

    println(io, "Node voltages: ")
    for (k, v) in cop.node_voltages
        println(io, string(v) * " <==> " * string(k.name))
    end
    println(io, "DCVoltageSource currents: ")
    for (k, v) in cop.dcvs_currents
        println(io, string(v) * " <==> " * string(k))
    end
end

# methods for linear and non-linear operating point analysis

# find the DC operating point of a linear circuit
function op_linear(circ::Circuit)
    
    # TODO: since for the majority of circuits, the number of 
    # connections on a node is generally much smaller than the 
    # total number of nodes plus the total number of current sources
    # (which is the number of equations we will have) - therefore
    # the linear system tends to be sparse
    # figure out a way to exploit this

    # now we need to construct the matrix of equations
    # one equation for each node

    # there are things that can go wrong IF we treat
    # the voltage and current sources as ideal

    # TODO: check if the GND node of the circuit is actually connected
    # TODO: check if GND is connected to all nodes through a finite resistance
    # (a perfectly capacitive connection between two nodes is essentially an
    # open circuit in the DC sense)
    
    # at this point assume the above conditions are satisfied ..

    nodes_vec = collect(circ.nodes)
    n_nodes = length(nodes_vec)

    # before we start, find all the DC voltage sources in the circuit
    dcv_sources = Set{DCVoltageSource}()
    
    # TODO: more concise way of doing this?
    for node in nodes_vec
        for port in node.ports
            if typeof(port.component) == DCVoltageSource
                push!(dcv_sources, port.component)
            end
        end
    end
    
    # TODO: look into using an OrderedSet instead (DataStructures.jl ??)
    dcv_sources = collect(dcv_sources)
    n_dcvs = length(dcv_sources)

    # store the linear system
    A = zeros((n_nodes + n_dcvs, n_nodes + n_dcvs))
    b = zeros(n_nodes + n_dcvs)

    # the variables in the system are ordered as follows (for n nodes and k voltage sources)
    # v_1, v_2, ... v_n, I_1, I_2, ... I_k
    
    # track which equation we're up to
    i_eqn = 1

    # find index in array, assuming the item occurs exactly once
    # use this for testing, asserting that it does actually only occur once
    # TODO: once tested fully, replace with findin
    function index_of(x::Any, a::Array)
        indices = find(y->y == x, a)
        @assert length(indices) == 1
        return indices[1]
    end

    # for each node, fill a row of the system 
    for i = 1:n_nodes
        
        # examine this node
        node = nodes_vec[i]

        # if this node is the ground node, then we set this voltage to zero
        if node == circ.gnd
            A[i_eqn, i] = 1.
            b[i_eqn] = 0.
            i_eqn += 1
            continue
        end

        # otherwise, if there are no voltage sources connected, construct the equations
        # at this point there can only be impedances and current sources, so set the currents
        # IN through the resistors equal to the current OUT through the sources
        for port in node.ports

            # before any of this - if the component is a two port component, 
            # AND the other end of the component is not connected, then set the
            # current through the component to zero
            if typeof(port.component) <: TwoPortComponent &&
                is_floating(other_port(port))
               
                # the entry in this row of the matrix for this component will be
                # zero by default - so all we need to do is continue
                continue
            end

            # at this point both ends of the component are guarenteed to be connected to something!

            # if it's a voltage source - which one is it? use the corresponding current variable
            if typeof(port.component) == DCVoltageSource
                
                # find the index of the voltage source (we need this to get the current index)
                dcvs_index = index_of(port.component, dcv_sources)

                # the current convention is from - to +
                A[i_eqn, dcvs_index + n_nodes] = port == port.component.pHigh ? 1. : -1.
            end
            
            # if it's a current source
            if typeof(port.component) == DCCurrentSource
                
                current_dir = port == port.component.pIn ? 1 : -1
                b[i_eqn] += current_dir * port.component.I
            end

            # if it's an impedance
            if typeof(port.component) == Resistor

                A[i_eqn, i] -= 1. / port.component.R
                A[i_eqn, node_index(circ, other_end(port))] = 1. / port.component.R
            end
        end

        i_eqn += 1
    end

    # we still need n_dcvs more equations
    for i = 1:n_dcvs

        dcvs = dcv_sources[i]

        # if either port is floating, we don't have an equation to add
        if is_floating(dcvs.pHigh) || is_floating(dcvs.pLow) continue end

        # otherwise find the index of each port 
        pLow_node_index = index_of(dcvs.pLow.node, nodes_vec)
        pHigh_node_index = index_of(dcvs.pHigh.node, nodes_vec)

        # do the equation
        A[i_eqn, pHigh_node_index] = 1.
        A[i_eqn, pLow_node_index] = -1.
        b[i_eqn] = dcvs.V

        i_eqn += 1
    end
    
    # we've constructed the linear system - now solve it
    # of course we will need to do more than this for non-linear operating point analysis
    
    # need some way of guaranteeing this isn't singular
    # should happen when we replace with non-ideal sources
    sol_raw = A \ b

    cop = CircuitOP{Float64}()

    # return a mapping from nodes to their voltages
    # and from DCVoltageSources to their currents
    for i = 1:n_nodes cop[nodes_vec[i]] = sol_raw[i] end
    for i = 1:n_dcvs cop[dcv_sources[i]] = sol_raw[n_nodes + i] end

    return cop
end

function op_raw(circ::Circuit; sym_map=nothing, F=nothing, J=nothing, x0=nothing,
    params::Parameters = Parameters())

    # symbol map
    sym_map = sym_map == nothing ? gen_sym_map(circ) : sym_map
    n = length(sym_map)

    # generate functions if necessary
    F = F == nothing ? gen_sys_F(:F, sym_map, circ) : F
    J = J == nothing ? gen_sys_J(:J, sym_map, circ) : J

    # solve
    x0 = x0 == nothing ? zeros(n) : x0

    # TODO: what if this fails to converge?
    # don't think I have time for that kind of error handling ..
    x = newton(F, J, x0, params)
    
    return x
end

# newton-raphson for non-linear circuits - return the unmapped voltage/currents
function op(circ::Circuit; sym_map=nothing, F=nothing, J=nothing, x0=nothing,
    params::Parameters = Parameters())
    
    # symbol map
    sym_map = sym_map == nothing ? gen_sym_map(circ) : sym_map

    x = op_raw(circ, sym_map=sym_map, F=F, J=J, x0=x0, params=params)

    cop = CircuitOP{Float64}()

    i = 1
    for (node_or_comp, sym) in sym_map
        cop[node_or_comp] = x[i]
        i += 1
    end

    return cop
end

# operating point analysis, sweeping over the parameter
function dc_sweep(circ::Circuit, sweep_param::Parameter, sweep_range::Any,
    params::Parameters = Parameters())
    
    # symbol map
    sym_map = gen_sym_map(circ)
    n = length(sym_map)

    # generate functions if necessary
    F = gen_sys_F(:F, sym_map, circ)
    J = gen_sys_J(:J, sym_map, circ)

    x0 = zeros(n)
    x = Array{Float64, 2}(n, length(sweep_range))

    i = 1
    for param in sweep_range

        params[sweep_param] = param
        x0 = op_raw(circ, sym_map=sym_map, F=F, J=J, x0=x0, params=params)
        
        x[:, i] = x0

        i += 1
    end

    cop = CircuitOP{Vector{Float64}}()

    # fill in the solution 
    i = 1
    for (node_or_comp, sym) in sym_map
        cop[node_or_comp] = vec(x[i, :])
        i += 1
    end

    return cop
end

# transient analysis
function trans_raw(circ::Circuit, time_range::Any;
    params::Parameters = Parameters(),
    sym_map=nothing, dt_sym_map=nothing)

    # symbol maps and stuff
    sym_map = sym_map == nothing ? gen_sym_map(circ) : sym_map
    dt_sym_map = dt_sym_map == nothing ? gen_dt_sym_map(sym_map) : dt_sym_map
    
    # first find the operating point of the circuit
    x0 = op_raw(circ; sym_map=sym_map, params=params)

    n = length(x0)

    # initial time derivatives of zero is valid
    # TODO: this may not be the case - account for it
    xp0 = zeros(n)

    # generate the residual function required by Sundials' DAE solver
    # this is actually just the 'sys_F' function, but with the differential
    # voltage and current components from capacitors and inductors 
    # taken into account
    res_F = gen_sys_residuals_F(:res_F, sym_map, dt_sym_map, circ)

    # solve it with Sundials
    res_x, res_xp = Sundials.idasol(res_F, x0, xp0, collect(time_range); reltol=1e-8, abstol=1e-9)
    
    return res_x
end

# experiemental transient analysis - trying to fix the stability issues
function trans_raw_exp(circ::Circuit, time_range::Any;
    sym_map = nothing, dt_sym_map = nothing)

    # symbol maps and stuff
    sym_map = sym_map == nothing ? gen_sym_map(circ) : sym_map
    dt_sym_map = dt_sym_map == nothing ? gen_dt_sym_map(sym_map) : dt_sym_map

    # first find the operating point of the circuit
    x0 = op_raw(circ; sym_map=sym_map)

    n = length(x0)

    # initial time derivatives of zero is valid
    # TODO: this may not be the case - account for it
    xp0 = zeros(n)

    # generate F and J
    F = gen_sys_F(:F, sym_map, circ, true)
    J = gen_sys_J(:J, sym_map, circ, true)

    # this should be the same thing as the non-experimental one
    SimpleCircuits.Generated.eval(quote
        function res(t, x, xp, r)
            params = Parameters(:t=>t, :xp=>xp)
            F(x, r, params)
        end
    end)

    res_x, res_xp = Sundials.idasol(SimpleCircuits.Generated.res, x0, xp0, 
        collect(time_range); reltol=1e-9, abstol=1e-9)

    return res_x
end

function trans(circ::Circuit, time_range::Any,
    params::Parameters = Parameters())

    # generate symbol maps
    sym_map = gen_sym_map(circ)
    dt_sym_map = gen_dt_sym_map(sym_map)
    
    res_x = trans_raw(circ, time_range; params=params, sym_map=sym_map,
        dt_sym_map=dt_sym_map)

    # organize the results
    cop = CircuitOP{Vector{Float64}}()
    
    i = 1
    for (k, v) in sym_map
        cop[k] = vec(res_x[:, i])
        i += 1
    end

    return cop
end

# experimental trans
function trans_exp(circ::Circuit, time_range::Any)

    # generate symbol maps
    sym_map = gen_sym_map(circ)
    dt_sym_map = gen_dt_sym_map(sym_map)
    
    res_x = trans_raw_exp(circ, time_range; sym_map=sym_map,
        dt_sym_map=dt_sym_map)

    # organize the results
    cop = CircuitOP{Vector{Float64}}()
    
    i = 1
    for (k, v) in sym_map
        cop[k] = vec(res_x[:, i])
        i += 1
    end

    return cop
end
