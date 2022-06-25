local border=20
local textborder=5

local fr=0
local fg=0
local fb=0

fader_timing=0.5
fader_color_transparent=vmath.vector4(fr,fg,fb, 0)
fader_color_opaque=vmath.vector4(fr,fg,fb, 1)

fader_request=""
fader_request_msg=""

local function on_fading_completed(self, url, property)
	self.inputlock=nil
end

local function on_animation_done(self, url, property)
	if fader_request == "" then
		fader_request=""	 		
	else
		if fader_request_msg=="" then
			fader_request_msg="end"
		end
		msg.post(fader_request, fader_request_msg)
		fader_request=""	 
	end
end

function handle_touch(self,x,y,bpressed,breleased,dad)
	local abtns=self.abtns
	if self.dlgabtns then abtns=self.dlgabtns end
	for i,obj in ipairs(abtns) do
		if obj.cmd == nil then
		else
			local pos = gui.get_position(obj.btn)
			local size = gui.get_size(obj.btn)
			local pickup=false
			if fixedsize == 1 then
				if x >= pos.x - size.x /2 and x<= pos.x + size.x /2 and y >= pos.y - size.y /2 and y<= pos.y + size.y /2 then
					pickup=true
				end
			else
				pickup=gui.pick_node(obj.btn,x,y)
			end
			if pickup then
				if breleased then			
					if self.inputlock then
					else
						local pos=string.find(obj.cmd,"+")					
						if pos then
							local poscode=string.find(obj.cmd,"::")
							local scmd=string.sub(obj.cmd, 1,pos-1)
							local swhat
							local scode=nil
							if poscode == nil then
								swhat=string.sub(obj.cmd, pos+1)
							else
								swhat=string.sub(obj.cmd, pos+1, poscode-1)
								scode=string.sub(obj.cmd, poscode+2)
							end
							local wcmd="btn_cmd_"..scmd
							msg.post(obj.dad, wcmd, {what=swhat,code=scode})
						else
							local poscode=string.find(obj.cmd,"::")
							local wcmd="btn_cmd"
							local scode=nil
							if poscode then
								local newcmd=string.sub(obj.cmd, 1,poscode-1)
								scode=string.sub(obj.cmd, poscode+2)
								msg.post(obj.dad, wcmd, {cmd=newcmd,code=scode})
							else
								msg.post(obj.dad, wcmd, {cmd=obj.cmd,code=scode})
							end							
							
						end
					end
					obj.reqpressed=false
				else
					obj.reqpressed=true
				end
			end
		end
	end
end

function gui_init(self)
	self.abtns={}
	self.bbtns={}
	self.sbtns={}

	self.dlgabtns=nil
	self.dlgbbtns=nil
	self.dlgsbtns=nil
	
	self.black_box = nil
	self.jsonstring = nil
	self.data = nil

	self.left_box = nil
	self.right_box = nil
end

function gui_update(self, dt)
	local abtns=self.abtns
	if self.dlgabtns then abtns=self.dlgabtns end
	for i,obj in ipairs(abtns) do
		if obj.pressed == obj.reqpressed then
		else	
			obj.pressed=obj.reqpressed
			if obj.pressed then 
				gui.animate(obj.btn, gui.PROP_SCALE, vmath.vector3(obj.scale*0.9, obj.scale*0.9, obj.scale*0.9), gui.EASING_LINEAR, 0.25, 0.0)
			else
				gui.animate(obj.btn, gui.PROP_SCALE, vmath.vector3(obj.scale, obj.scale, obj.scale), gui.EASING_LINEAR, 0.25, 0.0)
			end
		end
		obj.reqpressed=false
	end
end

function abtn_delete(self,item)
	gui.delete_node(item)
end

function dlgabtn_delete(self,item)
	gui.delete_node(item)
end

function gui_blackbox(self)
	if self.black_box == nil then
		local w=screen_w
		local h=screen_h
		local new_position = vmath.vector3(w/2, h/2, 0)
		local new_size = vmath.vector3(w, h, 0)			
		self.black_box = gui.new_box_node(new_position, new_size)		
		gui.set_color(self.black_box, vmath.vector4(0, 0, 0, 0))			
	else
		local w=screen_w
		local h=screen_h
		local new_position = vmath.vector3(w/2, h/2, 0)
		local new_size = vmath.vector3(w, h, 0)			
		gui.set_position(self.black_box , new_position)
		gui.set_size(self.black_box , new_size)
	end
end

