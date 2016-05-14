# MATH3976 project - a simple circuit simulator for developing 
# analog circuit design intuition

module SimpleCircuits

# need stuff here like resistor, capacitor, inductor, diode, BJT, MOSFET, etc
include("components.jl")
export Circuit, Port, Resistor, Capacitor, Inductor, DCVoltageSource

# methods for constructing circuits via connections
import Base.merge!
include("connections.jl")
export is_floating, node_name_in_use, is_connected, port_belongs
export merge!, connect!, disconnect!

# display methods
import Base.show
include("show.jl")
export show

# linear analysis
include("linear.jl")

end
