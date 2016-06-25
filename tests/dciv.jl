using SimpleCircuits

dciv_tests() = Array{Test, 1}([

Test("DCIV test 1 - test DCVoltageSource", function()

    # test DCIV for a voltage source
    V = 5.
    vdc = DCVoltageSource(V)

    ps = Dict(vdc.pHigh => :v1, vdc.pLow => :v2)

    # expression comparison is quite fragile (we're testing for the 
    # exact same AST, not the same mathematical expresion here)
    @assert dciv(vdc, ps, vdc.pLow, :I1) == :(1.0 * I1)
    @assert dciv(vdc, ps, vdc.pHigh, :I1) == :(-1.0 * I1)

    @assert dciv_diff(vdc, ps, vdc.pLow, :v1, :I1) == 0.
    @assert dciv_diff(vdc, ps, vdc.pLow, :v2, :I1) == 0.
    @assert dciv_diff(vdc, ps, vdc.pLow, :I1, :I1) == 1.

    @assert dcsatisfy(vdc, ps, :I1) == [:((v1 - v2) - $(V))]
    
    @assert dcsatisfy_diff(vdc, ps, :v1, :I1)  == [1.]
    @assert dcsatisfy_diff(vdc, ps, :v2, :I1)  == [-1.]
    @assert dcsatisfy_diff(vdc, ps, :I1, :I1)  == [0.]
end)

])
