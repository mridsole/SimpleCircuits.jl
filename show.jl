# methods for printing components in the REPL

port_node_str(p::Port) = typeof(p.node) == Node ? p.node.name : "floating"

function port_id_str(p::Port)

	port_id_str = ""

	for fieldsym in fieldnames(typeof(p.component))
		if p.component.(fieldsym) == p
			port_id_str = string(fieldsym)
	end end

	return port_id_str
end

# show a circuit
function show(io::IO, circ::Circuit)
    
    #= need to print:
        - number of nodes
        - number of components
    =#
    
    # TODO: figure out better format for displaying a circuit
    print(io, "Circuit(nodes = " * string(length(circ.nodes)) * ")")
end

# show a port
function show(io::IO, x::Port)
	
	#= we need to print: 
		- the component type
		- the port id
		- the node name
	=#

	# finding the port id string: compare to all fields of the component
	# there should be exactly one match here - if not something's very wrong
	port_str = port_id_str(x)

	# get the node name, if one is connected
	if !is_floating(x)
		print(io, "port " * port_str * " on a " * component_type_name(x.component) * 
			" connected to node \"" * x.node.name * "\"")
	else
		print(io, "floating port " * port_str * " on a " * 
			component_type_name(x.component))
	end
end

# show a resistor
function show(io::IO, r::Resistor)

	# over multiple lines
	println(io, "Resistor ")
	println(io, "R: " * string(r.R))
	println(io, "p1: " * port_node_str(r.p1))
	print(io, "p2: " * port_node_str(r.p2))
end

# show a capacitor
function show(io::IO, c::Capacitor)

	# over multiple lines
	println(io, "Capacitor ")
	println(io, "C: " * string(c.C))
	println(io, "p1: " * port_node_str(c.p1))
	print(io, "p2: " * port_node_str(c.p2))
end

# show an inductor
function show(io::IO, l::Inductor)

	# over multiple lines
	println(io, "Inductor ")
	println(io, "L: " * string(l.L))
	println(io, "p1: " * port_node_str(l.p1))
	print(io, "p2: " * port_node_str(l.p2))
end

# show a node
function show(io::IO, node::Node)
	
	# need to print the name of the node, and each component
	# that's connected, and the pin by which it's connected
	println(io, "Node: " * node.name)

	for port in node.ports
		println(io, "	port " * port_id_str(port) * " on " 
		* component_type_name(port.component) * " " * port.component.name)
	end
end
