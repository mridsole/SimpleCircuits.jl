include("components.jl")

# contains the numerical values for a circuit operating point
type CircuitOP
    
    node_voltages::Dict{Node, Float64}
    dcvs_currents::Dict{DCVoltageSource, Float64}

    CircuitOP() = new(Dict{Node, Float64}(), Dict{DCVoltageSource, Float64}())
end

import Base.setindex!, Base.getindex

function Base.setindex!(cop::CircuitOP, val::Float64, node::Node)
    cop.node_voltages[node] = val 
end

function Base.setindex!(cop::CircuitOP, val::Float64, dcvs::DCVoltageSource) 
    cop.dcvs_currents[dcvs] = val 
end

Base.getindex(cop::CircuitOP, node::Node) = cop.node_voltages[node]
Base.getindex(cop::CircuitOP, dcvs::DCVoltageSource) = cop.dcvs_currents[dcvs]

# get voltage at ports (uses the connected node)
Base.getindex(cop::CircuitOP, port::Port) = cop.node_voltages[port.node]

function show(io::IO, cop::CircuitOP)

    println(io, "Node voltages: ")
    println(io, cop.node_voltages)
    println(io, "DCVoltageSource currents: ")
    println(io, cop.dcvs_currents)
end

# methods for linear and non-linear operating point analysis

# find the DC operating point
function op(circ::Circuit)

    # newton-raphson method here?
    # solve with a system of linear equations
    # for non-linear components, solve matrix system
    # at each step, using the gradients of the 
    # non-linear components

    # TODO: since for the majority of circuits, the number of 
    # connections on a node is generally much smaller than the 
    # total number of nodes plus the total number of current sources
    # (which is the number of equations we will have) - therefore
    # the linear system tends to be sparse
    # figure out a way to exploit this
    
    # we should return a map from nodes to voltages
    dict = Dict{Node, Float64}()

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

    cop = CircuitOP()

    # return a mapping from nodes to their voltages
    # and from DCVoltageSources to their currents
    for i = 1:n_nodes cop[nodes_vec[i]] = sol_raw[i] end
    for i = 1:n_dcvs cop[dcv_sources[i]] = sol_raw[n_nodes + i] end

    return cop
end
