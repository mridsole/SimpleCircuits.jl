# this contains type definitions for some circuit components

# used for storing ports connected to a node
using DataStructures

# supertype of all circuit components
abstract Component
abstract TwoPortComponent <: Component

# a parameter may be used to efficiently vary a numerical value
# during the simulation, or over a DC sweep or something
# (the system and Jacobian functions won't be recompiled)
# ... for now just use symbols - but might want to do something more later
typealias Parameter Symbol

# for potential generality later on
symbol(param::Parameter) = param

# an arbitrary, empty concrete Component, used internally when constructing
# Resistors, Capacitors, etc (see their constructors)
type NullComponent <: Component end

# components also have terminals, or ports
# i.e. resistors, capacitors, inductors are two terminal components
# while transistors have three ports
# underscore = internal use (the parameter is used to resolve a 
# circular type reference - use Port (defined below Node) instead
type Port_{NodeT}

	# the node it's connected to
	# setting type to Any is an unfortunately necessary hack, 
	# because julia doesn't support circular type declarations (yet?), see:
	# https://github.com/JuliaLang/julia/issues/269
	# (on the bright side it lets us represent a floating connection with "nothing")
	# might be an alternative with parametric types
    # UPDATE: better than nothing - just use a parametric type
	node::NodeT

	# upwards reference to this port's component
	component::Component

	Port_() = new(NULL_NODE, NullComponent())
end

# used to describe which ports are connected
type Node
	
	# list of connected ports
	ports::OrderedSet{Port_{Node}}

	# name of the node
	name::ASCIIString

	Node() = new(OrderedSet{Port_{Node}}(), "")
	Node(ports::OrderedSet{Port_{Node}}, name::ASCIIString) = new(ports, name)
    Node(name::ASCIIString) = new(OrderedSet{Port_{Node}}(), name)

	# node must belong to a circuit

	# need to do more than this - check if name is in use
	# Node(ports::Set{Port}, name::ASCIIString) = new(ports, name)
end

typealias Port Port_{Node}

# the "null node" - used to specify a floating connection
global const NULL_NODE = Node(OrderedSet{Port}(), "NULL_NODE")

# a Circuit is just a set of nodes (maybe with some other data too?)
# (describes the connections between components)
type Circuit

	nodes::OrderedSet{Node}
	
	# how many "unnamed" (automatically named) nodes do we have?
	autonamed_nodes::Int64

    # the special ground node, reference from which voltages are measured
    gnd::Node
	
	# construct empty circuit
    function Circuit() 
        this = new(OrderedSet{Node}(), 0, Node("GND"))
        push!(this.nodes, this.gnd)
        return this
    end
end

# type definitions for circuit components

# resistor
type Resistor <: TwoPortComponent

	# component name, not essential
	name::ASCIIString
	
	# the resistance, in Ohms
	R::Union{Float64, Parameter}
	
	# resistors are non-polar of course, but for consistency
	# we'll store connections like this
	p1::Port
	p2::Port

	function Resistor(R::Union{Float64, Parameter})
		this = new("", R, Port(), Port())
		this.p1.component = this
		this.p2.component = this
        return this
	end
end

# capacitor
type Capacitor <: TwoPortComponent

	# component name, not essential
	name::ASCIIString

	# the capacitance, in Farads
	C::Union{Float64, Parameter}

	p1::Port
	p2::Port

	function Capacitor(C::Union{Float64, Parameter})
		this = new("", C, Port(), Port())
		this.p1.component = this
		this.p2.component = this
        return this
	end
end

# inductor
type Inductor <: TwoPortComponent

	# component name, not essential
	name::ASCIIString

	# the inductance, in Henrys
	L::Union{Float64, Parameter}

	p1::Port
	p2::Port

	function Inductor(L::Union{Float64, Parameter})
		this = new("", L, Port(), Port())
		this.p1.component = this
		this.p2.component = this
        return this
	end
end

# constant/DC voltage source
type DCVoltageSource <: TwoPortComponent

	# component name, not essential
	name::ASCIIString

	# the source voltage
	V::Union{Float64, Parameter}

	# the ports: 
	pHigh::Port
	pLow::Port

	function DCVoltageSource(V::Union{Float64, Parameter})
		this = new("", V, Port(), Port())
		this.pHigh.component = this
		this.pLow.component = this
        return this
	end
end

type DCCurrentSource <: TwoPortComponent

    name::ASCIIString

    I::Union{Float64, Parameter}

    # the ports
    pIn::Port
    pOut::Port

    function DCCurrentSource(I::Union{Float64, Parameter})
        this = new("", I, Port(), Port())
        this.pIn.component = this
        this.pOut.component = this
        return this
    end
end

type Diode <: TwoPortComponent

    name::ASCIIString

    # reverse saturation current
    Is::Union{Float64, Parameter}

    # thermal voltage (0.026 V at 25 degrees C)
    VT::Union{Float64, Parameter}

    # ideality factor (between 1 and 2)
    n::Union{Float64, Parameter}

    pIn::Port
    pOut::Port

    # common "mistake" looks to be passing an integer as n ..
    # so don't type annotate that
    function Diode(Is::Union{Float64, Parameter}, VT::Union{Float64, Parameter}, n = 1.)
        this = new("", Is, VT, n, Port(), Port())
        this.pIn.component = this
        this.pOut.component = this
        return this
    end
end

# the default
p1(comp::Component) = comp.p1
p1(comp::DCVoltageSource) = comp.pLow
p1(comp::DCCurrentSource) = comp.pIn
p1(comp::Diode) = comp.pIn

p2(comp::Component) = comp.p2
p2(comp::DCVoltageSource) = comp.pHigh
p2(comp::DCCurrentSource) = comp.pOut
p2(comp::Diode) = comp.pOut

function parameters(comp::Component)

    # some parameters may be tied!
    params = OrderedSet{Parameter}()

    # wow
    for val in map(x->getfield(comp, x), fieldnames(typeof(comp)))
        if typeof(val) == Parameter push!(params, val) end
    end

    return params
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

# most TwoPortComponents follow this convention - exceptions are below ...
function other_port{T<:TwoPortComponent}(c::T, p::Port)
    return p == c.p1  ? c.p2 : c.p1
end

function other_port(c::DCVoltageSource, p::Port)
    return p == c.pHigh ? c.pLow : c.pHigh
end

function other_port(c::DCCurrentSource, p::Port)
    return p == c.pIn ? c.pOut : c.pIn
end

function other_port(d::Diode, p::Port)
    return p == d.pIn ? d.pOut : d.pIn
end
    
# given a port on a two port component, return the port at the other end
function other_port(port::Port)

    # this only makes sense for two terminal components
    @assert typeof(port.component) <: TwoPortComponent
    
    # multiple dispatch to account for weird port naming ...
    other_port(port.component, port)
end

# given a port on a two port component, return the node on the other end
# if it's floating, return 'nothing' as per normal
function other_end(port::Port)
    
    if port == nothing return nothing end

    # get the other component 
    return other_port(port).node
end
