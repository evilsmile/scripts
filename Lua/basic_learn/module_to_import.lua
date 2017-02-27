
module={}
module.const="This is a const"

function module.func1()
    io.write("This is a public function\n")
end

local function func2()
    print("This is a private function")
end

function module.func3()
    func2()
end

return module
