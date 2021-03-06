spr_lamp_off=98
spr_lamp_on=96
spr_lamp2_off=106
spr_lamp2_on=104

spr_lamp_nr_base=84

cls_lamp=subclass(typ_lamp,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.is_on=(tile)%4==0
 self.is_solid=false
 -- lookup number in tile below
 self.nr=room:tile_at(self.pos/8+v2(0,1))-spr_lamp_nr_base
 self.spr=tile-(self.is_on and 0 or 2)
 self.light_position=self.pos+v2(6,6)
 add(room.lamps,self)
end)

tiles[spr_lamp_off]=cls_lamp
tiles[spr_lamp_on]=cls_lamp
tiles[spr_lamp2_off]=cls_lamp
tiles[spr_lamp2_on]=cls_lamp

function cls_lamp:update()
 -- flickering light logic
 if self.timer!=nil then
  local tick=frame%self.timer[1]
  if tick==0 or tick==self.timer[2] then
   self.is_on=not self.is_on
   if (self.is_on) sfx(40)
  end
 end

 -- these lights turn off after a while
 if self.countdown!=nil and self.is_on then
  self.countdown_t-=dt
  if self.countdown_t<0 then
   room:handle_lamp_off(self)
   sfx(31)
  end
 end
end

function cls_lamp:toggle()
 self.is_on=not self.is_on
 if self.countdown!=nil and self.is_on then
  self.countdown_t=self.countdown
 end
end

function cls_lamp:draw()
 local is_light=self.is_on
 if (self.timer and maybe(0.01)) is_light=true

 if self.countdown_t!=nil
    and self.countdown_t<3
    and self.is_on then
  local max_blk=64
  local min_blk=16
  local h=max_blk-min_blk
  local blk=min_blk+(self.countdown_t/self.countdown)*h
  if should_blink(blk,blk) then
   is_light=false
  end
 end

 if not is_light then
  pal(9,0)
  pal(7,0)
 elseif is_light and not self.is_on then
  pal(13,1)
  pal(5,1)
  pal(6,1)
  pal(7,13)
 end
 local spr_=self.spr+(is_light and 0 or 2)
 spr(spr_,self.pos.x,self.pos.y,2,2)
 pal()

 if self.countdown_t!=nil and self.countdown_t>0 and is_light then
  local x1=self.pos.x
  local y1=self.pos.y-5
  rect(x1,y1,x1+10,y1+2,1)
  rect(x1+9*(1-self.countdown_t/self.countdown),y1+1,x1+9,y1+1,9)
 end
end

spr_switch_on=69
spr_switch_off=70

cls_lamp_switch=subclass(typ_lamp_switch,cls_actor,function(self,pos,tile)
 cls_actor._ctr(self,pos)
 self.pos=pos
 self.hitbox=hitbox(v2(-2,-2),v2(12,12))
 self.is_solid=false

 -- lookup number in tile above
 self.nr=room:tile_at(self.pos/8+v2(0,-1))-spr_lamp_nr_base
 self.is_on=tile==spr_switch_on
 self.player_near=false
 add(room.switches,self)
end)

tiles[spr_switch_off]=cls_lamp_switch
tiles[spr_switch_on]=cls_lamp_switch

function cls_lamp_switch:update()
 self.player_near=player!=nil and player:collides_with(self)
 if self.player_near and btnp(btn_action) then
  room:handle_switch_toggle(self)
 end
end

function cls_lamp_switch:draw()
 local spr_=self.is_on and spr_switch_on or spr_switch_off
 spr(spr_,self.pos.x,self.pos.y)
 -- self:bbox():draw(7)
end

function cls_lamp_switch:draw_text()
 if player!=nil and self.player_near and should_blink(24) and player.on_ground then
  palt(0,false)
  bstr("\x97",self.pos.x-1,self.pos.y-8,0,6)
  palt()
 end
end
