export type TextSegment = {
	kind: "text",
	value: string,
}

export type IconSegment = {
	kind: "icon",
	enum: string,
	color: string,
	scale: number,
	transparency: number,
}

export type Segment = TextSegment | IconSegment

local DEFAULT_COLOR = "#FFFFFF"
local DEFAULT_SCALE = 100
local DEFAULT_TRANSPARENCY = 0

local QUOTE_DOUBLE = string.byte('"')
local QUOTE_SINGLE = string.byte("'")
local GREATER_THAN = string.byte(">")

local function parseAttributes(raw: string): { [string]: string }
	local attrs: { [string]: string } = {}
	local pos = 1

	while true do
		local s, e, key, value = string.find(raw, '^%s*([%w_]+)%s*=%s*"([^"]*)"', pos)
		if not s then
			s, e, key, value = string.find(raw, "^%s*([%w_]+)%s*=%s*'([^']*)'", pos)
		end
		if not s then
			s, e, key, value = string.find(raw, "^%s*([%w_]+)%s*=%s*([^%s\"'/]+)", pos)
		end
		if not s then
			break
		end

		attrs[string.lower(key)] = value
		pos = e + 1
	end

	return attrs
end

-- Finds the closing ">" of a tag, ignoring any ">" inside quoted values.
local function findTagEnd(text: string, from: number): number?
	local quote: number? = nil

	for i = from, #text do
		local c = string.byte(text, i)
		if quote then
			if c == quote then
				quote = nil
			end
		elseif c == QUOTE_DOUBLE or c == QUOTE_SINGLE then
			quote = c
		elseif c == GREATER_THAN then
			return i
		end
	end

	return nil
end

-- Splits a string into ordered text / icon segments.
local function parseSegments(text: string): { Segment }
	local segments: { Segment } = {}
	local cursor = 1 -- start of text not yet emitted
	local searchFrom = 1

	while true do
		local tagStart = string.find(text, "<ico", searchFrom, true)
		if not tagStart then
			break
		end

		local bodyStart = tagStart + 4

		-- "<ico" must be followed by whitespace, "/" or ">" (rejects e.g. "<icon>")
		if not string.match(string.sub(text, bodyStart, bodyStart), "^[%s/>]$") then
			searchFrom = bodyStart
			continue
		end

		local tagEnd = findTagEnd(text, bodyStart)
		if not tagEnd then
			break -- unterminated tag, leave the rest as plain text
		end

		local attrs = parseAttributes(string.sub(text, bodyStart, tagEnd - 1))
		local enum = attrs.enum

		-- Tags without an enum are left in place as plain text
		if enum then
			if tagStart > cursor then
				table.insert(segments, {
					kind = "text",
					value = string.sub(text, cursor, tagStart - 1),
				})
			end

			table.insert(segments, {
				kind = "icon",
				enum = enum,
				color = attrs.color or DEFAULT_COLOR,
				scale = tonumber(attrs.scale) or DEFAULT_SCALE,
				transparency = tonumber(attrs.transparency) or DEFAULT_TRANSPARENCY,
			})

			cursor = tagEnd + 1
		end

		searchFrom = tagEnd + 1
	end

	if cursor <= #text then
		table.insert(segments, {
			kind = "text",
			value = string.sub(text, cursor),
		})
	end

	return segments
end

return parseSegments
