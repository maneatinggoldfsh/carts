pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
typ_player=0
typ_smoke=1
typ_bubble=2
typ_button=3
typ_spring=4
typ_spawn=5
typ_spikes=6
typ_room=7
typ_moving_platform=8
typ_particle=9
typ_moth=10
typ_camera=11
typ_lamp=12
typ_lamp_switch=13
typ_exit=14
typ_game=15

flg_solid=0
flg_ice=1

btn_right=1
btn_left=0
btn_jump=4
btn_action=5

jump_button_grace_interval=10
jump_max_hold_time=15

ground_grace_interval=12

moth_los_limit=200

dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}


function class (typ,init)
  local c = {}
  c.__index = c
  c._ctr=init
  c.typ=typ
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.typ=typ
    return self
  end
  return c
end

function subclass(typ,parent,init)
 local c=class(typ,init)
 return setmetatable(c,{__index=parent})
end


-- vectors
local v2mt={}
v2mt.__index=v2mt

function v2(x,y)
 local t={x=x,y=y}
 return setmetatable(t,v2mt)
end

function v2mt.__add(a,b)
 return v2(a.x+b.x,a.y+b.y)
end

function v2mt.__sub(a,b)
 return v2(a.x-b.x,a.y-b.y)
end

function v2mt.__mul(a,b)
 if (type(a)=="number") return v2(b.x*a,b.y*a)
 if (type(b)=="number") return v2(a.x*b,a.y*b)
 return v2(a.x*b.x,a.y*b.y)
end

function v2mt.__div(a,b)
 if (type(a)=="number") return v2(b.x/a,b.y/a)
 if (type(b)=="number") return v2(a.x/b,a.y/b)
 return v2(a.x/b.x,a.y/b.y)
end

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:min(v)
 return v2(min(self.x,v.x),min(self.y,v.y))
end

function v2mt:max(v)
 return v2(max(self.x,v.x),max(self.y,v.y))
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:sqrmagnitude()
 return self.x^2+self.y^2
end

function v2mt:normalize()
 return self/self:magnitude()
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
end

function v2mt:flr()
 return v2(flr(self.x),flr(self.y))
end

function v2mt:clone()
 return v2(self.x,self.y)
end

dir_down=0
dir_right=1
dir_up=2
dir_left=3

vec_down=v2(0,1)
vec_up=v2(0,-1)
vec_right=v2(1,0)
vec_left=v2(-1,0)

function dir2vec(dir)
 local dirs={v2(0,1),v2(1,0),v2(0,-1),v2(-1,0)}
 return dirs[(dir+4)%4]
end

function angle2vec(angle)
 return v2(cos(angle),sin(angle))
end

-- intersects a line with a bounding box and returns
-- the intersection points
-- line is a bbox representing a segment
function isect(l,b)
 local res={}

 -- check if we can eliminate the bbox altogether
 local vmin=l.aa:min(l.bb)
 local vmax=l.aa:max(l.bb)
 if b.aa.x>vmax.x or
    b.aa.y>vmax.y or
    b.bb.x<vmin.x or
    b.bb.y<vmin.y then
  return {}
 end

 local d=l.bb-l.aa

 local p=function(u)
  return l.aa+d*u
 end

 local check_y=function(u)
  if u<=1 and u>=0 then
   local y1=l.aa.y+u*d.y
   if y1>=b.aa.y and y1<=b.bb.y then
    add(res,p(u))
   end
  end
 end
 local check_x=function(u)
  if u<=1 and u>=0 then
   local x1=l.aa.x+u*d.x
   if x1>=b.aa.x and x1<=b.bb.x then
    add(res,p(u))
   end
  end
 end

 local baa=b.aa-l.aa
 local bba=b.bb-l.aa
 if d.x!=0 then
  check_y(baa.x/d.x)
  check_y(bba.x/d.x)
 end
 if d.y!=0 then
  check_x(baa.y/d.y)
  check_x(bba.y/d.y)
 end

 return res
end
local bboxvt={}
bboxvt.__index=bboxvt

function bbox(aa,bb)
 return setmetatable({aa=aa,bb=bb},bboxvt)
end

function bboxvt:w()
 return self.bb.x-self.aa.x
end

function bboxvt:h()
 return self.bb.y-self.aa.y
end

function bboxvt:is_inside(v)
 return v.x>=self.aa.x
 and v.x<=self.bb.x
 and v.y>=self.aa.y
 and v.y<=self.bb.y
end

function bboxvt:str()
 return self.aa:str().."-"..self.bb:str()
end

function bboxvt:draw(col)
 rect(self.aa.x,self.aa.y,self.bb.x-1,self.bb.y-1,col)
end

function bboxvt:to_tile_bbox()
 local x0=max(0,flr(self.aa.x/8))
 local x1=min(room.dim.x,(self.bb.x-1)/8)
 local y0=max(0,flr(self.aa.y/8))
 local y1=min(room.dim.y,(self.bb.y-1)/8)
 return bbox(v2(x0,y0),v2(x1,y1))
end

function bboxvt:collide(other)
 return other.bb.x > self.aa.x and
   other.bb.y > self.aa.y and
   other.aa.x < self.bb.x and
   other.aa.y < self.bb.y
end

function bboxvt:clip(p)
 return v2(mid(self.aa.x,p.x,self.bb.x),
           mid(self.aa.y,p.y,self.bb.y))
end

function bboxvt:shrink(amt)
 local v=v2(amt,amt)
 return bbox(v+self.aa,self.bb-v)
end


local hitboxvt={}
hitboxvt.__index=hitboxvt

function hitbox(offset,dim)
 return setmetatable({offset=offset,dim=dim},hitboxvt)
end

function hitboxvt:to_bbox_at(v)
 return bbox(self.offset+v,self.offset+v+self.dim)
end

function hitboxvt:str()
 return self.offset:str().."-("..self.dim:str()..")"
end


frame=0
dt=0
lasttime=time()
room=nil

actors={}
tiles={}
crs={}
draw_crs={}

moth=nil
player=nil

