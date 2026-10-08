--!strict

local Runtime = {}
function Runtime.start()
	require(script.Parent.Parent.Parent.TycoonRuntime).start({ walkOn = true })
	print("EXP02 Factory purchases ready: one server-validated attempt per pad visit.")
end
return Runtime
