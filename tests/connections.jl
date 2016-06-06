# tests for connections.jl and related
using SimpleCircuits

# fixture for creating circuit 1
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

# array of test functions - true = passed, error = failure
connection_tests = Array{Test, 1}([

Test("connection test 1 - construct circuit 1", function()

    # this test constructs circuit 1, but does some testing along the way
    # so it doesn't use the fixture macro
    
    circ = Circuit()
    
    r1 = Resistor(5e+3)
    r2 = Resistor(10e+3)
    v_DC = DCVoltageSource(5.)

    # all ports should be floating
    @assert is_floating(r1.p1)
    @assert is_floating(r1.p2)
    @assert is_floating(r2.p1)
    @assert is_floating(r2.p2)
    @assert is_floating(v_DC.pHigh)
    @assert is_floating(v_DC.pLow)

    # ports should be disconnected
    @assert !is_connected(v_DC.pHigh, r1.p1)
    @assert !is_connected(r1.p2, r2.p1)
    @assert !is_connected(r2.p2, v_DC.pLow)
    
    println(typeof(circ))
    println(typeof(v_DC.pHigh))
    println(typeof(r1.p1))
    connect!(circ, v_DC.pHigh, r1.p1)
    connect!(circ, r1.p2, r2.p1)
    connect!(circ, r2.p2, v_DC.pLow)

    # this one's a bit different - connect port directly to a node
    connect!(circ, circ.gnd, v_DC.pLow)

    # now things should be connected
    @assert is_connected(v_DC.pHigh, r1.p1)
    @assert is_connected(r1.p2, r2.p1)
    @assert is_connected(r2.p2, v_DC.pLow)
end ),

Test("connection test 2 - test circuit 1 connections", function()
    
    # test our circuit 1 construction macro
    @circuit1

    # now things should be connected
    @assert is_connected(v_DC.pHigh, r1.p1)
    @assert is_connected(r1.p2, r2.p1)
    @assert is_connected(r2.p2, v_DC.pLow)
end ),

Test("connection test 3 - test node_index", function()
    
    @circuit1
    
    # this is only currently testing that there's no errors ..
    for node in circ.nodes
        SimpleCircuits.node_index(circ, node)
    end
end),

Test("connection test 4 - test other_end", function()
    
    @circuit1

    # test other_end on r1 and r2
    @assert r1.p2.node == SimpleCircuits.other_end(r1.p1)
    @assert r1.p1.node == SimpleCircuits.other_end(r1.p2)
    @assert r2.p2.node == SimpleCircuits.other_end(r2.p1)
    @assert r2.p1.node == SimpleCircuits.other_end(r2.p2)
end)
])
