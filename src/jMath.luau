--!strict

local Math = {}

function Math.lerp(start:number, goal:number, alpha:number) : number
	return start + (goal - start) * alpha
end

function Math.MinLerp(start:number, goal:number, alpha:number, lastnum:number, min:number) : number
	local result = start + (goal - start) * alpha
	return if result - lastnum >= min then result else goal
end

function Math.QuadraticBezier(alpha:number, p0:Vector3, p1:Vector3, p2:Vector3) : Vector3
	return (1 - alpha)^2 * p0 + 2 * (1 - alpha) * alpha * p1 + alpha^2 * p2
end
--[[
	use .Compress and .Decompress to bypass integer limits on ordered datastores or similar
	WARNING: Loss of precision
]]
function Math.Compress(num: number)
	return num ~= 0 and math.floor(math.log(num) / math.log(1.0000001)) or 0
end

--[[
	use .Compress and .Decompress to bypass integer limits on ordered datastores or similar
	WARNING: Loss of precision
]]
function Math.Decompress(num: number)
	return num ~= 0 and (1.0000001^num) or 0
end

return Math