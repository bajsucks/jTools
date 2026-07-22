--!strict
--!native
--!optimize 2

export type SpatialHash = {
	cellSize: number,
	invCellSize: number,
	maxEntities: number,
	hashCapacity: number,
	queryStamp: number,
	hashStamps: buffer,
	cellHeads: buffer,
	nextEntity: buffer,
	entityPos: buffer,
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
	local entityCount = maxEntities + 1
	local hashBufferSize = hashCapacity * 4

	return setmetatable({
		cellSize = cellSize,
		invCellSize = 1 / cellSize,
		maxEntities = maxEntities,
		hashCapacity = hashCapacity,
		queryStamp = 0,
		hashStamps = buffer.create(hashBufferSize),
		cellHeads = buffer.create(hashBufferSize),
		nextEntity = buffer.create(entityCount * 4),
		entityPos = buffer.create(entityCount * 8),
	}, SpatialHash) :: any
end

function SpatialHash:clear()
	buffer.fill(self.cellHeads, 0, 0, (self.hashCapacity :: number) * 4)
end

function SpatialHash:insert(entity: number, x: number, z: number)
	local invCellSize: number = self.invCellSize
	local cx = math.floor(x * invCellSize)
	local cz = math.floor(z * invCellSize)

	local hashOffset = bit32.band(bit32.bxor(cx * 73856093, cz * 19349663), (self.hashCapacity :: number) - 1) * 4
	local posOffset = entity * 8

	buffer.writef32(self.entityPos, posOffset, x)
	buffer.writef32(self.entityPos, posOffset + 4, z)

	local head = buffer.readu32(self.cellHeads, hashOffset)
	buffer.writeu32(self.nextEntity, entity * 4, head)
	buffer.writeu32(self.cellHeads, hashOffset, entity)
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

	local qStamp = (self.queryStamp :: number) + 1
	if qStamp >= 0xFFFFFFFF then
		buffer.fill(self.hashStamps, 0, 0, (self.hashCapacity :: number) * 4)
		qStamp = 1
	end
	self.queryStamp = qStamp

	local hStamps = self.hashStamps
	local heads = self.cellHeads
	local nextE = self.nextEntity
	local ePos = self.entityPos
	local bitMask = (self.hashCapacity :: number) - 1

    -- crazy switch because luau native doesn't do loop unswitching
	if outSqrDistances then
		for cx = minCx, maxCx do
			local hashX = cx * 73856093
			for cz = minCz, maxCz do
				local hashZ = cz * 19349663
				local hashOffset = bit32.band(bit32.bxor(hashX, hashZ), bitMask) * 4

				if buffer.readu32(hStamps, hashOffset) ~= qStamp then
					buffer.writeu32(hStamps, hashOffset, qStamp)
					local curr = buffer.readu32(heads, hashOffset)

					while curr ~= 0 do
						local posOffset = curr * 8
						local dx = buffer.readf32(ePos, posOffset) - x
						local dz = buffer.readf32(ePos, posOffset + 4) - z
						local distSqr = dx * dx + dz * dz

						if distSqr <= radSqr then
							hitCount += 1
							outBuffer[hitCount] = curr
							outSqrDistances[hitCount] = distSqr
						end

						curr = buffer.readu32(nextE, curr * 4)
					end
				end
			end
		end
	else
		for cx = minCx, maxCx do
			local hashX = cx * 73856093
			for cz = minCz, maxCz do
				local hashZ = cz * 19349663
				local hashOffset = bit32.band(bit32.bxor(hashX, hashZ), bitMask) * 4

				if buffer.readu32(hStamps, hashOffset) ~= qStamp then
					buffer.writeu32(hStamps, hashOffset, qStamp)
					local curr = buffer.readu32(heads, hashOffset)

					while curr ~= 0 do
						local posOffset = curr * 8
						local dx = buffer.readf32(ePos, posOffset) - x
						local dz = buffer.readf32(ePos, posOffset + 4) - z
						local distSqr = dx * dx + dz * dz

						if distSqr <= radSqr then
							hitCount += 1
							outBuffer[hitCount] = curr
						end

						curr = buffer.readu32(nextE, curr * 4)
					end
				end
			end
		end
	end

	return hitCount
end

return SpatialHash