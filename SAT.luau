--!strict
--!native
--!optimize 2

export type Box = {
	pos: Vector2,
	halfSize: Vector2, -- Vector2.new(width / 2, height / 2)
	angle: number,     -- Rotation in radians
}

-- Usage:
-- local mtv = getSATCollision(unitA, unitB)
-- if mtv then
--     unitA.pos -= mtv * 0.5
--     unitB.pos += mtv * 0.5
-- end

local axes = {}

-- Returns the Minimum Translation Vector (MTV) to push Box A out of Box B, or nil if no collision
return function(a: Box, b: Box): Vector2?
	-- 1. Get unit axes for Box A and Box B from their angles
	local cosA, sinA = math.cos(a.angle), math.sin(a.angle)
	local ax, ay = Vector2.new(cosA, sinA), Vector2.new(-sinA, cosA)

	local cosB, sinB = math.cos(b.angle), math.sin(b.angle)
	local bx, by = Vector2.new(cosB, sinB), Vector2.new(-sinB, cosB)

	local t = b.pos - a.pos
	axes[1], axes[2], axes[3], axes[4] = ax, ay, bx, by

	local minOverlap = math.huge
	local bestAxis: Vector2? = nil

	for _, axis in axes do
		local rA = math.abs(a.halfSize.X * ax:Dot(axis)) + math.abs(a.halfSize.Y * ay:Dot(axis))
		local rB = math.abs(b.halfSize.X * bx:Dot(axis)) + math.abs(b.halfSize.Y * by:Dot(axis))

		local distance = math.abs(t:Dot(axis))
		local overlap = (rA + rB) - distance

		-- no intersect
		if overlap <= 0 then
			return nil
		end

		if overlap < minOverlap then
			minOverlap = overlap
			bestAxis = axis
		end
	end

	-- 3. Ensure MTV points away from A toward B
	if t:Dot(bestAxis :: Vector2) < 0 then
		bestAxis = -bestAxis :: Vector2
	end

	return (bestAxis :: Vector2) * minOverlap
end