function gui_fadeout(self)
	gui_blackbox(self)
	gui.set_color(self.black_box, fader_color_transparent)	
	gui.animate(self.black_box, gui.PROP_COLOR, fader_color_opaque, gui.EASING_INOUTQUAD, fader_timing, 0.0, on_animation_done)
	for i,obj in ipairs(self.abtns) do
		local color=gui.get_color(obj.btn)
		gui.animate(obj.btn, gui.PROP_COLOR, vmath.vector4(color.x, color.y, color.z, 0), gui.EASING_INOUTQUAD, fader_timing, 0.0, on_animation_done)
	end		
	for i,obj in ipairs(self.bbtns) do
		local color=gui.get_color(obj)
		gui.animate(obj, gui.PROP_COLOR, vmath.vector4(color.x, color.y, color.z, 0), gui.EASING_INOUTQUAD, fader_timing, 0.0, on_animation_done)
	end		
	for i,obj in ipairs(self.sbtns) do
		gui.animate(obj, gui.PROP_COLOR, fader_color_transparent, gui.EASING_INOUTQUAD, fader_timing, 0.0, on_animation_done)
	end	
end

function gui_fadein(self)
	gui_blackbox(self)
	gui.set_color(self.black_box, fader_color_opaque)	
	gui.animate(self.black_box, gui.PROP_COLOR, fader_color_transparent, gui.EASING_INOUTQUAD, fader_timing, 0.0, on_animation_done)
	fader_timing=0.5
end

function gui_loadjson(self,filename,dad)
	self.jsonstring = sys.load_resource(filename)
	self.data = json.decode(self.jsonstring)
	self.jsondad = dad
	self.template = self.data["template"]
end 

function gui_unloadjson(self)
	self.template = nil
	self.jsonstring = nil
	self.data = nil 
end

function gui_dismissdlg(self,kill)
	if self.dlgabtns then
		for i,obj in ipairs(self.dlgabtns) do
			local color=gui.get_color(obj.btn)
			gui.animate(obj.btn, gui.PROP_COLOR, vmath.vector4(color.x, color.y, color.z, 0), gui.EASING_INOUTQUAD, fader_timing, 0.0, dlgabtn_delete)
		end		
		for i,obj in ipairs(self.dlgbbtns) do
			local color=gui.get_color(obj)
			gui.animate(obj, gui.PROP_COLOR, vmath.vector4(color.x, color.y, color.z, 0), gui.EASING_INOUTQUAD, fader_timing, 0.0, dlgabtn_delete)
		end		
		for i,obj in ipairs(self.dlgsbtns) do
			gui.animate(obj, gui.PROP_COLOR, vmath.vector4(0,0,0, 0), gui.EASING_INOUTQUAD, fader_timing, 0.0, dlgabtn_delete)
		end		
		if kill then
			self.dlgabtns=nil
			self.dlgbbtns=nil
			self.dlgsbtns=nil
		end
	end
end

