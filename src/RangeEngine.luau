--!native
--!optimize 2
--[[
    RangeEngine
    Get entities that are in the range of another entity fast and cheap
]]

export type SpatialHash = {
	cellSize: number,
	invCellSize: number,
	maxEntities: number,
	hashCapacity: number,
	queryStamp: number,
	hashStamps: { number },
	cellHeads: { number? },
	nextEntity: { number? },
	entityX: { number },
	entityZ: { number },
	clear: (self: SpatialHash) -> (),
	insert: (self: SpatialHash, entity: number, x: number, z: number) -> (),
	queryRadius: (
		self: SpatialHash,
		x: number,
		z: number,
		radius: number,
		outBuffer: { number },
		outSqrDistances: { number }?,
		accumulate: boolean?
	) -> number,
}

local SpatialHash = {}
SpatialHash.__index = SpatialHash

local function nextPowerOf2(n: number): number
	local p = 1
	while p < n do
		p *= 2
	end
	return p
end

function SpatialHash.new(cellSize: number, maxEntities: number): SpatialHash
	local hashCapacity = math.max(8192, nextPowerOf2(maxEntities))
	return setmetatable({
		cellSize = cellSize,
		invCellSize = 1 / cellSize,
		maxEntities = maxEntities,
		hashCapacity = hashCapacity,
		queryStamp = 0,
		hashStamps = table.create(hashCapacity, 0) :: { number },
		cellHeads = table.create(hashCapacity) :: { number? },
		nextEntity = table.create(maxEntities) :: { number? },
		entityX = table.create(maxEntities, 0) :: { number },
		entityZ = table.create(maxEntities, 0) :: { number },
	}, SpatialHash) :: any
end

function SpatialHash:clear()
	table.clear(self.cellHeads)
end

function SpatialHash:insert(entity: number, x: number, z: number)
	local invCellSize: number = self.invCellSize
	local hashCapacity: number = self.hashCapacity
	local cx = math.floor(x * invCellSize)
	local cz = math.floor(z * invCellSize)

	local hash = bit32.band(bit32.bxor(cx * 73856093, cz * 19349663), hashCapacity - 1) + 1

	self.entityX[entity] = x
	self.entityZ[entity] = z
	self.nextEntity[entity] = self.cellHeads[hash]
	self.cellHeads[hash] = entity
end

function SpatialHash:queryRadius(
	x: number,
	z: number,
	radius: number,
	outBuffer: { number },
	outSqrDistances: { number }?,
	accumulate: boolean?
): number
	if not accumulate then
		table.clear(outBuffer)
		if outSqrDistances then
			table.clear(outSqrDistances)
		end
	end

	local hitCount = if accumulate then #outBuffer else 0
	local radSqr = radius * radius
	local invCellSize: number = self.invCellSize

	local minCx = math.floor((x - radius) * invCellSize)
	local maxCx = math.floor((x + radius) * invCellSize)
	local minCz = math.floor((z - radius) * invCellSize)
	local maxCz = math.floor((z + radius) * invCellSize)

	local qStamp = self.queryStamp + 1
	self.queryStamp = qStamp

	local hStamps = self.hashStamps
	local heads = self.cellHeads
	local nextE = self.nextEntity
	local eX: { number } = self.entityX
	local eZ: { number } = self.entityZ
	local hashCapacity: number = self.hashCapacity
	local bitMask = hashCapacity - 1

	for cx = minCx, maxCx do
		local hashX = cx * 73856093
		for cz = minCz, maxCz do
			local hash = bit32.band(bit32.bxor(hashX, cz * 19349663), bitMask) + 1

			if hStamps[hash] ~= qStamp then
				hStamps[hash] = qStamp
				local curr = heads[hash]

				while curr do
					local dx = eX[curr] - x
					local dz = eZ[curr] - z
					local distSqr = dx * dx + dz * dz

					if distSqr <= radSqr then
						hitCount += 1
						outBuffer[hitCount] = curr
						if outSqrDistances then
							outSqrDistances[hitCount] = distSqr
						end
					end

					curr = nextE[curr]
				end
			end
		end
	end

	return hitCount
end

return SpatialHash