levels={
 {pos=v2(0,16),
  dim=v2(16,16),
 },
 {pos=v2(16,0),
  dim=v2(32,16),
  timer_lights={{4,128,16}}
 },
 {pos=v2(0,0),
  dim=v2(16,16)}
}

is_fading=false
is_screen_dark=false

cls_camera=class(typ_camera,function(self)
 self.target=nil
 self.pull=16
 self.pos=v2(0,0)
 -- this is where to add shake
end)

function cls_camera:set_target(target)
 self.target=target
 self.pos=target.pos:clone()
end

function cls_camera:compute_position()
 return v2(self.pos.x-64,self.pos.y-64)
end

function cls_camera:abs_position(p)
 return p+self:compute_position()
end

function cls_camera:pull_bbox()
 local v=v2(self.pull,self.pull)
 return bbox(self.pos-v,self.pos+v)
end

function cls_camera:update()
 if (self.target==nil) return
 local b=self:pull_bbox()
 local p=self.target.pos
 if (b.bb.x<p.x) self.pos.x+=min(p.x-b.bb.x,4)
 if (b.aa.x>p.x) self.pos.x-=min(b.aa.x-p.x,4)
 if (b.bb.y<p.y) self.pos.y+=min(p.y-b.bb.y,4)
 if (b.aa.y>p.y) self.pos.y-=min(b.aa.y-p.y,4)
 self.pos=room:bbox():shrink(64):clip(self.pos)
end

-- from trasevol_dog
function add_shake(p)
 local a=rnd(1)
 shkx+=p*cos(a)
 shky+=p*sin(a)
end

function update_shake()
 if abs(shkx)+abs(shky)<1 then
  shkx=0
  shky=0
 end
 
 shkx*=-0.4-rnd(0.1)
 shky*=-0.4-rnd(0.1)
end

-- shkx,shky=0,0
--   add_shake(8)

function rspr(s,x,y,angle)
 angle=(angle+4)%4
 local x_=(s%16)*8
 local y_=flr(s/16)*8
 local f=function(i,j,p)
   pset(x+i,y+j,p)
 end
 if angle==1 then
  f=function(i,j,p)
   pset(x+7-j,y+i,p)
  end
 elseif angle==2 then
  f=function(i,j,p)
   pset(x+7-i,y+7-j,p)
  end
 elseif angle==3 then
  f=function(i,j,p)
   pset(x+j,y+7-i,p)
  end
 end
 for i=0,7 do
  for j=0,7 do
   local p=sget(x_+i,y_+j)
   if (p!=0) f(i,j,p)
  end
 end
end

function should_blink(n)
 return flr(frame/n)%2==1
end

function palbg(col)
 for i=1,16 do
  pal(i,col)
 end
end

function bspr(s,x,y,flipx,flipy,col)
 palbg(col)
 spr(s,x-1,y,1,1,flipx,flipy)
 spr(s,x+1,y,1,1,flipx,flipy)
 spr(s,x,y-1,1,1,flipx,flipy)
 spr(s,x,y+1,1,1,flipx,flipy)
 pal()
 spr(s,x,y,1,1,flipx,flipy)
end

function bstr(s,x,y,c1,c2)
	for i=0,2 do
	 for j=0,2 do
	  if not(i==1 and j==1) then
	   print(s,x+i,y+j,c1)
	  end
	 end
	end
	print(s,x+1,y+1,c2)
end



-- fade
function fade(fade_in)
 is_fading=true
 is_screen_dark=false
 local p=0
 for i=1,10 do
  local i_=i
  local time_elapsed=0
  
  if (fade_in==true) i_=10-i
  p=flr(mid(0,i_/10,1)*100)
 
  while time_elapsed<0.1 do
   for j=1,15 do
    local kmax=(p+(j*1.46))/22
    local col=j
    for k=1,kmax do
     if (col==0) break
     col=dpal[col]
    end
    pal(j,col,1)
   end
   
   if not fade_in and p==100 then
    -- this needs to be set before the final yield
    -- draw will continue to be called even if we are
    -- in a coresumed cr, if i understand this correctly
    is_screen_dark=true
   end  
   
   time_elapsed+=dt
   yield()
  end
 end

 is_fading=false
end


-- functions
function appr(val,target,amount)
 return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
 return v>0 and 1 or v<0 and -1 or 0
end

function rndsign()
 return rnd(1)>0.5 and 1 or -1
end

function round(x)
 return flr(x+0.5)
end

function maybe(p)
 if (p==nil) p=0.5
 return rnd(1)<p
end

function mrnd(x)
 return rnd(x*2)-x
end

--- function for calculating
-- exponents to a higher degree
-- of accuracy than using the
-- ^ operator.
-- function created by samhocevar.
-- source: https://www.lexaloffle.com/bbs/?tid=27864
-- @param x number to apply exponent to.
-- @param a exponent to apply.
-- @return the result of the
-- calculation.
function pow(x,a)
  if (a==0) return 1
  if (a<0) x,a=1/x,-a
  local ret,a0,xn=1,flr(a),x
  a-=a0
  while a0>=1 do
      if (a0%2>=1) ret*=xn
      xn,a0=xn*xn,shr(a0,1)
  end
  while a>0 do
      while a<1 do x,a=sqrt(x),a+a end
      ret,a=ret*x,a-1
  end
  return ret
end

function v_idx(pos)
 return pos.x+pos.y*128
end

-- tween routines from https://github.com/JoebRogers/PICO-Tween
function inoutquint(t, b, c, d)
 t = t / d * 2
 if (t < 1) return c / 2 * pow(t, 5) + b
 return c / 2 * (pow(t - 2, 5) + 2) + b
end

function inexpo(t, b, c, d)
 if (t == 0) return b
 return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end

function outexpo(t, b, c, d)
 if (t == d) return b + c
 return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

function inoutexpo(t, b, c, d)
 if (t == 0) return b
 if (t == d) return b + c
 t = t / d * 2
 if (t < 1) return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
 return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end

