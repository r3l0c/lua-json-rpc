local remote_procedures = {
    try1 = function(args)
        print("The 'try1()' function was called")
        return true, 42,43,"another ret value"
    end,

    try2 = function(args)
        print("The 'try2()' function was called, with the following args:")
        for k,v in pairs(args) do print(k,v) end
        return true, "success"
    end,

}

return remote_procedures
