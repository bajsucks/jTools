--!strict
local Parser = require(script.Parser)
local RichWrap = require(script.Parent.RichWrap)
local jUtil = require(script.Parent.jUtil)
local InlineIcon = {}
InlineIcon.__index = InlineIcon
type _InlineIcon = {
	Set: (self: _InlineIcon, Text: string) -> (),
	Destroy: (self: _InlineIcon) -> (),
	MakeContainer: (self: _InlineIcon) -> (),
	MakeText: (self: _InlineIcon, Segment: Parser.TextSegment) -> (),
	MakeIcon: (_self: _InlineIcon, Parser.IconSegment) -> (),
	ClearContainer: (self: _InlineIcon) -> (),
	PullOrder: (self: _InlineIcon) -> number,
	Label: TextLabel,
	Container: Frame,
	Order: number,
	Text: string?,
	Enums: Enums<string>,
}
local tag = {
	seg = "InlineIcon_seg",
	icon = "InlineIcon_icon",
}
function InlineIcon.PullOrder(self: _InlineIcon): number
	local old = self.Order
	self.Order += 1
	return old
end
function InlineIcon.MakeContainer(self: _InlineIcon)
	self.Label.Visible = false
	local l = self.Label
	local c = Instance.new("Frame")
	local uill = Instance.new("UIListLayout")
	uill.HorizontalAlignment = l.TextXAlignment == Enum.TextXAlignment.Left and Enum.HorizontalAlignment.Left
		or l.TextXAlignment == Enum.TextXAlignment.Right and Enum.HorizontalAlignment.Right
		or Enum.HorizontalAlignment.Center
	uill.Parent = c
	uill.FillDirection = Enum.FillDirection.Horizontal
	uill.SortOrder = Enum.SortOrder.LayoutOrder
	uill.VerticalAlignment = Enum.VerticalAlignment.Bottom
	c.Parent = l.Parent
	c.LayoutOrder = l.LayoutOrder
	c.ZIndex = l.ZIndex
	c.Size = l.Size
	c.AnchorPoint = l.AnchorPoint
	c.Position = l.Position
	c.BackgroundTransparency = 1
	self.Container = c
end
function InlineIcon.ClearContainer(self: _InlineIcon)
	for _, v in self.Container:QueryDescendants(`.{tag.seg}, .{tag.icon}`) do
		v:Destroy()
	end
	self.Order = 0
end
function InlineIcon.MakeText(self: _InlineIcon, Segment: Parser.TextSegment)
	local seg = self.Label:Clone()
	seg.AutomaticSize = Enum.AutomaticSize.X
	local s = seg.Size
	seg.Size = UDim2.new(0, 0, 1, s.Y.Offset)
	seg.Text = Segment.value
	seg.Visible = true
	seg.RichText = true
	seg:AddTag(tag.seg)
	seg.LayoutOrder = self:PullOrder()
	seg.Parent = self.Container
end
function InlineIcon.MakeIcon(self: _InlineIcon, Segment: Parser.IconSegment)
	local Id: string = jUtil.ResolvePath(self.Enums, Segment.enum, ".")
	if not Id then
		warn(`Icon enum {Segment.enum} is missing: render skipped`)
		return
	end
	local Image = Instance.new("ImageLabel")
	Image.BackgroundTransparency = 1
	Image.ImageColor3 = Color3.fromHex(Segment.color)
	Image.Image = Id
	Image.Size = UDim2.fromScale(1, Segment.scale / 100)
	Image.ImageTransparency = Segment.transparency / 100
	Image:AddTag(tag.icon)
	Image.LayoutOrder = self:PullOrder()
	local Ratio = Instance.new("UIAspectRatioConstraint")
	Ratio.Parent = Image
	Image.Parent = self.Container
end

--[[
	Text, but with icon support

	limitations:
	* does not support text wraps
	* anything that might break with text segmentation WILL break

	RichText markup is supported for text, icons ignore it

	tag parameters:
	- enum - icon to render
	- color - image color in hex [default: #FFFFFF]
	- scale - image scaling in percent (int) [default: 100]
	- transparency - image transparency in percent (int) [default: 0]

	example ico: `This item costs 10<ico enum="Image.Wheat" color="#000000" scale=80>`
]]
function InlineIcon.Set(self: _InlineIcon, Text: string)
	if self.Container == nil then
		return -- it was already murdered
	end
	self:ClearContainer()
	-- we do not return on same text because it could be a property update call
	self.Text = Text
	-- parse
	local open: { any } = {}
	for _, v in Parser(Text) do
		if v.kind == "icon" then
			self:MakeIcon(v)
		else
			v.value = RichWrap(v.value, open)
			self:MakeText(v)
		end
	end
end
--[[
	Destroys the InlineIcon container and unhides the original TextLabel
]]
function InlineIcon.Destroy(self: _InlineIcon)
	self.Container:Destroy()
	self.Label.Visible = true
end

type InlineIcon = {
	Set: (self: _InlineIcon, Text: string) -> (),
	Destroy: (self: _InlineIcon) -> (),
	Text: string?,
}
type Enums<T> = { [string]: Enums<T> | { [string]: T } }
--[[
	Converts a TextLabel an InlineIcon container.
	Original label is preserved but hidden.
	@param Label TextLabel to convert
	@param Enums Enumeration table with icons
]]
return function(Label: TextLabel, Enums: Enums<string>): InlineIcon
	local self = setmetatable({} :: _InlineIcon, InlineIcon)
	self.Label = Label
	self.Order = 0
	self.Enums = Enums
	self:MakeContainer()
	return self :: InlineIcon
end
