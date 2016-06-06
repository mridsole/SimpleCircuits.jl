# runs all tests

workspace()
include("../SimpleCircuits.jl")
using SimpleCircuits

# connection tests
include("connections.jl")

tests = []

append!(tests, connection_tests)

function run_all_tests()

    println("Running all tests ...\n")
    
    for test in tests
        passed, msg = test()
        println(msg)
#        try 
#            test.func() 
#            println(test.name * " passed")
#        catch(err)
#            println(test.name * " failed: ")
#            println(string(err))
#            println("")
#        end
    end
end
