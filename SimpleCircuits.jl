# MATH3976 project - a simple circuit simulator

module SimpleCircuits

# need stuff here like resistor, capacitor, inductor, diode, BJT, MOSFET, etc
include("components.jl")

# defines functions for building up a circuit via adding connections

export Port, Resistor, Capacitor, Inductor

end
