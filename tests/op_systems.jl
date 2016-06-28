using SimpleCircuits

print_exprs = false

op_systems_tests() = Array{Test, 1}([

Test("op system test 1 - gen_sys_exprs circuit1", function()
    
    @circuit1
    
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)
    
    if true
        println("Circuit 1 symbol map: ")
        println(sym_map)
        println("Circuit 1 generated expressions (= 0): ")
        for expr in exprs println(expr) end
    end
end), 

Test("op system test 2 - gen_sys_exprs circuit2", function()
    
    @circuit2
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)

    if print_exprs
        println("Circuit 2 generated expressions (= 0): ")
        for expr in exprs println(expr) end
    end
end), 

Test("op system test 3 - gen_sys_exprs circuit3", function()
    
    @circuit3
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)


    if print_exprs
        println("Circuit 3 generated expressions (= 0): ")
        for expr in exprs println(expr) end
    end
end),

Test("op system test 4 - gen_sys_exprs circuit4", function()

    @circuit4
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)

    if print_exprs
        println("Circuit 4 generated expressions (= 0): ")
        for expr in exprs println(expr) end
    end
end),

Test("op system test 5 - gen_sys_exprs circuit5", function()

    @circuit5
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)

    if print_exprs
        println("Circuit 5 generated expressions (= 0): ")
        for expr in exprs println(expr) end
    end
end),

Test("op system test 6 - gen_sys_F circuit1", function()
    
    @circuit1
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c1_F, sym_map, circ)
end),

Test("op system test 7 - gen_sys_F circuit2", function()
    
    @circuit2
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c2_F, sym_map, circ)
end),

Test("op system test 8 - gen_sys_F circuit3", function()
    
    @circuit3
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c3_F, sym_map, circ)
end),

Test("op system test 9 - gen_sys_F circuit4", function()
    
    @circuit4
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c4_F, sym_map, circ)
end),

Test("op system test 10 - gen_sys_F circuit5", function()
    
    @circuit5
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c5_F, sym_map, circ)
end),

Test("op system test 11 - gen_J_exprs circuit1", function()
    
    @circuit1
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    println("size: " * string(size(exprs)))
    println(exprs)
    #for expr in exprs println(expr) end
end),

Test("op system test 12 - gen_J_exprs circuit1", function()
    
    @circuit2
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    # println("size: " * string(size(exprs)))
    # for expr in exprs println(expr) end
end),

Test("op system test 13 - gen_J_exprs circuit1", function()
    
    @circuit3
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    # println("size: " * string(size(exprs)))
    # for expr in exprs println(expr) end
end),

Test("op system test 14 - gen_J_exprs circuit1", function()
    
    @circuit4
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    # println("size: " * string(size(exprs)))
    # for expr in exprs println(expr) end
end),

Test("op system test 15 - gen_J_exprs circuit1", function()
    
    @circuit5
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    # degenerate system! (floating ports) - need to put in no current condition
    #println("size: " * string(size(exprs)))
    #for expr in exprs println(expr) end
end),

Test("op system test 16 - gen_sys_J circuit1", function()

    @circuit1
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c1_F, sym_map, circ)
    gen_sys_J(:c1_J, sym_map, circ)

    F = SimpleCircuits.Generated.c1_F
    J = SimpleCircuits.Generated.c1_J

    x0 = zeros(4)
    Jx = zeros(4, 4)
    
    # EVENING BOYS
    println(newton(F, J, x0))
end)

])
