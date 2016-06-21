# tests for op.jl - testing operating point stuff
using SimpleCircuits

# array of test functions - call me for the array
op_tests() = Array{Test, 1}([

Test("operating point test 1", function()
    
    @circuit1

    # do the analysis
    op(circ)

    # TODO: ensure the values are correct

end),

# example of a circuit that currently breaks the solver
# (results in a singular matrix A)
# not anymore!
Test("operating point test 2", function()

    # testing a more complicated circuit
    @circuit2
    op(circ)
end),

# TODO: add numeric assertions in the following tests to ensure validity
Test("operating point test 3", function()

    @circuit3
    op(circ)
end),

Test("operating point test 4", function()

    @circuit4
    op(circ)
end),

Test("operating point test 5", function()

    @circuit5
    op(circ) |> println
end),
])
