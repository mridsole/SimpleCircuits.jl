begin
workspace()
include("../SimpleCircuits.jl")
using SimpleCircuits
using PyPlot
circ = Circuit()
r1 = Resistor(50.)
d1 = Diode(1e-11, 0.026, 1.)
v_DC = DCVoltageSource(5.)
connect!(circ, r1.p1, v_DC.pHigh)
connect!(circ, r1.p2, p1(d1))
connect!(circ, p2(d1), v_DC.pLow)
connect!(circ, v_DC.pLow, circ.gnd)

#op(circ)

# turn the diode current expression into a function
ps = PortSyms(p1(d1) => :v1, p2(d1) => :v2)
dciv_expr = dciv(d1, ps, p1(d1), :I_)
dciv_diff_expr = dciv_diff(d1, ps, p1(d1), :v1, :I_)

eval(quote
    function fi(v)
        v1 = v
        v2 = 0.
        $(dciv_expr)
    end
end)

eval(quote
    function fid(v)
        v1 = v
        v2 = 0.
        $(dciv_diff_expr)
    end
end)

end
