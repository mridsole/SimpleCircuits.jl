type Test

    name::ASCIIString
    func::Function

    Test(name::ASCIIString, func::Function) = new(name, func)
end

function Base.call(test::Test)

    passed = true
    msg = ""
    try
        test.func()
        msg = "Test '" * test.name * "' passed."
    catch(err)
        msg = "Test '" * test.name * "' failed: \n" *
        string(err) * "\n"
        passed = false
    end

    return passed, msg
end
