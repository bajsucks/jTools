--[[
    Breadcrumb buffer implementation, useful for train-like behavior
]]
local module = {}
local Crumbs = {}
Crumbs.__index = Crumbs

export type CrumbEntry = {CFrame|number} -- {pos, dist}

export type Crumbs = typeof(module.new())

function module.new(Segments: number, DistancePerSegment: number, InitialCFrame: CFrame)
    if Segments < 2 then
		error("A crumbs object has to have at least 2 segments!")
	end
	local self = setmetatable({}, Crumbs)
	
	self.Segments = Segments
	self.Distance = DistancePerSegment
	self.TotalDistance = 0
	self.Breadcrumbs = { {cf = InitialCFrame, dist = 0} }
	
	return self
end

--[[
    Update the head CFrame and manage history cleanup
]]
function Crumbs.Record(self: Crumbs, CF: CFrame)
	local lastCrumb = self.Breadcrumbs[#self.Breadcrumbs]
	local moveStep = (CF.Position - lastCrumb[1].Position).Magnitude

    self.TotalDistance += moveStep
    table.insert(self.Breadcrumbs, {CF, self.TotalDistance})

    local maxDistance = self.TotalDistance - (self.Segments * self.Distance)
    
    -- Keep at least 2 crumbs to allow for interpolation logic
    while #self.Breadcrumbs > 2 and self.Breadcrumbs[2][2] < maxDistance do
        table.remove(self.Breadcrumbs, 1)
    end
end

--[[
    Returns a table of all segment CFrames
]]
function Crumbs.Get(self: Crumbs): {CFrame}
	local segmentCFs = {}
	local crumbs = self.Breadcrumbs
	local crumbCount = #crumbs
	
	local currentCrumbIdx = crumbCount

	for i = 1, self.Segments do
		local targetDist = self.TotalDistance - (i * self.Distance)
		local found = false

		-- Search backwards through crumbs to find the interval containing targetDist
		for j = currentCrumbIdx, 2, -1 do
			local p1 = crumbs[j]
			local p2 = crumbs[j-1]

			if p1[2] >= targetDist and p2[2] <= targetDist then
				local alpha = (targetDist - p2[2]) / (p1[2] - p2[2])
				segmentCFs[i] = p2[1]:Lerp(p1[1], alpha)
				currentCrumbIdx = j -- Save index to optimize next segment search
				found = true
				break
			end
		end
		
		-- Fallback
		if not found then
			segmentCFs[i] = crumbs[1][1]
		end
	end

	return segmentCFs
end

return module