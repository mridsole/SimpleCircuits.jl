# each component must specify IV (current-voltage) relations
# for a two port component, we only require one IV relation
# for a three port component, we require two, etc
# NOTE: for perfect voltage sources, clearly we don't have an
# IV relation - so for these, we use the obvious node voltage relation
# and a "dummy" current variable when constructing the linear system.

# note these are DC relations, so for capacitors we have an open circuit
# and for inductors we have a short circuit

# the functions should return an expression for the current through the device
# in terms of the provided symbols

# I'm not really worried about type stability here because these are just used
# for building the function for the system of equations for a given circuit,
# and the corresponding Jacobian matrix function - so it's a bit like a compiler

typealias PortSyms Dict{Port, Union{Symbol, Expr}}

# specify which components use dummy currents
uses_dummy_current(comp::DCVoltageSource) = true
uses_dummy_current(comp::DCCurrentSource) = false
uses_dummy_current(comp::Resistor) = false
uses_dummy_current(comp::Capacitor) = false
uses_dummy_current(comp::Inductor) = true
uses_dummy_current(comp::Diode) = false

# IV relations for a voltage source
# in this case, we don't use most of the interface because all we're returning is the 
# dummy current - but we could also use this to specify an implicit current relation
# (like I = exp(I) or something ...)
function dciv(comp::DCVoltageSource, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)
    
    # return the current symbol, taking into account the direction
    # using the provided in port as a reference
    # (the dummy current always goes from pLow to pHigh)
    sgn = pIn == comp.pLow ? 1. : -1.
    return :($(sgn) * $(currentSym))
end

function dciv_diff(comp::DCVoltageSource, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    # return the (partial) derivative of the directed current with respect to 
    # the given symbol - in this case, current does not depend on the voltages
    if wrt == currentSym
        return pIn == comp.pLow ? 1. : -1.
    else
        return 0.
    end
end

# other equations to satisfy for a DC voltage source (equation is expression = 0)
function dcsatisfy(comp::DCVoltageSource, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)
    return [:($(ps[comp.pHigh]) - $(ps[comp.pLow]) - $(comp.V))]
end

# return the partial derivative of EVERY "other equation" w.r.t the given symbol
function dcsatisfy_diff(comp::DCVoltageSource, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    if wrt == ps[comp.pHigh]
        eqn1_diff = 1.
    elseif wrt == ps[comp.pLow]
        eqn1_diff = -1.
    elseif wrt == currentSym
        eqn1_diff = 0.
    else
        eqn1_diff = 0.
    end
    
    return [eqn1_diff]
end

# DC IV relation for a current source
function dciv(comp::DCCurrentSource, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)

    @assert pIn == comp.pIn || pIn == comp.pOut
    @assert pIn in keys(ps)

    # obviously for a DC current source we know that the current is just a constant
    # only thing that matters is direction
    return pIn == comp.pIn ? comp.I : :(-$(comp.I))
end

function dciv_diff(comp::DCCurrentSource, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr},
    currentSym::Union{Symbol, Expr} = :I)
    
    # .. no dummy current - the current is constant here
    return 0.
end

function dcsatisfy(comp::DCCurrentSource, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)

    # no other equations
    return Expr[]
end

function dcsatisfy_diff(comp::DCCurrentSource, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currenSym::Symbol)

    return Expr[]
end

# DC IV relation for a resistor (V = IR)
function dciv(comp::Resistor, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)
    
    # ensure the port belongs to the component
    @assert pIn == comp.p1 || pIn == comp.p2

    # ensure the port is in the given dictionary
    @assert pIn in keys(ps)

    # return the expression for the currents
    return :(($(ps[pIn]) - $(ps[other_port(pIn)])) / $(comp.R))
end

function dciv_diff(comp::Resistor, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)
    
    # derivative of (v_pIn - v_pOut) / R w.r.t the given port
    if wrt == currentSym
        return 0.
    else
        if wrt == ps[pIn]
            return :(1 / $(comp.R))
        elseif wrt == ps[other_port(pIn)]
            return :(-1 / $(comp.R))
        else
            return 0.
        end
    end
end

# other equations to satisfy for a resistor (none in this case)
function dcsatisfy(comp::Resistor, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)
    return Expr[]
end

# nothing to do here
function dcsatisfy_diff(comp::Resistor, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end

# DC IV relation for a capacitor - treat it as an open circuit (current = 0)
function dciv(comp::Capacitor, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)

    return 0.
end

# (derivative of 0 is 0 ...)
function dciv_diff(comp::Capacitor, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr},
    currentSym::Union{Symbol, Expr} = :I)

    return 0.
end

# no other DC relations for a capacitor
function dcsatisfy(comp::Capacitor, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end

# ...
function dcsatisfy_diff(comp::Capacitor, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)
    
    return Expr[]
end

# DC IV relation for an inductor - treat it as a short circuit (voltage across it = 0)
function dciv(comp::Inductor, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)

    # dummy currents for inductors now go from p1 to p2
    sgn = pIn == comp.p1 ? 1. : -1.
    return :($(sgn) * $(currentSym))
end

function dciv_diff(comp::Inductor, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr},
    currentSym::Union{Symbol, Expr} = :I)

    # very similar to DCVoltageSource
    if wrt == currentSym
        return pIn == comp.p1 ? 1. : -1.
    else
        return 0.
    end
end

# no other DC relations for an inductor
function dcsatisfy(comp::Inductor, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end

# ...
function dcsatisfy_diff(comp::Inductor, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)
    
    return Expr[]
end

# relations for a diode
function dciv(comp::Diode, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)

    v1 = ps[p1(comp)]
    v2 = ps[p2(comp)]
    sgn = pIn == p1(comp) ? 1. : -1.

    expr = :($(sgn) * $(comp.Is) * (exp(($(v1) - $(v2))
        / ($(comp.n) * $(comp.VT))) - 1.))

    return expr
end

function dciv_diff(comp::Diode, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    v1 = ps[p1(comp)]
    v2 = ps[p2(comp)]
    sgn = pIn == p1(comp) ? 1. : -1.
    sgn *= wrt == v1 ? 1. : -1.

    if wrt != v1 && wrt != v2 return 0. end

    expr = :(($(sgn) / ($(comp.n) * $(comp.VT))) * $(comp.Is) * 
        exp(($(v1) - $(v2)) / ($(comp.n) * $(comp.VT))))

    return expr
end

function dcsatisfy(comp::Diode, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end

function dcsatisfy_diff(comp::Diode, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end
