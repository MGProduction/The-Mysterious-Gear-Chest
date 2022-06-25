local audio = require "adv/lua/audio"
local config = require "adv/lua/config"
local advcmd = require "adv/lua/cmd"
local pathfind = require "adv/lua/pathfinding"
local gop = require "adv/lua.gop"

local slotname="slot01"

local TRUE=1
local FALSE=0

local posy_notdefined=-1234

function split(s, delimiter)
	result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

function varcmp(a,b,neg)
	if neg==true then
		if a~=b then
			return true
		end
	else
		if a==b then
			return true
		end
	end
	return false
end

function table_find(t,what) -- find element v of l satisfying f(v)
	for _, v in ipairs(t) do
		if v==what then
			return true
		end
	end
	return false
end

global_hero=nil

local M = {}

function M.addfunct(self,cmd,funct,mode,bool)
	local w={}
	w.f=funct
	w.mode=mode
	if bool then w.bool=bool end
	M.code[cmd]=w
end

function M.exec(self,CMD,cmd,cmdobj,cmdtootbj,val,mode)
	local f=M.code[cmd]
	if f then		
		if M.skipscene and mode=="I" and f.mode=="I" then
			if cmd=="moveto" then
				M.dosetpos(self,CMD,cmd,cmdobj,val)
			end
			return true
		elseif mode=="S" and f.mode=="I" then
			return false
		else
			--print(cmd.." ")
			if f.bool then
				if f.bool==1 then
					f.f(self,val,true)
				else
					f.f(self,val,false)
				end
			else
				f.f(self,CMD,cmd,cmdobj,val,cmdtootbj)
			end
			return true
		end
	else
		return false
	end
end

function M.loadlanguage(self)
	M.code={}
	M.addfunct(self,"say",M.dosay,"I")
	M.addfunct(self,"sayhard",M.dosay,"I")
	M.addfunct(self,"sayhappy",M.dosay,"I")
	M.addfunct(self,"declare",M.dosay,"I")
	M.addfunct(self,"think",M.dosay,"I")
	M.addfunct(self,"scream",M.dosay,"I")
	M.addfunct(self,"narrate",M.dosay,"I")

	M.addfunct(self,"addcharacter",M.doaddcharacter,"S")	
	M.addfunct(self,"selcharacter",M.doselcharacter,"S")	
	M.addfunct(self,"delcharacter",M.dodelcharacter,"S")	
	M.addfunct(self,"resetcharacter",M.doresetcharacter,"S")	
	M.addfunct(self,"setcharacterdesc",M.dosetcharacterdesc,"S")	
	M.addfunct(self,"setcharactericon",M.dosetcharactericon,"S")	
	
	--M.addfunct(self,"setcameraon",M.dosetcameraon,"S")	

	M.addfunct(self,"setcameraon",M.dosetcameraon,"S")	
	M.addfunct(self,"lockcameraon",M.dolockcameraon,"S")
	M.addfunct(self,"movecameraon",M.domovecameraon,"I")

	M.addfunct(self,"playmusic",M.doplaymusic,"S")
	M.addfunct(self,"playsound",M.doplaysound,"I")

	M.addfunct(self,"setfader",M.dosetfader,"S")

	M.addfunct(self,"saveactor",M.dosaveactor,"S")
	M.addfunct(self,"restoreactor",M.dorestoreactor,"S")

	M.addfunct(self,"savegame",M.dosavegame,"S")
	M.addfunct(self,"restoregame",M.doreloadgame,"I")
	
	M.addfunct(self,"resetanim",M.doresetanim,"S")	
	M.addfunct(self,"setanim",M.dosetanim,"S")
	M.addfunct(self,"setprop",M.dosetprop,"S")
	M.addfunct(self,"playanim",M.dosetanim,"I")
	M.addfunct(self,"lockplayanim",M.dosetanim,"I")

	M.addfunct(self,"roomtemplate",M.doroomtemplate,"S")

	M.addfunct(self,"setpos",M.dosetpos,"S")
	
	M.addfunct(self,"moveto",M.domoveto,"I")
	M.addfunct(self,"amoveto",M.domoveto,"I")
	M.addfunct(self,"reach",M.domoveto,"I")
	M.addfunct(self,"areach",M.domoveto,"I")

	M.addfunct(self,"call",M.docall,"S")

	M.addfunct(self,"setroom",M.dosetroom,"S")
	M.addfunct(self,"unsetroom",M.dounsetroom,"S")
	M.addfunct(self,"setsuffix",M.dosetsuffix,"S")

	M.addfunct(self,"faceto",M.dofaceto,"S")

	M.addfunct(self,"take",M.dotake,"S")
	M.addfunct(self,"drop",M.dodrop,"S")

	M.addfunct(self,"set",M.doset,"S",TRUE)
	M.addfunct(self,"unset",M.doset,"S",FALSE)
	
	M.addfunct(self,"learn",M.dolearn,"S",TRUE)
	M.addfunct(self,"preserve",M.dopreserve,"S",TRUE)
	M.addfunct(self,"unlearn",M.dolearn,"S",FALSE)
	M.addfunct(self,"forget",M.dolearn,"S",FALSE)

	M.addfunct(self,"setroomstatus",M.dosetroomstatus,"S")

	M.addfunct(self,"setconfig",M.dosetconfig,"S")
	
	M.addfunct(self,"setstatus",M.dosetstatus,"S")
	M.addfunct(self,"setleader",M.dosetleader,"S")

	M.addfunct(self,"setblock",M.dosetblock,"S")

	M.addfunct(self,"label",M.dolabel,"S")

	M.addfunct(self,"showactor",M.doshowactor,"S")
	M.addfunct(self,"hideactor",M.doshowactor,"S")

	M.addfunct(self,"showobj",M.doshowobj,"S")
	M.addfunct(self,"hideobj",M.doshowobj,"S")

	M.addfunct(self,"addtimer",M.doaddtimer,"S")
	M.addfunct(self,"removetimer",M.doremovetimer,"S")

	M.addfunct(self,"addtask",M.doaddtask,"S")
	M.addfunct(self,"removetask",M.doremovetask,"S")

end

M.bPause=false
M.bDialog=false

M.dialogs={}

M.player=nil
M.bkg=nil
M.efx=nil

M.rooom=nil

M.timers=nil

M.gamestring=nil
M.game=nil
M.theroom=nil
M.theobjects=nil
M.theactions=nil
M.theactors=nil
M.dlgs=nil

-- Inventory handling

M.verbs={}

M.inventory={}
M.actorselector={}

M.cmds={}

function M.getfrominventory(self,val)
	local i=1
	while i<=M.hudinventorycnt do
		if M.hudinventory[i].name==val then
			return M.hudinventory[i],i
		end
		i=i+1
	end
	return nil,-1
end

function M.removefrominventory(self,val)
	local i=1
	local status=nil
	while i<=M.hudinventorycnt do
		if M.hudinventory[i].name==val then
			local ii=i+1
			status=M.hudinventory[i].status
			while ii<=M.hudinventorycnt do
				local pos=M.hudinventory[i].pos
				M.hudinventory[i]=M.hudinventory[ii]
				M.hudinventory[i].pos=pos
				msg.post("hud", "hud_setinv",{num=i,img=M.hudinventory[i].icon})
				i=i+1
				ii=ii+1
			end
			M.hudinventory[i]=nil
			msg.post("hud", "hud_setinv",{num=i,img="void"})
			M.hudinventorycnt=M.hudinventorycnt-1
			break
		end
		i=i+1
	end
	return status
end

function M.getinventorydesc(self,item,name,wantedstatus)
	local iteminfo=M.theobjects[name]
	if iteminfo then
		iteminfo=iteminfo[1]
		local status=iteminfo["onstatus"]		
		if status then 
			if wantedstatus==nil then wantedstatus="_" end
			status=status[1] 
			if status and status[wantedstatus] then 
				status=status[wantedstatus] 
				status=status[1]
			else
				status=nil
			end
		end
		if status and status["desc"] then
			item["desc"]=status["desc"]
		else
			item["desc"]=iteminfo["desc"]
		end
		if status and status["fulldesc"] then
			item["fulldesc"]=status["fulldesc"]
		else
			item["fulldesc"]=iteminfo["fulldesc"]
		end
		if status and status["icon"] then
			item["icon"]=status["icon"]
		else
			item["icon"]=iteminfo["icon"]			
		end
	end
end

function M.getactorselectordesc(self,item,name,wantedstatus)
	local iteminfo=M.theactors[name]
	if iteminfo then
		iteminfo=iteminfo[1]
		local status=iteminfo["onstatus"]		
		if status then 
			if wantedstatus==nil then wantedstatus="_" end
			status=status[1] 
			if status and status[wantedstatus] then 
				status=status[wantedstatus] 
				status=status[1]
			else
				status=nil
			end
		end
		if status and status["desc"] then
			item["desc"]=status["desc"]
		else
			item["desc"]=iteminfo["desc"]
		end
		if status and status["fulldesc"] then
			item["fulldesc"]=status["fulldesc"]
		else
			item["fulldesc"]=iteminfo["fulldesc"]
		end
		if status and status["selecticon"] then
			item["icon"]=status["selecticon"]
		else
			item["icon"]=iteminfo["selecticon"]			
		end
	end
end

function M.addtoinventory(self,name,status)
	local objects=M.theobjects
	if objects then
		local item={}
		local iteminfo=objects[name]
		if iteminfo then
			iteminfo=iteminfo[1]
			item["name"]=name
			item["status"]=iteminfo["status"]
			if status~=nil then
				item.status=status
			end
			M.getinventorydesc(self,item,name,item["status"])			
			item["pos"]=vmath.vector3(12+M.hudinventorycnt*24,screen_h-12,0)
			item["size"]=vmath.vector3(24,24,0)
			item["usewith"]=iteminfo["usewith"]
			item["usefar"]=iteminfo["usefar"]			
			item["inventory"]=1
			item["kind"]=2
			item["value"]=iteminfo["value"]			
			M.hudinventorycnt=M.hudinventorycnt+1
			--if M.hudinventorycnt > 1 then
			msg.post("hud", "hud_setinv",{num=""..M.hudinventorycnt,val=iteminfo["value"],img=item["icon"]})
			--end
			table.insert(M.hudinventory,item)		
			if M.inventory.base+M.inventory.grid.x*M.inventory.grid.y < M.hudinventorycnt then
				M.inventory.base=M.inventory.base+2
			end
		end
	end
end

function M.showhotspots(self)
	local CMD =M.cmds
	if CMD.commands==nil then
		msg.post("hud", "hud_showhotspots",{camera=camerapos})
	end
end

function M.removefromactorselector(self,name)
	local i=1
	while i<=M.hudactorselectorcnt do
		if M.hudactorselector[i].name==name then
			local ii=i+1
			while ii<=M.hudactorselectorcnt do
				local pos=M.hudactorselector[i].pos
				M.hudactorselector[i]=M.hudactorselector[ii]
				M.hudactorselector[i].pos=pos
				msg.post("hud", "hud_setactsel",{num=i,img=M.hudactorselector[i].icon})
				i=i+1
				ii=ii+1
			end
			M.hudactorselector[i]=nil
			msg.post("hud", "hud_setactsel",{num=i,img="void"})
			M.hudactorselectorcnt=M.hudactorselectorcnt-1
			break
		end
		i=i+1
	end
end

function M.changeactorselectorattr(self,name,desc,icon)
	local i=1
	while i<=M.hudactorselectorcnt do
		if M.hudactorselector[i].name==name then
			if icon then
				M.hudactorselector[i].icon=icon
				msg.post("hud", "hud_setactsel",{num=i,img=M.hudactorselector[i].icon})
			end
			if desc then
				M.hudactorselector[i].desc=desc
			end
			break
		end
		i=i+1
	end	
end

function M.addtoactorselector(self,name)
	local actors=M.theactors
	if actors then
		local item={}
		local iteminfo=actors[name]
		if iteminfo then
			iteminfo=iteminfo[1]
			item["name"]=name
			item["status"]=iteminfo["status"]
			M.getactorselectordesc(self,item,name,item["status"])			
			item["pos"]=vmath.vector3(12+M.hudactorselectorcnt*24,screen_h-12,0)
			item["size"]=vmath.vector3(24,24,0)
			item["actorselector"]=1
			item["kind"]=3
			item["value"]=iteminfo["value"]			
			M.hudactorselectorcnt=M.hudactorselectorcnt+1
			--if M.hudinventorycnt > 1 then
			msg.post("hud", "hud_setactsel",{num=""..M.hudactorselectorcnt,val=iteminfo["value"],img=item["icon"]})
			--end
			table.insert(M.hudactorselector,item)							
		end
	end
end

function M.getselectedfromname(self,val)
	if val==nil or val=="" or val=="me" or val=="player" or (val==M.tplayer.name and M.player) then
		return M.tplayer,M.player
	else
		for i,obj in ipairs(M.actors) do
			if obj.name==val then
				return obj,obj.obj
			end
		end
		for j,obj in ipairs(M.tplayers) do
			if obj.name==val then
				return obj,obj.obj
			end
		end
	end
	return nil
end

function M.getobjpos(self,val)
	for j,obj in ipairs(M.elements) do	
		if obj.name==val then
			return vmath.vector3(obj.pos.x,obj.pos.y,0)
		end
	end
	return nil
end

function M.getobjquickuse(self,val)
	if M.verbs.quick then
		for j,obj in ipairs(M.elements) do	
			if obj.name==val then
				local quick=obj.quickuse	
				quick=M.verbs.quick[quick]
				if quick then		
					quick=quick[1]
					return M.gettrad(self,"hud",quick.text)
				else
					return nil
				end
			end
		end
	end
	return nil
end

function M.getactor(self,val)
	if val==nil or val=="" or val=="player" or val=="me" or val==M.tplayer.name then
		return M.tplayer
	else
		for i,obj in ipairs(M.actors) do
			if obj.name==val then
				return obj
			end
		end
		return nil
	end
end

function M.getglobalactor(self,val)
	if val=="" then val="me" end
	if val=="me" then
		return M.tplayer
	else
		for i,obj in ipairs(M.tplayers) do
			if obj.name==val then
				return obj
			end
		end
		return nil
	end
end

function M.fixundefinedy(self,val,actor)
	local y=posy_notdefined
	local usedy=nil
	local doubley=nil
	if M.tplayer and M.tplayer.pos and M.tplayer.pos.y~=posy_notdefined then
		usedy=math.floor(M.tplayer.pos.y)
	end
	for i,obj in ipairs(M.actors) do
		if obj.name==val then
			y=obj.pos.y
		else
			if obj.pos.y==posy_notdefined then
			else
				if usedy and usedy==math.floor(obj.pos.y) then
					doubley=usedy
				else
					usedy=math.floor(obj.pos.y)
				end
			end
		end
	end
	if doubley then
		y=doubley
	elseif usedy then
		y=usedy
	elseif y==posy_notdefined and M.rectarea then
		local sy=M.tplayer.size.y
		if actor and actor.size then
			sy=actor.size.y
		end
		y=M.rectarea.y-M.rectarea.h-sy+4
	end
	return y
end

function M.getactorpos(self,val)
	if val==nil or val=="" then val="me" end
	if val=="me" or val==M.tplayer.name then
		if val=="me" then
			val=M.tplayer.name
		end
		if heropos==nil and M.player then
			heropos=gop.get(M.player).rposition
		end
		if heropos then
			return vmath.vector3(heropos.x,heropos.y,0)
		else
			if M.tplayer.pos.y==posy_notdefined then
				M.tplayer.pos.y=M.fixundefinedy(self,val,M.tplayer)
			end
			return vmath.vector3(M.tplayer.pos.x,M.tplayer.pos.y,0)
		end
	else
		for i,obj in ipairs(M.actors) do
			if obj.name==val then
				return vmath.vector3(obj.pos.x,obj.pos.y,0)
			end
		end
		return nil
	end
end

function M.getcmdpos(self,val)
	local actpos=M.getactorpos(self,val)
	if actpos == nil then
		local objpos=M.getobjpos(self,val)
		if objpos==nil then
			local dig=split(val,",")	
			if dig[2] then
				return vmath.vector3(dig[1],dig[2],0)
			else
				return vmath.vector3(dig[1],-1,0)
			end
		else
			return objpos
		end
	else
		return actpos
	end
end

-- Functions

function M.dolearn(self,val,bool)
	local what=val.."_known"
	if bool==true then
		M.memory[what]=true
	else
		M.memory[what]=nil
	end
end

function M.dopreserve(self,val,bool)
	local what=val.."_known"
	if M.staticmemory==nil then
		M.staticmemory={}
	end
	if bool==true then
		M.staticmemory[what]=true
	else
		M.staticmemory[what]=nil
	end
end

function M.doset(self,val,bool)
	if bool==true then
		local sep=split(val,",")
		local what=sep[1]
		local withwhat=true
		if sep[2] then withwhat=sep[2] end
		M.memory[what]=withwhat
	else
		M.memory[val]=nil																
	end
end

function M.doroomtemplate(self,CMD,cmd,cmdobj,val)
	M.roomtemplate=M.thelocations[val]		
	if M.roomtemplate==nil then
		M.roomtemplate=M.thescenes[val]	
	end
	if M.roomtemplate then
		M.roomtemplate=M.roomtemplate[1]
	end	
end

function M.docall(self,CMD,cmd,cmdobj,val)
	local act=M.theactions[val]
	if act then
		if CMD.commands[CMD.commandspos+1] then
			local more={}
			local j=CMD.commandspos
			local i=j+1
			while CMD.commands[i] do										
				table.insert(more,CMD.commands[i])	
				i=i+1
				--table.remove(CMD.commands,i)										
			end									
			CMD.commands={}
			CMD.commandspos=0
			advcmd.addcommands(self,CMD, act)
			advcmd.addcommands(self,CMD, more)
		else
			CMD.commands={}
			CMD.commandspos=0
			advcmd.addcommands(self,CMD, act)
		end
	end
end

function M.dounsetroom(self,CMD,cmd,cmdobj,val)
	if val=="*" then
		for j,actor in ipairs(M.tplayers) do	
			if actor.obj and actor.room==M.room then
				actor.room=nil
			end
		end
	else
		for j,actor in ipairs(M.tplayers) do	
			if actor.name==val then
				actor.room=nil
			end
		end
	end
end

