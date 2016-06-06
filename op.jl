include("components.jl")

# methods for linear and non-linear operating point analysis

# find the DC operating point
function op(circ::Circuit)

    # newton-raphson method here?
    # solve with a system of linear equations
    # for non-linear components, solve matrix system
    # at each step, using the gradients of the 
    # non-linear components
    
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

    # construct the system of linear equations
    nodes_vec = collect(circ.nodes)
    n_nodes = length(nodes_vec)

    # store the linear system
    A = zeros((n_nodes, n_nodes))
    b = zeros(n_nodes)
    
    # flag which DC voltage sources we've used so far
    dcvs_used = Set{DCVoltageSource}()
    
    # track which equation we're up to
    i_eqn = 1

    # for each node, fill a row of the system 
    for i = 1:n_nodes
        
        # examine this node
        node = nodes_vec[i]

        # if this node is the ground node, then we set this voltage to zero
        if node == circ.gnd
            A[i_eqn, i] = 1.
            b[i_eqn] = 0.
        end

        # if there's a voltage source here that we haven't used, then 
        # we should use it to relate two variables

        # is there a voltage source connected to this node?
        if is_type_connected(node, DCVoltageSource)

            # if so, we have to use one - if we've used them all, skip this node

            # get all DC voltage sources connected directly
            dcvs_ports = filter(node.ports, p -> typeof(p.component) == DCVoltageSource)

            # filter for sources we haven't used
            filter!(dcvs_ports, p -> !(p.component in dcvs_used))
            
            # if there's any sources that haven't been used, use one
            if length(dcvs_ports) > 0
                A[i_eqn, i] = 1.
                A[i_eqn, node_index(other_end(dcvs_ports[1]))] = -1.
                b[i_eqn] = dcvs_ports[1].component.V
                append!(dcvs_used, dcvs_ports[1])
                i_eqn += 1
            end
            
            # skip to next node
            continue
        end

        # otherwise, if there are no voltage sources connected, construct the equations
        # at this point there can only be impedances and current sources, so set the currents
        # IN through the resistors equal to the current OUT through the sources
        for port in node.ports
            
            # if it's a current source
            if typeof(port.component) == DCCurrentSource
                current_dir = port == port.component.pIn ? 1 : -1
                b[i_eqn] += current_dir * port.component.I
            end

            # if it's an impedance
            if typeof(port.component) == Resistor
                A[i_eqn, i] -= 1 / port.component.R
                A[i_eqn, node_index(other_end(port))] = 1 / port.component.R
            end
        end

        i_eqn += 1
    end

end


