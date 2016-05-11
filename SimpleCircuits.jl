# MATH3976 project - a simple circuit simulator for developing 
# analog circuit design intuition

module SimpleCircuits

# need to overwrite some base methods
import Base.merge!

# need stuff here like resistor, capacitor, inductor, diode, BJT, MOSFET, etc
include("components.jl")
export Circuit, Port, Resistor, Capacitor, Inductor

# methods for constructing circuits via connections
include("connections.jl")
export merge!, connect!

end
