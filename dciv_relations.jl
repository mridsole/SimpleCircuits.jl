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
uses_dummy_current(comp::DCVoltageSource)   = true
uses_dummy_current(comp::VoltageSource)     = true
uses_dummy_current(comp::DCCurrentSource)   = false
uses_dummy_current(comp::Resistor)          = false
uses_dummy_current(comp::Capacitor)         = false
uses_dummy_current(comp::Inductor)          = true
uses_dummy_current(comp::Diode)             = false
uses_dummy_current(comp::NPN)               = false
uses_dummy_current(comp::PNP)               = false

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
    currenSym::Union{Symbol, Expr})

    return Expr[]
end

# variable voltage sources really shouldn't be used for DC operating point analysis
# and here's why - I'm just treating them as short circuit in this case
function dciv(comp::VoltageSource, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)

    # dummy currents for inductors now go from p1 to p2
    sgn = pIn == p1(comp) ? 1. : -1.
    return :($(sgn) * $(currentSym))
end

function dciv_diff(comp::VoltageSource, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr},
    currentSym::Union{Symbol, Expr} = :I)

    # very similar to DCVoltageSource
    if wrt == currentSym
        return pIn == p1(comp) ? 1. : -1.
    else
        return 0.
    end
end

# the two voltages are the same
function dcsatisfy(comp::VoltageSource, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)

    return Expr[:($(ps[p1(comp)]) - $(ps[p2(comp)]))]
end

