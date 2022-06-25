local M = {}

local gop_tables = {}

function M.get(url)
	local askpath=nil
	if url == nil then
		url=msg.url(".")
		askpath=true
	end
	if type(url) == "string" then url = msg.url(url) end
	if askpath==nil then
		if gop_tables[url] == nil then gop_tables[url] = {} end
		return gop_tables[url]
	else
		if gop_tables[url.path] == nil then gop_tables[url.path] = {} end
		return gop_tables[url.path]
	end
end

function M.final(url)
	url = url or msg.url(".")
	if type(url) == "string" then url = msg.url(url) end
	gop_tables[url.path] = nil
end

return M