spr_moth=5

cls_moth=subclass(typ_moth,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.flip=v2(false,false)
 self.target=self.pos:clone()
 self.target_dist=0
 self.found_lamp=false
 self.new_light_debounce=0
 del(actors,self)
 moth=self
end)

tiles[spr_moth]=cls_moth

function cls_moth:get_nearest_lamp()
 local nearest_lamp=nil
 local dir=nil
 local dist=10000
 for _,lamp in pairs(room.lamps) do
  if lamp.is_on then
   local v=(lamp.pos-self.pos)
   local d=v:magnitude()
   if d<dist and d<moth_los_limit then
    if self:is_lamp_visible(lamp) then
     dist=d
     dir=v
     nearest_lamp=lamp
    end
   end
  end
 end

 return nearest_lamp,dir
end

function cls_moth:is_lamp_visible(lamp)
 local ray=bbox(self.pos+v2(4,4),lamp.light_position)
 for tile in all(room.solid_tiles) do
  local p=isect(ray,tile)
  if (#p>0) return false
 end
 return true
end

function cls_moth:update()
 self.new_light_debounce=max(0,self.new_light_debounce-1)

 if self.new_light_debounce==0 then
  local nearest_lamp=self:get_nearest_lamp()
  if nearest_lamp!=nil then
   local p=nearest_lamp.light_position
   if p!=self.target then
    self.new_light_debounce=60
    self.target=nearest_lamp.light_position
    self.found_lamp=true
   end
  elseif self.found_lamp then
   self.found_lamp=false
   self.target=self.pos:clone()
  end
 end

 local maxvel=.3
 local accel=0.1
 local dist=self.target-self.pos
 self.target_dist=dist:magnitude()

 local spd=v2(0,0)
 if self.target_dist>1 then
  spd=dist/self.target_dist*maxvel
 end
 self.spd.x=appr(self.spd.x,spd.x,accel)+mrnd(accel)
 self.spd.y=appr(self.spd.y,spd.y,accel)+mrnd(accel)

 if (abs(self.spd.x)>0.2) self.flip.x=self.spd.x<0
 self:move(self.spd)

 self.spr=spr_moth+flr(frame/8)%3
end

function cls_moth:draw()
 -- if self.target_dist>3 and frame%16<8 then
 --  fillp(0b0011001111001100)
 --  line(self.pos.x+4,self.pos.y+4,self.target.x,self.target.y,5)
 --  fillp()
 -- end
 bspr(self.spr,self.pos.x,self.pos.y,self.flip.x,self.flip.y,0)
end