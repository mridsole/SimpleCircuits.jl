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

    # ensure the values are correct

end )
])
