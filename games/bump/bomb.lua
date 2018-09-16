spr_bomb=23
cls_bomb_pwrup=subclass(cls_pwrup,function(self,pos)
 cls_pwrup._ctr(self,pos)
end)
tiles[spr_bomb]=cls_bomb_pwrup

function cls_bomb_pwrup:on_powerup_start(player)
 local bomb=cls_bomb.init(player)
end

fuse_cols={8,9,10,7}
cls_fuse_particle=class(function(self,pos)
 self.x=pos.x
 self.y=pos.y
 local v=angle2vec(rnd(1.0))
 self.spd_x=v.x
 self.spd_y=v.y
 self.t=0
 self.lifetime=rnd(2)
 add(particles,self)
end)

function cls_fuse_particle:update()
 self.t+=dt
 self.x+=self.spd_x+mrnd(1)
 self.y+=self.spd_y+mrnd(1)
 if (self.t>self.lifetime) del(particles,self)
end

function cls_fuse_particle:draw()
 circfill(self.x,self.y,3,fuse_cols[flr(#fuse_cols*self.t/self.lifetime)])
 printh("fuse particle draw")
end

cls_bomb=subclass(cls_actor,function(self,player)
 cls_actor._ctr(self,v2(player.x,player.y))
 self.is_thrown=false
 self.is_solid=false
 self.player=player
 self.time=5
 self.name="bomb"
end)

function cls_bomb:update()
 local solid=solid_at_offset(self,0,0)
 local is_actor,actor=self:is_actor_at(0,0)

 printh("update bomb")
 if (rnd(1)<0.1) cls_fuse_particle.init(v2(self.x,self.y))

 self.time-=dt
 if self.time<0 then
  make_blast(self.x,self.y,45)
  del(actors,self)
 end

 if self.is_thrown then
  local actor,a=self:is_actor_at(0,0)
  if actor then
   make_blast(self.x,self.y,45)
   del(actors,self)
  end

  local gravity=0.12
  local maxfall=2
  self.spd_y=appr(self.spd_y,maxfall,gravity)
  cls_actor.move_x(self,self.spd_x)
  cls_actor.move_y(self,self.spd_y)
 elseif self.player.is_dead then
  del(actors,self)
 else
  self.x=self.player.x
  self.y=self.player.y-8
  if btnp(btn_action,self.player.input_port) then
   self.is_thrown=true
   self.spd_x=(self.player.flip.x and -1 or 1) + self.player.spd_x
   self.spd_y=-1
   self.is_solid=true
  end
 end
end

function cls_bomb:draw()
 spr(spr_bomb,self.x,self.y)
end

add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
add(power_up_tiles,spr_bomb)
