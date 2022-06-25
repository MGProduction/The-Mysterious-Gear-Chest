local config = require "adv/lua/config"

local M = {}

M.TIME = 2 
M.DELAY = 1 
M.gain = 0
M.time = 1
M.in_fade_now = 0
M.speed = 0.25
M.gainratio = 0.1

function M.fade_in(self) 
	M.in_fade_now = 1
	M.time=1
	M.gain=0
end

function M.fade_out(self) 
	M.in_fade_now = 2
	M.time=1
	M.gain=1
end

function M.update(self,dt)
	if M.in_fade_now > 0 and M.music and config.music==1 then
		M.time=M.time-dt*M.speed
		if M.time<0 then
			if M.in_fade_now==1 then
				M.gain=1
			else
				M.gain=0
				M.stopmusic(self)
			end
			M.in_fade_now=0
		else
			if M.in_fade_now==1 then
				M.gain=1-(M.time)
			else
				M.gain=(M.time)
			end
		end
		msg.post(M.music, "set_gain", {gain = M.gain*M.gainratio})
	end
end

function M.stopmusic(self)
	if M.music then 
		if config.music==1 then 		
			msg.post(M.music, "stop_sound")
		end
		M.music=nil
	end	
end

function M.playmusic(self,music)
	M.stopmusic(self)
	M.music=music
	if config.music==1 then 		
		msg.post(M.music,"play_sound",{gain = 0})
		M.fade_in(self)
	end	
end

function M.playsound(self,soundurl)
	if config.sound==1 then 		
		msg.post(soundurl,"play_sound",{gain = 1.0})
	end
end

local function complete_function(self, message_id, message, sender)
	-- do something when sound ends
	sound.stop(url)
end

function M.playvoice(self,soundurl)
	if config.sound==1 then 
		sound.play(soundurl,{gain = 1.0},complete_function)		
	end
end

return M