function gui_playjson(self,section,btndad,autofade)

	gui_dismissdlg(self)

	if section then
	
		self.dlgabtns={}
		self.dlgbbtns={}
		self.dlgsbtns={}		

		local features={"img9","img","btn9","atlas","cut","x","xp","y","yp","w","wp","h","hp","text","align","color","font","cmd","scale","name"};
		local last_height=0

		for i,obj in ipairs(section) do
			if obj.template and self.template then
				for j,templ in ipairs(self.template) do
					base=templ[obj.template]
					if base then
						for f,ff in ipairs(features) do
							if base[1][ff] and obj[ff] == nil then
								obj[ff]=base[1][ff]
							end
						end						
						break
					end
				end
			end
			if obj.kind=="btn" or obj.kind==nil then
				if obj.disable==1 then
				else
					local ww=screen_w
					local x=obj.x or 0.5
					local y=0.5
					local w=obj.w or 0.1
					local h=obj.h or 0.1					
					local size = vmath.vector3(screen_w*w, screen_h*h, 0)
					local ntbn	
					if obj.hp then
						h=obj.hp
						size = vmath.vector3(screen_w*w, h, 0)
					end
					if obj.wp then
						w=obj.wp
						if w < 0 then
							w=screen_w+w							
						end
						size = vmath.vector3(w, h, 0)
					end					
					if obj.yp then
						if obj.yp>=0 then
							y=obj.yp
						else
							y=screen_h+obj.yp
						end						
					else
						y=(1-obj.y)
						y=screen_h*y
					end
					if obj.cxp then
						if obj.cxp>=0 then
							x=screen_w/2+obj.cxp
						else
							x=screen_w/2+obj.cxp
						end
					elseif obj.xp then
						if obj.xp>=0 then
							x=obj.xp
						else
							x=screen_w+obj.xp
						end
					else
						x=screen_w*x
					end			
					if wanted_Y and wanted_Y>480 then						
						if y>screen_h-32 then
							if x==screen_w/2 then
								y=y-16
							else
								y=y-8
							end
						end
					end

					local pos = vmath.vector3(x, y, 0.0)
					local nbtns=nil
					if obj.textbox then
						if obj.align == "center" then
							pos.x=pos.x+size.x/2
						elseif obj.align == "right" then
							pos.x=pos.x+size.x
						else
							pos.x=pos.x--+size.x/2							
						end						
						pos.y=pos.y-size.y/2
						nbtn=gui.new_text_node(pos,obj.textbox)
						if obj.font then
							gui.set_font(nbtn, obj.font)
						end			
						if obj.scale then
							gui.set_scale(nbtn, vmath.vector3(obj.scale,obj.scale,obj.scale))
						end			
						if obj.align == "center" then
							gui.set_pivot(nbtn,gui.PIVOT_CENTER)
						elseif obj.align == "right" then
							gui.set_pivot(nbtn,gui.PIVOT_E)
						else
							gui.set_pivot(nbtn,gui.PIVOT_W)
						end
						gui.set_line_break(nbtn,true)						
						gui.set_size(nbtn,size)
					elseif obj.text then
						metrics=gui.get_text_metrics(obj.font,obj.text)
						pos.y=pos.y+metrics.height/2-textborder/4-1
						nbtn=gui.new_text_node(pos,obj.text)
						if obj.font then
							gui.set_font(nbtn, obj.font)
						end
						if obj.scale then
							gui.set_scale(nbtn, vmath.vector3(obj.scale,obj.scale,obj.scale))
						end
						if obj.color then
							local col=color2vect(obj.color)
							gui.set_color(nbtn, col)						
						end						
						metrics=gui.get_text_metrics_from_node(nbtn)
						size = vmath.vector3(metrics.width,metrics.height, 0)
						size.x=size.x+textborder*2
						if obj.scale then
							sizex=size.x*obj.scale
						else
							sizex=size.x
						end
						if obj.textborder=="no" then
						else
							size.y=size.y+textborder
						end
						gui.set_size(nbtn,size)
						if obj.align == "left" then
							pos.x=pos.x+sizex/2-textborder
							pos.y=pos.y-textborder/2
							gui.set_position(nbtn, pos)
						elseif obj.align == "right" then
							pos.x=pos.x-sizex/2+textborder
							pos.y=pos.y-textborder/2
							gui.set_position(nbtn, pos)
						else
							pos.x=pos.x
							pos.y=pos.y-textborder/2
							gui.set_position(nbtn, pos)
						end							

						gui.set_layer(nbtn, "front")
						
					elseif obj.img then 	
						nbtn=gui.new_box_node(pos, size)
						gui.set_size_mode(nbtn,gui.SIZE_MODE_AUTO)
						gui.set_texture(nbtn,obj.atlas)
						gui.play_flipbook(nbtn,obj.img)									
						if obj.scale then
							gui.set_scale(nbtn, vmath.vector3(obj.scale,obj.scale,obj.scale))
						end
						gui.set_layer(nbtn, "front")
						if obj.btn9 then
							ofy=0
							size=gui.get_size(nbtn)		
							if last_height>0 then
								ofy=(last_height-size.y)/2								
								size.x=last_height
								size.y=last_height
							else
								ofy=border/2								
								size.x=size.x+border
								size.y=size.y+border
							end
							local cutpx=16
							if obj.cut then
								cutpx=obj.cut
							end
							poss=vmath.vector3(0,-1, 0)			
							nbtns=gui.new_box_node(poss, size)
							--gui.set_size_mode(nbtn,gui.SIZE_MODE_MANUAL)
							--gui.set_size(nbtn, size)
							local cut=vmath.vector4(cutpx,cutpx,cutpx,cutpx)
							gui.set_slice9(nbtns, cut)					
							gui.set_texture(nbtns,obj.atlas)
							gui.play_flipbook(nbtns,obj.btn9)		
							gui.set_color(nbtns, vmath.vector4(1, 1, 1, 0))		
							gui.set_parent(nbtns, nbtn)				
							gui.set_layer(nbtns, "shadow")
							table.insert(self.bbtns, nbtns)								
						end
					elseif obj.img9 then
						local cutpx=8
						if obj.cut then
							cutpx=obj.cut
						end
						if cutpx*2 > size.y then
							cutpx=size.y/2
						end
						pos.x=pos.x+size.x/2
						pos.y=pos.y-size.y/2
						nbtn=gui.new_box_node(pos, size)
						local cut=vmath.vector4(cutpx,cutpx,cutpx,cutpx)
						gui.set_slice9(nbtn, cut)					
						gui.set_texture(nbtn,obj.atlas)
						gui.play_flipbook(nbtn,obj.img9)		
						gui.set_layer(nbtn, "front")			
					elseif obj.img3 then
						pos.x=pos.x+size.x/2
						pos.y=pos.y-size.y/2
						nbtn=gui.new_box_node(pos, size)
						local cut=vmath.vector4(8,8,8,8)
						gui.set_slice9(nbtn, cut)					
						gui.set_texture(nbtn,obj.atlas)
						gui.play_flipbook(nbtn,obj.img3)		
						gui.set_layer(nbtn, "front")				
					end
					local name=obj.name
					if name then
						gui.set_id(nbtn, name)
						if nbtns then
							gui.set_id(nbtns, name.."s")
						end
					end
					local color=gui.get_color(nbtn)
					local pivot=gui.get_pivot(nbtn)
					local xa=gui.get_xanchor(nbtn)
					local ya=gui.get_yanchor(nbtn)
					gui.set_color(nbtn, vmath.vector4(color.x, color.y, color.z, 0))
					local item= {label=name,btn=nbtn,cmd=obj.cmd,dad=btndad,pressed=false,reqpressed=false,scale=obj.scale or 1.0,alpha=obj.alpha or 1.0}				
					table.insert(self.dlgabtns, item)				
				end
			elseif obj.kind=="panel" then
			end			
		end		
		if autofade == nil or autofade ==1 then
			self.inputlock=true
			for i,obj in ipairs(self.dlgabtns) do
				local color=gui.get_color(obj.btn)
				gui.animate(obj.btn, gui.PROP_COLOR, vmath.vector4(color.x, color.y, color.z, obj.alpha), gui.EASING_INOUTQUAD, fader_timing, 0.0,on_fading_completed)
			end			
			for i,obj in ipairs(self.dlgbbtns) do
				local color=gui.get_color(obj)
				gui.animate(obj, gui.PROP_COLOR, vmath.vector4(color.x, color.y, color.z, 1), gui.EASING_INOUTQUAD, fader_timing, 0.0,on_fading_completed)
			end			
			for i,obj in ipairs(self.dlgsbtns) do
				gui.animate(obj, gui.PROP_COLOR, vmath.vector4(0,0,0,0.25), gui.EASING_INOUTQUAD, fader_timing, 0.0,on_fading_completed)
			end
		end
		msg.post(btndad, "json_loaded")			
	else
		self.dlgabtns=nil
		self.dlgbbtns=nil
		self.dlgsbtns=nil
	end	
