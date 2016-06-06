# this contains type definitions for some circuit components

# supertype of all circuit components
abstract Component
abstract TwoPortComponent <: Component

# an arbitrary, empty concrete Component, used internally when constructing
# Resistors, Capacitors, etc (see their constructors)
type NullComponent <: Component end

# components also have terminals, or ports
# i.e. resistors, capacitors, inductors are two terminal components
# while transistors have three ports
type Port

	# the node it's connected to
	# setting type to Any is an unfortunately necessary hack, 
	# because julia doesn't support circular type declarations (yet?), see:
	# https://github.com/JuliaLang/julia/issues/269
	# (on the bright side it lets us represent a floating connection with "nothing")
	# might be an alternative with parametric types
	node::Any

	# TODO: investigate accessor function method
	# i.e use node(p::Port)

	# upwards reference to this port's component
	component::Component

	Port() = new(nothing, NullComponent())
end

# used to describe which ports are connected
type Node
	
	# list of connected ports
	ports::Set{Port}

	# name of the node
	name::ASCIIString

	Node() = new(Set{Port}(), "")
	Node(ports::Set{Port}, name::ASCIIString) = new(ports, name)
    Node(name::ASCIIString) = new(Set{Port}(), name)

	# node must belong to a circuit

	# need to do more than this - check if name is in use
	# Node(ports::Set{Port}, name::ASCIIString) = new(ports, name)
end

# a Circuit is just a set of nodes (maybe with some other data too?)
# (describes the connections between components)
type Circuit

	nodes::Set{Node}
	
	# how many "unnamed" (automatically named) nodes do we have?
	autonamed_nodes::Int64

    # the special ground node, reference from which voltages are measured
    gnd::Node
	
	# construct empty circuit
	Circuit() = new(Set{Node}(), 0, Node("GND"))
end

# type definitions for circuit components

# resistor
type Resistor <: TwoPortComponent

	# component name, not essential
	name::ASCIIString
	
	# the resistance, in Ohms
	R::Float64
	
	# resistors are non-polar of course, but for consistency
	# we'll store connections like this
	p1::Port
	p2::Port

	function Resistor(R::Float64)
		this = new("", R, Port(), Port())
		this.p1.component = this
		this.p2.component = this
	end
end

# capacitor
type Capacitor <: TwoPortComponent

	# component name, not essential
	name::ASCIIString

	# the capacitance, in Farads
	C::Float64

	p1::Port
	p2::Port

	function Capacitor(C::Float64)
		this = new("", C, Port(), Port())
		this.p1.component = this
		this.p2.component = this
	end
end

# inductor
type Inductor <: TwoPortComponent

	# component name, not essential
	name::ASCIIString

	# the inductance, in Henrys
	L::Float64

	p1::Port
	p2::Port

	function Inductor(L::Float64)
		this = new("", L, Port(), Port())
		this.p1.component = this
		this.p2.component = this
	end
end

# constant/DC voltage source
type DCVoltageSource <: TwoPortComponent

	# component name, not essential
	name::ASCIIString

	# the source voltage
	V::Float64

	# the ports: 
	pHigh::Port
	pLow::Port

	function DCVoltageSource(V::Float64)
		this = new("", V, Port(), Port())
		this.pHigh.component = this
		this.pLow.component = this
	end
end

type DCCurrentSource <: TwoPortComponent

    name::ASCIIString

    I::Float64

    # the ports
    pIn::Port
    pOut::Port

    function DCCurrentSource(I::Float64)
        this = new("", I, Port(), Port())
        this.pIn.component = this
        this.pOut.component = this
    end
end

# obtain the name of a component type
function component_type_name(c)
	
	# for now assume all component types are those defined within the
	# SimpleCircuits module (found in components.jl)
	ret_str = string(typeof(c))

	# cut off the SimpleCircuits. part of the string if it's there
	search_res = search(ret_str, "SimpleCircuits.")
	if search_res.stop > -1 && search_res.stop < length(ret_str)
		ret_str = ret_str[(search_res.stop + 1):end]
	end

	return ret_str
end

# get the index of a node in a circuit
function node_index(circ::Circuit, node::Node)
    
    nodes_array = collect(circ.nodes)
    matches = find(x->x == node, nodes_array)
    assert(length(matches) <= 1)
    return length(matches) == 0 ? -1 : matches[1]
end

# given a port on a two port component, return the node on the other end
# if it's floating, return 'nothing' as per normal
function other_end(port::Port)
    
    if port == nothing return nothing end
    
    # this only makes sense for two terminal components
    @assert typeof(port.component) <: TwoPortComponent
    
    # TODO: there are some two port components defined (the sources) that 
    # don't follow this convention ... figure out what to do for those.
    # (should we store the two ports in a pair instead?)
    if port == port.component.p1
        if port.component.p2 == nothing return nothing end
        return port.component.p2.node
    else
        if port.component.p1 == nothing return nothing end
        return port.component.p1.node
    end
end