function M.dosetroom(self,CMD,cmd,cmdobj,val)
	local selected=M.tplayer.name
	local setposx,setposy
	if cmdobj then
		local v=split(val,",")
		selected=cmdobj
		val=v[1]
		setposx=v[2]
		setposy=v[3]
	elseif string.find(val, ",") then
		local v=split(val,",")
		selected=v[1]
		val=v[2]
		setposx=v[3]
		setposy=v[4]
	end						
	if val=="here" then
		val=M.room
	end	
	if selected==M.player then
		--M.tplayer.reloadpos=nil
	else
		for j,actor in ipairs(M.tplayers) do	
			if actor.name==selected then
				actor.faceto=nil
				actor.room=val
				if actor.pos then
					if setposx  then
						actor.pos.x=setposx
					end
					if setposy then
						actor.pos.y=setposy
					end
				end
				if actor.obj and M.leavingroom==nil then
					msg.post(actor.obj, "show",{visible=false})
					msg.post(actor.obj, "set_ref",{ref=nil})
					for i,obj in ipairs(M.actors) do
						if obj.name==selected then
							go.delete(obj.obj)
							obj.obj=nil
							break
						end
					end
				end
				if actor.room==M.room then
					if actor.obj==nil then
						M.addactor(self,actor)
					else
						msg.post(actor.obj, "show",{visible=true})
					end
				else
					actor.disabled=true
				end
				selected=M.player
				break
			end
		end
	end
end

function M.getreferencepos(self,val)	
	local dist=0
	local pos_x=nil
	local pos_y=nil
	local actpos=M.getactorpos(self,val)
	if actpos then 
		local herosize=M.tplayer["size"]
		pos_x=actpos.x
		pos_y=actpos.y
		dist=herosize.x
	else
		local objpos=M.getobjpos(self,val)
		if objpos then
			pos_x=objpos.x
			pos_y=objpos.y
		else
			local dig=split(val,",")	
			local start=dig[1]:sub(1, 1)
			if start=="_" then
				local movingpos
				if cmdobj==nil then
					movingpos=M.getactorpos(self,"me")
				else
					movingpos=M.getactorpos(self,cmdobj)
				end
				pos_x=movingpos.x+tonumber(dig[1]:sub(2))				
			else
				pos_x=tonumber(dig[1])
			end
			if dig[2] then
				pos_y=tonumber(dig[2])
			end
		end
	end			
	return pos_x,pos_y,dist
end

function M.domoveto(self,CMD,cmd,cmdobj,val)
	local dist=0
	local walk
	local pos_x=nil
	local pos_y=nil

	pos_x,pos_y,dist=M.getreferencepos(self,val)

	local movepos
	local moveactor
	if cmdobj then		
		local actor,actorobj=M.getselectedfromname(self,cmdobj)
		movepos=actor.pos--M.getactorpos(self,cmdobj)
		moveactor=actorobj--M.getactor(self,cmdobj)
		--if moveactor then
			--moveactor=moveactor.obj
		--end
	else
		movepos=gop.get(M.player).rposition--go.get_position(M.player)
		moveactor=M.player
	end				
	if cmd=="reach" or cmd=="areach" then 
		dist=dist+16	
	end
	if movepos then
		if math.abs(movepos.x-pos_x)>dist then
			local pos
			if movepos.x<pos_x then
				pos = vmath.vector3(pos_x-dist,movepos.y,0)
			else
				pos = vmath.vector3(pos_x+dist,movepos.y,0)
			end
			if moveactor then
				msg.post(moveactor, "look_at",{lookat=pos,mode="turn"})	
			end			
			if moveactor==M.player then
				if M.rectarea then
					if pos.x > M.rectarea.x+M.rectarea.w then
						pos.x = M.rectarea.x+M.rectarea.w
					end
					if pos.x < M.rectarea.x then
						pos.x = M.rectarea.x
					end
				end
			end
			if moveactor then
				msg.post(moveactor, "move_to",{destination=pos,xonly=true,alert=true})			
				walk=true
			else
				local odd
				odd=0
			end
			if cmd=="amoveto" or cmd=="areach" then
			elseif walk then
				advcmd.setwaitfor(self,M.cmds,advcmd.WAITFORMOVEMENT)
			end
		end
	end		
end

-- Commands handling

function M.playaction(self,name)
	local act=M.theactions[name]
	if act then
		advcmd.addcommands(self,M.cmds, act)
	end
end

function M.doplaysound(self,CMD,cmd,cmdobj,val)
	if M.musicroom then
		audio.playsound(self,M.room..":/audio#"..val)
	else
		audio.playsound(self,"/audio#"..val)
	end
end

function M.doplaymusic(self,CMD,cmd,cmdobj,val)
	if val=="" or val==nil or val=="_" then
		val=nil
		if M.music~=val then
			M.music=nil
			audio.stopmusic(self)
		end
	else
		if M.music~=val then
			M.music=val
			if M.musicroom then
				audio.playmusic(self,M.room..":/audio#"..M.music)
			else			
				audio.playmusic(self,"/audio#"..M.music)
			end
		end
	end
end

function M.animationalert(self)
	advcmd.unlockanimwait(self,M.cmds)
end

function M.cameramovementalert(self,alert)
	M.cmds.cameramoveto=nil
end

function M.movementalert(self,alert)
	advcmd.unlockmovementwait(self,M.cmds)
	if alert then
		local onalert=M.getcmd(self,"_","onalert_"..alert)
		if onalert then
			local CMD=M.cmds
			advcmd.addcommands(self,CMD,onalert)
			M.playcommands(self,CMD,true)
		end
	end
end

function M.doaddtimer(self,CMD,cmd,cmdobj,val)	
	local sep=split(val,",")
	if M.timers==nil then M.timers={} end
	local timer={}
	timer["name"]=sep[1]
	if sep[2] then
		timer["timer"]=tonumber(sep[2])/1000
	else
		timer["timer"]=2500/1000
	end
	M.timers[sep[1]]=timer
end

function M.doremovetimer(self,CMD,cmd,cmdobj,val)
	local sep=split(val,",")
	if M.timers then
		M.timers[sep[1]]=nil
	end
end

function M.doaddtask(self,CMD,cmd,cmdobj,val)	
	local sep=split(val,",")
	M.tasks[sep[1]]=sep[2]	
end

function M.doremovetask(self,CMD,cmd,cmdobj,val)
	local sep=split(val,",")
	M.tasks[sep[1]]=nil
end

function M.gettrad(self,kind,val)
	local desc=tonumber(val)	
	if desc then
		local t=M.txt
		if t then
			local tt=t[kind]
			if tt then
				return ""..tt[desc]
			end
		end
	end
	return val
end

function charcount(base, pattern)
    return select(2, string.gsub(base, pattern, ""))
end

function M.docoresay(self,CMD,val,cmd,tpos,tsize,tcolor)
	msg.post("hud", "action.examine",{desc=val,pos=tpos,size=tsize,color=tcolor})											
	if cmd=="declare" then
		advcmd.setwaitfor(self,CMD,advcmd.WAITFORTALK,string.len(val)*0.25)
	else
		local spacecnt=charcount(val," ")
		local commacnt=charcount(val,",")
		local dotcnt=charcount(val,".")
		local talktime=math.max(24,string.len(val))*0.075+spacecnt*0.075+commacnt*0.2+commacnt*0.1
		if config.talkspeed then
			talktime=talktime*config.talkspeed
		end
		if config.waitforclick==true then
			talktime=talktime*10
		end
		advcmd.setwaitfor(self,CMD,advcmd.WAITFORTALK,talktime)
	end	
end

function M.dosay(self,CMD,cmd,cmdobj,val,cmdobjto)
	if M.skipscene then
	else
		local tpos=nil
		local tsize=nil
		local tcolor="#FFFFC0"
		if cmdobj==nil or (M.tplayer and M.tplayer.name==cmdobj) then
			M.talker=M.player							
			tpos=gop.get(M.player).rposition--go.get_position(M.player)
			tsize=M.tplayer["size"]
			if cmd=="think" then 
				tcolor=M.tplayer["thinkcolor"]	
			elseif cmd=="scream" then 
				tcolor=M.tplayer["screamcolor"]	
			elseif cmd=="narrate" then 
				tcolor="#BAE1FF"
				tpos=nil
				M.talker=nil
			else
				tcolor=M.tplayer["saycolor"]	
			end			
		else
			for j,actor in ipairs(M.tplayers) do	
				if actor.name==cmdobj then
					tpos=actor.pos
					if tpos.y == posy_notdefined then
						tpos.y=M.fixundefinedy(self,cmdobj,actor)
					end
					tsize=actor.size
					if cmd=="think" then 
						if actor["thinkcolor"] then
							tcolor=actor["thinkcolor"]	
						else
							tcolor="#E0E0E0"							
						end					
					elseif cmd=="scream" then 
						 if actor["screamcolor"] then
							tcolor=actor["screamcolor"]	
						else
							tcolor="#E04040"	
						end
					else
					 tcolor=actor["saycolor"]	
					end
					M.talker=actor["obj"]									
					break
				end
			end								
			if tpos==nil then
				tcolor=cmdobj
				for j,actor in pairs(M.theactors) do	
					local lactor=actor[1]
					if lactor.name==cmdobj then
						tpos=lactor["pos"]
						tsize=lactor["size"]
						if cmd=="think" and actor["thinkcolor"] then 
						 tcolor=actor["thinkcolor"]	
						elseif cmd=="scream" and actor["screamcolor"] then 
						 tcolor=actor["screamcolor"]	
						else
						 tcolor=actor["saycolor"]	
						end
						break
					end			
				end
			end
		end	
		if M.talker then
			if cmd=="say" or cmd=="scream" then
				msg.post(M.talker,"lockanim",{anim="talk",stopmovement=true})
			elseif cmd=="sayhard" then
				msg.post(M.talker,"lockanim",{anim="talkhard",stopmovement=true})
			elseif cmd=="sayhappy" then
				msg.post(M.talker,"lockanim",{anim="talkhappy",stopmovement=true})
			else
				if M.general.usefrontanim=="0" then
					msg.post(M.talker,"lockanim",{anim="talk",stopmovement=true})
				else
					msg.post(M.talker,"lockanim",{anim="talk.front",stopmovement=true})
				end
			end							
		end
		if cmdobjto then
			M.dofaceto(self,CMD,"faceto",cmdobj,cmdobjto)
		end

		local texts=M.gettrad(self,"say",val)
		M.text=split(texts," _ ")
		M.textpos=tpos
		M.textsize=tsize
		M.textcolor=tcolor
		M.textindex=1
		M.textcmd=cmd
		M.docoresay(self,CMD,M.text[M.textindex],M.textcmd,M.textpos,M.textsize,M.textcolor)		
	end
end

function M.doshowtasks(self,CMD,val,cmdobj)
	local txt=""
	local cnt=0
	for k, v in pairs(M.tasks) do
		if cnt>0 then txt=txt.."|" end
		txt=txt.."- "..v
		cnt=cnt+1
	end
	M.dosay(self,CMD,"say",nil,txt)
end

function M.dofaceto(self,CMD,cmd,cmdobj,val)
	local dig=split(val,",")
	local actor,actorobj=M.getselectedfromname(self,cmdobj)
	if actorobj then		
		local pos
		local save=nil
		if dig[1]=="left" then
			pos=vmath.vector3(-8192,0,0)
			save=dig[1]
		elseif dig[1]=="right" then
			pos=vmath.vector3(8192,0,0)
			save=dig[1]
		else
			pos=M.getactorpos(self,dig[1])
			if pos then
				save=dig[1]
			else
				pos=M.getobjpos(self,dig[1])
				if pos then
					save=dig[1]
				end
			end
		end	
		if actor then
			if dig[2]=="lock" and save then
				actor.faceto=save
			else
				actor.faceto=nil
			end
		end
		mode=dig[2]
		if mode==nil then mode="turn" end
		msg.post(actorobj, "look_at",{lookat=pos,mode=mode})	
	else
		for j,actor in ipairs(M.tplayers) do	
			if actor.name==cmdobj then
				actor.faceto=dig[1]		
				break
			end
		end
	end
end

function M.dosetpos(self,CMD,cmd,cmdobj,val)
	local actor,actorobj=M.getselectedfromname(self,cmdobj)
	if actorobj then 		

		local dist=0
		local pos_x=nil
		local pos_y=nil
		local xonly=true
		
		pos_x,pos_y=M.getreferencepos(self,val)

		if actor then
			actor.pos.x=pos_x
			if xonly then
			else
				actor.pos.y=pos_y
			end
		end
		
		msg.post(actorobj, "set_to",{destination=actor.pos,xonly=xonly,follow=-1})	
	end
end

function M.dosetpos_old(self,CMD,cmd,cmdobj,val)
	local actor,actorobj=M.getselectedfromname(self,cmdobj)
	if actorobj then 		
				
		local pos
		
		local dig=split(val,",")
		local start=dig[1]:sub(1, 1)
		local offset_x=nil
		local pos_x=nil
		local objpos=M.getobjpos(self,val)
		if objpos then
			pos_x=objpos.x
			pos_y=objpos.y
			pos=objpos
		else		
			if start=="_" then
				local movingpos
				if cmdobj==nil then
					movingpos=M.getactorpos(self,"me")
				else
					movingpos=M.getactorpos(self,cmdobj)
				end
				offset_x=tonumber(dig[1]:sub(2))				
				pos_x=nil
			else
				pos_x=tonumber(dig[1])				
				offset_x=nil
			end		
			if dig[2]==nil then
				pos=M.getactorpos(self,cmdobj)
				if offset_x then
					pos.x=pos.x+offset_x
				else
					if pos_x then
						pos.x=pos_x
					end
				end
			else
				local herosize=actor.size
				pos = vmath.vector3(dig[1],screen_h-((dig[2]-herosize.y/2)),0)
				xonly=false
			end
		end
		if actor then
			if xonly then
				if actor.pos then
					actor.pos.x=pos.x
				end
			else
				actor.pos=pos
			end
		end
		msg.post(actorobj, "set_to",{destination=pos,xonly=xonly,follow=-1})			
	end
end

function M.doleavingto(self,nextroom,CMD,add)
	local l=CMD
	if add then
		local CMDX={}							
		l=CMDX
	end
	advcmd.setcommand(self,l,"setstatus",nextroom..",opening")
	advcmd.addcommand(self,l,"loadroom",nextroom)
	--advcmd.addcommand(self,l,"setstatus",nextroom..",closing")
	if add then
		advcmd.insertcommands(self,CMD,CMD.commandspos+1,l)
	end
	
	M.playcommands(self,CMD)
	
	M.dosetstatus(self,CMD,"setstatus",nil,nextroom..",closing",nil,true)
end

function M.doenterfrom(self,val,bkgsx,CMD,add)
	local herosize=M.tplayer["size"]
	local py=M.rectarea.y+M.rectarea.h/2+herosize.y/2
	local movement=math.min(64,screen_w/4)
	if val=="left" then
		if add then
			local CMDX={}
			advcmd.setcommand(self,CMDX,"setpos",(-herosize.x/2-8))--..","..py)
			advcmd.addcommand(self,CMDX,"moveto",""..(herosize.x*2))--..","..py)
			advcmd.insertcommands(self,CMD,CMD.commandspos+1,CMDX)
		else
			advcmd.setcommand(self,CMD,"setpos",(-herosize.x/2-8))--..","..py)
			advcmd.addcommand(self,CMD,"moveto",""..(herosize.x*2))---..","..py)
		end
	elseif val=="right" then
		if add then
			local CMDX={}
			advcmd.setcommand(self,CMDX,"setpos",(bkgsx+herosize.x/2+8))--..","..py)
			advcmd.addcommand(self,CMDX,"moveto",(bkgsx-herosize.x*2))--..","..py)
			advcmd.insertcommands(self,CMD,CMD.commandspos+1,CMDX)
		else
			advcmd.setcommand(self,CMD,"setpos",(bkgsx+herosize.x/2+8))--..","..py)
			advcmd.addcommand(self,CMD,"moveto",(bkgsx+herosize.x/2-herosize.x*2))--..","..py)
		end		
	else
		local fromroom=M.lastroom
		if val and val~="auto" then
			fromroom=val
		end
		if fromroom then
			if M.fromroom then
				local found=false
				local alternative=nil
				for i, v in ipairs(M.elements) do
					if v.moveto==fromroom then					
						found=true
						break
					end
				end	
				if found==false then
					fromroom=M.fromroom
				end
			end
			for i, v in ipairs(M.elements) do
				if v.moveto==fromroom then					
					local l=CMD
					if add then
						local CMDX={}							
						l=CMDX
					end
					if v.pos.x-v.size.x/2 <=10 then
						advcmd.setcommand(self,l,"setstatus",fromroom..",opening")
						advcmd.addcommand(self,l,"setpos",(-herosize.x/2-8))--..","..py)
						if M.tplayer.follower then
							for name, val in pairs(M.tplayer.follower) do
								advcmd.addcommand(self,l,"setpos,"..name,(-herosize.x/2-8))--..","..py)
							end							
						end
						advcmd.addcommand(self,l,"moveto",(v.pos.x+v.size.x/2+herosize.x))
						if M.tplayer.follower then
							for name, val in pairs(M.tplayer.follower) do
								advcmd.addcommand(self,l,"reach,"..name,"me")
							end
						end
						advcmd.addcommand(self,l,"setstatus",fromroom..",closing")
					elseif v.pos.x+v.size.x/2 >=bkgsx-10 then
						advcmd.setcommand(self,l,"setstatus",fromroom..",opening")
						advcmd.addcommand(self,l,"setpos",(bkgsx+herosize.x/2+8))--..","..py)
						if M.tplayer.follower then
							for name, val in pairs(M.tplayer.follower) do
								advcmd.addcommand(self,l,"setpos,"..name,(bkgsx+herosize.x/2+8))--..","..py)
							end														
						end
						advcmd.addcommand(self,l,"moveto",(v.pos.x-v.size.x/2-herosize.x))--..","..py)	
						if M.tplayer.follower then
							for name, val in pairs(M.tplayer.follower) do
								advcmd.addcommand(self,l,"reach,"..name,"me")
							end
						end
						advcmd.addcommand(self,l,"setstatus",fromroom..",closing")	
					else
						advcmd.setcommand(self,l,"setstatus",fromroom..",opening")						
						advcmd.addcommand(self,l,"setpos",(v.pos.x))--..","..py)
						if M.tplayer.follower then
							for name, val in pairs(M.tplayer.follower) do
								advcmd.addcommand(self,l,"setpos,"..name,(v.pos.x-herosize.x/2))
							end
						end
						advcmd.addcommand(self,l,"wait","250")
						advcmd.addcommand(self,l,"setstatus",fromroom..",closing")
					end
					if add then
						advcmd.insertcommands(self,CMD,CMD.commandspos+1,l)
					end
					break
				end
			end	
		end
	end
	M.fromroom=nil
end

function M.dolockcameraon(self,CMD,cmd,cmdobj,val)
	if val=="" or val=="_" then
		msg.post("camera", "look_at")
	else
		local actors=split(val,",")
		local pos
		if actors[2] then
			pos=M.getactorpos(self,actors[1])
			local pos2=M.getactorpos(self,actors[2])
			pos.x=(pos.x+pos2.x)/2
		else
			pos=M.getactorpos(self,actors[1])
		end
		msg.post("camera", "look_at",{position=pos})
	end
end

