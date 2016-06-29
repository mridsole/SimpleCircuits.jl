# MATH3976 project - a simple circuit simulator for developing 
# analog circuit design intuition

module SimpleCircuits

# need stuff here like resistor, capacitor, inductor, diode, BJT, MOSFET, etc
include("components.jl")
export Circuit, Port, Resistor, Capacitor, Inductor, DCVoltageSource, DCCurrentSource
export Diode, p1, p2, parameters
export TwoPortComponent, Parameter

# multidimensional newton-raphson iteration
include("newton.jl")
export newton

# methods for constructing circuits via connections
import Base.merge!
include("connections.jl")
export is_floating, node_name_in_use, is_connected, port_belongs
export merge!, connect!, disconnect!

# methods for expressions for DC IV (current-voltage) relations
# of various components
include("dciv_relations.jl")
export dciv, dcsatisfy, dciv_diff, dcsatisfy_diff
export PortSyms

# display methods
import Base.show
include("show.jl")
export show

# include op systems (expression generation)
include("op_systems.jl")
export gen_sym_map, gen_sys_exprs, gen_sys_F, gen_J_exprs, gen_sys_J

# operating point analysis
# TODO: this is the old, linear only implementation - name this appropriately
include("op.jl")
export op_linear, op

# include tests
include("tests/tests.jl")

end
