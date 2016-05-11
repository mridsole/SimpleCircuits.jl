# methods for printing components in the REPL
port_node_str(p::Port) = typeof(p.node) == Node ? p.node.name : "floating"

# show a port
function show(io::IO, x::Port)
	
	#= we need to print: 
		- the component type
		- the port id
		- the node name
	=#

	# finding the port id string: compare to all fields of the component
	# there should be exactly one match here - if not something's very wrong
	port_id_str = ""
	for fieldsym in fieldnames(typeof(x.component))
		if x.component.(fieldsym) == x
			port_id_str = string(fieldsym)
	end end

	# get the node name, if one is connected
	if !is_floating(x)
		print(io, "port " * port_id_str * " on a " * component_type_name(x.component) * 
			" connected to node \"" * x.node.name * "\"")
	else
		print(io, "floating port " * port_id_str * " on a " * 
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
