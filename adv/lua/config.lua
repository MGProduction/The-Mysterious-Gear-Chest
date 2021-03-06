local appname=sys.get_config("project.title")

local M = {}

M.music=1
M.sound=1
M.fullscreen=tonumber(sys.get_config("display.fullscreen"))
M.language="en"
M.talkwaitforclick=false
M.talkspeed=1
M.saveslots={"empty","empty","empty","empty","empty","empty"}

function M.load(self)
	local my_file_path = sys.get_save_file(appname, "config.json")
	local myconfig = sys.load(my_file_path)
	if not next(myconfig) then
		M.music=1
		M.sound=1
		local info = sys.get_sys_info()
		if info.device_language then
			lang=string.sub(info.device_language,1,2)
		else
			lang=info.language
		end
		--if lang=="it" or lang=="en" then -- deve controllare nell'elenco delle lingue DISPONIBILI
		if lang=="en" then
			M.language=lang
		else
			M.language="en"
		end
	else
		for key,value in pairs(M) do
			if key=="load" or key=="save" then
			else
				M[key]=myconfig[key]
			end
		end
	end
end

function M.save(self)
	local my_file_path = sys.get_save_file(appname, "config.json")
	local myconfig = {}
	for key,value in pairs(M) do
		if key=="load" or key=="save" then
		else
			myconfig[key]=M[key]
		end
	end	
	sys.save(my_file_path, myconfig)
end

return M