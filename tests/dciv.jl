using SimpleCircuits

# these relations are fairly important so test most/every case

dciv_tests() = Array{Test, 1}([

Test("DCIV test 1 - test DCVoltageSource", function()

    # test DCIV for a voltage source
    V = 5.
    vdc = DCVoltageSource(V)

    ps = PortSyms(vdc.pHigh => :v1, vdc.pLow => :v2)

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
end),

Test("DCIV test 2 - test DCCurrentSource", function()

    I = 5.
    idc = DCCurrentSource(I)

    ps = PortSyms(idc.pIn => :v1, idc.pOut => :v2)

    @assert dciv(idc, ps, idc.pIn, :I1) == I
    @assert dciv(idc, ps, idc.pOut, :I1) == -I

    @assert dciv_diff(idc, ps, idc.pIn, :v1, :I1) == 0.
    @assert dciv_diff(idc, ps, idc.pIn, :v2, :I1) == 0.
    @assert dciv_diff(idc, ps, idc.pIn, :I1, :I1) == 0.

    @assert dcsatisfy(idc, ps, :I1) == Expr[]

    @assert dcsatisfy_diff(idc, ps, :v1, :I1) == Expr[]
    @assert dcsatisfy_diff(idc, ps, :v2, :I1) == Expr[]
    @assert dcsatisfy_diff(idc, ps, :I1, :I1) == Expr[]
end),

Test("DCIV test 3 - test Resistor", function()

    R = 5e+3
    r = Resistor(R)

    ps = PortSyms(r.p1 => :v1, r.p2 => :v2)

    @assert dciv(r, ps, r.p1, :I1) == :((v1 - v2) / $(R))
    @assert dciv(r, ps, r.p2, :I1) == :((v2 - v1) / $(R))

    @assert dciv_diff(r, ps, r.p1, :v1, :I1) == :(1. / $(R))
    @assert dciv_diff(r, ps, r.p1, :v2, :I1) == :(-1. / $(R))
    @assert dciv_diff(r, ps, r.p2, :v1, :I1) == :(-1. / $(R))
    @assert dciv_diff(r, ps, r.p2, :v2, :I1) == :(1. / $(R))

    @assert dcsatisfy(r, ps, :I1) == Expr[]

    @assert dcsatisfy_diff(r, ps, :v1, :I1) == Expr[]
    @assert dcsatisfy_diff(r, ps, :v2, :I1) == Expr[]
    @assert dcsatisfy_diff(r, ps, :I1, :I1) == Expr[]
end),

Test("DCIV test 4 - test Capacitor", function()
    
    C = 1e-6
    cap = Capacitor(C)

    ps = PortSyms(cap.p1 => :v1, cap.p2 => :v2)

    @assert dciv(cap, ps, cap.p1, :I1) == 0.
    @assert dciv(cap, ps, cap.p2, :I1) == 0.

    @assert dciv_diff(cap, ps, cap.p1, :v1, :I1) == 0.
    @assert dciv_diff(cap, ps, cap.p1, :v2, :I1) == 0.
    @assert dciv_diff(cap, ps, cap.p2, :v1, :I1) == 0.
    @assert dciv_diff(cap, ps, cap.p2, :v2, :I1) == 0.

    @assert dcsatisfy(cap, ps, :I1) == Expr[]
    
    @assert dcsatisfy_diff(cap, ps, :v1, :I1) == Expr[]
    @assert dcsatisfy_diff(cap, ps, :v2, :I1) == Expr[]
    @assert dcsatisfy_diff(cap, ps, :I1, :I1) == Expr[]
end),

Test("DCIV test 5 - test Inductor", function()

    L = 1e-6
    ind = Inductor(L)

    ps = PortSyms(ind.p1 => :v1, ind.p2 => :v2)

    # dummy currents again
    @assert dciv(ind, ps, ind.p1, :I1) == :(1.0 * I1)
    @assert dciv(ind, ps, ind.p2, :I1) == :(-1.0 * I1)
    
    @assert dciv_diff(ind, ps, ind.p1, :v1, :I1) == 0.
    @assert dciv_diff(ind, ps, ind.p1, :v2, :I1) == 0.
    @assert dciv_diff(ind, ps, ind.p1, :I1, :I1) == 1.

    @assert dciv_diff(ind, ps, ind.p2, :v1, :I1) == 0.
    @assert dciv_diff(ind, ps, ind.p2, :v2, :I1) == 0.
    @assert dciv_diff(ind, ps, ind.p2, :I1, :I1) == -1.

    @assert dcsatisfy(ind, ps, :I1) == Expr[]
    
    @assert dcsatisfy_diff(ind, ps, :v1, :I1) == Expr[]
    @assert dcsatisfy_diff(ind, ps, :v2, :I1) == Expr[]
    @assert dcsatisfy_diff(ind, ps, :I1, :I1) == Expr[]
end),

Test("DCIV test 6 - test Diode", function()
    
    # reverse saturation current
    Is = 1e-14

    # thermal voltage at room temperature
    VT = 0.026

    # ideality factor
    n = 1.

    d1 = Diode(Is, VT, n)

    ps = PortSyms(p1(d1) => :v1, p2(d1) => :v2)

    # TODO: some asserts here
end)

])
