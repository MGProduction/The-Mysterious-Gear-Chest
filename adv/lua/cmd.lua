local M = {}

M.WAITFORMOVEMENT=256
M.WAITFORWAIT=0
M.WAITFORFORCEDWAIT=1
M.WAITFORTALK=2
M.WAITFORDIALOG=3
M.WAITFORANIM=4
M.WAITFORCAMERAMOVEMENT=5
M.WAITFORDIALOGCLOSING=6

M.commands=nil
M.commandspos=1

M.conditional=nil
M.conditionalpos=0
M.conditionalcheck=0	

M.waittime=0
M.waitfor=-1

function M.setwaitfor(self,CMD,waitfor,time)
	CMD.waitfor=waitfor
	if time then
		CMD.waittime=time
	end
	if waitfor ==M.WAITFORANIM then
		if CMD.animcnt==nil then
			CMD.animcnt=1
		else
			CMD.animcnt=CMD.animcnt+1
		end
	elseif waitfor ==M.WAITFORCAMERAMOVEMENT then
		CMD.cameramoveto=true
	elseif waitfor ==M.WAITFORMOVEMENT then
		if CMD.movecnt==nil then
			CMD.movecnt=1
		else			
			CMD.movecnt=CMD.movecnt+1
		end
	end
end

function M.unlockanimwait(self,CMD)
	if CMD.animcnt==nil then
		
	else
		CMD.animcnt=CMD.animcnt-1
		if CMD.animcnt<=0 then
			CMD.animcnt=nil
		end
	end
end

function M.unlockmovementwait(self,CMD)
	if CMD.movecnt==nil then
		
	else
		CMD.movecnt=CMD.movecnt-1
		if CMD.movecnt<=0 then
			CMD.movecnt=nil
		end
	end
end

function M.reset(self,CMD,soft)
	if soft then		
	else
		CMD.commands=nil
	end
	CMD.commandspos=1
	CMD.conditional=nil
	CMD.conditionalpos=0
	CMD.conditionalcheck=0	
	CMD.waittime=0
	CMD.waitfor=-1
end

function M.setcommand(self,CMD,key,value,defvalue)	
	CMD.commands={}
	M.reset(self,CMD,true)	
	cmd={}
	if value then
		cmd[key]=value
	else
		cmd[key]=defvalue
	end
	table.insert(CMD.commands,cmd)	
end

function M.assigncommand(self,CMD,cmds)
	CMD.commands=cmds
	M.reset(self,CMD,true)
end

function M.addcommand(self,CMD,key,value,defvalue)
	if CMD.commands==nil then
		CMD.commands={}
		M.reset(self,CMD,true)
	end	
	cmd={}
	if value then
		cmd[key]=value
	else
		cmd[key]=defvalue
	end
	table.insert(CMD.commands,cmd)	
end

function M.addcommands(self,CMD,cmds)
	if CMD.commands==nil then
		CMD.commands={}
		M.reset(self,CMD,true)
	end
	for k, v in pairs(cmds) do
		table.insert(CMD.commands,v)	
	end	
end

function M.clonecommands(self,CMD,cmds)
	CMD.commands={}
	M.reset(self,CMD,true)
	for k, v in pairs(cmds) do
		table.insert(CMD.commands,v)	
	end	
end

function M.insertcommands(self,CMD,pos,cmds)
	if CMD.commands==nil then
		CMD.commands={}
		M.reset(self,CMD,true)
	end
	for k, v in pairs(cmds.commands) do
		table.insert(CMD.commands,pos,v)	
		pos=pos+1
	end	
end

function M.deletecommands(self,CMD)
	if CMD.commands then
		if M.player then msg.post(M.player,"unlockanim",{kind="all"}) end
		msg.post("hud", "settextcolor",{color="white"})				
	end	
	M.reset(self,CMD)	
end

function M.addcondition(self,CMD)
	if CMD.conditionalpos>0 then
		if CMD.conditionals==nil then
			CMD.conditionals={}
		end
		CMD.conditionals[CMD.conditionalpos]=CMD.conditional
	end
	CMD.conditionalpos=CMD.conditionalpos+1
	CMD.conditionalcheck=CMD.conditionalpos
	CMD.conditional=0
end


return M

