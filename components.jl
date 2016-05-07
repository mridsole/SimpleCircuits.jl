# supertype of all circuit components
abstract Component

# an arbitrary, empty concrete Component, used internally when constructing
# Resistors, Capacitors, etc (see their constructors)
type NullComponent <: Component end

# components also have terminals, or ports
# i.e. resistors, capacitors, inductors are two terminal components
# they also happen to be non-polar but for the sake of generality
# we'll store separate connections (we'll have to do this for diodes anyway,
# and also eventually account for components with more than two ports
# when we come to transistors and op amps etc
type Port

	# the node it's connected to
	# setting type to Any is an unfortunately necessary hack, 
	# because julia doesn't support circular type declarations (yet?), see:
	# https://github.com/JuliaLang/julia/issues/269
	# (on the bright side it lets us represent a floating connection with "nothing")
	# might be an alternative with parametric types
	node::Any

	# upwards reference to this port's component
	component::Component
end

# the user doesn't need to worry about this
type Node
	
	# list of connected ports
	ports::Set{Port}
end

# a Circuit is just a list of nodes (maybe with some other data too?)
# (describes the connections between components)
type Circuit
	nodes::Array{Node, 1}
end

# type definitions for circuit components

# resistor
type Resistor <: Component
	
	# the resistance, in Ohms
	R::Float64
	
	# resistors are non-polar of course, but for consistency
	# we'll store connections like this
	p1::Port
	p2::Port

	# constructor for client - leave ports initially floating
	function Resistor(R::Float64)
		this = new(R, Port(nothing, NullComponent()), Port(nothing, NullComponent()))
		this.p1.component = this
		this.p2.component = this
	end
end

# capacitor
type Capacitor <: Component

	# the capacitance, in Farads
	C::Float64

	p1::Port
	p2::Port

	function Capacitor(C::Float64)
		this = new(C, Port(nothing, NullComponent()), Port(nothing, NullComponent()))
		this.p1.component = this
		this.p2.component = this
	end
end

# inductor
type Inductor <: Component

	# the inductance, in Henrys
	L::Float64

	p1::Port
	p2::Port

	function Inductor(L::Float64)
		this = new(L, Port(nothing, NullComponent()), Port(nothing, NullComponent()))
		this.p1.component = this
		this.p2.component = this
	end
end
