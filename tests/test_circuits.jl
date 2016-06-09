# c-style unhygenic macros for constructing test circuits

macro circuit1()

    expr = quote
        circ = Circuit()
        r1 = Resistor(5e+3)
        r2 = Resistor(10e+3)
        v_DC = DCVoltageSource(5.)
        connect!(circ, v_DC.pHigh, r1.p1)
        connect!(circ, r1.p2, r2.p1)
        connect!(circ, r2.p2, v_DC.pLow)
        connect!(circ, circ.gnd, v_DC.pLow)
    end
    
    return esc(expr)
end

macro circuit2()

    expr = quote
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
        connect!(circ, r1.p2, v_DC_2.pHigh)
        connect!(circ, circ.gnd, v_DC_1.pLow)
    end
    
    return esc(expr)
end