function cr_move_to(obj,target,d,easetype)
 local t=0
 local bx=obj.pos.x
 local cx=target.x-obj.pos.x
 local by=obj.pos.y
 local cy=target.y-obj.pos.y
 while t<d do
  t+=dt
  if (t>d) return
  obj.pos.x=round(easetype(t,bx,cx,d))
  obj.pos.y=round(easetype(t,by,cy,d))
  yield()
 end
end
function tick_crs(crs_)
 for cr in all(crs_) do
  if costatus(cr)!='dead' then
   local status,err=coresume(cr)
   if (not status) printh("cr error "..err)
  else
   del(crs_,cr)
  end
 end
end

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
end

function add_draw_cr(f)
 local cr=cocreate(f)
 add(draw_crs,cr)
 return cr
end

function wait_for(t)
 while t>0 do
  t-=dt
  yield()
 end
end

actor_cnt=0

cls_actor=class(typ_actor,function(self,pos)
 self.pos=pos
 self.id=actor_cnt
 actor_cnt+=1
 self.spd=v2(0,0)
 self.is_solid=true
 self.hitbox=hitbox(v2(0,0),v2(8,8))
 add(actors,self)
end)

function cls_actor:bbox(offset)
 if (offset==nil) offset=v2(0,0)
 return self.hitbox:to_bbox_at(self.pos+offset)
end

function cls_actor:str()
 return "actor["..tostr(self.id)..",t:"..tostr(self.typ).."]"
end

function cls_actor:move(o)
 self:move_x(o.x)
 self:move_y(o.y)
end

function cls_actor:move_x(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step
   if not self:is_solid_at(v2(step,0)) then
    self.pos.x+=step
   else
    self.spd.x=0
    break
   end
  end
 else
  self.pos.x+=amount
 end
end

function cls_actor:move_y(amount)
 if self.is_solid then
  while abs(amount)>0 do
   local step=amount
   if (abs(amount)>1) step=sign(amount)
   amount-=step
   if not self:is_solid_at(v2(0,step)) then
    self.pos.y+=step
   else
    self.spd.y=0
    break
   end
  end
 else
  self.pos.y+=amount
 end
end

function cls_actor:is_solid_at(offset)
 return solid_at(self:bbox(offset))
end

function cls_actor:collides_with(other_actor)
 return self:bbox():collide(other_actor:bbox())
end

function cls_actor:get_collisions(typ,offset)
 local res={}

 local bbox=self:bbox(offset)
 for actor in all(actors) do
  if actor!=self and actor.typ==typ then
   if (bbox:collide(actor:bbox())) add(res,actor)
  end
 end

 return res
end

function draw_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.draw!=nil) a:draw()
 end
end

function update_actors(typ)
 for a in all(actors) do
  if ((typ==nil or a.typ==typ) and a.update!=nil) a:update()
 end
end

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
 if self.target_dist>3 and frame%16<8 then
  fillp(0b0011001111001100)
  line(self.pos.x+4,self.pos.y+4,self.target.x,self.target.y,5)
  fillp()
 end
 bspr(self.spr,self.pos.x,self.pos.y,self.flip.x,self.flip.y,0)
end
cls_button=class(typ_button,function(self,btn_nr)
 self.btn_nr=btn_nr
 self.is_down=false
 self.is_pressed=false
 self.down_duration=0
 self.hold_time=0
 self.ticks_down=0
end)

function cls_button:update()
 self.is_pressed=false
 if btn(self.btn_nr) then
  self.is_pressed=not self.is_down
  self.is_down=true
  self.ticks_down+=1
 else
  self.is_down=false
  self.ticks_down=0
  self.hold_time=0
 end
end

function cls_button:was_recently_pressed()
 return self.ticks_down<jump_button_grace_interval and self.hold_time==0
end

function cls_button:was_just_pressed()
 return self.is_pressed
end

function cls_button:is_held()
 return self.hold_time>0 and self.hold_time<jump_max_hold_time
end
cls_room=class(typ_room,function(self,r)
 self.pos=r.pos
 self.dim=r.dim
 self.player_spawn=nil
 self.moth_spawn=nil
 self.lamps={}
 self.switches={}
 self.solid_tiles={}

 room=self

 -- initialize tiles
 for i=0,self.dim.x-1 do
  for j=0,self.dim.y-1 do
   local p=v2(i,j)
   local tile=self:tile_at(p)
   -- add solid tile bboxes for collision check
   if fget(tile,flg_solid) then
    add(self.solid_tiles,bbox(p*8,p*8+v2(8,8)))
   end
   if (tile==spr_spawn_point) self.player_spawn=p*8
   if (tile==spr_moth) self.moth_spawn=p*8
   local t=tiles[tile]
   if (t!=nil) t.init(p*8,tile)
  end
 end
end)

function cls_room:bbox()
 return bbox(v2(0,0),self.dim*8)
end

function cls_room:get_friction(tile,dir)
 local accel=0.3
 local decel=0.2

 if (fget(self:tile_at(tile),flg_ice)) accel,decel=min(accel,0.1),min(decel,0.03)

 return accel,decel
end

function cls_room:draw()
 palt(14,true)
 palt(0,false)
 map(self.pos.x,self.pos.y,0,0,self.dim.x,self.dim.y,flg_solid+1)
 palt()
end

function cls_room:spawn_player()
 local spawn=cls_spawn.init(self.player_spawn:clone())
 main_camera:set_target(spawn)
end

function cls_room:tile_at(pos)
 local v=self.pos+pos
 return mget(v.x,v.y)
end

function solid_at(bbox)
 if bbox.aa.x<0
  or bbox.bb.x>room.dim.x*8
  or bbox.aa.y<0
  or bbox.bb.y>room.dim.y*8 then
   return true,nil
 else
  return tile_flag_at(bbox,flg_solid)
 end
end

function ice_at(bbox)
 return tile_flag_at(bbox,flg_ice)
end

function tile_at(x,y)
 return room:tile_at(v2(x,y))
end

