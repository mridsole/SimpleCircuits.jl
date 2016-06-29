using SimpleCircuits

print_exprs = true
print_J_exprs = true
print_op = true

op_symbols_tests() = Array{Test, 1}([

Test("op symbols test 1 - circuit1 voltage symbol exprs", function()
    
    # change the voltage source value to a parameter (symbol)
    @circuit1

    # introduce the parameter :V
    v_DC.V = Parameter(:V)

    # try generating the system expressions
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)
    
    println("Circuit 1 system expressions (with V symbol):")
    println(exprs)

    # generate jacobian expressions
    J_exprs = gen_J_exprs(sym_map, circ)
    
    println("Circuti 1 jacobian expressions (with V symbol):")
    println(J_exprs)
end)

])
