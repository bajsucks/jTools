local CollectionService = game:GetService("CollectionService")
local Collect = {}

-- returns all descendants that have specified tag
function Collect.GetTaggedDescendants(inst:Instance, tag:string): {Instance?}
	local desc = {}
	local tagged = CollectionService:GetTagged(tag)
	for _, v in tagged do
		if v:IsDescendantOf(inst) then
            table.insert(desc, inst)
        end
	end
	return desc
end

-- returns all children that have specified tag
function Collect.GetTaggedChildren(inst:Instance, tag:string): {Instance?}
	local children = {}
	local tagged = CollectionService:GetTagged(tag)
	for _, v in tagged do
		if not v.Parent then continue end
		if v.Parent == inst then
            table.insert(children, inst)
        end
	end
	return children
end

return Collect
