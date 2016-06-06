# tests for op.jl - testing operating point stuff
using SimpleCircuits

# fixture for circuit 1 (same as in tests/connections.jl)
macro circuit1()
    quote
        # dumps the components into the parent scope
        $(esc(:circ)) = Circuit()
        $(esc(:r1)) = Resistor(5e+3)
        $(esc(:r2)) = Resistor(10e+3)
        $(esc(:v_DC)) = DCVoltageSource(5.)
        connect!($(esc(:circ)), $(esc(:v_DC)).pHigh, $(esc(:r1)).p1)
        connect!($(esc(:circ)), $(esc(:r1)).p2, $(esc(:r2)).p1)
        connect!($(esc(:circ)), $(esc(:r2)).p2, $(esc(:v_DC)).pLow)
        connect!($(esc(:circ)), $(esc(:circ)).gnd, $(esc(:v_DC)).pLow)
    end
end

# array of test functions
op_tests = Array{Test, 1}([

Test("operating point test 1", function()
    
    @circuit1

    # do the analysis
    op(circ)

    # TODO: ensure the values are correct

end),

# example of a circuit that currently breaks the solver
# (results in a singular matrix A)
Test("operating point test 2", function()

    # testing a more complicated circuit
    circ = Circuit()

    r1 = Resistor(5e+3)
    r2 = Resistor(10e+3)
    r3 = Resistor(7e+3)
    v_DC_1 = DCVoltageSource(5.)
    v_DC_2 = DCVoltageSource(10.)

    connect!(circ, v_DC_1.pHigh, r1.p1, "Node 1")
    connect!(circ, r1.p2, r2.p1, "Node 2")
    connect!(circ, r2.p2, v_DC_1.pLow)
    connect!(circ, circ.gnd, r3.p1)
    connect!(circ, r3.p2, v_DC_2.pLow, "Node 3")
    connect!(circ, v_DC_2.pHigh, r1.p2)
    connect!(circ, r1.p2, v_DC_2.pHigh)
    connect!(circ, circ.gnd, v_DC_1.pLow)
    
    op(circ)
end)
])
