# functions for constructing a circuit via adding connections

# check if a node name's already in use
function node_name_in_use(circ::Circuit, name::ASCIIString)

	for node in circ.nodes
		if name == node.name return true end
	end
	return false
end

# check if all the connections on a port belong to the circuit
function port_belongs(circ::Circuit, port::Port)
    
    for node in port.nodes
        if !(node in circ.nodes || node == circ.gnd)
            return false
    end end

    return true
end

# check if two ports are connected
function is_connected(p1::Port, p2::Port)
    
    # if they're connected there's a node that's common to both p.nodes
    for n1 in p1.nodes, n2 in p2.nodes
        if n1 == n2 return true end
    end

    return false
end

# merge the connections of the second node into the first, then disconnect the
# second node from everything
function merge!(circ::Circuit, node1::Node, node2::Node)
	
	# if the nodes are the same, quit now
	if node1 == node2 return end
	
	# copy all the ports over, also removing them from node 1
	for port in node2.ports
		port.node = node1
		push!(node1.ports, port)
		delete!(node2.ports, port)
	end

	# remove node 2 from the circuit
	delete!(circ.nodes, node2)
end
	
# connect two ports together in a circuit
# optionally, supply a name to give the node
# if there already exists a node, the name will be overwritten
function connect!(circ::Circuit, p1::Port, p2::Port, name::ASCIIString="")
	
	if is_floating(p1) && is_floating(p2)
		# CASE 1: both p1 and p2 aren't connected to anything (node == nothing)

		# so make a new node:
		new_node = Node(Set{Port}([p1, p2]), name)

		if name == ""
			# give the node an automatic name if necessary
			circ.autonamed_nodes += 1
			new_node.name = "node " * string(circ.autonamed_nodes)

		elseif node_name_in_use(circ, name)
			# otherwise, check if the name is in use - if it is, throw error
			error("The provided node name is already in use.")
		end

		p1.node = new_node
		p2.node = new_node

		# add new node to the circuit
		push!(circ.nodes, new_node)

	elseif (is_floating(p1) && !is_floating(p2)) ||
		(is_floating(p2) && !is_floating(p1))
		# CASE 2: one port is floating but one isn't
		
		# get the floating and existing nodes
		if is_floating(p1) 
			p_floating = p1
			p_existing = p2
		else 
			p_floating = p2
			p_existing = p1
		end

		# check name replacement
		if name != "" && name != p_existing.node.name
			# if we're trying to set a new name but it's in use, that's an error
			# otherwise replace the name
			if node_name_in_use(circ, name)
				error("The provided node name is already in use.")
			else 
				p_existing.node.name = name 
			end
		end
		
		# add the currently floating connection in
		push!(p_existing.node.ports, p_floating)

	else
		# CASE 3: they're both connected - if not to the same node, then we 
		# have to merge nodes
		if p1.node == p2.node

			# when the ports are on the same node already, we only have to handle renaming
			if name != "" && name != p1.node.name
				if node_name_in_use(circ, name)
					error("The provided node name is already in use.")
				else
					p1.node.name = name
				end
			end
		else
			
			# when the ports are on different nodes, we have to merge them
			merge!(circ, p1.node, p2.node)

			# now check the node name
			if name != "" && name != p1.node.name
				if node_name_in_use(circ, name)
					error("The provided node name is already in use.")
				else
					p1.node.name = name
				end
			end
		end
	end

	return nothing
end

# connect a port directly to a node
function connect!(circ::Circuit, port::Port, node::Node)

    # check if the node actually belongs to the provided circuit
    if !(node in circ.nodes || node == circ.gnd)
        error("Attempted to connect a component to a node on a different circuit.")
    end

    # check if all the current connections of port are nodes in circ
    if !port_belongs(circ, port) 
        error("The given port doesn't belong to the given circuit.")
    end

    # assuming port has no connections on a different circuit, there's
    # only two cases here - either it's already on the node or not

    # if the port's already on that node
    if node in port.nodes return end

    # otherwise, 
    push!(port.nodes, node)
end

function disconnect!(circ::Circuit, p1::Port, p2::Port)
    
    # make sure both ports belong to the circuit
    if !(port_belongs(circ, p1) && port_belongs(circ, p2))
        error("Attempted to disconnect a port that doesn't belong to the circuit.")
    end

    # two cases - either the resulting node is not ground and is empty, or not
    # if the node is empty then we should remove it
    node = 
end

function disconnect!(circ::Circuit, port::Port, node::Node)
    
    # check if the node's in the circuit etc
    if !(node in circ.nodes || node == circ.gnd)
        error("Attempted to disconnect a node from a circuit it doesn't belong to.")
    end
    
    # remove the port from the node
    delete!(port.nodes, node)

    # now if the node is empty, it can be removed from the circuit
    # (as long as it's not ground!)
    if node != circ.gnd && isempty(node.ports)
        delete!(circ.nodes, node)
    end
end
