--!strict
local rich: { string } = {
	"b",
	"i",
	"u",
	"s",
	"font",
	"stroke",
	"mark",
	"uppercase",
	"smallcaps",
}

export type OpenTag = { name: string, raw: string }

--[[
	Carries richtext markup tags through segmented strings
	@param cache table that holds the cached markup tags. Create it prior to calling this function in a loop

	@return wrapped string
]]
return function(seg: string, cache: { OpenTag }): string
	local prefix = ""
	for _, t in cache do
		prefix ..= t.raw
	end

	for raw, slash, name in string.gmatch(seg, "(<(/?)(%a+)[^>]*>)") do
		if not name or not table.find(rich, name) then
			continue
		end
		if slash == "/" then
			for i = #cache, 1, -1 do
				if cache[i].name == name then
					table.remove(cache, i)
					break
				end
			end
		elseif string.sub(raw, -2, -2) ~= "/" then
			table.insert(cache, { name = name, raw = raw })
		end
	end

	local suffix = ""
	for i = #cache, 1, -1 do
		suffix ..= `</{cache[i].name}>`
	end

	return prefix .. seg .. suffix
end
