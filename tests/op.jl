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
end)
])
