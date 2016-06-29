print_exprs = true
print_J_exprs = true
print_op = true

op_systems_tests() = Array{Test, 1}([

Test("op system test 1 - gen_sys_exprs circuit1", function()
    
    @circuit1
    
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)
    
    if print_exprs
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

Test("op system test 6 - gen_sys_exprs circuit6", function()

    @circuit6
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)

    if print_exprs
        println("Circuit 6 generated expressions (= 0): ")
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

    if print_J_exprs
        println("Circuit 1 Jacobian expressions: ")
        println("size: " * string(size(exprs)))
        println(exprs)
    end
end),

Test("op system test 12 - gen_J_exprs circuit1", function()
    
    @circuit2
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    if print_J_exprs
        println("Circuit 2 Jacobian expressions: ")
        println("size: " * string(size(exprs)))
        println(exprs)
    end
end),

Test("op system test 13 - gen_J_exprs circuit1", function()
    
    @circuit3
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    if print_J_exprs
        println("Circuit 3 Jacobian expressions: ")
        println("size: " * string(size(exprs)))
        println(exprs)
    end
end),

Test("op system test 14 - gen_J_exprs circuit1", function()
    
    @circuit4
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    if print_J_exprs
        println("Circuit 4 Jacobian expressions: ")
        println("size: " * string(size(exprs)))
        println(exprs)
    end
end),

Test("op system test 15 - gen_J_exprs circuit1", function()
    
    @circuit5
    sym_map = gen_sym_map(circ)
    exprs = gen_J_exprs(sym_map, circ)

    if print_J_exprs
        println("Circuit 5 Jacobian expressions: ")
        println("size: " * string(size(exprs)))
        println(exprs)
    end
end),

Test("op system test 16 - gen_sys_J circuit1", function()

    @circuit1
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c1_F, sym_map, circ)
    gen_sys_J(:c1_J, sym_map, circ)

    F = SimpleCircuits.Generated.c1_F
    J = SimpleCircuits.Generated.c1_J

    x0 = zeros(length(sym_map))
    
    println("Circuit 1 operating point: ")
    println(newton(F, J, x0))
end),

Test("op system test 17 - gen_sys_J circuit2", function()

    @circuit2
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c1_F, sym_map, circ)
    gen_sys_J(:c1_J, sym_map, circ)

    F = SimpleCircuits.Generated.c1_F
    J = SimpleCircuits.Generated.c1_J
    
    x0 = zeros(length(sym_map))

    if print_op
        println("Circuit 2 symbol map: ")
        println(sym_map)
        println("Circuit 2 operating point: ")
        println(J(zeros(6), zeros(6, 6)))
        println(newton(F, J, x0))
    end
end),

Test("op system test 18 - gen_sys_J circuit3", function()

    @circuit3
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c1_F, sym_map, circ)
    gen_sys_J(:c1_J, sym_map, circ)

    F = SimpleCircuits.Generated.c1_F
    J = SimpleCircuits.Generated.c1_J
    
    x0 = zeros(length(sym_map))

    if print_op
        println("Circuit 3 operating point: ")
        println(newton(F, J, x0))
    end
end),

Test("op system test 19 - gen_sys_J circuit4", function()

    @circuit4
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c1_F, sym_map, circ)
    gen_sys_J(:c1_J, sym_map, circ)

    F = SimpleCircuits.Generated.c1_F
    J = SimpleCircuits.Generated.c1_J

    x0 = zeros(length(sym_map))
    
    if print_op
        println("Circuit 4 operating point: ")
        println(newton(F, J, x0))
    end
end),

Test("op system test 20 - gen_sys_J circuit5", function()

    @circuit5
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c1_F, sym_map, circ)
    gen_sys_J(:c1_J, sym_map, circ)

    F = SimpleCircuits.Generated.c1_F
    J = SimpleCircuits.Generated.c1_J

    x0 = zeros(length(sym_map))
    
    if print_op
        println("Circuit 5 operating point: ")
        println(newton(F, J, x0))
    end
end),

Test("op system test 22 - gen_sys_J circuit6", function()

    @circuit6
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c1_F, sym_map, circ)
    gen_sys_J(:c1_J, sym_map, circ)

    F = SimpleCircuits.Generated.c1_F
    J = SimpleCircuits.Generated.c1_J

    x0 = zeros(length(sym_map))
    
    if print_op
        println("Circuit 6 operating point: ")
        println(newton(F, J, x0))
    end
end),

Test("op system test 23 - gen_sys_J circuit7", function()

    @circuit7
    
    sym_map = gen_sym_map(circ)

    # (this should already exist)
    gen_sys_F(:c7_F, sym_map, circ)
    gen_sys_J(:c7_J, sym_map, circ)

    F = SimpleCircuits.Generated.c7_F
    J = SimpleCircuits.Generated.c7_J

    x0 = zeros(length(sym_map))
    
    if print_op
        println("Circuit 7 operating point: ")
        println(newton(F, J, x0))
    end
end)

])
