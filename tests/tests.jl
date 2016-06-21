
# submodule included in SimpleCircuits module - don't import this
module Tests

using SimpleCircuits

# circuit construction fixture macros
include("test_circuits.jl")

# utility for testing
# TODO: turns out Base has some similar features, look into those
include("test_type.jl")

# connection tests
include("connections.jl")

# operating point tests
include("op.jl")

tests = []

append!(tests, connection_tests())
append!(tests, op_tests())

function run_all_tests()

    println("Running all tests ...\n")
    
    for test in tests
        passed, msg = test()
        color = passed ? :green : :red
        print_with_color(color, msg * "\n")
    end
end

export run_all_tests

end     # module Tests
