# MATH3976 project - a simple circuit simulator for developing 
# analog circuit design intuition

module SimpleCircuits

# need stuff here like resistor, capacitor, inductor, diode, BJT, MOSFET, etc
include("components.jl")
export Circuit, Port, Resistor, Capacitor, Inductor, DCVoltageSource

# methods for constructing circuits via connections
import Base.merge!
include("connections.jl")
export merge!, connect!

# display methods
import Base.show
include("show.jl")
export show

# linear analysis


end
