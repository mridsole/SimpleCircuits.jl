using SimpleCircuits

print_exprs = false

op_systems_tests() = Array{Test, 1}([

Test("op system test 1 - gen_sys_exprs circuit1", function()
    
    @circuit1
    
    sym_map = gen_sym_map(circ)
    exprs = gen_sys_exprs(sym_map, circ)
    
    if print_exprs
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
    gen_sys_F(:c1_F, sym_map, circ)
end),

Test("op system test 8 - gen_sys_F circuit3", function()
    
    @circuit3
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c1_F, sym_map, circ)
end),

Test("op system test 9 - gen_sys_F circuit4", function()
    
    @circuit4
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c1_F, sym_map, circ)
end),

Test("op system test 10 - gen_sys_F circuit5", function()
    
    @circuit5
    sym_map = gen_sym_map(circ)
    gen_sys_F(:c1_F, sym_map, circ)
end)

])
