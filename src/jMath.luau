--[[
	Cool math functions
]]
--!strict

local Math = {}
--[[
	Regular ol' linear interpolation.
	@param alpha A number between 0 and 1
]]
function Math.lerp(start: number, goal: number, alpha: number): number
	return start + (goal - start) * alpha
end

-- Only use this if TweenService:GetValue() is not practical for whatever reason
function Math.inverseLerp(start: number, goal: number, output: number): number
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
function Math.MinLerp(start: number, goal: number, alpha: number, lastnum: number, min: number): number
	local lerped = Math.lerp(start, goal, alpha)
	return if lerped - lastnum >= min then lerped else goal
end

--[[
	Quadratic bezier.

	Not explaining this, shall Google help y'all 🙏
]]
function Math.QuadraticBezier(alpha: number, p0: Vector3, p1: Vector3, p2: Vector3): Vector3
	return (1 - alpha) ^ 2 * p0 + 2 * (1 - alpha) * alpha * p1 + alpha ^ 2 * p2
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
	return CompressedNum ~= 0 and (1.0000001 ^ CompressedNum) or 0
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
	return diff:Dot(diff) <= Radius ^ 2
end

--[[
	Fast calculation
]]
function Math.GetDistanceSquared(a: Vector3, b: Vector3): number
	local d = a - b
	return d:Dot(d)
end
--[[
	Returns a median of all numbers in a table
	Table indecies must not have gaps
]]
function Math.Median(Numbers: { number }): number?
	local count = #Numbers
	if count == 0 then
		return nil
	end

	local sorted = table.clone(Numbers)
	table.sort(sorted)

	local mid = math.floor(count / 2)
	if count % 2 == 0 then
		return (sorted[mid] + sorted[mid + 1]) / 2
	else
		return sorted[mid + 1]
	end
end

--[[
    @param RA ELO A
    @param RB ELO B
    @param S Score (1 - A wins, 0.5 - Draw, 0 - B wins)
	@param KFactor Max difference
	@param SFactor Scaling factor

	@return newRA newRB - new ELO ratings
]]
function Math.Elo(RA: number, RB: number, S: number, KFactor: number, SFactor: number): (number, number)
	local EA = 1 / (1 + 10 ^ ((RB - RA) / SFactor))
	local EB = 1 - EA
	local SB = 1 - S
	local newRA = math.round(RA + KFactor * (S - EA))
	local newRB = math.round(RB + KFactor * (SB - EB))
	return newRA, newRB
end

--[[
	Catmull-Rom Spline
	@param Points Vector2 or Vector3 table of points to spline
	@param t 0-1 where to sample

	@return Position of the sample
]]
Math.CRSpline = (
	function(Points: { any }, t: number): any?
		local n = #Points

		if n < 2 then
			return nil
		end

		if n == 2 then
			return Points[1]:Lerp(Points[2], t)
		end

		local p0 = Points[math.max(1, math.floor(t))]
		local p1 = Points[math.min(n, math.floor(t) + 1)]
		local p2 = Points[math.min(n, math.floor(t) + 2)]
		local p3 = Points[math.min(n, math.floor(t) + 3)]

		t -= math.floor(t)

		local a = 2 * p1
		local b = p2 - p0
		local c = 2 * p0 - 5 * p1 + 4 * p2 - p3
		local d = -p0 + 3 * p1 - 3 * p2 + p3

		local point = 0.5 * (a + (b * t) + (c * t * t) + (d * t * t * t))

		return point
	end
) :: ((Points: { Vector3 }, t: number) -> Vector3?) & ((Points: { Vector2 }, t: number) -> Vector2?)

return Math