function M.domovecameraon(self,CMD,cmd,cmdobj,val)
	local actor,actorobj=M.getselectedfromname(self,val)
	if actorobj then 		
		msg.post(actorobj, "set_to",{follow=true,dontupdate=true})
		msg.post(actorobj, "movecamera_to")		
		advcmd.setwaitfor(self,M.cmds,advcmd.WAITFORCAMERAMOVEMENT)
	end
end

function M.dosetcameraon(self,CMD,cmd,cmdobj,val)
	local actor,actorobj=M.getselectedfromname(self,val)
	if actorobj then 
		msg.post(actorobj, "set_to",{follow=true})
	end
end

function M.dosetsuffix(self,CMD,cmd,cmdobj,val)
	local actorobj=M.player
	local actor=M.tplayer
	if cmdobj then
		actor,actorobj=M.getselectedfromname(self,cmdobj)									
	elseif string.find(val, ",") then
		local v=split(val,",")		
		actor,actorobj=M.getselectedfromname(self,v[1])									
		val=v[2]		
	end	
	if val=="_" or val==nil then 
		val="" 
	end
	if actor then
		actor.suffix=val
	end
	if actorobj then
		msg.post(actorobj,"set_suffix",{name=val})
	end
end

function M.doaddcharacter(self,CMD,cmd,cmdobj,val)
	M.myactorselector[val]=true
	M.addtoactorselector(self,val)
	M.updateactorselector(self)
end

function M.doselcharacter(self,CMD,cmd,cmdobj,val)
	if M.myactorselector[val] then
		local i=1
		while i<=M.hudactorselectorcnt do
			if M.hudactorselector[i].name==val then
				M.actorselector.selected=i
				msg.post("hud", "hud_setactsel",{num=i,sel=1})				
			else
				msg.post("hud", "hud_setactsel",{num=i,sel=0})
			end
			i=i+1
		end
	end
end

function M.dosetcharacterdesc(self,CMD,cmd,cmdobj,val)
	M.changeactorselectorattr(sel,cmdobj,val,nil)
end

function M.dosetcharactericon(self,CMD,cmd,cmdobj,val)
	M.changeactorselectorattr(sel,cmdobj,nil,val)
end

function M.dodelcharacter(self,CMD,cmd,cmdobj,val)
	M.myactorselector[val]=nil
	M.removefromactorselector(self,val)
	M.updateactorselector(self)
end

function M.doresetcharacter(self,CMD,cmd,cmdobj,val)
	M.myactorselector[val]=true
	M.addtoactorselector(self,val)
	M.updateactorselector(self)	
end

function M.dosetfader(self,CMD,cmd,cmdobj,val)
	local color=nil
	local timing
	if string.find(val, ",") then
		local v=split(val,",")
		color=v[2]
		timing=v[1]
	else
		timing=val
	end
	fader_timing=tonumber(timing)/1000
end

function M.dosetprop(self,CMD,cmd,cmdobj,val)
	local actorobj=M.player
	local actor=M.tplayer
	if cmdobj then
		actor,actorobj=M.getselectedfromname(self,cmdobj)									
	end
	if val=="" or val=="_" then val=nil end
	if actor then
		actor.prop=val			
	end
	if actorobj then
		msg.post(actorobj,"set_prop",{name=val})	
	end
end

function M.dosavegame(self,CMD,cmd,cmdobj,val)
	M.save(self,val)
end

function M.doreloadgame(self,CMD,cmd,cmdobj,val)
	M.load(self,val)
	if M.staticmemory then
		for i, v in pairs(M.staticmemory) do
			M.memory[i]=v
		end
		M.staticmemory=nil
	end
end

function M.dosaveactor(self,CMD,cmd,cmdobj,val)
	local actorobj=M.player
	local actor=M.tplayer
	if val then
		actor,actorobj=M.getselectedfromname(self,val)									
	end
end

function M.dosrestoreactor(self,CMD,cmd,cmdobj,val)
	local actorobj=M.player
	local actor=M.tplayer
	if val then
		actor,actorobj=M.getselectedfromname(self,val)									
	end
end

function M.doresetanim(self,CMD,cmd,cmdobj,val)
	local actorobj=M.player
	local actor=M.tplayer
	if val then
		actor,actorobj=M.getselectedfromname(self,val)									
	end
	if actorobj then
		msg.post(actorobj,"set_prop")
		msg.post(actorobj,"set_suffix",{name=""})
		msg.post(actorobj,"unlockanim")
	end
	if actor then
		actor.prop=nil		
		actor.suffix=nil
		actor.anim=nil
	end
end

function M.dosetanim(self,CMD,cmd,cmdobj,val)
	local actorobj=M.player
	local actor=M.tplayer
	local wait=nil
	if cmd=="playanim" or cmd=="lockplayanim" then 
		wait=true 
	end
	if cmdobj then
		actor,actorobj=M.getselectedfromname(self,cmdobj)									
	elseif string.find(val, ",") then
		local v=split(val,",")
		actor,actorobj=M.getselectedfromname(self,v[1])							
		val=v[2]
	end
	if val=="" or val==nil or val=="_" then
		msg.post(actorobj,"unlockanim")
	else
		if actorobj then
			
				msg.post(actorobj,"unlockanim",{kind="all"})
				msg.post(actorobj,"lockanim",{anim=val,alert=wait})
				if actorobj==M.player then
				else
					if wait==false then 
						actor.anim=val							
					end				
				end			
				if wait then 
					if cmd=="playanim" then
						advcmd.ANIMSELECTED=actorobj
					end
					advcmd.setwaitfor(self,M.cmds,advcmd.WAITFORANIM)
				end			
			
		end
	end
end

function M.setstatusanim(self,obj)
	if obj.overlay then
		if obj.frames and obj.frames[obj.status] then
			local frame=obj.frames[obj.status]
			msg.post(obj.obj,"changeanim",{anim=frame.overlay,x=frame.x,y=frame.y,z="auto"})
		else				
			msg.post(obj.obj,"changeanim",{anim="void"})
		end		
	end
end

function M.dosetleader(self,CMD,cmd,cmdobj,val)
	actor,actorobj=M.getselectedfromname(self,cmdobj)	
	if val=="" or val=="_" then
		if actor and actor.leader then
			leader,leaderobj=M.getselectedfromname(self,actor.leader)	
			actor.leader=nil
			if actorobj then
				msg.post(actorobj,"set_leader",{leader=nil})
			end
			if leader then
				if leader.follower then
					local size1=0
					leader.follower[actor.name]=nil
					for _ in pairs(leader.follower) do size1 = size1 + 1 end
					if size1==0 then
						leader.follower=nil
					end
				end
			end
		end
	else
		leader,leaderobj=M.getselectedfromname(self,val)	
		if actor and leader then
			actor.leader=leader.name
			if actorobj then
				msg.post(actorobj,"set_leader",{leader=leaderobj})
			end
			if leader.follower==nil then
				leader.follower={}
			end
			leader.follower[actor.name]=true
		end	
	end
end

function M.dosetblock(self,CMD,cmd,cmdobj,val)
	local v=split(val,",")
	for i,obj in ipairs(M.actors) do
		if obj.name==v[1] then
			selected=obj.obj		
			obj.pos=go.get_position(selected)
			obj.blocking=true
			obj.blockingalert=v[2]
			msg.post(M.player,"addblockingarea",{pos=obj.pos,size=obj.size,name=obj.name,alert=v[2]})														
			break
		end
	end
end

function M.addtolocalinventory(self,name,actor,status)
	local objects=M.theobjects
	if objects then
		local item={}
		local iteminfo=objects[name]
		if iteminfo then
			iteminfo=iteminfo[1]
			item["name"]=name
			item["status"]=iteminfo["status"]
			if status~=nil then
				item.status=status
			end
			M.getinventorydesc(self,item,name,item["status"])			
			item["pos"]=vmath.vector3(12+actor.hudinventorycnt*24,screen_h-12,0)
			item["size"]=vmath.vector3(24,24,0)
			item["usewith"]=iteminfo["usewith"]
			item["usefar"]=iteminfo["usefar"]			
			item["inventory"]=1
			item["kind"]=2
			item["value"]=iteminfo["value"]			
			actor.hudinventorycnt=actor.hudinventorycnt+1
			--if M.hudinventorycnt > 1 then
			--msg.post("hud", "hud_setinv",{num=""..actor.hudinventorycnt,val=iteminfo["value"],img=item["icon"]})
			--end
			table.insert(actor.hudinventory,item)							
		end
	end
end

function M.removefromlocalinventory(self,val,actor)
	local i=1
	local status=nil
	while i<=actor.hudinventorycnt do
		if actor.hudinventory[i].name==val then
			local ii=i+1
			status=actor.hudinventory[i].status
			while ii<=actor.hudinventorycnt do
				local pos=actor.hudinventory[i].pos
				actor.hudinventory[i]=actor.hudinventory[ii]
				actor.hudinventory[i].pos=pos
				--msg.post("hud", "hud_setinv",{num=i,img=actor.hudinventory[i].icon})
				i=i+1
				ii=ii+1
			end
			actor.hudinventory[i]=nil
			--msg.post("hud", "hud_setinv",{num=i,img="void"})
			actor.hudinventorycnt=actor.hudinventorycnt-1
			break
		end
		i=i+1
	end
	return status
end

function M.doselectforswitch(self,val)
	local sep=split(val,",")
	local A=M.memory["switchAfrom"]
	if A==nil then
		if sep[2] then
			M.memory["switchAfrom"]=sep[1]
			M.memory["switchA"]=sep[2]
		end
	elseif A==sep[1] then
		if sep[2]==nil then
			M.memory["switchAfrom"]=nil
			M.memory["switchA"]=nil
		else
			M.memory["switchA"]=sep[2]
		end
	else
		local actorA=nil
		local actorB=nil
		local statusA=nil
		local statusB=nil
		for j,actor in ipairs(M.tplayers) do	
			if actor.name==M.memory["switchAfrom"] then				
				actorA=actor				
			elseif actor.name==sep[1] then							
				actorB=actor				
			end
		end
		if actorA and actorB then	
			if actorA.myinventory[M.memory["switchA"]]==nil then
				M.memory["switchAfrom"]=nil
				M.memory["switchA"]=nil
			else				
				if actorA then	
					statusA=M.removefromlocalinventory(self,M.memory["switchA"],actorA)
				end
				if actorB then
					statusB=M.removefrominventory(self,sep[2])			
				end
				if actorA then			
					actorA.myinventory[M.memory["switchA"]]=nil
					M.addtolocalinventory(self,sep[2],actorA,statusB)
					actorA.myinventory[sep[2]]=true
				end
				if actorB then			
					M.myinventory[sep[2]]=nil
					M.addtoinventory(self,M.memory["switchA"],statusA)
					M.myinventory[M.memory["switchA"]]=true
					M.updateinventory(self)
				end
				M.memory["switchAfrom"]=nil
				M.memory["switchA"]=nil
			end
		end
	end
end

function M.doloadroom(self,val)
	local sep=split(val,",")		
	val=sep[1];
	if val=="$previous" then
		M.jumpto=M.lastroom
	else							
		M.jumpto=val							
	end
	M.fromroom=sep[2];
	M.unloadRoom(self)
end

function M.doloadmap(self,val)
	M.jumpto=val	
	M.tplayer.mapreloadpos=gop.get(M.player).rposition
	M.unloadRoom(self)
	M.roomisamap=true
end

function M.doswitch(self,val)
	local sep=split(val,",")
	local actorname=sep[1]
	if M.tplayer.name==actorname then						
	else
		local jumpto
		for j,actor in ipairs(M.tplayers) do	
			if actor.name==actorname then
				if sep[2]=="direct" then
				else
					M.tplayer.reloadpos=gop.get(M.player).rposition--go.get_position(M.player)
					M.tplayer.pos=gop.get(M.player).rposition
				end
				M.tplayer.hudinventory=M.hudinventory				
				M.tplayer.hudinventorycnt=M.hudinventorycnt
				M.tplayer.myinventory=M.myinventory
				M.tplayer.inventorybase=M.inventory.base
				M.tplayer.kind=1
				M.tplayer.room=M.room
				M.tplayer.lastroom=M.lastroom
				-- SWITCH
				M.tplayer.human=3
				actor.human=2
				---
				M.tplayer=actor
				M.tplayer.kind=2
				if M.tplayer.hudinventory then
					M.hudinventory=M.tplayer.hudinventory
					M.hudinventorycnt=M.tplayer.hudinventorycnt										
					M.myinventory=M.tplayer.myinventory
					if M.tplayer.inventorybase then
						M.inventory.base=M.tplayer.inventorybase
					else
						M.inventory.base=0
					end
				else
					M.hudinventory={}
					M.myinventory={}
					M.hudinventorycnt=0
					M.inventory.base=0
				end							
				
				M.playername=actorname				
				if sep[2]=="direct" then
				else
					jumpto=actor.room									
				end
				break
			end
		end
		if jumpto then									
			M.jumpto=jumpto			
			M.unloadRoom(self)
			return true
		end
	end
	return false
end

function M.dosetmoveto(self,val)
	local v=split(val,",")
	local sel=v[1]				
	local room=v[2]
	local dir=v[3]
	for j,obj in ipairs(M.elements) do	
		if obj.name==sel then
			obj["moveto"]=room
			M.memory[M.room.."_"..obj.name.."_moveto"]=room
			obj["movedir"]=dir
			M.memory[M.room.."_"..obj.name.."_movedir"]=dir
			break
		end
	end
end

function M.dosetroomstatus(self,CMD,cmd,cmdobj,val)
	if val=="here" then
		val=M.room
	end	
	if cmdobj then
		M.memory[cmdobj.."_status"]=val
	else
		M.memory[M.room.."_status"]=val
	end
end

function M.dosetconfig(self,CMD,cmd,cmdobj,val,cmdtootbj,silent)	                  
	local v=split(val,",")
	local what=v[1]				
	local value=v[2]
	config[what]=value
	config.save(self)
end

function M.dosetstatus(self,CMD,cmd,cmdobj,val,cmdtootbj,silent)	                  
	local v=split(val,",")
	local sel=v[1]				
	local status=v[2]
	for j,obj in ipairs(M.tplayers) do
		if obj.name==sel then				
			obj.status=status
			return
		end
	end	
	for j,obj in ipairs(M.hudinventory) do
		if obj.name==sel then
			obj.status=status
			M.getinventorydesc(self,obj,obj.name,obj.status)
			M.updateinventory(self)
		end
	end
	for j,obj in ipairs(M.elements) do	
		if obj.name==sel then
			M.memory[M.room.."_"..obj.name.."_status"]=status
			obj.status=status
			if silent then
				local l
				l=0
			else
				M.setstatusanim(self,obj)
			end
			return
		end
	end	
end

function M.adddialog(self,val,condition,act)
	if M.dialog == nil then M.dialog={} end
	local line={}
	line["text"]=val
	line["condition"]=condition
	line["cmd"]=act
	table.insert(M.dialog, line)
end

function M.newdialog(self,val)
	M.dialog={}
	table.insert(M.dialogs,M.dialog)	
end