function tile_flag_at(bbox,flag)
 local bb=bbox:to_tile_bbox()
 for i=bb.aa.x,bb.bb.x do
  for j=bb.aa.y,bb.bb.y do
   if fget(tile_at(i,j),flag) then
    return true,v2(i,j)
   end
  end
 end
 return false
end
spr_wall_smoke=54
spr_ground_smoke=51
spr_full_smoke=48
spr_ice_smoke=57
spr_slide_smoke=60

cls_smoke=subclass(typ_smoke,cls_actor,function(self,pos,start_spr,dir)
 cls_actor._ctr(self,pos+v2(mrnd(1),0))
 self.flip=v2(maybe(),false)
 self.spr=start_spr
 self.start_spr=start_spr
 self.is_solid=false
 self.spd=v2(dir*(0.3+rnd(0.2)),-0.0)
end)

function cls_smoke:update()
 self:move(self.spd)
 self.spr+=0.2
 if (self.spr>self.start_spr+3) del(actors,self)
end

function cls_smoke:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end
cls_particle=subclass(typ_particle,cls_actor,function(self,pos,lifetime,sprs)
 cls_actor._ctr(self,pos+v2(mrnd(1),0))
 self.flip=v2(false,false)
 self.t=0
 self.lifetime=lifetime
 self.sprs=sprs
 self.is_solid=false
 self.weight=0
 self.spd=v2(0,0)
end)

function cls_particle:random_flip()
 self.flip=v2(maybe(),maybe())
end

function cls_particle:random_angle(spd)
 self.spd=angle2vec(rnd(1))*spd
end

function cls_particle:update()
 self.t+=dt
 if self.t>self.lifetime then
   del(actors,self)
   return
 end

 self:move(self.spd)
 local maxfall=2
 local gravity=0.12*self.weight
 self.spd.y=appr(self.spd.y,maxfall,gravity)
end

