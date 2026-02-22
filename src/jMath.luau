--[[
	Cool math functions
]]
--!strict

local Math = {}
--[[
	Regular ol' linear interpolation.
	@param alpha A number between 0 and 1
]]
function Math.lerp(start:number, goal:number, alpha:number): number
	return start + (goal - start) * alpha
end

-- Only use this if TweenService:GetValue() is not practical for whatever reason
function Math.inverseLerp(start:number, goal:number, output:number): number
    local delta = goal - start
    if delta == 0 then
        return 0
    end
    return (output - start) / delta
end

--[[
	Lerp, but it will snap to goal once it's change is lower than min.
	@param lastnum Previous value used by MinLerp. Used in calculation of change
	@param min Minimum value. If change is lower than min, it will snap to goal.
]]
function Math.MinLerp(start:number, goal:number, alpha:number, lastnum:number, min:number): number
	local lerped = Math.lerp(start, goal, alpha)
	return if lerped - lastnum >= min then lerped else goal
end

--[[
	Quadratic bezier.

	Not explaining this, shall Google help y'all 🙏
]]
function Math.QuadraticBezier(alpha:number, p0:Vector3, p1:Vector3, p2:Vector3): Vector3
	return (1 - alpha)^2 * p0 + 2 * (1 - alpha) * alpha * p1 + alpha^2 * p2
end
--[[
	use .Compress and .Decompress to bypass integer limits on ordered datastores or similar

	WARNING: Loss of precision
	@param num number to compress
]]
function Math.Compress(num: number): number
	return num ~= 0 and math.floor(math.log(num) / math.log(1.0000001)) or 0
end

--[[
	use .Compress and .Decompress to bypass integer limits on ordered datastores or similar

	WARNING: Loss of precision
	@param CompressedNum number to decompress
]]
function Math.Decompress(CompressedNum: number): number
	return CompressedNum ~= 0 and (1.0000001^CompressedNum) or 0
end

--[[
	Floors the number to to a nearest X.
	Example: (44, 5) will return 40
]]
function Math.FloorToNearest(ToRound: number, ToNearest: number)
	return ToNearest * math.floor(ToRound / ToNearest)
end

--[[
	Fast calculation
]]
function Math.IsWithinRadius(a: Vector3, b: Vector3, Radius: number): boolean
    local diff = a - b
    return diff:Dot(diff) <= Radius^2
end

--[[
	Fast calculation
]]
function Math.GetDistanceSquared(a: Vector3, b: Vector3): number
    local d = a - b
    return d:Dot(d)
end

return Math