function M.deletedialog(self,val)
	if M.dialog then
		M.dialog=nil
		M.dialogcmd=nil
		M.bDialog=false
		msg.post("hud","dismissdlg")
		advcmd.setwaitfor(self,M.cmds,advcmd.WAITFORDIALOGCLOSING,0.5)
		table.remove(M.dialogs)
		if #M.dialogs > 0 then
			M.dialog=M.dialogs[#M.dialogs]
			M.playdialog(self,"_")
		end
	end
end

function M.showdlg(self,name)
	local content=M.dlgs[name]
	if content then
		M.resetaction(self)
		msg.post("hud", "showdlg",{name=name,content=content[1]})
		return true
	else
		return false
	end
end

function M.playdialog(self,val)
	M.dialogcmd=nil
	if M.dialog then		
		local CMD=M.cmds
		if M.skipscene then M.skipscene=nil end
		msg.post("hud", "showdialog",{dialog=#M.dialogs})
		advcmd.setwaitfor(self,CMD,advcmd.WAITFORDIALOG)
		M.bDialog=true
	end
end

function M.checkpropertiesconditions(self,conditions,actor,property)
	local sep=split(conditions,"|")
	for i, v in ipairs(sep) do
		if v=='_' and actor[property]==nil then
			return true		
		elseif actor[property]==v then
			return true		
		end
	end
	return false
end

function M.checkroomconditions(self,conditions,cmdobj)
	local sep=split(conditions,"|")
	local actor=nil
	local actorobj=nil
	if cmdobj then
		actor,actorobj=M.getselectedfromname(self,cmdobj)
	end
	for i, v in ipairs(sep) do
		v=M.normalizeroom(self,v)
		if actor then
			if actor.room==v then
				return true		
			end
		else
			if M.room==v then
				return true		
			end
		end
	end
	return false
end

function M.checkconditions(self,conditions,wsuffix)
	local sep=split(conditions,"+")

	for i, v in ipairs(sep) do
		local neg
		local val
		local vname=v
		local suffix
		
		if string.sub(v,1, 1)=='!' then
			v=string.sub(v,2)
			neg=true
		end
		if wsuffix==nil then 
			suffix="_known" 
		else
			suffix=wsuffix
		end
		if string.sub(v,1, 1)=='$' then
			v=string.sub(v,2)
			suffix="_taken"
		end
		
		vname=v..suffix
		val=M.memory[vname]
		if neg and val then
			return false
		elseif neg==nil and val==nil then
			return false
		end
	end
	return true
end

function M.dolabel(self,CMD,cmd,cmdobj,val)
	local texts
	if val=="" or val==nil or val=="0" then
		texts=""
	else
		texts=M.gettrad(self,"say",val)		
	end
	msg.post("hud", "action.setlabel",{kind=cmdobj,text=texts})	
end

function M.doshowactor(self,CMD,cmd,cmdobj,val)
	local visible
	if cmd=="showactor" then 
		visible=true 
	else 
		visible=false 
	end	
	for j,actor in ipairs(M.tplayers) do	
		if actor.name==val then									
			if actor.obj then
				msg.post(actor.obj,"show",{visible=visible})											
			else
				--msg.post(M.player,"show",{visible=visible})											
			end
			actor.visible=visible										
			break
		end
	end
end

function M.doshowobj(self,CMD,cmd,cmdobj,val)
	local sep=split(val,",")
	local vsible
	if cmd=="showobj" then visible=true else visible=false end
	if sep[2] then -- show / hide in other rooms
		local nm=sep[2].."_"..sep[1].."_visible"
		if visible==true then
			M.memory[nm]=1
		else
			M.memory[nm]=0
		end
	else
		for i,obj in ipairs(M.elements) do
			if obj.name==sep[1] then
				msg.post(obj.obj, "show",{visible=visible})
				local nm=M.room.."_"..obj.name.."_visible"
				if visible==true then
					M.memory[nm]=1
				else
					M.memory[nm]=0
				end
				obj.visible=visible
				for i,obj in ipairs(M.elements) do
					if obj.name=="mask."..sep[1] then
						msg.post(obj.obj, "show",{visible=visible})
					end
				end
				break
			end								
		end
	end
end

function M.dodrop(self,CMD,cmd,cmdobj,val)
	if val=='*' then
		M.hudinventory={}
		M.hudinventorycnt=0
		M.myinventory={}	
		M.updateinventory(self)
	else
		if cmdobj and cmdobj~=M.tplayer.name then
			local a=M.getglobalactor(self,cmdobj)
			if a and a.myinventory then
				a.myinventory[val]=nil				
				M.removefromlocalinventory(self,val,a)
			end
		else
			M.myinventory[val]=nil
			M.removefrominventory(self,val)		
			M.updateinventory(self)						
		end
	end
	
end

function M.dotake(self,CMD,cmd,cmdobj,obj)
	local sep=split(obj,",")
	local val=sep[1]
	local what=val.."_taken"
	M.memory[what]=true
	if cmdobj and cmdobj~=M.tplayer.name then
		local a=M.getglobalactor(self,cmdobj)
		if a and a.myinventory then
			a.myinventory[val]=true				
			M.addtolocalinventory(self,val,a)
		end
	else			
		M.myinventory[val]=true
		M.addtoinventory(self,val)
		M.updateinventory(self)
		if sep[2] then
			M.doshowobj(self,nil,"hideobj",nill,sep[2])
		end
	end
end

function M.normalizeroom(self,val)
	if val==nil or val=="_" or val=="here" then
		return M.room
	else
		return val
	end
end

function M.ifcheck(self,CMD,cmd,val,cmdobj)
	if cmd=="ifconfig" then
		local sep=split(val,",")
		advcmd.addcondition(self,CMD)		
		if config[sep[1]]==sep[2] then
			CMD.conditional=1
		end
		return true
	elseif cmd=="ifknown" then
		advcmd.addcondition(self,CMD)		
		if M.checkconditions(self,val,"_known") == true then
			CMD.conditional=1
		end	
		return true
	elseif cmd=="ifnotknown" then
		local what=val.."_known"
		advcmd.addcondition(self,CMD)		
		if M.memory[what]==nil then
			CMD.conditional=1
		end			
		return true
	elseif cmd=="ifmet" then
		local what=val.."_met"
		advcmd.addcondition(self,CMD)		
		if M.memory[what]==true then
			CMD.conditional=1
		end			
		return true				
	elseif cmd=="ifnotmet" then
		local what=val.."_met"
		advcmd.addcondition(self,CMD)		
		if M.memory[what]==nil then
			CMD.conditional=1
		end					
		return true												
	elseif cmd=="ifvisited" then
		advcmd.addcondition(self,CMD)		
		val=M.normalizeroom(self,val)
		if M.visited[val] then
			CMD.conditional=1
		end					
		return true
	elseif cmd=="ifnotvisited" then
		advcmd.addcondition(self,CMD)	
		val=M.normalizeroom(self,val)
		if M.visited[val] == nil then
			CMD.conditional=1
		end					
		return true
	elseif cmd=="ifroomstatus" then
		advcmd.addcondition(self,CMD)		
		cmdobj=M.normalizeroom(self,cmdobj)
		if  M.memory[cmdobj.."_status"]==val then
			CMD.conditional=1
		end					
		return true		
	elseif cmd=="ifroom" then
		advcmd.addcondition(self,CMD)		
		if M.checkroomconditions(self,val,cmdobj) then
			CMD.conditional=1
		end
		return true
	elseif cmd=="ifleader" then
		local actor=M.getactor(self,cmdobj)
		if val=="me" then
			val=M.tplayer.name
		end
		advcmd.addcondition(self,CMD)		
		if actor and M.checkpropertiesconditions(self,val,actor,"leader") then								
			CMD.conditional=1
		end	
		return true
	elseif cmd=="ifsuffix" then
		local actor=M.getactor(self,cmdobj)
		advcmd.addcondition(self,CMD)		
		if actor and M.checkpropertiesconditions(self,val,actor,"suffix") then
			CMD.conditional=1
		end	
		return true
	elseif cmd=="ifprop" then
		local actor=M.getactor(self,cmdobj)
		advcmd.addcondition(self,CMD)		
		if actor and M.checkpropertiesconditions(self,val,actor,"prop") then
			CMD.conditional=1
		end					
		return true
	elseif cmd=="ifactor" then
		advcmd.addcondition(self,CMD)		
		if M.tplayer.name==val then
			CMD.conditional=1
		end			
		return true
	elseif cmd=="iftaken" then
		advcmd.addcondition(self,CMD)		
		if M.checkconditions(self,val,"_taken") == true then
			CMD.conditional=1
		end					
		return true
	elseif cmd=="ifnottaken" then
		local what=val.."_taken"
		advcmd.addcondition(self,CMD)		
		if M.memory[what]==nil then
			CMD.conditional=1
		end		
		return true
	elseif cmd=="ificon" then
		advcmd.addcondition(self,CMD)		
		local sep=split(val,",")
		local obj,i=M.getfrominventory(self,sep[1])
		if obj and obj["icon"]==sep[2] then
			CMD.conditional=1
		end					
		return true		
	elseif cmd=="ifnoticon" then
		advcmd.addcondition(self,CMD)		
		local sep=split(val,",")
		local obj,i=M.getfrominventory(self,sep[1])
		if obj and obj["icon"]==sep[2] then
		else
			CMD.conditional=1
		end					
		return true
	elseif cmd=="ifhave" then
		advcmd.addcondition(self,CMD)		
		if cmdobj then
			local a=M.getglobalactor(self,cmdobj)
			if a and a.myinventory then
				if a.myinventory[val] then
					CMD.conditional=1
				end	
			end
		else
			if M.myinventory[val] then
				CMD.conditional=1
			end	
		end				
		return true
	elseif cmd=="ifdonthave" then
		advcmd.addcondition(self,CMD)		
		if M.myinventory[val] == nil then
			CMD.conditional=1
		end			
		return true	
	elseif cmd=="ifonce" then
		advcmd.addcondition(self,CMD)		
		local what=val.."_known"
		if M.memory[what]==nil then
			M.memory[what]="1"
			CMD.conditional=1
		end	
		return true	
	elseif cmd=="ifset" then
		local sep=split(val,",")
		advcmd.addcondition(self,CMD)		
		if sep[2] then
			if M.memory[sep[1]]==sep[2] then
				CMD.conditional=1
			end	
		else
			if M.memory[val] then
				CMD.conditional=1
			end	
		end			
		return true			
	elseif cmd=="ifnotset" then
		local sep=split(val,",")
		advcmd.addcondition(self,CMD)		
		if sep[2] then
			if M.memory[sep[1]]~=sep[2] then
				CMD.conditional=1
			end	
		else
			if M.memory[val] == nil then
				CMD.conditional=1
			end				
		end		
		return true	
	else
		return false
	end
end

function M.playcommands(self,CMD,consolemode)		
	local selected=M.player
	while(CMD.commands~=nil) do		
		local current=CMD.commands[CMD.commandspos]
		if current==nil then
			advcmd.deletecommands(self,CMD)
			if consolemode then
			else
				if M.bDialog ==false then
					local mask
					if M.player then
						mask=2
					else
						mask=1
					end			
					msg.post("hud", "hud_enable",{enable=mask})
				end
				M.handle_cursormovements(self,M.lastaction)
			end
		else
			for cmdx,val in pairs(current) do
				local sep=split(cmdx,",")
				local cmd=sep[1]
				local cmdobj=sep[2]
				local cmdobjto=sep[3]
				if cmd=="else" then
					if CMD.conditionalcheck==CMD.conditionalpos then
						if CMD.conditional then
							if CMD.conditional==0 then
								CMD.conditional=1
							elseif CMD.conditional==1 then
								CMD.conditional=0
							end
						end
					end
				elseif cmd=="endif" then				
					if CMD.conditionalcheck==CMD.conditionalpos then
						CMD.conditionalpos=CMD.conditionalpos-1
						CMD.conditionalcheck=CMD.conditionalpos
						if CMD.conditionalpos==0 then
							CMD.conditional=nil
						else
							CMD.conditional=CMD.conditionals[CMD.conditionalpos]
						end
					else	
						CMD.conditionalpos=CMD.conditionalpos-1
						if CMD.conditionalpos==0 then
							CMD.conditional=nil
							CMD.conditionalcheck=CMD.conditionalpos
						end
					end
				else
					local skip=false
					if CMD.conditionalpos~=CMD.conditionalcheck or (CMD.conditional and CMD.conditional==0) then skip=true end
					if skip==true then
						if cmd=="elseif" and CMD.conditionalcheck==CMD.conditionalpos then
							cmd="if"
							skip=false
						end
					end
					if skip==true then
						if string.sub(cmd,1,2)=="if" then						
							CMD.conditionalpos=CMD.conditionalpos+1
						end
					else							
						if M.exec(self,CMD,cmd,cmdobj,cmdobjto,val,"I") then		
						elseif M.ifcheck(self,CMD,cmd,val,cmdobj) then				
						elseif cmd=="if" then				
							local neg
							local sep=split(val,",")
							advcmd.addcondition(self,CMD)									
							if string.sub(sep[1], 1, 1)=="!" then
								sep[1]=string.sub(sep[1],2)
								neg=true
							end
							local what=M.getglobalactor(self,sep[1])
							if what and varcmp(what.status,sep[2],neg) then
								CMD.conditional=1
							else
								what=M.room.."_"..sep[1].."_status"
								if varcmp(M.memory[what],sep[2],neg) then
									CMD.conditional=1								
								end
								local obj,i=M.getfrominventory(self,sep[1])
								if obj and varcmp(obj.status,sep[2],neg) then
									CMD.conditional=1								
								end
							end
						elseif cmd=="ifnot" then				
								advcmd.addcondition(self,CMD)		
								local sep=split(val,",")
								local what=M.room.."_"..sep[1].."_status"
								if M.memory[what]~=sep[2] then
									CMD.conditional=1
								else
									what=M.getglobalactor(self,sep[1])
									if what and what.status~=sep[2] then
										CMD.conditional=1
									end
								end
						elseif cmd=="ifequal" then
							advcmd.addcondition(self,CMD)		
							local sep=split(val,",")
							local obj,i=M.getfrominventory(self,sep[1])
							if obj and obj["value"] then
								if tonumber(obj["value"])==tonumber(sep[2]) then
									CMD.conditional=1
								end								
							end
						elseif cmd=="ifmorethan" then
							advcmd.addcondition(self,CMD)		
							local sep=split(val,",")
							local obj,i=M.getfrominventory(self,sep[1])
							if obj and obj["value"] then
								if tonumber(obj["value"])>tonumber(sep[2]) then
									CMD.conditional=1
								end
							end							
						elseif cmd=="iflessthan" then
							advcmd.addcondition(self,CMD)		
							local sep=split(val,",")
							local obj,i=M.getfrominventory(self,sep[1])
							if obj and obj["value"] then
								if tonumber(obj["value"])<tonumber(sep[2]) then
									CMD.conditional=1
								end
							end									
						elseif cmd=="setvisited" then
							M.dosetvisited(self,val)														
						elseif cmd=="modifyicon" then
							local sep=split(val,",")
							local obj,i=M.getfrominventory(self,sep[1])
							if obj then
								obj["icon"]=sep[2]
								M.updateinventory(self)
							end
						elseif cmd=="selectforswitch" then
							M.doselectforswitch(self,val)
						elseif cmd=="incval" then	
							local sep=split(val,",")
							local obj,i=M.getfrominventory(self,sep[1])
							if obj and obj["value"] then
								obj["value"]=tonumber(obj["value"])+tonumber(sep[2])
								msg.post("hud", "hud_setinv",{num=i,val=obj["value"]})
							end
						elseif cmd=="setval" then		
							local sep=split(val,",")
							local obj,i=M.getfrominventory(self,sep[1])
							if obj and obj["value"] then
								obj["value"]=tonumber(sep[2])
								msg.post("hud", "hud_setinv",{num=i,val=obj["value"]})
							end
						elseif cmd=="switchto" then		
							if M.doswitch(self,val) == true then
								break
							end
						elseif cmd=="loadmap" then									
							M.doloadmap(self,val)
							break
						elseif cmd=="loadroom" then			
							M.doloadroom(self,val)													
							break
						elseif cmd=="unsetblock" then	
							local sep=split(val,",")	
							msg.post(M.player,"delblockingarea",{name=sep[1]})
							for j,actor in ipairs(M.tplayers) do	
								if actor.name==sep[1] then
									actor.blocking=nil
									actor.blockingalert=nil
									break
								end
							end
						elseif cmd=="stop" then		
							if M.tplayer and M.tplayer.name==val then
								msg.post(M.player,"stop",{name=val})
							else
								for i,obj in ipairs(M.actors) do
									if obj.name==val then
										msg.post(obj.obj,"stop",{name=obj.name})
										break
									end
								end	
							end
						elseif cmd=="setstartingpos" then
							local actorobj=M.player
							local actor=M.tplayer
							local v=split(val,",")
							if v[3] then
								actor,actorobj=M.getselectedfromname(self,v[1])							
								val=v[2]..","..v[3]
							end							
							if actorobj==M.player then
							else
								for j,actor in ipairs(M.tplayers) do	
									if actor.obj==actorobj then
										local dig=split(val,",")
										local pos = vmath.vector3(dig[1],screen_h-((dig[2]-actor.size.y/2)),0)
										actor.pos=pos
										selected=M.player
										break
									end
								end
							end						
						elseif cmd=="musicfadeout" then	
							if M.music~=val then
								audio.fade_out(self)
								advcmd.setwaitfor(self,CMD,advcmd.WAITFORFORCEDWAIT,0.5)
							end
						elseif cmd=="showtasks" then	
							M.doshowtasks(self,CMD,val,cmdobj)		
						elseif cmd=="audio" then
							M.toggle_audio(self,true,true)
						elseif cmd=="music" then
							M.toggle_audio(self,true,false)
						elseif cmd=="sound" then
							M.toggle_audio(self,false,true)
						elseif cmd=="fullscreen" then
							M.toggle_fullscreen(self)						
						elseif cmd=="setmoveto" then	
							M.dosetmoveto(self,val)
						elseif cmd=="addline" then	
							local level=1
							local actions={}
							local tell={}
							tell["say"]=val							
							table.insert(actions,tell)
							CMD.commandspos=CMD.commandspos+1
							while(CMD.commands~=nil)and(level>0) do		
								local current=CMD.commands[CMD.commandspos]
								if current==nil then
									break
								else
									for cmdx,val in pairs(current) do
										local sep=split(cmdx,",")
										local cmd=sep[1]
										local cmdobj=sep[2]		
										if cmd=="addline" then
											level=level+1
										elseif cmd=="endadd" then
											level=level-1											
										end
										if level>0 then
											table.insert(actions,current)
											CMD.commandspos=CMD.commandspos+1
										end										
									end									
								end						
							end	
							M.adddialog(self,M.gettrad(self,"say",val),cmdobj,actions)								
						elseif cmd=="showdlg" then
							--M.showdlg(self,val)			
							msg.post(".", "btn_cmd_show", {what=val})				
							--hgui_show(self,val)
						elseif cmd=="playdialog" then
							M.playdialog(self,val)
						elseif cmd=="newdialog" then
							M.newdialog(self,val)
						elseif cmd=="deletedialog" then
							M.deletedialog(self,val)
						elseif cmd=="wait" then	
							if M.skipscene then
							else
								advcmd.setwaitfor(self,CMD,advcmd.WAITFORWAIT,tonumber(val)/1000)
							end
						elseif cmd=="saycolor" then	
							msg.post("hud", "settextcolor",{color=val})					
						elseif cmd=="randomsay" then
							local what=split(val,"|")
							local which=math.random(#what)
							M.dosay(self,CMD,"say",cmdobj,what[which])
						elseif cmd=="gane" or cmd=="game" then
							if val=="new" then
								M.reset(self)
							end
						else
							print("unrecognized cmd: "..cmd.." "..val)
						end
					end
				end
			end
			CMD.commandspos=CMD.commandspos+1
			if M.skipscene then
			else
				if CMD.waitfor >= 0 then
					if M.hardskipscene and ( (CMD.waitfor==advcmd.WAITFORMOVEMENT) or (CMD.waitfor==advcmd.WAITFORTALK) )then
						
					else
						break
					end
				end
			end
		end
	end
	if CMD.waitfor >= 0 then
	else
		M.skipscene=nil
	end
end

function M.getcmd(self,obj,action,kind)
	if M.theroom then
		local theobj=nil
		local roomstatus=M.memory[M.room.."_status"]
		if roomstatus then			
			local statusrelatedactions=M.theroom["onstatus_"..roomstatus]
			if statusrelatedactions then
				statusrelatedactions=statusrelatedactions[1]
				local theobj=statusrelatedactions[obj]
				if theobj==nil and M.roomtemplate then
					theobj=M.roomtemplate[obj]
				end
				if theobj then
					theobj=theobj[1]
					local theact=theobj[action]
					if theact then
						return theact
					end
				end
			end
		end
		if M.tplayer and M.tplayer.name then 
			local actorrelatedactions=M.theroom["onactor_"..M.tplayer.name]
			if actorrelatedactions then
				actorrelatedactions=actorrelatedactions[1]
				local theobj=actorrelatedactions[obj]
				if theobj==nil and M.roomtemplate then
					theobj=M.roomtemplate[obj]
				end
				if theobj then
					theobj=theobj[1]
					local theact=theobj[action]
					if theact then
						return theact
					end
				end
			end
		end
		if theobj==nil then
			theobj=M.theroom[obj]
			if theobj==nil and M.roomtemplate then
				theobj=M.roomtemplate[obj]
			end
			if theobj then
				theobj=theobj[1]
				local theact=theobj[action]
				if theact then
					return theact
				end
			end
		end
		local what=nil
		local status=nil
		if kind==1 or kind==3 then
			what=M.theactors[obj]
		elseif kind==2 then
			what=M.theobjects[obj]
			for i, v in ipairs(M.hudinventory) do
				if v.name==obj then
					status=v.status
					break					
				end
			end
		end
		if what then
			what=what[1]
			local onaction=what["onaction"]
			if onaction then
				local theact=nil
				onaction=onaction[1]
				if status then theact=onaction[status.."_"..action] end
				if theact==nil then theact=onaction[action] end
				return theact
			end
		end
	end
	return nil
end

-- Commands handling

function M.readactiveconfig(self)
	local config
	local info=sys.get_engine_info()
	if info and info.is_debug then
		config=M.game["debugconfig"]
	else
		config=M.game["config"]		
	end
	return config[1]
end

function M.readbasesets(self,baseset,container,val,suffix)
	if baseset and baseset~="" and baseset~="_" then
		local items=split(baseset,",")	
		for i, v in ipairs(items) do		
			if container==nil then container={} end
			if suffix then
				local vv=v..suffix
				container[vv]=val
			else
				container[v]=val
			end
		end
	end
end

function M.readbaseinventory(self,baseinv)	
	if baseinv then
		local items=split(baseinv,",")	
		for i, v in ipairs(items) do	
			if v=="_" then
			else
				M.myinventory[v]=true	
				M.addtoinventory(self,v)		
			end
		end
	end
end

function M.readbaseactors(self,baseactsel)	
	if baseactsel then
		local items=split(baseactsel,",")	
		for i, v in ipairs(items) do	
			if v=="_" then
			else
				M.myactorselector[v]=true	
				M.addtoactorselector(self,v)		
			end
		end
	end
end

function M.readbase(self,config)
	M.readbaseinventory(self,config["baseinventory"])
	M.readbaseactors(self,config["basecharacters"])	
	M.readbasesets(self,config["baseset"],M.memory,true)
	M.readbasesets(self,config["basevisited"],M.visited,1)
	M.readbasesets(self,config["basemet"],M.memory,true,"_met")	
	M.readbasesets(self,config["baseknown"],M.memory,true,"_known")	
end

function M.resetvars(self)
	M.visited={}
	M.tasks={}
	M.memory={}	
	M.lastmusic={}
	
	M.hudinventory={}
	M.hudinventorycnt=0
	M.myinventory={}	
	
	M.hudactorselector={}
	M.hudactorselectorcnt=0
	M.myactorselector={}
	M.actorselector.selected=0
	
	M.lastroom=""
	M.jumpto=nil
end

function M.safereset(self)
	M.tplayer={}
end

function M.reset(self)
	
	M.resetvars(self)

	M.loadTPLAYERS(self)
	
	for i = 1, M.inventory.count do
		msg.post("hud", "hud_setinv",{num=i,img="void"})
	end

	local config=M.readactiveconfig(self)

	M.readbase(self,config)
	
	M.updateinventory(self)
	M.updateactorselector(self)
end

function M.unloadGame(self)
	audio.stopmusic(self)
	if defos then defos.set_cursor_visible(true) end
end

function M.getsize(t,sx,sy)
	local size
	if t then
		local p=split(t,",")			
		size=vmath.vector3(tonumber(p[1]),tonumber(p[2]),0)
	else
		size=vmath.vector3(sx,sy,0)
	end		
	return size
end

function M.addbtn(self,hpause)
	if  hpause then
		hpause=hpause[1]
		local pause={}
		pause.icon=hpause["icon"]
		pause.anchor=hpause["anchor"] or "topcenter"
		pause.size=M.getsize(hpause["size"],16,16)
		return pause
	else
		return nil
	end
end

function M.defactorread(self,other,actor,actorbasename)
	other["name"]=actor["name"]	
	other["desc"]=actor["desc"]
	if other["name"]==nil then
		if actorbasename then
			other["name"]=actorbasename
		else
			local name=M.gettrad(self,"desc",other["desc"])
			other["name"]=name
		end
	end
	if actor["animset"]==nil then
		other["animset"]=actor["body_animset"]
		other["head_animset"]=actor["head_animset"]
	else
		other["animset"]=actor["animset"]
	end
	other["fulldesc"]=actor["fulldesc"]
	other["size"]=M.getsize(actor["size"],40,80)
	other["saycolor"]=actor["saycolor"] or "white"
	other["thinkcolor"]=actor["thinkcolor"] or "#E0E0E0"
	other["shadow"]=actor["shadow"]		
	other["room"]=actor["room"]		
	other["status"]=actor["status"]	
	other["onstatus"]=actor["onstatus"]
	if other["onstatus"] then
		other["onstatus"]=other["onstatus"][1]
	end
end

function M.setmousebuttons(self,which)
	local hud=M.game["hud"]
	if hud then
		hud=hud[1]		
		local general_v=hud["verbs"]	
		if general_v then	
			general_v=general_v[1]
				
			if which=="left" then
				M.verbs.dragwith="right" --general_v["dragwith"] or "left"

				M.verbs.defrightclick=general_v["leftclick"] or nil
				M.verbs.defrightclickinv=general_v["leftclickinventory"] or nil
				M.verbs.defrightclickactors=general_v["leftclickactors"] or nil

				M.verbs.defleftclick=general_v["rightclick"] or "lookat"
				M.verbs.defleftclickinv=general_v["rightclickinventory"] or nil
				M.verbs.defleftclickactors=general_v["rightclickactors"] or "talkto"
			else
				M.verbs.dragwith=general_v["dragwith"] or "right"

				M.verbs.defleftclick=general_v["leftclick"] or nil
				M.verbs.defleftclickinv=general_v["leftclickinventory"] or nil
				M.verbs.defleftclickactors=general_v["leftclickactors"] or nil

				M.verbs.defrightclick=general_v["rightclick"] or "lookat"
				M.verbs.defrightclickinv=general_v["rightclickinventory"] or nil
				M.verbs.defrightclickactors=general_v["rightclickactors"] or "talkto"
			end
		end
	end
end

function M.loadverbs(self,hud)
	local general_v=hud["verbs"]	
	if general_v then	
		local t	
		general_v=general_v[1]
		M.verbs.showmode=general_v["showmode"]
		M.verbs.ignoreplayer=general_v["ignoreplayer"]
		M.verbs.grid=M.getgrid(self,general_v)		
		M.verbs.anchor=general_v["anchor"] or "topright"		
		M.verbs.deftext=M.gettrad(self,"hud",general_v["deftext"]) or "Sorry, I can't do that"
		M.verbs.usedeftext="I can't do that"
		if M.short then
			M.verbs.defart=""
			M.verbs.walkto=""
			M.verbs.switchto=""
			M.verbs.lookat=""
		else
			M.verbs.walkto=M.gettrad(self,"hud",general_v["walkto"]) or "walk to"
			M.verbs.switchto=M.gettrad(self,"hud",general_v["switchto"]) or "switch to"
			M.verbs.lookat=M.gettrad(self,"hud",general_v["lookat"]) or "look at"					
			M.verbs.defart=general_v[M.lang..".defarticle"] or " the"
			if M.verbs.defart=="_" then M.verbs.defart="" end
		end
		M.getblank(self,M.verbs,general_v)
		local quick=general_v["quickuse"]
		if quick then
			M.verbs.quick=quick[1]
		end
		local list=general_v["list"]
		M.verbs.list={}
		M.verbs.listcnt=0
		if list then
			for kk, vv in pairs(list) do
				for cmd, content in pairs(vv) do
					content=content[1]
					local other={}
					kk=math.abs(content["pos"])
					other["cmd"]=cmd
					other["pos"]=kk
					other["acton"]=content["acton"]
					other["prep"]=content["double"]
					other["drag"]=content["drag"]
					local icon=content["icon"]
					if icon then
						other["icon"]=icon
					else
						other["icon"]=M.lang..".cmd."..cmd
					end
					local text=M.gettrad(self,"hud",content["text"])
					if text then
						other["text"]=text					
					else
						other["text"]=cmd					
					end
					if cmd=="lookat" then
						if M.short then
							other["text"]=nil
						else
							M.verbs.lookat=other["text"]
						end
					end						
					other["deftext"]=M.gettrad(self,"hud",content["deftext"])
					if cmd == "use" then
						M.verbs.usedeftext=other.deftext
					end
					if content["reach"] then
						other["reach"]=math.abs(content["reach"])
					end
					M.verbs.list[cmd]=other
					if kk > M.verbs.listcnt then M.verbs.listcnt=kk end
				end
			end
		end			
		if M.verbs.grid.x*M.verbs.grid.y==0 then
			M.verbs.listcnt=0
		end
		M.verbs.size=M.getsize(general_v["size"],24,24)
		if general_v["invertbuttons"] then
			M.setmousebuttons(self,"left")
		else
			M.setmousebuttons(self,"right")
		end
			
	end	
end

function M.setlanguage(self,lang)
	if lang=="_" then lang="" end
	config.language=lang
	config.save(self)
	M.lang=lang
	M.txtstring=nil
	M.txt=nil
	M.txtstring = sys.load_resource("/adv/json/"..M.name.."_"..M.lang.."_texts.json")
	M.txt = json.decode(M.txtstring)	
	local hud=M.game["hud"]
	if hud then
		hud=hud[1]
		M.loadverbs(self,hud)
		msg.post("hud", "hud_updatelanguage",{dad=msg.url(".")})
	end	
end

function M.loadTPLAYERS(self)
	M.tplayers={}
	M.tplayer={}
	for kk, vv in pairs(M.theactors) do
		local name=kk
		local actor=M.theactors[name]
		if actor then
			actor=actor[1]
			if 0==1 then -- name==M.playername then
				M.defactorread(self,M.tplayer,actor)				
				M.tplayer["pos"]=vmath.vector3(12,screen_h-12,0)				
				M.tplayer["human"]=2
				M.tplayer["kind"]=1				
			else
				other={}
				M.defactorread(self,other,actor,name)
				local val=actor["startingpos"]
				if val then
					local dig=split(val,",")	
					local h=other["size"].y		
					other.pos=vmath.vector3(dig[1],screen_h-((dig[2]-h/2)),0)							
				else
					--other["pos"]=vmath.vector3(12,screen_h-12,0)		
					other.pos=vmath.vector3(12,posy_notdefined,0)				
					--other.pos=vmath.vector3(12,screen_h-other.size.y-12,0)		
					--other.pos=vmath.vector3(12,screen_h-12,0)
					--other["pos"]=vmath.vector3(screen_w/2,screen_h/2,0)
				end
				other["human"]=3
				other["blocking"]=actor["blocking"]
				other["blockingalert"]=actor["blockingalert"]
				other["room"]=actor["startingfrom"]
				other["anim"]=actor["startinganim"]
				other["prop"]=actor["startingaprob"]
				other["suffix"]=actor["startingasuffix"]
				other["status"]=actor["startingstatus"]
				other["baseinventory"]=actor["baseinventory"]
				other["kind"]=1				
				
				table.insert(M.tplayers, other)	
				if name==M.playername then
					M.tplayer=other
					M.tplayer["human"]=2
				end
			end
		end
	end
end

function M.getblank(self,inventory,general_i)
	local blank=general_i["blank"]
	if blank then
		blank=blank[1]
		inventory.blankicon=blank["icon"]	
		inventory.blankiconsel=blank["selecticon"]	
		inventory.blankiconbar=blank["iconbar"]	
	else
		inventory.blankicon=general_i["blankicon"]	
		inventory.blankiconsel=general_i["blankselectionicon"]	
		inventory.blankiconbar=general_i["blankiconbar"]	
	end					
end

function M.getgrid(self,general_i)
	local columns,rows
	local grid=general_i["grid"]
	if grid then
		grid=grid[1]
		columns=grid["columns"] or 4
		rows=grid["rows"] or 1
	else
		columns=general_i["columns"] or 4
		rows=general_i["rows"] or 1
	end
	return vmath.vector3(columns,rows,0)	
end

function M.loadbasics(self)
	M.dlgs=M.game["dlgs"]
	if M.dlgs then
		M.dlgs=M.dlgs[1]
	end
	M.theobjects=M.game["objects"]
	if M.theobjects then
		print("loaded objects");
		M.theobjects=M.theobjects[1]
	end
	M.theactors=M.game["actors"]
	if M.theactors then
		print("loaded actors");
		M.theactors=M.theactors[1]
	end
	M.theactionspool=M.game["actions"]
	if M.theactionspool then
		print("loaded actions");
		M.theactionspool=M.theactionspool[1]
		M.theactions=M.theactionspool["base"]
		if M.theactions then
			M.theactions=M.theactions[1]		
		end
		M.thewalkthru=M.theactionspool["walkthru"]
		if M.thewalkthru then
			M.thewalkthru=M.thewalkthru[1]		
		end
	end
	M.thelocations=M.game["locations"]
	if M.thelocations then
		print("loaded locations");
		M.thelocations=M.thelocations[1]
	end
	M.thescenes=M.game["scenes"]
	if M.thescenes then
		print("loaded scenes");
		M.thescenes=M.thescenes[1]
	end
end

function M.loadGame(self,name)	

	local systemname=sys.get_sys_info().system_name 

	config.load(self)
	if config.fullscreen==1 and defos and defos.is_fullscreen()==false then
		defos.toggle_fullscreen()
	end

    M.loadlanguage(self)

	M.lang=config.language	

	M.player=nil
	global_hero=nil
	M.bkg=nil
	M.efx=nil	
	M.rooom=nil
	
	advcmd.reset(self,M.cmds)

	M.resetvars(self)

	M.name=name

	M.gamestring = sys.load_resource("/adv/"..name..".json")
	M.game = json.decode(M.gamestring)	

	M.locstring = sys.load_resource("/adv/json/"..name.."_loc.json")
	M.loc = json.decode(M.locstring)	

	local localfile="/adv/json/"..name.."_"..M.lang.."_texts.json"
	M.txtstring = sys.load_resource(localfile)
	M.txt = json.decode(M.txtstring)	

	local config=M.readactiveconfig(self)

	M.general=M.game["general"]
	if M.general then
		local title
		M.general=M.general[1]
		title=M.general["name"]
		if title then
			print("game name:"..title);
			if defos then defos.set_window_title(title) end
		end
		local config_wantedY=M.general["height"]
		local config_wantedX=M.general["width"]
		if config_wantedY then
			msg.post("@render:", "update_wantedY",{wanted_Y=config_wantedY,wanted_X=config_wantedX})
			screen_h=math.abs(config_wantedY)
			screen_w = math.floor(screen_width*(screen_h/screen_height))	
		end
	end

	local hud=M.game["hud"]
	if hud then
		hud=hud[1]

		M.short=hud["short"]
		M.slotprefix=hud["slotprefix"]
		M.fullscreen=hud["fullscreen"]
		
		M.pause=M.addbtn(self,hud["btn_pause"])
		
		M.inventoryleft=M.addbtn(self,hud["btn_invleft"])
		M.inventoryright=M.addbtn(self,hud["btn_invright"])

		M.bottombar=M.addbtn(self,hud["bar_bottom"])
		M.topbar=M.addbtn(self,hud["bar_top"])

		if virtualrightclick then 
			local button_selector=hud["button_selector"]
			if button_selector then
				button_selector=button_selector[1]
				print("loaded buttonselector");
				M.buttonselector={}
				M.buttonselector.left=button_selector["lefticon"]
				M.buttonselector.right=button_selector["righticon"]
				M.buttonselector.size=M.getsize(button_selector["size"],24,24)
				M.buttonselector.grid=M.getgrid(self,button_selector)		
				M.buttonselector.anchor=button_selector["anchor"] or "topleft"
				M.buttonselector.count=M.buttonselector.grid.x*M.buttonselector.grid.y
			end
		end

		local dlgframe=hud["dlg.frame"]
		if dlgframe then
			dlgframe=dlgframe[1]
			if dlgframe then
				print("loaded dlg.frame");
				local title=dlgframe["title"]
				if title then
					title=title[1]
					M.dlgframetitle=title["icon"] or "hframe"	
				end
				local body=dlgframe["body"]
				if body then
					body=body[1]
					M.dlgframebody=body["icon"] or "hframe"	
				end
			end
		else
			M.dlgframetitle=hud["dlg.frame.title"] or "hframe"
			M.dlgframebody=hud["dlg.frame.body"] or "hframe"
		end
		
		local general_i=hud["inventory"]	
		if general_i then					
			print("loaded inventory");
			general_i=general_i[1]
			M.inventory.anchor=general_i["anchor"] or "topleft"
			M.inventory.grid=M.getgrid(self,general_i)		
			M.getblank(self,M.inventory,general_i)				
			M.inventory.size=M.getsize(general_i["size"],24,24)
			local cnt=general_i["cnt"]
			if cnt then
				cnt=cnt[1]
				M.inventory.cntsize=M.getsize(cnt["size"],10,10)
			end
		end	
		local general_as=hud["actorselector"]	
		if general_as then		
			print("loaded actorselector");
			general_as=general_as[1]
			M.actorselector.anchor=general_as["anchor"] or "topleft"
			M.actorselector.grid=M.getgrid(self,general_as)		
			M.getblank(self,M.actorselector,general_as)			
			M.actorselector.size=M.getsize(general_as["size"],24,24)
			M.actorselector.count=M.actorselector.grid.x*M.actorselector.grid.y
			M.actorselector.base=0
			M.actorselector.selected=0
		else
			M.actorselector.count=0
			M.actorselector.selected=0
		end	
		
		M.loadverbs(self,hud)
	end	
	M.inventory.count=M.inventory.grid.x*M.inventory.grid.y
	M.inventory.base=0

	local firstroom=config["starting"]

	M.playername=config["playas"]
	if M.playername==nil then
		M.playername="me"
	end	

	M.onfirstskip=config["onfirst_skip"]
	
	M.loadbasics()
	
	M.loadTPLAYERS(self)

	msg.post("hud", "hud_create",{dad=msg.url(".")})

	M.readbase(self,config)

	if defos then defos.set_cursor_visible(false) end

	return firstroom
end

function M.deleteRoom(self)
	for i,obj in ipairs(M.elements) do
		go.delete(obj.obj)
		obj.obj=nil
	end
	for i,obj in ipairs(M.actors) do
		if obj.obj then
			go.delete(obj.obj)
		end
		obj.obj=nil
	end		
	if M.player then
		go.delete(M.player)	
		global_hero=nil		
	end
	if M.bkg then
		go.delete(M.bkg)
		M.bkg=nil
	end
	if M.efx then
		go.delete(M.efx)
		M.efx=nil
	end
end		

function M.unloadRoom(self,force)
	if M.roomisamap then
		M.leavingamap=true
		M.roomisamap=nil
	end
	if M.musicroom then
		msg.post("DAGS:/sound#script", "unload_room",{name=M.musicroom})	
		M.musicroom=nil	
	end 
	if force==nil then
		local onexit
		if M.jumpto then
			onexit=M.getcmd(self,"_","onexitto_"..M.jumpto)
			if onexit then
				local CMD={}
				M.leavingroom=true
				advcmd.assigncommand(self,CMD,onexit)
				M.playcommands(self,CMD,true)
				M.leavingroom=nil
			end
		end
		onexit=M.getcmd(self,"_","onexit")
		if onexit then
			local CMD={}
			M.leavingroom=true
			advcmd.assigncommand(self,CMD,onexit)
			M.playcommands(self,CMD,true)
			M.leavingroom=nil
		end
	end	
	heropos=nil
	M.timers=nil
	M.selected=nil
	M.selectedwith=nil
	M.twoobjects=nil	
	M.bLoading=true				
	advcmd.deletecommands(self,M.cmds)
	msg.post("hud", "hud_enable",{enable=0})
	msg.post("hud","cursor_set",{status=-1,desc=""})		
	msg.post("hud","setactionprefix",{prefix=nil})
	if M.hardskipscene then
		M.deleteRoom(self)
		M.loadRoom(self,M.jumpto)
	else
		fader_request=msg.url(".")
		fader_request_msg="readytoload"
		msg.post("hud","fadeout")	
	end
end

function M.loadRoomActors(self,objects,atlas,thisroom)	
	for j,jobj in pairs(objects) do	
		jobj=jobj["obj"]
		local w=jobj["width"] or 0
		local h=jobj["height"] or 0
		local x=jobj["x"] or 0
		local y=jobj["y"] or 0
		local pos = vmath.vector3(x+w/2,screen_h-((y+h/2)),0)		
		local name=jobj["name"]
		local visible=jobj["show"]
		if name=="player" then
			M.player=factory.create("#actorsfactory",pos,nil,{player=1})					
			global_hero=M.player
			local animset=M.tplayer.animset
			if animset then
				msg.post(M.player,"set_name",{name=animset,head=M.tplayer["head_animset"],shadow=M.tplayer["shadow"]})
			end
			msg.post(M.player, "set_to",{destination=pos,follow=true})			
			for z, obj in ipairs(M.elements) do
				if obj.alert then
					msg.post(M.player,"addblockingarea",{pos=obj.pos,size=obj.size,name=obj.name})
				end
			end			
			local suffix=M.tplayer.suffix
			if suffix then				
				msg.post(M.player,"set_suffix",{name=suffix})
			end			
			local prop=M.tplayer.prop
			if prop then				
				msg.post(M.player,"set_prop",{name=prop})
			end			
			M.tplayer.room=thisroom
			if M.tplayer.inventoryloaded == nil then
				local baseinventory=M.tplayer.baseinventory
				if baseinventory then
					M.readbaseinventory(self,baseinventory)
					M.tplayer.inventoryloaded=true
				end
			end
			if M.tplayer and M.tplayer.name then
				msg.post(M.player, "set_ref",{ref="player"})		
			end
		else
			for j,actor in ipairs(M.tplayers) do	
				if actor.name==name then					
					if actor.room then
						local skip
						skip=1
					else
						local size = vmath.vector3(w,h,0)
						actor.room=thisroom
						actor.pos=pos
						if actor.size==nil then
							actor.size=size
						end
					end
				end
			end
		end
	end
end

function reverse(t)
	local n = #t
	local i = 1
	while i < n do
		t[i],t[n] = t[n],t[i]
		i = i + 1
		n = n - 1
	end
end

function M.loadRoomWalkarea(self,objects,atlas)
	for j,jobj in pairs(objects) do	
		jobj=jobj["obj"]
		local w=jobj["width"] or 0
		local h=jobj["height"] or 0
		local x=jobj["x"] or 0
		local y=jobj["y"] or 0
		local poly=jobj["polyline"]
		if x+y+w+h>0 then
			area={}
			area.x=tonumber(x)
			area.y=tonumber(y)
			area.w=tonumber(w)
			area.h=tonumber(h)
			M.rectarea=area
		end
		if poly then
			local polypnts=split(poly, ",")
			local p1={}
			p1.points={}		
			local cnt=0
			for k,kobj in ipairs(polypnts) do	
				local pnt=split(kobj, "-")
				local rx=tonumber(pnt[1])
				local ry=tonumber(pnt[2])
				p1.points[cnt+1]=vmath.vector3(rx+x,screen_h-(ry+y),0)
				cnt=cnt+1
			end
			if M.poly==nil then
				M.poly={}
			end
			reverse(p1.points)
			table.insert(M.poly,p1)			
		end
	end
end

function M.loadRoomObjects(self,objects,atlas)
	for j,jobj in pairs(objects) do	
		jobj=jobj["obj"]		
		local w=jobj["width"] or 0
		local h=jobj["height"] or 0
		local x=jobj["x"] or 0
		local y=jobj["y"] or 0
		local overlay=jobj["overlay"]
		local status=jobj["status"]
		local opos=nil
		local osz=nil
		tobj={}
		tobj.name=jobj["name"]
		tobj.name=string.gsub(tobj.name," +", "_")
		
		if overlay==nil then
			overlay="void"
		else					
			local overlaypos=jobj["overlaypos"]
			if overlaypos then
				local dig=split(overlaypos, ",")
				opos=vmath.vector3(dig[1],dig[2],0.1)
				osz=vmath.vector3(dig[3],dig[4],0.1)
			end
			tobj.overlay=overlay
			tobj.frames=jobj["frames"]
		end			

		tobj.desc=jobj["desc"]
		if tobj.desc==nil then
			tobj.desc=string.gsub(tobj.name,"_+", " ")
		end
		tobj.fulldesc=jobj["fulldesc"]
		tobj.quickuse=jobj["quickuse"]
		tobj.decalc=jobj["decalc"]
			
		local visible=jobj["show"]
		local nm=M.room.."_"..tobj.name.."_visible"		
		local lvisible=M.memory[nm]
		if lvisible then			
			visible=lvisible
		end
		
		if jobj["pickable"] then
			tobj.pickable=jobj["pickable"]					
		end		
		local lmoveto=M.memory[M.room.."_"..tobj.name.."_moveto"]
		if lmoveto then
			local lmovedir=M.memory[M.room.."_"..tobj.name.."_movedir"]
			tobj.moveto=lmoveto
			tobj.movedir=lmovedir
		elseif jobj["moveto"] then
			local rtdesc=jobj["desc"]
			tobj.moveto=jobj["moveto"]
			tobj.movedir=jobj["movedir"]
			if rtdesc==nil then
				rtdesc=M.thelocations[tobj.name]
				if rtdesc then					
					rtdesc=rtdesc[1]
					if rtdesc.desc then
						tobj.desc=rtdesc.desc
					end
				end
			end
		else
			tobj.movetocode=M.getcmd(self,tobj.name,"moveto")
			if tobj.movetocode==nil then
				tobj.clickcode=M.getcmd(self,tobj.name,"click")
			end
		end
		local lstatus=M.memory[M.room.."_"..tobj.name.."_status"]
		if status then			
			tobj.status=status	
		end
		if lstatus then
			tobj.status=lstatus
		end				

		if tobj.pickable then
			if table_find(inventory,tobj.desc) == true then
				tobj.disabled=true
				overlay=overlay.."_taken"
			end					
		end
		tobj.walkable=jobj["walkable"]
		tobj.alert=jobj["alert"]
		if tobj.walkable==nil then
			tobj.walkable=true
		end
		if visible==nil or visible==true or visible==1 then
			tobj.visible=true
		else
			tobj.visible=false
		end
		local zvalue
		if jobj["z"] then
			zvalue=0
		else
			zvalue="auto"
		end
		if jobj["polyline"] then
			local pos = vmath.vector3(x,y,0.1)										
			if opos==nil then
				opos=pos
			else
				opos.x=opos.x+osz.x/2
				opos.y=screen_h-(opos.y+osz.y/2)
			end					
			tobj.obj=factory.create("#items"..atlas.."factory",opos,nil,{position=opos,anim=hash(overlay),size=osz,visible=tobj.visible})					
			tobj.pos=pos
			tobj.points=jobj["polyline"]
			table.insert(M.elements, tobj)
		else
			local sz = vmath.vector3(w,h,0.1)
			local pos = vmath.vector3(x+w/2,screen_h-(y+h/2),0.1)					
			if osz==nil then
				osz=sz
			end
			if opos==nil then
				opos=pos						
			else
				opos.x=opos.x+osz.x/2
				opos.y=screen_h-(opos.y+osz.y/2)
			end					
			tobj.obj=factory.create("#items"..atlas.."factory",pos,nil,{position=opos,anim=hash(overlay),visible=tobj.visible})					
			tobj.pos=pos
			tobj.size=sz
			if tobj.status then
				M.setstatusanim(self,tobj)
			else
				if tobj.obj==nil then
					local n
					n=0
				else
					msg.post(tobj.obj, "changeanim",{anim=overlay,z=zvalue})
				end
			end
			
			table.insert(M.elements, tobj)
			if tobj.walkable==false then
				msg(M.player,"addblockingarea",{pos=tobj.pos,size=tobj.size})
			end										
		end
	end	
end

function M.playsilentcommands(self,bkgsx,CMD,cmds)
	if cmds then
		CMD.commands=cmds
	end
	if CMD.commands then
		local stop=false
		while(CMD.commands~=nil) do																				
			local current=CMD.commands[CMD.commandspos]
			if current==nil then
				break
			else
				for cmdx,val in pairs(current) do
					local sep=split(cmdx,",")
					local cmd=sep[1]
					local cmdobj=sep[2]								
					local cmdobjto=sep[3]

					if cmd=="else" then
						if CMD.conditionalcheck==CMD.conditionalpos then
							if CMD.conditional then
								if CMD.conditional==0 then
									CMD.conditional=1
								elseif CMD.conditional==1 then
									CMD.conditional=0
								end
							end
						end
						CMD.commandspos=CMD.commandspos+1
					elseif cmd=="endif" then				
						if CMD.conditionalcheck==CMD.conditionalpos then
							CMD.conditionalpos=CMD.conditionalpos-1
							CMD.conditionalcheck=CMD.conditionalpos
							if CMD.conditionalpos==0 then
								CMD.conditional=nil
							else
								CMD.conditional=CMD.conditionals[CMD.conditionalpos]
							end
						else	
							CMD.conditionalpos=CMD.conditionalpos-1
							if CMD.conditionalpos==0 then
								CMD.conditional=nil
								CMD.conditionalcheck=CMD.conditionalpos
							end
						end
						CMD.commandspos=CMD.commandspos+1
					else
						local skip=false
						if CMD.conditionalpos~=CMD.conditionalcheck or (CMD.conditional and CMD.conditional==0) then skip=true end
						if skip==true then
							if cmd=="elseif" and CMD.conditionalcheck==CMD.conditionalpos then
								cmd="if"
								skip=false
							end
						end
						if skip==true then
							if string.sub(cmd,1,2)=="if" then						
								CMD.conditionalpos=CMD.conditionalpos+1
							end
							CMD.commandspos=CMD.commandspos+1
						else
					
							if M.exec(self,CMD,cmd,cmdobj,cmdobjto,val,"S") then		
								CMD.commandspos=CMD.commandspos+1
							elseif M.ifcheck(self,CMD,cmd,val,cmdobj) then		
								CMD.commandspos=CMD.commandspos+1							
							elseif cmd=="enterfrom" then	
								M.doenterfrom(self,val,bkgsx,CMD,true)
								CMD.commandspos=CMD.commandspos+1
							elseif cmd=="game" then	
								if val=="new" then
									M.reset()
								end
								CMD.commandspos=CMD.commandspos+1
							else						
								if current["loadromm"] then		
									M.redirect=current["loadromm"]
								end
								stop=true
							end
							
						end
					end
				end
				if stop==true then
					break
				end
			end
		end
	end	
end

function M.loadtheroom(self)
	M.theroom=M.thelocations[M.room]	
	if M.theroom==nil then
		M.theroom=M.thescenes[M.room]	
	end
	if M.theroom then
		M.theroom=M.theroom[1]
		local template=M.theroom["_"]
		if template then
			template=template[1]			
			if template.template then
				M.doroomtemplate(self,nil,nil,nil,template.template)
			end
		end
	end
end

function M.addactor(self,actor)
	local pos=actor.pos
	local size=actor.size
	local a=factory.create("#actorsfactory",pos,nil,{player=0})
	local name=actor.name
	local animset=actor.animset
	if animset then
		msg.post(a,"set_name",{name=animset,head=actor["head_animset"],shadow=actor["shadow"]})
	end
	if pos.y==posy_notdefined then
		pos.y=M.fixundefinedy(self,actor.name,actor)
	end
	msg.post(a, "set_to",{destination=pos,ownz=M.ownz})	
	M.ownz=M.ownz+0.0001
	local lanim=actor.anim
	if lanim then
		msg.post(a, "lockanim",{anim=lanim})			
		--print("lockanim: "..actor.name.." "..lanim)
	end			
	local mactor=M.theactors[name]
	if mactor then
		mactor=mactor[1]
		if mactor.desc then
			actor.desc=mactor.desc
		end
		if mactor.fulldesc then
			actor.fulldesc=mactor.fulldesc
		end
	end
	actor.room=M.room
	actor.obj=a		
	actor.disabled=nil			
	if actor.visible==nil then
		actor.visible=true	
	end
	--msg.post(a, "show",{visible=actor["visible"]})	
	if actor.blocking then
		local lpos=vmath.vector3(pos.x+size.x/2,pos.y-size.y/2,0)
		local lsize=size
		local lname=name
		msg.post(M.player,"addblockingarea",{pos=pos,size=lsize,name=lname,alert=actor.blockingalert})
		--actor.blocking=true
	end						
	if actor.leader then		
		if M.tplayer and (actor.leader=="me" or actor.leader==M.tplayer.name) then 
			msg.post(a,"set_leader",{leader=M.player})	
		end
	end
	if actor.suffix then
		msg.post(a,"set_suffix",{name=actor.suffix})	
	end
	if actor.prop then
		msg.post(a,"set_prop",{name=actor.prop})	
	end
	if actor.visible==false then
		msg.post(a, "show",{visible=false})
	end
	msg.post(a, "set_ref",{ref=actor.name})			
	table.insert(M.actors, actor)

	if actor.status then
		if actor.onstatus then
			local label=M.room.."_"..actor.status
			local code=actor.onstatus[label]
			if code==nil then
				code=actor.onstatus[actor.status]
			end
			if code then
				local CMD={}
				advcmd.assigncommand(self,CMD,code)
				M.playcommands(self,CMD,true)
			end
		end
	end
end

function M.autosave(self)
	if M.general.autosave and M.player then
		M.dosavegame(self,nil,nil,nil,"slot_"..M.general.autosave)
		config.saveslots[tonumber(M.general.autosave)]="<autosave>"
		config.save(self)
	end
end

function M.dosetvisited(self,name)
	if name and name ~= "" then
		if M.visited[name]==nil then
			M.visited[name]=1
		else
			M.visited[name]=M.visited[name]+1
		end
	end
end

function M.loadRoom(self,name)

	-- print("room::"..name)		
	--M.hardright=nil
	M.bLoading=nil
	M.camerapos=vmath.vector3()
	if M.lastaction==nil then
		M.lastaction=vmath.vector3()
	end

	if M.room then
		M.lastmusic[M.room]=M.music
	end
	if M.leavingamap then
	else
		if M.lastroom==nil or M.lastroom=="" then
		else
			M.dosetvisited(self,M.lastroom)			
		end
		M.lastroom=M.room
	end
	M.room=name
	M.roomtemplate=nil
	M.roomdatatemplate=nil
	
	advcmd.reset(self,M.cmds)
	--M.waittime=0
	--M.waitfor=-1
	--M.commands=nil
	--M.commandspos=1	    
	--M.conditionals={}
	--M.conditionalspos=0
	
	M.selected=nil
	M.selectedwith=nil
	M.twoobjects=nil
	M.action=""
	M.auto_action=""
	M.timers=nil
	M.elements={}
	M.actors={}	
	M.poly=nil
	M.rectarea=nil
	M.player=nil
	global_hero=nil

	M.data=M.loc[name]

	if M.data==nil then
		print("undefined room: "..name)
	elseif M.data.sounds then
		M.musicroom="/sound#"..name
		msg.post("DAGS:/sound#script", "load_room",{name=M.musicroom})
	end

	M.dolabel(self,nil,"label","all","")

	M.loadtheroom(self)
	
	local atlas
	local bkg=M.data["bkg"]
	local bkgsx=2048
	if bkg then
		local img=bkg["name"]
		local align=bkg["align"]
		local width=bkg["width"]
		background_leftshift=0		
		if width then
			bkgsx=math.abs(width)
			background_width=bkgsx
			if bkgsx<screen_w then
				background_leftshift=(screen_w-bkgsx)/2
			end
		end
		atlas=bkg["atlas"]				
		if align==nil then
			align=M.general["bkgalign"]
		end
		if align then
			M.bkg=factory.create("#back"..atlas.."factory",nil,nil,{anim=hash(img),align=hash(align)})			
		else
			M.bkg=factory.create("#back"..atlas.."factory",nil,nil,{anim=hash(img)})			
		end
		msg.post(M.bkg, "update")
	end	
	local objects=M.data["objects"]
	local objectstemplate=nil
	if objects then
		M.loadRoomObjects(self,objects,atlas)
	end
	local actors=M.data["actors"]
	if actors then
		M.loadRoomActors(self,actors,atlas,M.room)
	end	
	local movearea=M.data["movearea"]
	if movearea then
		M.loadRoomWalkarea(self,movearea,atlas)
	end		
	local efx=M.data["efx"]
	if efx then
		local img=efx["name"]
		local align=efx["align"]
		local width=efx["width"]
		if width then
			bkgsx=math.abs(width)
		end
		atlas=efx["atlas"]				
		if align==nil then
			align=M.general["bkgalign"]
		end
		if align then
			M.efx=factory.create("#back"..atlas.."factory",nil,nil,{anim=hash(img),efx=1,align=hash(align)})			
		else
			M.efx=factory.create("#back"..atlas.."factory",nil,nil,{anim=hash(img),efx=1})			
		end
		msg.post(M.efx, "update")
	end
	M.ownz=0.0001
	for j,actor in ipairs(M.tplayers) do	
		if actor==M.tplayer then
		elseif actor.room==M.room or (M.tplayer.room==M.room and M.tplayer.follower and M.tplayer.follower[actor.name]==true) then
			M.addactor(self,actor)
		end
	end
	for j,actor in ipairs(M.tplayers) do	
		if actor==M.tplayer then
		elseif actor["room"]==M.room then
			if actor.faceto then		
				local pos
				if actor.faceto=="left" then
					pos=vmath.vector3(-8192,0,0)
				elseif actor.faceto=="right" then
					pos=vmath.vector3(8192,0,0)
				else
					pos=M.getactorpos(self,actor.faceto)
				end
				msg.post(actor.obj,"look_at",{lookat=pos,mode="lock"})	
			end
		end
	end
	
	msg.post("camera", "reset")

	local first
	
	
	if M.leavingamap then
		if M.lastroom==M.room then
			M.tplayer.reloadpos=M.tplayer.mapreloadpos
		end
		M.tplayer.mapreloadpos=nil
	end
		
	if M.reloadpos and M.player then
		msg.post(M.player, "set_to",{destination=M.reloadpos,follow=true})			
		M.reloadpos=nil
		local onenter=M.getcmd(self,"_","onreload")
		if onenter then
			local CMD={}
			advcmd.assigncommand(self,CMD,onenter)
			M.playcommands(self,CMD,true)
		end		
		local onmusic=M.getcmd(self,"_","onmusic")
		if onmusic then
			local CMD={}
			advcmd.assigncommand(self,CMD,onmusic)
			M.playcommands(self,CMD,true)
		else
			if M.lastmusic[M.room] then
				M.doplaymusic(self,M.lastmusic[M.room])
				M.lastmusic[M.room]=nil
			end
		end
		if M.short then
		else
			advcmd.setcommand(self,M.cmds,"declare","Game loaded")		
		end
	else
		local posjusreloaded=false
		if M.player and M.tplayer.reloadpos then
			msg.post(M.player, "set_to",{destination=M.tplayer.reloadpos,follow=true})			
			posjusreloaded=true
			M.tplayer.reloadpos=nil
		end
		local CMD=M.cmds
		if M.visited[M.room]==nil then
			if M.onfirstskip then
			else
				local config=M.getcmd(self,"_","onconfig")
				if config then 
					M.playsilentcommands(self,bkgsx,CMD,config) 
				end
				first=M.getcmd(self,"_","onfirst")
			end
			--M.visited[M.room]=1
		else
			--M.visited[M.room]=M.visited[M.room]+1
			first=M.getcmd(self,"_","onnext")
		end
		local onenter=M.getcmd(self,"_","onenter")
		if onenter then
			local CMD={}
			advcmd.assigncommand(self,CMD,onenter)
			M.playcommands(self,CMD,true)
		end
		local onmusic=M.getcmd(self,"_","onmusic")
		if onmusic then
			local CMD={}
			advcmd.assigncommand(self,CMD,onmusic)
			M.playcommands(self,CMD,true)
		end
		if first then
			--CMD.commands=first
			advcmd.assigncommand(self,CMD,first)
		else
			if posjusreloaded then
			else
				local enterfrom=M.getcmd(self,"_from",M.lastroom)
				if enterfrom==nil then
					if M.player then
						M.doenterfrom(self,"auto",bkgsx,CMD)
					end
				end
				if enterfrom then
					--CMD.commands=enterfrom
					advcmd.clonecommands(self,CMD,enterfrom)
					--advcmd.assigncommand(self,CMD,enterfrom)
				end
				local onentershow=M.getcmd(self,"_","onentershow")
				if onentershow then
					advcmd.addcommands(self,CMD,onentershow)
				end
			end
		end
		M.playsilentcommands(self,bkgsx,CMD)
	end

	if M.player==nil then
		msg.post("camera", "center")
	end
	
	M.updateinventory(self)

	M.leavingamap=nil

	--M.save(self,"auto")
	if M.hardskipscene then
	else
		fader_request=msg.url(".")
		fader_request_msg="endfadein"
		msg.post("hud","fadein")
	end
	
end

function M.pointinObjectH(self,obj,pnt,size)
	if obj.pos then
		if pnt.x >= obj.pos.x-obj.size.x/2 and pnt.x <= obj.pos.x+obj.size.x/2  then
			return true
		elseif size and math.abs(pnt.x-obj.pos.x)<math.min(size.x/2,obj.size.x/2) then
			return true
		end	
	end
	return false
end

function M.pointinObject(self,obj,pnt,size,actors)
	if obj.points then
		local x=pnt.x
		local y=screen_h-pnt.y
		local y = y and y or x.y
		local x = y and x or x.x

		local polySides = #obj.points - 1
		local j = polySides
		local res = false
		local bx=obj.pos.x
		local by=obj.pos.y

		for i = 1, polySides do
			local p1 = obj.points[i]
			local p2 = obj.points[j]
			local x1,y1 = p1.x+bx,p1.y+by
			local x2,y2 = p2.x+bx,p2.y+by
			if (y1 < y and y2 >= y or y2 < y and y1 >= y) and
			(x1 <= x or x2 <= x) then
				if x1 + (y-y1)/(y2-y1)*(x2-x1)< x then
					res = not res
				end
			end
			j=i
		end
		return res
	elseif obj.pos then
		local hL=obj.pos.x-obj.size.x/2
		local hR=obj.pos.x+obj.size.x/2
		local hT=obj.pos.y-obj.size.y/2
		local hB=obj.pos.y+obj.size.y/2
		if actors then
			if actors.suffix=="die" or actors.suffix=="dead" or actors.suffix=="down" or actors.suffix=="tied" then
				hB=obj.pos.y
			else
				hT=obj.pos.y
				hL=obj.pos.x-obj.size.x/4
				hR=obj.pos.x+obj.size.x/4
			end
		end
		if pnt.x >= hL and pnt.x <= hR and (pnt.y) >= hT and (pnt.y) <= hB then
			return true
		elseif size and math.abs(pnt.x-obj.pos.x)<math.min(size.x/2,obj.size.x/2) and (pnt.y) >= obj.pos.y-obj.size.y/2 and (pnt.y) <= obj.pos.y+obj.size.y/2 then
			return true
		end
	else
		local l
		l=0
	end
	return false
end

function M.getdesc(self,what,full)
	if full then
		if what.fulldesc then
			return M.gettrad(self,"fulldesc",what.fulldesc)
		else
			return nil
		end
	else
		return M.gettrad(self,"desc",what.desc)
	end
end

function M.handle_cursormovements(self,action)
	local screen_width = tonumber(sys.get_config("display.width"))
	local screen_height = tonumber(sys.get_config("display.height"))
	local dest=vmath.vector3()
	local ratio_y=screen_h/screen_height
	local ratio_x=screen_w/screen_width		
	local activity=0
	local kind=-1
	local selected=nil
	local mydesc=nil
	local mymovedir=nil
	local autoaction=nil
	dest.x=action.x*ratio_x
	dest.y=action.y*ratio_y
	if M.bPause or M.bDialog then
		local pos=vmath.vector3(action.x*ratio_x,action.y*ratio_y,0.99)
		msg.post("hud","cursor_set",{position=pos,status=activity,kind=kind,desc=mydesc,movedir=mymovedir})		
	elseif (M.cmds and (M.cmds.waitfor == advcmd.WAITFORDIALOGCLOSING)) then
		local pos=vmath.vector3(action.x*ratio_x,action.y*ratio_y,0.99)
		msg.post("hud","cursor_set",{position=pos,status=activity,kind=kind,desc=mydesc,movedir=mymovedir,silent=true})			
	else
		local validobj=nil
		if M.action then
			local t=M.verbs.list[M.action]
			if t then
				validobj=M.verbs.list[M.action].acton
			end
		end
		if (M.twoobjects==nil) and (validobj=="A" or validobj=="O") then
		else			
			if M.buttonselector and M.buttonselector.count>0 and M.pointinObject(self,M.buttonselector.hud,dest) then
				local x=math.floor((dest.x-(M.buttonselector.hud.pos.x-M.buttonselector.hud.size.x/2))/M.buttonselector.size.x)
				local y=math.floor((dest.y-(M.buttonselector.hud.pos.y-M.buttonselector.hud.size.y/2))/M.buttonselector.size.y)
				local i=x+(M.buttonselector.grid.y-y-1)*M.buttonselector.grid.x+1				
				if i==1 then
					activity=255
					kind=255
					M.action="left_button"
				elseif i==2 then
					activity=255
					kind=255
					M.action="right_button"
				end
			end
			if hud.enabledverbs == true and M.pointinObject(self,M.inventory.hud,dest) then
				local x=math.floor((dest.x-(M.inventory.hud.pos.x-M.inventory.hud.size.x/2))/M.inventory.size.x)
				local y=math.floor((dest.y-(M.inventory.hud.pos.y-M.inventory.hud.size.y/2))/M.inventory.size.y)
				local i=x+(M.inventory.grid.y-y-1)*M.inventory.grid.x+1
				obj=M.hudinventory[i+M.inventory.base]
				if obj and obj.disabled==nil then 
					activity=2
					kind=10
					selected=obj
				end
			end
			if hud.enabledverbs == true and M.actorselector.count>0 and M.pointinObject(self,M.actorselector.hud,dest) then
				local x=math.floor((dest.x-(M.actorselector.hud.pos.x-M.actorselector.hud.size.x/2))/M.actorselector.size.x)
				local y=math.floor((dest.y-(M.actorselector.hud.pos.y-M.actorselector.hud.size.y/2))/M.actorselector.size.y)
				local i=x+(M.actorselector.grid.y-y-1)*M.actorselector.grid.x+1
				obj=M.hudactorselector[i+M.actorselector.base]
				if obj and obj.disabled==nil then 
					if M.twoobjects then -- and M.action~="give"
					else
						activity=3
						kind=30
						selected=obj
					end
					-- gestire il CAMBIO di PERSONAGGIO
				end
			end
		end
			
		if activity==0 then
			dest.x=action.x*ratio_x+camerapos.x		
			if (M.twoobjects==nil) and (validobj=="I" or validobj=="O") then
			else			
				local defclick=M.verbs.defleftclickactors
				if M.virtualbtn==1 then					
					defclick=M.verbs.defrightclickactors
				end
				for i,obj in ipairs(M.actors) do
					if obj.disabled==nil and obj.visible==true then
						obj.pos=go.get_position(obj.obj)
						if	M.pointinObject(self,obj,dest,nil,obj) then 
							activity=1
							kind=20
							selected=obj	
							if defclick and defclick~="walkto" then
								autoaction=defclick
							end			
							break
						end
					end
				end
			end
		end
		if activity==0 then
			dest.x=action.x*ratio_x+camerapos.x		
			if (M.twoobjects==nil) and (validobj=="A" or validobj=="I") then
			else			
				local area=nil			
				for i,obj in ipairs(M.elements) do
					if obj.disabled==nil and obj.decalc==nil and obj.visible==true and M.pointinObject(self,obj,dest) then 
						local thisarea=obj.size.x*obj.size.y
						if area==nil then
							area=thisarea
							activity=1
							kind=1
							selected=obj
						elseif thisarea < area then
							area=thisarea
							activity=1
							kind=1
							selected=obj
						end							
					end
				end
				if area then
					local defclick=M.verbs.defleftclick
					if M.virtualbtn==1 then					
						defclick=M.verbs.defrightclick
					end
					mymovedir=selected["movedir"]
					if selected["moveto"]==nil and defclick and defclick~="walkto" then
						if M.getcmd(self,selected.name,defclick,2) then
							autoaction=defclick
						elseif defclick=="lookat" and M.getdesc(self,selected,true) then
							autoaction=defclick
						end
					end
				end
			end
		end
		if (M.twoobjects==nil) and (validobj=="I" or validobj=="O") then
		else
			if M.verbs.ignoreplayer then
			else
				local heropos
				local herosize
				if M.player then
					heropos=gop.get(M.player).rposition--go.get_position(M.player)
					herosize=M.tplayer["size"] 
				end
				if activity==0 and heropos then
					M.tplayer.pos.x=heropos.x
					M.tplayer.pos.y=heropos.y+herosize.y/4
					--M.tplayer.size.x=herosize.x/2
					--M.tplayer.size.y=herosize.y/2
					if M.pointinObject(self,M.tplayer,dest) then 
						activity=2
						kind=21
						selected=M.tplayer
					end
				end
			end
		end
		if M.twoobjects then			
			if selected==M.selectedwith then
			else		
				M.selectedwith=selected
				if M.selectedwith then
					mydesc=""..M.getdesc(self,M.selectedwith)
				else
					mydesc=""
				end			
			end						
		else
			if selected==M.selected then
			else			
				M.selected=selected
				if M.selected then
					mydesc=""..M.getdesc(self,M.selected)
				else
					mydesc=""
				end			
			end
		end
		local pos=vmath.vector3(action.x*ratio_x,action.y*ratio_y,0.99)
		if M.twoobjects then
			msg.post("hud","cursor_setobj",{position=pos,status=activity,kind=kind,desc=mydesc})		
		else
			local actpref=nil
			if autoaction then
				M.auto_action=autoaction
				actpref=M.verbs.list[autoaction].text
			else
				M.auto_action=""
			end
			msg.post("hud","cursor_set",{position=pos,status=activity,kind=kind,desc=mydesc,movedir=mymovedir,autoaction=actpref})					
		end
		if M.cmds.commands then
		else		
			dest.x=action.x*ratio_x+camerapos.x
			dest.y=action.y*ratio_y
			if M.player then msg.post(M.player, "look_at",{lookat=dest}) end
		end

		M.lastaction.x=action.x
		M.lastaction.y=action.y
	end
end

function M.toggle_fullscreen(self,skipsay)
	if M.fullscreen=="disabled" then
	else
		local CMD=M.cmds
		if defos then defos.toggle_fullscreen() end
		if CMD.commands==nil then
			if defos and defos.is_fullscreen() then
				config.fullscreen=0				
				if commands==nil and skipsay==nil then	
					if M.short then
					else
						advcmd.setcommand(self,CMD,"say","Good, now the world looks better")					
						M.playcommands(self,CMD)					
					end
				end
			else
				config.fullscreen=0
				if commands==nil and skipsay==nil then
					if M.short then
					else
						advcmd.setcommand(self,CMD,"say","Uh, now the world looks smaller")
						M.playcommands(self,CMD)					
					end
				end
			end				
			config.save(self)
		end
	end
end

function M.toggle_audio(self,music,sound,skipsay)
	local CMD=M.cmds			
	if music then
		if config.music==1 then							
			audio.stopmusic(self)
			config.music=0
		else
			config.music=1
		end
	end
	if sound then
		if config.sound==1 then							
			config.sound=0
		else
			config.sound=1
		end
	end	
	config.save(self)
	if M.music then
		if config.music==0 then
			if commands==nil and skipsay==nil then
				if M.short then
				else
					advcmd.setcommand(self,CMD,"say","Uh, now the world sounds silent")
					M.playcommands(self,CMD)
				end
			end
		else
			if M.music then
				audio.playmusic(self,"/audio#"..M.music)
				if CMD.commands==nil and skipsay==nil then
					if M.short then
					else
						advcmd.setcommand(self,CMD,"say","Good, now the world sounds better")
						M.playcommands(self,CMD)
					end
				end
			end
		end
	end	
end

function M.handle_onkeyevents(self,action_id,action)
	local info=sys.get_engine_info()
	 if action_id==hash("togglefullscreen") then
		if action.released then
			M.toggle_fullscreen(self)
		end
	elseif action_id==hash("exitfullscreen") then
		if action.released then
			if defos and defos.is_fullscreen() then
				defos.toggle_fullscreen()
				config.fullscreen=0	
				config.save(self)
			end
		end
	elseif action_id==hash("goleft") then			
		if info and info.is_debug then		
			if M.player then
				if action.pressed then
					local pos=gop.get(M.player).rposition--go.get_position(M.player)
					local ratio_x=screen_width/screen_w
					local ratio_y=screen_height/screen_h
					action.x=(pos.x-64)*ratio_x-camerapos.x*ratio_y
					action.y=pos.y*ratio_y
					M.handle_onclick(self,action,false)
				end
			end
		end
	elseif action_id==hash("goright") then	
		if info and info.is_debug then		
			if action.pressed then
				if action.pressed then
					local pos=gop.get(M.player).rposition--go.get_position(M.player)
					local ratio_x=screen_width/screen_w
					local ratio_y=screen_height/screen_h
					action.x=(pos.x+64)*ratio_x-camerapos.x*ratio_y
					action.y=pos.y*ratio_y
					M.handle_onclick(self,action,false)
				end
			end
		end
	elseif action_id==hash("quick") then	
		if action.pressed then
			M.quickmove=true
		elseif action.released then
			M.quickmove=nil
		end
	elseif action_id==hash("walkthru") then	
		if info and info.is_debug then
			local wt=M.thewalkthru[M.tplayer.name]
			local CMD=M.cmds
			local stop=false
			M.skipscene=true
			M.hardskipscene=true
			for k, cmd in pairs(wt) do
				if stop then 
					break 
				end
				for cmdx,val in pairs(cmd) do
					if cmdx == "moveto" then
						local movetocode=M.getcmd(self,val,"moveto")
						if movetocode then
							advcmd.addcommands(self,CMD,movetocode)
							M.playcommands(self,CMD)
						else
							M.doleavingto(self,val,CMD)		
							--M.playcommands(self,CMD)					
						end						
					elseif cmdx == "use" then
						local odd
						odd=1
					elseif cmdx == "talkto" then
						for i,obj in ipairs(M.actors) do
							if obj.disabled==nil and obj.visible==true then
								if obj.name==val then
									M.selected=obj
									M.handle_action(self,cmdx,msg,false)
									break
								end
							end
						end
					elseif cmdx == "select" then
						M.handledialog(self,"line_"..val)
					else
						local odd
						odd=1
					end
				end
			end		
			M.hardskipscene=false
			M.skipscene=false
		end		
	elseif action_id==hash("roomreload") then	
		if info and info.is_debug then
			if action.pressed then
				if true==false then
					M.jumpto="cutscene_giveusthedevice"
					M.unloadRoom(self)
				else
					local jsonfile="C:/tmp/main.json"
					local file=io.open(jsonfile,"r")
					if file then
						io.input(file)
						local gamestring=io.read("*all")
						io.close(file)		
						os.remove(jsonfile)	
						M.game = json.decode(gamestring)	
						M.loadbasics(self)
						M.loadtheroom(self)					
					end
				end
			end
		end
	elseif action_id==hash("skipscene") then	
		if info and info.is_debug then
			if action.released then
				M.skipscene=true
			end
		end
	elseif action_id==hash("loadgame") then	
		if action.released then
			M.load(self,slotname)
		end
	elseif action_id==hash("savegame") then	
		if action.released then
			local CMD=M.cmds
			M.save(self,slotname)
			if M.short then
			else
				if CMD.commands==nil then
					advcmd.setcommand(self,CMD,"say","Game saved")
					M.playcommands(self,CMD)
				end	
			end	
		end
	elseif action_id==hash("toggleaudio") then
		if action.released then
			M.toggle_audio(self,true,true)
		end
	end
end	

function M.handle_action(self,actionname,defaulttext,gonear)
	local action=M.getcmd(self,M.selected.name,actionname,M.selected.kind)
	local CMD=M.cmds
	if action then	
		if gonear and M.hardskipscene==nil then
			if M.selected.kind~=2 then
				advcmd.setcommand(self,CMD,"reach",M.selected.name)--M.selected.pos.x..","..M.selected.pos.y)
			end
		end
		advcmd.addcommands(self,CMD,action)
		M.playcommands(self,CMD)
	else
		if actionname=="lookat" then
			advcmd.setcommand(self,CMD,"declare",M.getdesc(self,M.selected,true),defaulttext)
		elseif actionname=="use" then
			local quick=M.getobjquickuse(self,M.selected.name)
			if quick then
				advcmd.setcommand(self,CMD,"declare",quick)
			else
				advcmd.setcommand(self,CMD,"declare",defaulttext)
			end
		else
			advcmd.setcommand(self,CMD,"declare",defaulttext)
		end
		M.playcommands(self,CMD)
	end
end

function M.resetaction(self)
	M.selected=nil
	M.selectedwith=nil
	M.twoobjects=nil
	M.action=""
	M.auto_action=""
	msg.post("hud","setactionprefix",{prefix=nil})
end

function M.walkto(self,dest,tomovedit)
	if tomovedit then
	else
		M.resetaction(self)
	end
	local herosize=M.tplayer["size"]
	local h=herosize.y
	local result, points,forceddest

	if M.player then heropos=gop.get(M.player).rposition end --go.get_position(M.player)
	if heropos then		
		if M.poly then
			local yoff=herosize.y*2/4
			local tdest=vmath.vector3(dest.x,dest.y,0)
			local startpos=vmath.vector3(heropos.x,(heropos.y-yoff),0)
			local endpos=vmath.vector3(dest.x,(dest.y-yoff),0)
			if dest.y<heropos.y-yoff then
				--dest.y=dest.y+yoff
			elseif dest.y>heropos.y+yoff*2/3 then
				--dest.y=dest.y-(yoff-yoff*1/3)
			elseif dest.y<=heropos.y+yoff*2/3 and dest.y>=heropos.y-yoff then
				--dest.y=heropos.y
			end
			endpos.y=dest.y-yoff

			if not pathfind.pointInPolygonSet(endpos.x,endpos.y,M.poly) then
				local points=pathfind.findLimit(startpos,endpos,M.poly)
				if points then
					dest.x=points.x
					dest.y=points.y+yoff
					endpos.x=points.x
					endpos.y=points.y
				end
			end
			
			-- still in development
			local result, points=pathfind.findPath(startpos,endpos,M.poly)
			if result==true then
				if points then
					dest.x=points[1].x
					dest.y=points[1].y
					dest.y=heropos.y
					dest.x=heropos.x
				else
					dest.x=dest.x
					dest.y=dest.y
				end
			else
				points=pathfind.findLimit(startpos,endpos,M.poly)
				if points then
					dest.x=points.x
					dest.y=points.y+yoff
					dest.y=heropos.y
					dest.x=heropos.x
				else
					dest.y=heropos.y
					dest.x=heropos.x					
				end
			end
		elseif M.rectarea then
			dest.y=heropos.y							
			if dest.x > M.rectarea.x+M.rectarea.w then
				dest.x = M.rectarea.x+M.rectarea.w
			end
			if dest.x < M.rectarea.x then
				dest.x = M.rectarea.x
			end
		end					
	end							
	msg.post(M.player, "move_to",{destination=dest,sdestination=sdest})			
end

function M.handle_onclick(self,action,right)
	local sdest=nil
	local dest=vmath.vector3()
	local screen_height=tonumber(sys.get_config("display.height"))
	local screen_width=tonumber(sys.get_config("display.width"))
	local ratio_y=screen_h/screen_height
	local ratio_x=screen_w/screen_width
	local herosize=M.tplayer["size"]
	local icon=nil
	local CMD=M.cmds
	if M.dialogcmd then
		CMD=M.dialogcmd
	end	
	dest.x=action.x*ratio_x		
	dest.y=action.y*ratio_y	

	if M.virtualbtn==1 then right=true end

	if M.hotspots then
	elseif M.bLoading then
	elseif M.bPause or M.bDialog then
		msg.post("hud", "on_input",{action_id=action_id,action=action})		
	else
		if CMD.commands then
			if action.pressed == true then	
				if CMD.waitfor==advcmd.WAITFORTALK or CMD.waitfor==advcmd.WAITFORWAIT then
					CMD.waittime=0
				end
			end
		else

			if hud.enabledverbs ==true then
				if M.pause and M.pause.hud and M.pointinObject(self,M.pause.hud,dest) then 
					msg.post("hud", "on_input",{action_id=action_id,action=action})		
					icon = 1
				elseif M.inventoryleft and M.inventoryleft.hud and M.pointinObject(self,M.inventoryleft.hud,dest) then 
						msg.post("hud", "on_input",{action_id=action_id,action=action})		
						icon = 1
					elseif M.inventoryright and M.inventoryright.hud and M.pointinObject(self,M.inventoryright.hud,dest) then 
					msg.post("hud", "on_input",{action_id=action_id,action=action})		
					icon = 1
				elseif M.pointinObject(self,M.verbs.hud,dest) then 
					msg.post("hud", "on_input",{action_id=action_id,action=action})		
					icon = 1
				end		
			end

			if icon then

			elseif action.released == true then	
				if (right==true and M.verbs.dragwith=="right") or (right==false and M.verbs.dragwith=="left") then
					local withprep=nil
					if M.action then
						local t=M.verbs.list[M.action]
						if t then
							withprep=M.verbs.list[M.action].prep							
						end
					end	
					if withprep and M.selected.usewith then

						if M.selectedwith then
							local action=M.getcmd(self,M.selectedwith.name,M.action..withprep.."_"..M.selected.name,M.selectedwith.kind)			
							if action == nil and M.selected.kind then
								action=M.getcmd(self,M.selected.name,M.action..withprep.."_"..M.selectedwith.name,M.selected.kind)			
								if action == nil then
									action=M.getcmd(self,M.selectedwith.name,M.action..withprep.."_all",M.selected.kind)			
								end
								if action == nil then
									action=M.getcmd(self,M.selected.name,M.action..withprep.."_all",M.selected.kind)			
								end
							end
							if action then			
								if M.selected["usefar"] == nil and M.selected.inventory~=1 then
									advcmd.setcommand(self,CMD,"reach",M.selectedwith.pos.x..","..M.selectedwith.pos.y)
								end
								advcmd.addcommands(self,CMD,action)
								M.playcommands(self,CMD)
							else
								advcmd.setcommand(self,CMD,"declare",M.verbs.usedeftext)
								M.playcommands(self,CMD)
							end
						end
						M.resetaction(self)
					end
				end
			elseif action.pressed == true then			
				local h
				local btnselector=nil

				if M.action=="left_button" then
					btnselector=true
					M.virtualbtn=0
					msg.post("hud","set_buttonselector",{right=false})
					M.action=""
				elseif M.action=="right_button" then
					btnselector=true
					M.virtualbtn=1
					msg.post("hud","set_buttonselector",{right=true})
					M.action=""
				end

				if M.player and btnselector==nil then 
					if M.selected and M.selected.inventory==1 then
					else
						local cdest=vmath.vector3()
						cdest.x=action.x*ratio_x+camerapos.x
						cdest.y=action.y*ratio_y
						msg.post(M.player,"look_at",{lookat=cdest,mode="turn"}) 
					end
				end
				
				if right==true then
					local used_right=nil
					if (M.selected==nil) then
					elseif M.selected.inventory==1 then
						M.action=M.verbs.defrightclickinv
						used_right=true
					elseif M.selected.actorselector==1 then
					elseif M.selected.human==3 then
						M.action=M.verbs.defrightclickactors
						used_right=true
					elseif M.selected.movedir then
					else
						M.action=M.verbs.defrightclick
						used_right=true
					end
					if M.autoresetbtnselector and used_right and M.virtualbtn==1 then
						M.virtualbtn=0
						msg.post("hud","set_buttonselector",{right=false})
					end
				else
					if M.selected and M.selected.inventory==1 and M.verbs.defleftclickinv then
						M.action=M.verbs.defleftclickinv
					else
						if M.action=="" and M.auto_action~="" then
							M.action=M.auto_action
						end
					end
				end
				if M.player then
					heropos=gop.get(M.player).rposition--go.get_position(M.player)
					h=vmath.vector3(heropos.x, heropos.y,0)
				else
					h=0
				end
				if M.selected and M.action=="" then
					if (M.selected.inventory==1 or M.selected.human==2) then
						M.action="lookat"
					elseif M.selected.actorselector==1 and M.selected.usewith==nil then
						M.action="switchto"
					end
				end
				if M.selected and M.action~="" then
					local keepit=0
					local withprep=nil
					local drag=nil
					if M.action then
						local t=M.verbs.list[M.action]
						if t then
							withprep=M.verbs.list[M.action].prep
							drag=M.verbs.list[M.action].drag
						end
					end					
					if withprep then
						if M.selected.usewith then
							if M.selectedwith == nil then
								if drag then
									if (right==true and M.verbs.dragwith=="right") or (right==false and M.verbs.dragwith=="left") then
										msg.post("hud","setdragicon",{dragicon=M.selected.icon,prefix=withprep})
										keepit=1
										M.twoobjects=1
									end
								else
									msg.post("hud","setactionprepprefix",{prefix=withprep})
									keepit=1
									M.twoobjects=1
								end
								
							else
								local action=M.getcmd(self,M.selectedwith.name,M.action..withprep.."_"..M.selected.name,M.selectedwith.kind)			
								if action == nil and M.selected.kind then
									action=M.getcmd(self,M.selected.name,M.action..withprep.."_"..M.selectedwith.name,M.selected.kind)			
									if action == nil then
										action=M.getcmd(self,M.selected.name,M.action..withprep.."_all",M.selected.kind)			
									end
								end
								if action then			
									if M.selected["usefar"] == nil and M.selected.inventory~=1 then
										advcmd.setcommand(self,CMD,"reach",M.selectedwith.pos.x..","..M.selectedwith.pos.y)
									end
									advcmd.addcommands(self,CMD,action)
									M.playcommands(self,CMD)
								else
									advcmd.setcommand(self,CMD,"declare",M.verbs.usedeftext)
									M.playcommands(self,CMD)
								end
							end
						else
							M.handle_action(self,"use",M.verbs.usedeftext,true)
						end		
					elseif M.action~="" then
						local what=M.verbs.list[M.action]
						if what then
							local msg=what.deftext or M.verbs.deftext
							if what.reach==0 then
								M.handle_action(self,M.action,msg)
							else
								M.handle_action(self,M.action,msg,true)
							end
						elseif M.action=="switchto" then
							M.handle_action(self,M.action,msg)
						end
					end
					if keepit==1 then
					else
						M.resetaction(self)						
					end
				elseif M.selected and M.action=="" and (M.player==nil or M.pointinObjectH(self,M.selected,h,herosize)) and (M.selected.moveto or M.selected.movetocode or M.selected.clickcode) then
					local movetocode=M.getcmd(self,M.selected.name,"moveto",msg)
					if movetocode then
						advcmd.addcommands(self,CMD,movetocode)
						M.playcommands(self,CMD)
					elseif M.selected.moveto then
						M.doleavingto(self,M.selected.moveto,CMD)
						--M.playcommands(self,CMD)						
					elseif M.selected.movetocode then
						advcmd.addcommands(self,CMD,M.selected.movetocode)
						M.playcommands(self,CMD)
					else
						advcmd.addcommands(self,CMD,M.selected.clickcode)
						M.playcommands(self,CMD)
					end
				else
					if M.player then
						dest.x=action.x*ratio_x+camerapos.x
						dest.y=action.y*ratio_y+camerapos.y
						if M.selected and M.selected.movedir then
							if M.quickmove then								
								M.jumpto=M.selected.moveto
								M.unloadRoom(self)
							else
								M.walkto(self,dest,true)
							end
						else
							if btnselector then
							else
								M.walkto(self,dest)
							end
						end
					end
				end
			else
				local what=1
			end
		end
	end
end

function M.handledialog(self,what)
	if M.dialog then
		local dig=split(what,"_")	
		local which=math.abs(dig[2])
		M.dialog[which].already=true
		M.dialogcmd={}
		advcmd.addcommands(self,M.dialogcmd,M.dialog[which].cmd)		
		--M.bDialog=false
		msg.post("hud","dismissdlg")
		advcmd.setwaitfor(self,M.dialogcmd,advcmd.WAITFORDIALOGCLOSING,0.5)
	end
end

function M.update(self,dt)
	local CMD=M.cmds
	if M.dialogcmd then
		CMD=M.dialogcmd
	end
	audio.update(self,dt)
	if CMD.commands then		
		if CMD.waitfor == advcmd.WAITFORDIALOG then						
			if CMD.bDialog==false then				
				CMD.waitfor=-1
				M.playcommands(self,CMD)
			end			
		elseif CMD.waitfor == advcmd.WAITFORANIM then
			if M.skipscene then CMD.animcnt=nil end
			if CMD.animcnt==nil then
				CMD.waitfor=-1
				if advcmd.ANIMSELECTED then
					msg.post(advcmd.ANIMSELECTED,"unlockanim")
					advcmd.ANIMSELECTED=nil
				end
				M.playcommands(self,CMD)
			end
		elseif CMD.waitfor == advcmd.WAITFORMOVEMENT then
			if M.skipscene then CMD.movecnt=nil end
			if CMD.movecnt==nil then
				CMD.waitfor=-1
				M.playcommands(self,CMD)
			end
		elseif CMD.waitfor == advcmd.WAITFORCAMERAMOVEMENT then
			if M.skipscene then CMD.cameramoveto=nil end
			if CMD.cameramoveto==nil then
				CMD.waitfor=-1
				M.playcommands(self,CMD)
			end			
		elseif (CMD.waitfor == advcmd.WAITFORDIALOGCLOSING) then
			if M.skipscene then CMD.waittime=0 end
			if CMD.waittime>0 then
				CMD.waittime=CMD.waittime-dt
			end
			if CMD.waittime<=0 then
				M.bDialog=false
				CMD.waittime=0
				CMD.waitfor=-1			
				M.playcommands(self,CMD)				
			end			
		elseif (CMD.waitfor == advcmd.WAITFORWAIT)or(CMD.waitfor == advcmd.WAITFORFORCEDWAIT) then
			if M.skipscene then CMD.waittime=0 end
			if CMD.waittime>0 then
				CMD.waittime=CMD.waittime-dt
			end
			if CMD.waittime<=0 then
				CMD.waittime=0
				CMD.waitfor=-1			
				M.playcommands(self,CMD)				
			end			
		elseif CMD.waitfor == advcmd.WAITFORTALK then
			if M.skipscene then CMD.waittime=0 end			
			if CMD.waittime>0 then
				CMD.waittime=CMD.waittime-dt
			end
			if CMD.waittime<=0 then
				CMD.waittime=0
				CMD.waitfor=-1
				if M.text[M.textindex+1]==nil or M.skipscene then
					M.text=nil
					M.textindex=nil
					M.textpos=nil
					M.textsize=nil
					M.textcodor=nil
					if M.talker then
						msg.post(M.talker,"unlockanim")
						M.talker=nil
					end
					msg.post("hud", "action.examine",{desc=""})
					M.playcommands(self,CMD)				
				else
					M.textindex=M.textindex+1
					M.docoresay(self,CMD,M.text[M.textindex],M.textcmd,M.textpos,M.textsize,M.textcolor)
				end
			end			
		end
	else
		if M.bPause or M.bDialog then
		else
			if M.timers then
				for k, v in pairs(M.timers) do
					v.timer=v.timer-dt
					if v.timer <= 0 then
						local ontimer=M.getcmd(self,"_","ontimer_"..v.name)
						if ontimer then
							local CMD=M.cmds
							advcmd.assigncommand(self,CMD,ontimer)
							M.timers[v.name]=nil
							M.playcommands(self,CMD)
						end
					end
				end
			end		
		end
		if camerapos and M.camerapos then
			if camerapos.x == M.camerapos.x then
			else
				M.camerapos.x=camerapos.x
				M.handle_cursormovements(self,M.lastaction)
			end
		end
	end

	if defos then
		if defos.is_mouse_in_view() then
			if defos.is_cursor_visible() then
				defos.set_cursor_visible(false)
			end
		else
			if defos.is_cursor_visible()==false then
				defos.set_cursor_visible(true)
			end
		end
	end
end	

function M.updateinventory(self)
	for i = 1, M.inventory.count do
		local ii=i+M.inventory.base
		if ii<=M.hudinventorycnt then
			local item=M.hudinventory[ii]
			msg.post("hud", "hud_setinv",{num=i,val=item["value"],img=item["icon"]})
		else
			msg.post("hud", "hud_setinv",{num=i,val=nil,img="void"})
		end
	end
end

function M.updateactorselector(self)
	for i = 1, M.actorselector.count do
		local ii=i+M.actorselector.base
		if ii<=M.hudactorselectorcnt then
			local item=M.hudactorselector[ii]
			msg.post("hud", "hud_setactsel",{num=i,val=item["value"],img=item["icon"]})
		else
			msg.post("hud", "hud_setactsel",{num=i,val=nil,img="void"})
		end
	end
end

function M.load(self,name)
	local ret=false
	local appname=sys.get_config("project.title")
	local my_file_path = sys.get_save_file(appname, "adv_"..name..".json")
	if my_file_path then
		local myfile = sys.load(my_file_path)
		if myfile and myfile["room"] then
			local room=myfile["room"]

			M.visited=myfile["visited"]
			M.tasks=myfile["tasks"]
			M.memory=myfile["memory"]
			M.lastmusic=myfile["lastmusic"]
			if M.lastmusic==nil then
				M.lastmusic={}
			end
			M.tplayers=myfile["tplayers"]
			M.playername=myfile["playername"]
			for j,actor in ipairs(M.tplayers) do	
				if actor.name==M.playername then
					M.tplayer=actor
				end
			end
			
			M.myinventory=myfile["inventory"]
			M.hudinventory=myfile["hudinventory"]
			M.hudinventorycnt=myfile["hudinventorycnt"]				
			M.updateinventory(self)	
			
			M.myactorselector=myfile["actorselector"]
			
			M.hudactorselector=myfile["hudactorselector"]
			M.hudactorselectorcnt=myfile["hudactorselectorcnt"]	
			M.updateactorselector(self)					
			if M.hudactorselectorcnt > 0 and M.playername and M.myactorselector[M.playername] then
				M.doselcharacter(self,nil,"selcharacter",nil,M.playername)
			end
			
			M.reloadpos=myfile["playerpos"]			
			
			M.lastroom=""
			if myfile["lastroom"] then
				M.room=myfile["lastroom"]			
			else
				M.room=""
			end
			M.jumpto=room
			M.unloadRoom(self,true)
			ret=true
		end
	end
	return ret
end

function M.save(self,name)
	local appname=sys.get_config("project.title")
	local my_file_path = sys.get_save_file(appname, "adv_"..name..".json")
	local myfile = {}

	-- M.dosetvisited(M.room) -- lo forza perché di base lo farebbe uscendo
	
	myfile["room"]=M.room
	myfile["lastroom"]=M.lastroom
	myfile["visited"]=M.visited
	myfile["tasks"]=M.tasks
	myfile["memory"]=M.memory
	myfile["lastmusic"]=M.lastmusic
	
	myfile["inventory"]=M.myinventory
	myfile["hudinventory"]=M.hudinventory
	myfile["hudinventorycnt"]=M.hudinventorycnt
	
	myfile["actorselector"]=M.myactorselector
	myfile["hudactorselector"]=M.hudactorselector
	myfile["hudactorselectorcnt"]=M.hudactorselectorcnt
	
	myfile["tplayers"]=M.tplayers
	myfile["playername"]=M.playername
	
	myfile["playerpos"]=gop.get(M.player).rposition--go.get_position(M.player)
	
	sys.save(my_file_path, myfile)
end

return M