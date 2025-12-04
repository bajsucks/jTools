--[[
    Utilities for working with grid-based systems

    Experimental but should work good
]]
local GridUtil = {}

local Grid = {}
Grid.__index = Grid

--[[
    Creates a new grid.
]]
function GridUtil.new(root:CFrame, cellSize:Vector3, gridSize:Vector3)
    local self = {}
    self.root = root
    self.cellSize = cellSize
    self.gridSize = gridSize

    setmetatable(self, Grid)

    return self
end

--[[
    Transforms a vector3 from world to grid space, also flooring the result afterwards
]]
function Grid.ToGS(self:Grid, vec:Vector3): GridSpace
    local relative = self.root:PointToObjectSpace(vec)
    return Vector3.new(
        relative.X // self.cellSize.X,
        relative.Y // self.cellSize.Y,
        relative.Z // self.cellSize.Z
    )
end
--[[
    Transforms a vector3 from world to grid space without flooring the result  
]]
function Grid.ToGS_frac(self:Grid, vec:Vector3): GridSpace
    local relative = self.root:PointToObjectSpace(vec)
    return Vector3.new(
        relative.X / self.cellSize.X,
        relative.Y / self.cellSize.Y,
        relative.Z / self.cellSize.Z
    )
end
--[[
    Transforms a vector3 from grid to world space
]]
function Grid.FromGS(self:Grid, vec:GridSpace): Vector3
    local relative = Vector3.new(
        vec.X * self.cellSize.X,
        vec.Y * self.cellSize.Y,
        vec.Z * self.cellSize.Z
    )
    return self.root:PointToWorldSpace(relative)
end
--[[
    Checks if given cell coordinates are out of bounds.
]]
function Grid.IsOOB(self:Grid, vec:GridSpace)
    if vec.X < 0 or vec.Y < 0 or vec.Z < 0 then
        return true
    end
    if vec.X >= self.gridSize.X or vec.Y >= self.gridSize.Y or vec.Z >= self.gridSize.Z then
        return true
    end
    return false
end

export type GridSpace = Vector3
export type Grid = typeof(GridUtil.new())

return GridUtil