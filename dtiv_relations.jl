# contains time derivatives of IV relations 
# two different functions here: one returns the symbol 

# these are in some way a generalization of dciv relations

# and for most components, they will be exactly the same as the dciv relations
function dtiv(comp::Component, ps::PortSyms, dtps::PortSyms, pIn::Port, 
    currentSym = :I, dtcurrentSym = :I_)

    return dciv(comp, ps, pIn, currentSym)
end

# we need to generalize all four functions
function dtiv_diff(comp::Component, ps::PortSyms, dtps::PortSyms, pIn::Port, wrt, 
    currentSym = :I, dtcurrentSym = :I_)

    return dciv_diff(comp, ps, pIn, wrt, currentSym)
end

function dtsatisfy(comp::Component, ps::PortSyms, dtps::PortSyms, currentSym = :I)

    return dcsatisfy(comp, ps, currentSym)
end

function dtsatisfy_diff(comp::Component, ps::PortSyms, dtps::PortSyms, wrt, currentSym = :I)

    return dcsatisfy_diff(comp, ps, wrt, currentSym)
end

# but for some components - capacitors, inductors, and variable voltage 
# and current sources, there will be differences
function dtiv(comp::Capacitor, ps::PortSyms, dtps::PortSyms, pIn::Port, 
    currentSym = :I, dtcurrentSym = :I_)

    return :($(comp.C) * ($(dtps[pIn]) - $(dtps[other_port(pIn)])))
end

function dtiv_diff(comp::Capacitor, ps::PortSyms, dtps::PortSyms, pIn::Port, wrt, 
    currentSym = :I, dtcurrentSym = :I_)
    
    # confusing ... what if wrt == ps[p1(comp)] ? => is (d/dx) (dx/dt) = 0? yes! (by linearity)
    if !(wrt == dtps[p1(comp)] || wrt == dtps[p2(comp)]) return 0. end

    sgn = pIn == p1(comp) ? 1. : -1.
    sgn *= wrt == dtps[p1(comp)] ? 1. : -1.

    # functionally, this is just zero
    return :($(sgn) * $(comp.C))
end

function dtsatisfy(comp::Capacitor, ps::PortSyms, dtps::PortSyms, currentSym = :I)
    
    # nothing to do here
    return Expr[]
end

function dtsatisfy_diff(comp::Capacitor, ps::PortSyms, dtps::PortSyms, wrt, currentSym = :I)

    return Expr[]
end

# TODO: implement inductor relations if time allows

# for a variable voltage source:
function dtiv(comp::VoltageSource, ps::PortSyms, dtps::PortSyms, pIn::Port, 
    currentSym = :I, dtcurrentSym = :I_)
    
    sgn = pIn == comp.pLow ? 1. : -1.
    return :($(sgn) * $(currentSym))
end

function dtiv_diff(comp::VoltageSource, ps::PortSyms, dtps::PortSyms, pIn::Port, wrt, 
    currentSym = :I, dtcurrentSym = :I_)

    if wrt == currentSym
        return pIn == comp.pLow ? 1. : -1.
    else
        return 0.
    end
end

function dtsatisfy(comp::VoltageSource, ps::PortSyms, dtps::PortSyms, 
    currentSym = :I, dtcurrentSym = :I_)
    
    return [:($(ps[p2(comp)]) - $(ps[p1(comp)]) - $(comp.V))]
end

function dtsatisfy_diff(comp::VoltageSource, ps::PortSyms, dtps::PortSyms, 
    wrt, currentSym = :I)
    
    if wrt == ps[p2(comp)]
        return 1.
    elseif wrt == ps[p1(comp)]
        return -1.
    else
        return 0.
    end
end
