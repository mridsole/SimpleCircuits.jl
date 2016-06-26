using SimpleCircuits


op_systems_tests() = Array{Test, 1}([

Test("op system test 1 - gen_sys_exprs circuit1", function()
    
    @circuit1
    
    exprs = gen_sys_exprs(circ)# |> println

    for expr in exprs println(expr) end
end), 

Test("op system test 2 - gen_sys_exprs circuit2", function()
    
    @circuit2
    gen_sys_exprs(circ)
end), 

Test("op system test 3 - gen_sys_exprs circuit3", function()
    
    @circuit3
    gen_sys_exprs(circ)
end),

Test("op system test 4 - gen_sys_exprs circuit4", function()

    @circuit4
    gen_sys_exprs(circ)
end),

Test("op system test 5 - gen_sys_exprs circuit5", function()

    @circuit5
    gen_sys_exprs(circ)
end)

])
