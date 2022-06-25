local M = {}

M.LEFT=1
M.RIGHT=2

function M.update_prop(self)
	if self.prop then
		msg.post("#spriteobj", "play_animation", { id = hash(self.prop..self.current_anim) })
	else
		msg.post("#spriteobj", "play_animation", { id = hash("void") })
	end
end

function M.play_animation(self,anim,facing)
	if facing and facing ~= self.current_facing then
		self.current_facing=facing
		if facing==M.LEFT then
			sprite.set_hflip("#sprite", true)
			sprite.set_hflip("#spritehead", true)
			sprite.set_hflip("#spriteobj", true)
			sprite.set_hflip("#shadow", true)
		else
			sprite.set_hflip("#sprite", false)
			sprite.set_hflip("#spritehead", false)
			sprite.set_hflip("#spriteobj", false)
			sprite.set_hflip("#shadow", false)
		end
	end
	if anim==nil or anim == self.current_anim then return end
	msg.post("#sprite", "play_animation", { id = hash(anim) })
	if self.head then
		msg.post("#spritehead", "play_animation", { id = hash(self.head..anim) })
	end
	if self.prop then
		msg.post("#spriteobj", "play_animation", { id = hash(self.prop..anim) })
	end
	self.current_anim = anim
end

return M