end

function gui_on_message(self, message_id, message, sender)
	if message_id == hash("loadjson") then
		gui_loadjson(self,message.filename,message.dad)
	elseif message_id == hash("setdad") then
		self.jsondad=message.dad
	elseif message_id == hash("unloadjson")	then
		gui_unloadjson(self)
	elseif message_id == hash("dismissdlg")	then
		gui_dismissdlg(self,true)
	elseif message_id == hash("playjson") then
		local section=self.data[message.table]
		local btndad=self.jsondad
		gui_playjson(self,section,btndad,message.autofade)		
	elseif message_id == hash("fadein") then
		gui_fadein(self)
	elseif message_id == hash("fadeout") then
		gui_fadeout(self)
	elseif message_id == hash("on_input") then	
		local world_scale_x = screen_w/screen_width
		local world_scale_y = screen_h/screen_height	
		if	fixedsize == 1 then
			world_scale_x = fixed_world_scale_x
			world_scale_y = fixed_world_scale_y
		end
		if  message.action.touch then
			for i, tpoint in ipairs(message.action.touch) do
				local x=tpoint.x*world_scale_x
				local y=tpoint.y*world_scale_y
				handle_touch(self,x,y,tpoint.pressed,tpoint.released,pressed)
			end	
		else 
			local x=message.action.x*world_scale_x
			local y=message.action.y*world_scale_y
			handle_touch(self,x,y,message.action.pressed,message.action.released,pressed)
		end								
	end
end