# derivatives of that
function dcsatisfy_diff(comp::VoltageSource, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    if wrt == ps[p1(comp)]
        eqn1_diff = 1.
    elseif wrt == ps[p2(comp)]
        eqn1_diff = -1.
    elseif wrt == currentSym
        eqn1_diff = 0.
    else
        eqn1_diff = 0.
    end
    
    return [eqn1_diff]
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

# the two voltages are the same
function dcsatisfy(comp::Inductor, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)

    return Expr[:($(ps[p1(comp)]) - $(ps[p2(comp)]))]
end

# derivatives of that
function dcsatisfy_diff(comp::Inductor, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    if wrt == ps[p1(comp)]
        eqn1_diff = 1.
    elseif wrt == ps[p2(comp)]
        eqn1_diff = -1.
    elseif wrt == currentSym
        eqn1_diff = 0.
    else
        eqn1_diff = 0.
    end
    
    return [eqn1_diff]
end

# relations for a diode
function dciv(comp::Diode, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :I)

    v1 = ps[p1(comp)]
    v2 = ps[p2(comp)]
    sgn = pIn == p1(comp) ? 1. : -1.

    # a hack: define a 'critical voltage' - which, if passed, make the current linear instead
    # and also make the first derivative w.r.t. voltage continuous
    # if we don't do this, we will get NaNs unless we have very good initial conditions
    #expr = :($(sgn) * $(comp.Is) * (exp(($(v1) - $(v2))
    #    / ($(comp.n) * $(comp.VT))) - 1.))

    # this is just a heuristic ...
    v_crit_expr = :(-log10($(comp.Is)) / 10.)
    I_crit_expr = :($(comp.Is) * (exp($(v_crit_expr) / ($(comp.n) * $(comp.VT))) - 1.))

    # I derivative expression at v_crit
    diff_I_crit_expr = :(($(comp.Is)/($(comp.n)*$(comp.VT)))*
        (exp($(v_crit_expr)/($(comp.n)*$(comp.VT)))))

    expr = quote
        I = 0.;
        if $(v1) - $(v2) > $(v_crit_expr)
            I = $(I_crit_expr) + $(diff_I_crit_expr) * ($(v1) - $(v2) - $(v_crit_expr));
        else
            I = $(comp.Is) * (exp(($(v1) - $(v2)) / ($(comp.n) * $(comp.VT))) - 1.);
        end;
        I = $(sgn) * I
        I
    end


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

    # this is just a heuristic ...
    v_crit_expr = :(-log10($(comp.Is)) / 10.)
    I_crit_expr = :($(comp.Is) * (exp($(v_crit_expr) / ($(comp.n) * $(comp.VT))) - 1.))

    # I derivative expression at v_crit
    diff_I_crit_expr = :(($(comp.Is)/($(comp.n)*$(comp.VT)))*
        (exp($(v_crit_expr)/($(comp.n)*$(comp.VT)))))

    expr = quote
        I = 0.;
        if $(v1) - $(v2) > $(v_crit_expr)
            I = $(diff_I_crit_expr);
        else
            # yer true
            I = (1. / ($(comp.n) * $(comp.VT))) * $(comp.Is) * 
                exp(($(v1) - $(v2)) / ($(comp.n) * $(comp.VT)));
        end
        I = $(sgn) * I
    end

    return expr
end

function dcsatisfy(comp::Diode, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end

function dcsatisfy_diff(comp::Diode, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end

# DCIV relations for an NPN bipolar junction transistor
function dciv(comp::NPN, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :_I)
    
    # port map: p1 is C, p2 is B, p3 is E
    vC = ps[p1(comp)]
    vB = ps[p2(comp)]
    vE = ps[p3(comp)]

    αf = :((($(comp.βf) / ($(comp.βf) + 1))))
    αr = :((($(comp.βr) / ($(comp.βr) + 1))))

    # heuristic for stability linearization again - see dciv for diode
    v_crit = :(-log10($(comp.Is))/10.)

    # some more useful building blocks
    expbe = :((exp(($(vB)-$(vE))/$(comp.VT))-1.))
    expbc = :((exp(($(vB)-$(vC))/$(comp.VT))-1.))

    function exp_v(at)
        return :(((exp(($(at))/$(comp.VT))-1.)))
    end

    # we can 'evaulate' this at the critical voltages, for example
    function exp_d(at)
        return :(((1./$(comp.VT))*exp(($(at))/$(comp.VT))))
    end

    # exponential, linearized passed the critical voltage
    function exp_crit(v)
        quote
            val = 0.
            if $(v) > $(v_crit)
                val = $(exp_v(v_crit)) + $(exp_d(v_crit)) * ($(v) - $(v_crit))
            else
                val = $(exp_v(v))
            end
            val
        end
    end

    expr = quote
        if $(vB) - $(vE) > $(v_crit) vBE = $(v_crit) else vBE = $(vB) - $(vE) end
        if $(vB) - $(vC) > $(v_crit) vBC = $(v_crit) else vBC = $(vB) - $(vC) end
    end

    # really hope i don't have to come back to this ...
    exBE = exp_crit(:($(vB) - $(vE)))
    exBC = exp_crit(:($(vB) - $(vC)))

    # use the Ebers-Moll model
    if pIn == p1(comp)      # collector
        expr = :($(comp.Is) * ($(αf) * ($(exBE)) - ($(exBC))))
    elseif pIn == p2(comp)  # base
        expr = :($(comp.Is) * ((1.-$(αf))*($(exBE)) + (1.-$(αr))*($(exBC))))
    elseif pIn == p3(comp)  # emitter
        expr = :(-$(comp.Is) * ($(exBE) - $(αr)*($(exBC))))
    else
        return 0.
    end

    return expr
end

function dciv_diff(comp::NPN, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :_I)
    
    # port map: p1 is C, p2 is B, p3 is E
    vC = ps[p1(comp)]
    vB = ps[p2(comp)]
    vE = ps[p3(comp)]

    αf = :((($(comp.βf) / ($(comp.βf) + 1))))
    αr = :((($(comp.βr) / ($(comp.βr) + 1))))

    function expbe_d(wrt, at)
        if wrt == vC
            return 0.
        elseif wrt == vB
            return :(((1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        elseif wrt == vE
            return :(((-1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        end
        return 0.
    end

    function expbc_d(wrt, at)
        if wrt == vC
            return :(((-1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        elseif wrt == vB
            return :(((1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        elseif wrt == vE
            return 0.
        end
        return 0.
    end
    
    # heuristic for stability linearization again - see dciv for diode
    v_crit = :(-log10($(comp.Is))/10.)
    
    # 9 cases ... really should just use symbolic/automatic differentiation or something
    # Calculus.jl doesn't play nice with diff w.r.t expressions instead of symbols
    # could get around that, but at this point it's less effort just to write the 9 equations
    # (not enough time ..)

    expr = quote
        if $(vB) - $(vE) > $(v_crit) vBE = $(v_crit) else vBE = $(vB) - $(vE) end
        if $(vB) - $(vC) > $(v_crit) vBC = $(v_crit) else vBC = $(vB) - $(vC) end
    end

    if pIn == p1(comp)      # collector
        push!(expr.args, :(($(comp.Is))*(($(αf))*($(expbe_d(wrt, :vBE))) - ($(expbc_d(wrt, :vBC))))))
    elseif pIn == p2(comp)  # base
        push!(expr.args, :(($(comp.Is))*((1-($(αf)))*($(expbe_d(wrt, :vBE))) + 
            (1-($(αr)))*($(expbc_d(wrt, :vBC))))))
    elseif pIn == p3(comp)  # emitter
        push!(expr.args, :(-$(comp.Is)*($(expbe_d(wrt, :vBE)) - $(αr) * $(expbc_d(wrt, :vBC)))))
    end

    # TODO: limit the value in the same way we limited the diode value
    # this will probably be at least as unstable as the diode was!
    return expr
end

function dcsatisfy(comp::NPN, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)
    
    # no extra equations
    return Expr[]
end

function dcsatisfy_diff(comp::NPN, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end

# the PNP equations are similar, but with some signs/voltages flipped - careful!
function dciv(comp::PNP, ps::PortSyms, pIn::Port, currentSym::Union{Symbol, Expr} = :_I)
    
    # port map: p1 is C, p2 is B, p3 is E
    vC = ps[p1(comp)]
    vB = ps[p2(comp)]
    vE = ps[p3(comp)]

    αf = :((($(comp.βf) / ($(comp.βf) + 1))))
    αr = :((($(comp.βr) / ($(comp.βr) + 1))))

    # heuristic for stability linearization again - see dciv for diode
    v_crit = :(-log10($(comp.Is))/10.)

    # some more useful building blocks
    expbe = :((exp(($(vB)-$(vE))/$(comp.VT))-1.))
    expbc = :((exp(($(vB)-$(vC))/$(comp.VT))-1.))

    function exp_v(at)
        return :(((exp(($(at))/$(comp.VT))-1.)))
    end

    # we can 'evaulate' this at the critical voltages, for example
    function exp_d(at)
        return :(((1./$(comp.VT))*exp(($(at))/$(comp.VT))))
    end

    # exponential, linearized passed the critical voltage
    function exp_crit(v)
        quote
            val = 0.
            if $(v) > $(v_crit)
                val = $(exp_v(v_crit)) + $(exp_d(v_crit)) * ($(v) - $(v_crit))
            else
                val = $(exp_v(v))
            end
            val
        end
    end

    expr = quote
        if $(vE) - $(vB) > $(v_crit) vEB = $(v_crit) else vEB = $(vE) - $(vB) end
        if $(vC) - $(vB) > $(v_crit) vCB = $(v_crit) else vCB = $(vC) - $(vB) end
    end

    exEB = exp_crit(:($(vE) - $(vB)))
    exCB = exp_crit(:($(vC) - $(vB)))

    # use the Ebers-Moll model
    if pIn == p1(comp)      # collector
        expr = :(-$(comp.Is) * ($(αf) * ($(exEB)) - ($(exCB))))
    elseif pIn == p2(comp)  # base
        expr = :(-$(comp.Is) * ((1.-$(αf))*($(exEB)) + (1.-$(αr))*($(exCB))))
    elseif pIn == p3(comp)  # emitter
        expr = :($(comp.Is) * ($(exEB) - $(αr)*($(exCB))))
    else
        return 0.
    end

    return expr
end

function dciv_diff(comp::PNP, ps::PortSyms, pIn::Port, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :_I)
    
    # port map: p1 is C, p2 is B, p3 is E (same as NPN)
    vC = ps[p1(comp)]
    vB = ps[p2(comp)]
    vE = ps[p3(comp)]

    αf = :((($(comp.βf) / ($(comp.βf) + 1))))
    αr = :((($(comp.βr) / ($(comp.βr) + 1))))

    function expeb_d(wrt, at)
        if wrt == vC
            return 0.
        elseif wrt == vB
            return :(((-1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        elseif wrt == vE
            return :(((1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        end
        return 0.
    end

    function expcb_d(wrt, at)
        if wrt == vC
            return :(((1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        elseif wrt == vB
            return :(((-1./$(comp.VT))*exp(($(at))/$(comp.VT))))
        elseif wrt == vE
            return 0.
        end
        return 0.
    end
    
    # heuristic for stability linearization again - see dciv for diode
    v_crit = :(-log10($(comp.Is))/10.)
    
    expr = quote
        if $(vE) - $(vB) > $(v_crit) vEB = $(v_crit) else vEB = $(vE) - $(vB) end
        if $(vC) - $(vB) > $(v_crit) vCB = $(v_crit) else vCB = $(vC) - $(vB) end
    end

    if pIn == p1(comp)      # collector
        push!(expr.args, :((-$(comp.Is))*(($(αf))*($(expeb_d(wrt, :vEB))) - ($(expcb_d(wrt, :vCB))))))
    elseif pIn == p2(comp)  # base
        push!(expr.args, :((-$(comp.Is))*((1-($(αf)))*($(expeb_d(wrt, :vEB))) + 
            (1-($(αr)))*($(expcb_d(wrt, :vCB))))))
    elseif pIn == p3(comp)  # emitter
        push!(expr.args, :($(comp.Is)*($(expeb_d(wrt, :vEB)) - $(αr) * $(expcb_d(wrt, :vCB)))))
    end

    # TODO: limit the value in the same way we limited the diode value
    # this will probably be at least as unstable as the diode was!
    return expr
end

function dcsatisfy(comp::PNP, ps::PortSyms, currentSym::Union{Symbol, Expr} = :I)
    
    # no extra equations
    return Expr[]
end

function dcsatisfy_diff(comp::PNP, ps::PortSyms, wrt::Union{Symbol, Expr}, 
    currentSym::Union{Symbol, Expr} = :I)

    return Expr[]
end
