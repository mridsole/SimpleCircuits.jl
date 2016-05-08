# functions for constructing a circuit via adding connections

# check if a port is floating or not
# currently this is implemented as port.node == nothing, but this 
# is messy and will probably change in the future
is_floating(p::Port) = p.node == nothing

# check if a node name's already in use
function node_name_in_use(circ::Circuit, name::ASCIIString)

	for node in circ.nodes
		if name == node.name return true end
	end
	return false
end

# merge the connections of the second node into the first, then disconnect the
# second node from everything
function merge!(node1::Node, node2::Node)

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
			
			# when the ports are on different nodes, we have to try and merge them
			
		end
end