function cls_particle:draw()
 local idx=flr(#self.sprs*(self.t/self.lifetime))
 local spr_=self.sprs[1+idx]
 spr(spr_,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
end


cls_gore=subclass(typ_gore,cls_particle,function(self,pos)
 cls_particle._ctr(self,pos,0.5+rnd(2),{35,36,37,38,38})
 self.hitbox=hitbox(v2(2,2),v2(3,3))
 self.spd=angle2vec(rnd(0.5))
 self.spd.y*=1.5
 -- self:random_angle(1)
 self.spd.x*=0.5+rnd(0.5)
 self.weight=0.5+rnd(1)
 self:random_flip()
end)

function cls_gore:update()
 cls_particle.update(self)

 -- i tried generalizing this but it's just easier to write it out
 local dir=sign(self.spd.x)
 local ground_bbox=self:bbox(v2(0,1))
 local ceil_bbox=self:bbox(v2(0,-1))
 local side_bbox=self:bbox(v2(dir,0))
 local on_ground=solid_at(ground_bbox)
 local on_ceil=solid_at(ceil_bbox)
 local hit_side=solid_at(side_bbox)
 if on_ground then
  self.spd.y*=-0.9
 elseif on_ceil then
  self.spd.y*=-0.9
 elseif hit_side then
  self.spd.x*=-0.9
 end
end

function make_gore_explosion(pos)
 for i=0,30 do
  cls_gore.init(pos)
 end
end
player=nil

cls_player=subclass(typ_player,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 -- player is a special actor
 del(actors,self)
 player=self
 main_camera:set_target(self)

 self.flip=v2(false,false)
 self.jump_button=cls_button.init(btn_jump)
 self.spr=1
 self.hitbox=hitbox(v2(2,0),v2(4,8))
 self.atk_hitbox=hitbox(v2(1,0),v2(6,4))

 self.prev_input=0
 -- we consider we are on the ground for 12 frames
 self.on_ground_interval=0
end)

function cls_player:smoke(spr,dir)
 return cls_smoke.init(self.pos,spr,dir)
end

function cls_player:kill()
 make_gore_explosion(self.pos)
 player=nil
 sfx(0)
 add_cr(function()
  wait_for(1)
  room:spawn_player()
 end)
end

function cls_player:update()
 -- from celeste's player class
 local input=btn(btn_right) and 1
    or (btn(btn_left) and -1
    or 0)

 self.jump_button:update()

 local maxrun=1
 local accel=0.3
 local decel=0.2

 local ground_bbox=self:bbox(vec_down)
 local on_ground,tile=solid_at(ground_bbox)
 local on_ice=ice_at(ground_bbox)

 if on_ground then
  self.on_ground_interval=ground_grace_interval
 elseif self.on_ground_interval>0 then
  self.on_ground_interval-=1
 end
 local on_ground_recently=self.on_ground_interval>0

 if not on_ground then
  accel=0.2
  decel=0.1
 else
  if tile!=nil then
   accel,decel=room:get_friction(tile,dir_down)
  end

  if input!=self.prev_input and input!=0 then
   if on_ice then
    self:smoke(spr_ice_smoke,-input)
   else
    -- smoke when changing directions
    self:smoke(spr_ground_smoke,-input)
   end
  end

  -- add ice smoke when sliding on ice (after releasing input)
  if input==0 and abs(self.spd.x)>0.3
     and (maybe(0.15) or self.prev_input!=0) then
   if on_ice then
    self:smoke(spr_slide_smoke,-input)
   end
  end
 end
 self.prev_input=input

 -- x movement
 if abs(self.spd.x)>maxrun then
  self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
 elseif input != 0 then
  self.spd.x=appr(self.spd.x,input*maxrun,accel)
 else
  self.spd.x=appr(self.spd.x,0,decel)
 end
 if (self.spd.x!=0) self.flip.x=self.spd.x<0

 -- y movement
 local maxfall=2
 local gravity=0.12

 -- slow down at apex
 if abs(self.spd.y)<=0.15 then
  gravity*=0.5
 elseif self.spd.y>0 then
  -- fall down fas2er
  gravity*=2
 end

 -- wall slide
 local is_wall_sliding=false
 if input!=0 and self:is_solid_at(v2(input,0))
    and not on_ground and self.spd.y>0 then
  is_wall_sliding=true
  maxfall=0.4
  if (ice_at(self:bbox(v2(input,0)))) maxfall=1.0
  local smoke_dir = self.flip.x and .3 or -.3
  if maybe(.1) then
    local smoke=self:smoke(spr_wall_smoke,smoke_dir)
    smoke.flip.x=self.flip.x
  end
 end

 -- jump
 if self.jump_button.is_down then
  if self.jump_button:is_held()
    or (on_ground_recently and self.jump_button:was_recently_pressed()) then
   if self.jump_button:was_recently_pressed() then
    self:smoke(spr_ground_smoke,0)
   end
   self.on_ground_interval=0
   self.spd.y=-1.0
   self.jump_button.hold_time+=1
  elseif self.jump_button:was_just_pressed() then
   -- check for wall jump
   local wall_dir=self:is_solid_at(v2(-3,0)) and -1
        or self:is_solid_at(v2(3,0)) and 1
        or 0
   if wall_dir!=0 then
    self.jump_interval=0
    self.spd.y=-1
    self.spd.x=-wall_dir*(maxrun+1)
    self:smoke(spr_wall_smoke,-wall_dir*.3)
    self.jump_button.hold_time+=1
   end
  end
 end

 if (not on_ground) self.spd.y=appr(self.spd.y,maxfall,gravity)

 self:move(self.spd)

 -- animation
 if input==0 then
  self.spr=1
 elseif is_wall_sliding then
  self.spr=4
 elseif not on_ground then
  self.spr=3
 else
  self.spr=1+flr(frame/4)%3
 end
end

function cls_player:draw()
 spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)
 -- not convinced by border
 -- bspr(self.spr,self.pos.x,self.pos.y,self.flip.x,self.flip.y,0)

 --[[
 local bbox=self:bbox()
 local bbox_col=8
 if self:is_solid_at(v2(0,0)) then
  bbox_col=9
 end
 bbox:draw(bbox_col)
 bbox=self.atk_hitbox:to_bbox_at(self.pos)
 bbox:draw(12)
 print(self.spd:str(),64,64)
 ]]
end


spr_spring_sprung=66
spr_spring_wound=67

cls_spring=subclass(typ_spring,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox=hitbox(v2(0,5),v2(8,3))
 self.sprung_time=0
end)
tiles[spr_spring_sprung]=cls_spring
tiles[spr_spring_wound]=cls_spring

function cls_spring:update()
 -- collide with player
 local bbox=self:bbox()
 if self.sprung_time>0 then
  self.sprung_time-=1
 else
  if player!=nil then
   if bbox:collide(player:bbox()) then
    player.spd.y=-3
    self.sprung_time=10
    local smoke=cls_smoke.init(self.pos,spr_full_smoke,0)
   end
  end
 end
end

function cls_spring:draw()
 local spr_=spr_spring_wound
 if (self.sprung_time>0) spr_=spr_spring_sprung
 spr(spr_,self.pos.x,self.pos.y)
end
spr_spawn_point=1

cls_spawn=subclass(typ_spawn,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.is_solid=false
 self.target=self.pos
 self.pos=v2(self.target.x,128)
 self.spd.y=-2
 add_cr(function()
  self:cr_spawn()
 end)
 add_cr(function()
  wait_for(0.2)
  sfx(32)
 end)
end)

function cls_spawn:cr_spawn()
 cr_move_to(self,self.target,1,inexpo)
 del(actors,self)
 cls_player.init(self.target)
 cls_smoke.init(self.pos,spr_full_smoke,0)
end

function cls_spawn:draw()
 spr(spr_spawn_point,self.pos.x,self.pos.y)
end
spr_spikes=68

cls_spikes=subclass(typ_spikes,cls_actor,function(self,pos)
 cls_actor._ctr(self,pos)
 self.hitbox=hitbox(v2(0,3),v2(8,5))
end)
tiles[spr_spikes]=cls_spikes

function cls_spikes:update()
 local bbox=self:bbox()
 if player!=nil then
  if bbox:collide(player:bbox()) then
   player:kill()
   cls_smoke.init(self.pos,32,0)
  end
 end
end

function cls_spikes:draw()
 spr(spr_spikes,self.pos.x,self.pos.y)
end
cls_moving_platform=subclass(typ_moving_platform,cls_actor,function(pos)
 cls_actor._ctr(self,pos)
end)
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

 if self.timer!=nil then
  local tick=frame%self.timer[1]
  if tick==0 or tick==self.timer[2] then
   self.is_on=not self.is_on
  end
 end
end

function cls_lamp:draw()
 local spr_=self.spr+(self.is_on and 0 or 2)
 spr(spr_,self.pos.x,self.pos.y,2,2)
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
  self:switch()
 end
end

function cls_lamp_switch:switch()
 -- switch switches too
 room.player_spawn=self.pos
 for lamp in all(room.lamps) do
  if lamp.nr==self.nr then
   lamp.is_on=not lamp.is_on
   self.is_on=lamp.is_on
  end
 end
 for switch in all(room.switches) do
  if (switch.nr==self.nr) switch.is_on=self.is_on
 end
 if self.is_on then
  sfx(30)
 else
  sfx(31)
 end
end

function cls_lamp_switch:draw()
 local spr_=self.is_on and spr_switch_on or spr_switch_off
 spr(spr_,self.pos.x,self.pos.y)
 -- self:bbox():draw(7)
end

function cls_lamp_switch:draw_text()
 if self.player_near and should_blink(24) then
  palt(0,false)
  bstr("\x97",self.pos.x-1,self.pos.y-8,0,6)
  palt()
 end
end
spr_exit_on=100
spr_exit_off=102

cls_exit=subclass(typ_exit,cls_lamp,function(self,pos,tile)
 cls_lamp._ctr(self,pos,tile)
 self.hitbox=hitbox(v2(0,0),v2(16,16))
 self.player_near=false
 self.moth_near=false
end)

tiles[spr_exit_off]=cls_exit
tiles[spr_exit_on]=cls_exit

function cls_exit:update()
 self.player_near=player!=nil and player:collides_with(self)

 self.moth_near=moth!=nil and moth:collides_with(self)
 if self.player_near and self.moth_near and btnp(btn_action) then
  game:next_level()
 end
end

function cls_exit:draw()
 local spr_=self.is_on and spr_exit_on or spr_exit_off
 palt(0,false)
 spr(spr_,self.pos.x,self.pos.y,2,2)
 palt()
end

function cls_exit:draw_text()
 if self.player_near and self.moth_near and flr(frame/32)%2==1 then
  local pos=main_camera:abs_position(v2(50,64))
  bstr("\x97 - exit",self.pos.x-4,self.pos.y-10,0,14)
 end
end
cls_game=class(typ_game,function(self)
 self.current_level=1
end)

function cls_game:load_level(level)
 add_draw_cr(function ()
  fade(false)
  self.current_level=level
  actors={}
  player=nil
  moth=nil
  local l=levels[self.current_level]
  cls_room.init(l)
  for timer in all(l.timer_lights) do
   for lamp in all(room.lamps) do
    if lamp.nr==timer[1] then
     lamp.timer={timer[2],timer[3]}
    end
   end
  end

  fireflies_init(room.dim)
  room:spawn_player()
  fade(true)
 end)
end

function cls_game:next_level()
 self:load_level(self.current_level%#levels+1)
end

game=cls_game.init()
fireflies={}

function fireflies_update()
 for p in all(fireflies) do
  p.counter+=p.speed
  p.life+=.3
  if (p.life>p.maxlife) p.life=0
 end
end

function fireflies_draw()
 for p in all(fireflies) do
  local x=p.x+cos(p.counter/128)*p.radius
  local y=p.y+sin(p.counter/128)*p.radius
  local size=abs(p.life-p.maxlife/2)/(p.maxlife/2)
  size*=p.size
  circ(x,y,size,10)
 end
end

function fireflies_init(v)
 fireflies={}
 for i=0,(v.x*v.y/20) do
  local p={
   x=rnd(v.x*8),
   y=rnd(v.y*8),
   speed=(0.01+rnd(.1))*rndsign(),
   size=rnd(3),
   maxlife=30+rnd(50),
   life=0,
   counter=0,
   radius=30+min(v.x,v.y)
  }
  p.life=rnd(p.maxlife)
  add(fireflies,p)
 end
end

-- fade bubbles
-- x gravity
-- x downward collision
-- x wall slide
-- x add wall slide smoko
-- x fall down faster
-- x wall jump
-- x variable jump time
-- x test controller input
-- x add ice
-- x springs
-- x wall sliding on ice
-- x player spawn points
-- x spikes
-- x respawn player after death
-- x add ease in for spawn point
-- x add coroutine for spawn point
-- x slippage when changing directions
-- x flip smoke correctly when wall sliding
-- x particles with sprites
-- x fix world collision / falling off world
-- x add moving / pulling camera

-- x add moth sprites
-- x instantiate moth
-- x add light / light switch mechanic
-- x add moth following light
-- x move moth to nearest light
-- x ray collision with moth to find nearest visible lamp
-- x switches can toggle multiple lamps
-- x exit door
-- x better help texts
-- x draw moth above light
-- x show tutorial text above switch
-- x make wider levels
-- x implement camera
-- x better darker tiles
-- x add fireflies flying around
-- x parallax background
-- x make fireflies slower
-- x better spreading of fireflies
-- x debounce moth switching lamps
-- x limit moth fov
-- x switch levels when reaching exit door
-- x readd gore on death

-- x respawn at last switch
-- x fade and room transitions

-- x add timed lamps
-- better spike collision
-- room transition sfx
-- moth animation when seeing light
-- fix slight double jump (?)

-- add simple intro levels
-- add marker above lamps the switch will activate

-- add title screen
-- camera shake on death

-- moth dash mechanics?


-- x-x-x generate parallax background
-- find a proper way to define lamp target offsets
-- x better lamp switches
-- better moth movement
-- bresenham dashed line
-- x add checkpoints
-- particles trailing moth

-- add fire as a moth obstacle

-- add frogs

-- enemies
-- moving platforms
-- laser beam
-- vanishing platforms

-- fades

-- music
-- sfx

--include main-test
--include main-test-oo
main_camera=cls_camera.init()

function _init()
 -- music(0)
 game:load_level(2)
end

function _draw()
 frame+=1

 cls()

 if not is_screen_dark then
  local p=main_camera:compute_position()
  camera(p.x/1.5,p.y/1.5)
  fireflies_draw()

  camera(p.x,p.y)
  if (room!=nil) room:draw()
  draw_actors()
  if (player!=nil) player:draw()
  if (moth!=nil) moth:draw()

  palt(0,false)
  for a in all(actors) do
   if (a.draw_text!=nil) a:draw_text()
  end
  palt()

  camera(0,0)
  -- print cpu
  -- print(tostr(stat(1)),64,64,1)
  -- print(tostr(stat(7)).." fps",64,70,1)
 end

 tick_crs(draw_crs)

end

function _update60()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)
 fireflies_update()
 if (player!=nil) player:update()
 if (moth!=nil) moth:update()
 update_actors()
 main_camera:update()
end


__gfx__
0000000000ddd0000000000000ddd00000ddd0000000000000000000000000000000000000000000000005001111111511111111111111110000000000000000
000000000ddfdf0000ddd0000ddfdf000ddfdf000d0000d000000000000000000000000000555550000005001111111511111111111111110000000000000000
00700700ddf1f1f00ddfdf00ddf1f1f0ddf1f1f000d00d000d0000d0000000000000000000500000055505551111111511111111111111110000000000000000
000770000ff1f1f0ddf1f1f00ff1f1f00ff1f1f00005500000d00d000dd00dd00000000000505050000500501115111511111111111111110000000000000000
0007700000ffff000ff1f1f000ffff0000ffff000058d8000558d800055550000000000000500050000555501105111511101111111111110000000000000000
007007000009900000ffff0000044000000999600500d0000000d0000008d8000000000000555550000000001105101511101011111111110000000000000000
000000000004400000044000006006000004460000000000000000000000d0000000000000500500550000001105101510101011111111110000000000000000
00000000000660000006060000000000000000000000000000000000000000000000000000500500055555001105101510101001111111110000000000000000
000000000ff0ff0000000000f000f000000000000000000000000000000000000000000000000500050005001105101510101000000000000000000000000000
0990009900f00f0000f00f000fff0000000000000000000000000000000000000000000000000505550005550105101500001000000000000000000000000000
0095959000ffff0000ffff000cfc0000000000000000000000000000000000000000000005550500000005000105101500001000000000000000000000000000
0009990000fcfc00f0fcfc0066e66000000000000000000000000000000000000000000000055500055555000005100500000000000000000000000000000000
0009e900f0ffffe0f0fffef00f6f00f0000000000000000000000000000000000000000005050000050005000005000500000000000000000000000000000000
00000009f0099000f0044f000fff00f0000000000000000000000000000000000000000055055555550005000005000500000000000000000000000000000000
00099909f0ffff00f0fff0000fff00f0000000000000000000000000000000000000000005000000055555000005000500000000000000000000000000000000
009444900fffff400ff6f60005f5ff00000000000000000000000000000000000000000005000000050000000005000000000000000000000000000000000000
00000000004000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000800088008408000008800000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008480008400080000000000008e8000008e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008888800d0000d00000000000888880008e8800000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00488480000000000000000000288280000882000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000
000444000880000800000000000222000000200000020000000e0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d800d808000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d00d008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000770700000770000000000000000000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000
70000600007700667000007000000000000000000000000000060000007700007000000000000000000000000000000000000000000000000000000000000000
00770000006600000000006700000000000000000000000000000700006000006600000000000000000000000000000000000000000000000000000000000000
07766000000000000000000000000000000000000000000000707700000000000000700000000000000000000000000000000000000000000000000000000000
0677770000000000000000000000000000000000000000000777770007007000000060000000000007000000c00000000000000007000000c000000000000000
077776000000000700000000007770000000770000000070006676007700600000000000000c0000c60000000000007007000000c60000000000007000000000
0076600700700000000000700777600077006770070000600000660006700000070000000077c0000c00770000000000c6000c000c0077000000000000000000
0000000676607000070007607667770076000660000000000000060000000000060000000c766cc0000006c0000000000c00c7c0000006c00000000000000000
65d6d0065566c65c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd5007c5c500c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0005500060c0c060000000000000000000000000066650000666500000000000000000000000000000000000000000000000000000000000000000000000000
0000000d05060005000000000000000000000000006b650000686500000000000000000000000000000000000000000000000000000000000000000000000000
005d000000050000056666500000000007000700006b650000686500000000000000000000000000000000000000000000000000000000000000000000000000
000560000000000000d00d0000000000060006000065650000656500000000000000000000000000000000000000000000000000000000000000000000000000
5600000500000000000dd00000000000ddd0ddd0006d6500006d6500000000000000000000000000000000000000000000000000000000000000000000000000
050005dd0000000000d00d000566665055d555d50066650000666500000000000000000000000000000000000000000000000000000000000000000000000000
0000000088008088888ee88888eee8880000e00000eeee000eeeeee00000e00000eeeee0000eee00000000000000000000000000000000000000000000000000
00000000000000000082200000888822000ee00000e000e000000e00000e0e0000e0000000ee0000000000000000000000000000000000000000000000000000
0000000000000000000000000002820000e0e00000e000e00000e00000e00e0000e000000e000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000e000000000e00eeeee000e000e0000eeee00e0000000000000000000000000000000000000000000000000000000
dddddddd0000000000000000000000000000e00000eeeee0000000e0e0000e0000000ee0eeeeeee0000000000000000000000000000000000000000000000000
666666660000000000000000000000000000e00000e00000000000e00eeeeeee000000e0e000000e000000000000000000000000000000000000000000000000
666666660000000000000000000000000000e00000e00000000000e000000e0000000ee00e00000e000000000000000000000000000000000000000000000000
dddddddd00000000000000000000000000eeeee000eeeee00eeeee0000000e0000eeee0000eeeee0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000050000000000000005000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000d000000000000000d000000000000000000000000000000000000000000
00000005d000000000000006d0000000000000000000000000000000000000000000060000000000000006000000000000000000000000000000000000000000
0000005005000000000000600600000000000d6666d0000000000d6666d0000000006d500000000000006d500000000000000000000000000000000000000000
000005d50d000000000006d50d000000000000555500000000000055550000000000999000000000000000000000000000000000000000000000000000000000
0000099905000000000000000d000000000000799700000000000000000000000000797000000000000000000000000000000000000000000000000000000000
000007970d000000000000000d000000000007777770000000000000000000000007777700000000000000000000000000000000000000000000000000000000
0000777776000000000000000d000000000007944970000000000076670000000057777750000000000000000000000000000000000000000000000000000000
00007777760000000000000005000000000079151597000000000755557000000577777775000000000000000000000000000000000000000000000000000000
0007777776000000000000000d000000000074515147000000000650056000005677777776500000000000000000000000000000000000000000000000000000
0007777776000000000000000d000000000774151547700000000650056000007777777777600000000000000000000000000000000000000000000000000000
0077777776700000000000000d000000000774515147700000000650056000007777777777700000000000000000000000000000000000000000000000000000
00777777767000000000000005000000007774151547770000000650056000007777777777700000000000000000000000000000000000000000000000000000
0777777776770000000000000d000000007774515147770000000650056000007777777777700000000000000000000000000000000000000000000000000000
077777776d570000000000006d500000077779151597777000000d5005d000005777777777500000000000000000000000000000000000000000000000000000
77777776d555700000000006d5550000077774515147777000000650056000000556666655000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d00000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d0b0c0b0c0d0d0d0d0d0d0d0d0d0b0c0d0d0d0d0d0d0d0d0d0b0b0c0b0c0d00000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0
b0c0c1b1c1b0c0c0b0c0b0c0b0c0b1c1d0d0d0b0c0d0d0d0d0b1b1c1c1b1c1000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0
c0c1000000b1c1c1b1c1b1c1b1c10000b0c0c0b1c1b0c0b0c0000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b1
c1000000000000000000000000000000b1c1c10000b1c1b1c1000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0c0b0c0b0c0b0c000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b1c1b1c1b1c1b1c100000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0c0b0c0b0c0b0c0b0c000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b0c0b0c0b0c00000000000000000000000000000000000000000000000000000000000b1c1b1c1b1c1b1c1b1c100000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b1c1b1c1b1c10000000000000000000000000000000000000000000000000000000000b0c0b0c00000b0c0b0c000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b0c0b0c0b0c00000000000000000000000000000000000000000000000000000000000b1c1b1c100b0c0c1b1c100000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b1c1b1c1b1c100000000000000000000000000000000000000000000000000000000000000b0c0b0b1c1c0b0c000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b0c0b0c0b0c000000000000000000000000000000000000000000000000000000000000000b1c1b1c1b1c1b1c100000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b1c1b1c1b1c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd76700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd757570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07757570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
44433544444335444443354444433544444335444443354444433544444335444443354444433544444335444443354444433544444335444443354444433544
94445544944455449444554494445544944455449444554494445544944455449444554494445544944455449444554494445544944455449444554494445544
44444449444444494444444944444449444444494444444944444449444444494444444944444449444444494444444944444449444444494444444944444449
44594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444444594444
44459444444594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444444594444445944444459444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
00000000000000000000000000000000000000000000000000000000000000006600666000006660066000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000606000006060006000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000606000006060006000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006000606006006060006000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006600666060006660066000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000557900000000000000540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000040404040400000460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a000000000000000000000000000000000000000000090a0000000000000000000000000000000000
0000050000006667000000414040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a090a090a090a0000000000000000000000090a090a000000000000191a0000000000000000000000000000000000
4000626300005477000000000000000000000000000000000000000000000000626300560066670000000000000000000000000000000000000000000000000000000000000000000000000000000000191a191a191a191a0000000000000000000000191a191a000000000000090a0000000000000000000000000000000000
000055730000414141404040000000000000000000000000000000000000000057730046005677000000000000000000000000000000000000000000000000000000000000000000000000000000090a090a00000000000000000000000000090a090a00000000000000000000191a0000000000000000000000000000000000
4040404000000000005500000000000000000000006a6b00000000000000000000404440444040000000000000000000000000000000000000000000000000000000000000000000000000000000191a191a00000000000000000000000000191a191a00000000000000000000000000000000090a090a000000000000000000
000000000040000001460000000000000000006263587b000000000000000000000000005700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a000000000000000000000000000000000000191a191a000000000000000000
000000000040004040400000000000000000005573000000000000000000000000000043460000004040004444000000000000000000000000000000000000000000000000000000000000090a000000000000000000000000000000000000191a000000000000000000000000090a00000000090a090a000000000000000000
000000000000000000000000000000000500540040005500000000006263000000004141414100000000404040400000000000000000000000000000000000000000000000000000000000191a000000000000000000000000000000000000090a000000000000000000000000191a00000000191a191a000000000000000000
000000000000000000000000000000000001464040004600000000005473000000000000000000420000000000000000000000000000000000000000000000000000000000000000000000090a090a090a0000000000000000000000000000191a000000000000000000000000090a0000090a090a0000000000000000000000
444444444444444444444444444444444040404040404040444440404040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000191a191a191a00000000000000000000000000000000000000000000000000000000191a0000191a191a0000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a090a090a090a0000000000000000000000000000090a090a0000090a090a090a090a090a0000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a191a191a191a0000000000000000000000000000191a191a0000191a191a191a191a191a0000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a00000000000000000000000000000000090a090a090a090a090a0000090a0000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a000000000000000000000000000000191a00000000000000000000000000000000191a191a191a191a191a0000191a0000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a00000000090a0000090a090a090a090a090a090a090a090a0000090a090a00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a090a0000191a0000191a191a191a191a191a191a191a191a0000191a191a00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a191a090a000000000000000000000000000000000000090a090a090a000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a191a000000000000000000000000000000000000191a191a191a000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000000000054000000666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000001000000000046000000547700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000191a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001504024050220501d0501e0501d0501c0501b0501a050180501705016050140501405014050130501205014050100500f0500e0500c0400b040090300803008030060200602006010060100000000000
011800200c0550f055130550c0551f0551a0551b0551f0550c0500c0350c02500000000000000000000000000e05511055140550e055110551b05518055110551405014035140251400000000000000000000000
001800001803018030180300c0300c7300c7301b0301b0301b0301b0301b03511030117301173511030110300e0300e0300e0300e0300e7300e7300e0300f0300f0300f0300f0351303013730137351303013030
011800002b0522b0522b0422b0422b1322b1222905229052290422904229032290322902229022291122911227052270422704227032271222613226052260422604226032261122413224032240322b1222b122
011800001d05513055160550f055220551d0551f0550c0550e0500e035130051d005000000000000000000001105514055110550e0551a0551b0551a055160551305013035000000000000000000000000000000
011800002c0522c0522c0422c0422c1322c1222b0522b0522b0422b0422b03229032290222902226112261122705227042270422703227122241322405224042240421b0321b1121b1321b0321a0321a1221a122
001800001803018030180300c0300c7300c7301b0301b0301b0301b0301b03511030117301173511030110300e0300e0300e0300e0300e7300e7300e0300f0300f0300f0300f0351303013730137351303013030
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000000000a0500c0500f0500f0501105016050180501b0501d0501f050220502205027050290502e02027020290102b0002e000300003300035000350000000000000000000000000000000000000000000
0106000029050270502e050290502705022050220501f0501d0501b0501805016050110500f0500f0500c02009020290002b0002e000300003300035000350000000000000000000000000000000000000000000
00030000000000505006050060500705008050090500a0500c0500d0500f05011050170501c05023050290502d050000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01020344
02 04060544

