pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function class (init)
  local c = {}
  c.__index = c
  c._ctr=init
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    return self
  end
  return c
end

function subclass(parent,init)
 local c=class(init)
 return setmetatable(c,{__index=parent})
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

function rnd_elt(v)
 return v[min(#v,1+flr(rnd(#v)+0.5))]
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

mode_swinging=1
mode_free=2
mode_pulling=3

maxfall=5
gravity=0.20
normal_tether_length=10

prevbtn=false

player=nil

cls_player=class(function(self,pos)
 self.pos=pos
 self.spd=v2(.2,2)
 self.mode=mode_free
 self.tether_length=0
 self.prev=v2(10,28)
 self.frame_sensitive=5
 self.current_tether=nil
 self.previous_tether=nil
 self.flip=v2(false,false)
end)

function cls_player:get_closest_tether()
 local d=10000
 local res=nil
 local dir=self.spd.x>0 and 1 or -1
 if (btn(0)) dir=-1
 if (btn(1)) dir=1
 for tether in all(tethers) do
  if (dir==1 and tether.pos.x>self.pos.x) or
   (dir==-1 and tether.pos.x<self.pos.x) then
    local _d=abs(self.pos.x-tether.pos.x)
    if _d<d and d>50 and tether!=self.previous_tether then
     res=tether
     d=_d
    end
  end
 end
 if (res==nil) res=tethers[1]
 return res
end

function cls_player:draw()
 if self.current_tether!=nil then
  line(self.pos.x,self.pos.y,
  self.current_tether.pos.x,self.current_tether.pos.y,7)
 end
  
  if(self.pos.y>=118) then
      --printh("stopped on ground")
      spr(17,self.pos.x,self.pos.y,1,1,false, false)

  elseif(true) then
      local threshsm = .25
      local threshbig = 1.5
      if (self.spd.x > threshsm) then
          if(self.spd.y > threshbig) then
            --player going down+right
            spr(34,self.pos.x-6,self.pos.y-2,1,1,false, false)
          elseif(self.spd.y < threshbig*-1) then
            --player going up+right
            spr(36,self.pos.x-2,self.pos.y-2,1,1,false, false)
          else
            --player going right
            spr(35,self.pos.x-4,self.pos.y-2,1,1,false, false)
          end
      elseif (self.spd.x < threshsm*-1) then
          if(self.spd.y > threshbig) then
            --player going down+left
            spr(34,self.pos.x-1,self.pos.y-2,1,1,true, false)
          elseif(self.spd.y < threshbig*-1) then
            --player going up+left
            spr(36,self.pos.x-5,self.pos.y-2,1,1,true, false)
          else
            --player going left
            spr(35,self.pos.x-3,self.pos.y-2,1,1,true, false)
          end
      elseif(self.spd.y > threshsm) then
        --player going down
        spr(33,self.pos.x-5,self.pos.y-3,1,1,false,false) --temp, need to implement direction based on cur tether
      elseif(self.spd.y < threshsm*-1) then
        --player going up
        spr(36,self.pos.x-2,self.pos.y-2,1,1,false, false) --temp, need to implement direction based on cur tether
      else
        --player is idle
        spr(37,self.pos.x-5,self.pos.y-1,1,1,false, false)
      end
  end
end

function cls_player:update()
 local _gravity=gravity

 -- adjust gravity
 if (self.mode==mode_free) _gravity*=0.8
 if (self.mode==mode_swing) _gravity*=1.5
 self.spd.y=appr(self.spd.y,maxfall,_gravity)

 self.prev.x=self.pos.x
 self.prev.y=self.pos.y

 -- bounce on floor
 if self.pos.y>=118 then --if self.pos.y>118 then  --edited
  self.pos.y=118
  --self.spd.y=-self.spd.y --commented out --edited
  self.spd.x*=0.95
  self.spd.y=0 --self.spd.y*=0.3 --edited
  if (abs(self.spd.y)<0.5) self.spd.y=0
  if (abs(self.spd.x)<0.5) self.spd.x=0
 end

 self.pos.y+=self.spd.y
 self.pos.x+=self.spd.x

 if (btn(4) and not prevbtn) or self.pos.y>=100 then
  if self.mode==mode_free then
   self.mode=mode_pulling
   self.current_tether=self:get_closest_tether()
   local l=(self.pos-self.current_tether.pos):magnitude()
   self.tether_length=l
  end
 end

 if self.current_tether!=nil then
  local tether=self.current_tether

  local v=self.pos-tether.pos
  local l=v:magnitude()

  if not btn(4) and self.mode!=mode_free then
   self.mode=mode_free
   self.previous_tether=self.current_tether
   self.current_tether=nil
  end

  local _normal_tether_length=normal_tether_length
  if self.mode==mode_pulling then
   _normal_tether_length=max(self.tether_length,normal_tether_length)
   self.tether_length-=3
  end

  if self.mode!=mode_free then
   if self.mode==mode_pulling and l<normal_tether_length then
    -- printh("Switch to swinging l "..tostr(l))
    self.mode=mode_swinging
   end

   if l>_normal_tether_length then
    local _factor=_normal_tether_length/l
    -- printh("mode "..tostr(self.mode).." normal_tether_length "..tostr(_normal_tether_length))
    -- printh("resize tether pull by "..tostr(_factor).." l "..tostr(l))
    v*=_factor
    self.pos=tether.pos+v
    self.spd=self.pos-self.prev
   end
  end
 end

 local vs=self.spd:magnitude()
 local max_v=7
 self.spd.y=mid(-5,self.spd.y,4)
 if (vs>max_v) self.spd*=max_v/vs

 prevbtn=btn(4)
end

cls_tether=class(function(self,pos)
  self.pos=pos
  add(tethers,self)
end)

function cls_tether:draw()
 circ(self.pos.x,self.pos.y,2,9)
end

function cls_tether:update()
end

cls_camera=class(function(self)
 self.target=nil
 self.pull=16
 self.pos=v2(0,0)
 self.shk=v2(0,0)
 -- this is where to add shake
end)

function cls_camera:set_target(target)
 self.target=target
 self.pos=target.pos:clone()
end

function cls_camera:compute_position()
 return v2(self.pos.x-64+self.shk.x,self.pos.y-64+self.shk.y)
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
 local max_speed=10
 if (b.bb.x<p.x) self.pos.x+=min(p.x-b.bb.x,max_speed)
 if (b.aa.x>p.x) self.pos.x-=min(b.aa.x-p.x,max_speed)
 if (b.bb.y<p.y) self.pos.y+=min(p.y-b.bb.y,max_speed)
 if (b.aa.y>p.y) self.pos.y-=min(b.aa.y-p.y,max_speed)
 if (self.pos.y>64) self.pos.y=64
 -- self.pos=room:bbox():shrink(64):clip(self.pos)
 self:update_shake()
end

-- from trasevol_dog
function cls_camera:add_shake(p)
 local a=rnd(1)
 self.shk+=v2(p*cos(a),p*sin(a))
end

function cls_camera:update_shake()
 if abs(self.shk.x)+abs(self.shk.y)<1 then
  self.shk=v2(0,0)
 end
 if frame%4==0 then
  self.shk*=v2(-0.4-rnd(0.1),-0.4-rnd(0.1))
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

row_background=1
row_foreground=2
row_middleground=3
building_cols={1,13,5}
buildings={}

cls_building=class(function(self,pos,row)
 self.pos=pos
 self.row=row
 add(buildings,self)
end)

function cls_building:draw()
 rectfill(self.pos.x,122,self.pos.x+20,128-self.pos.y,building_cols[self.row])
end


lasttime=time()
dt=0
frame=1
tethers={}

player_field_start=384
player_field_end=player_field_start+128
player_field_width=player_field_start
cull_end=player_field_end+player_field_width
cull_start=player_field_start-player_field_width

function cull_elts()
 local off=0
 if player.pos.x>player_field_end then
  off=-128
 elseif player.pos.x<player_field_start then
  off=128
 else
  return
 end

 player.pos.x+=off
 player.prev.x+=off
 main_camera.pos.x+=off

 for tether in all(tethers) do
  tether.pos.x+=off
  if tether.pos.x>cull_end or tether.pos.x<cull_start then
   del(tethers,tether)
  end
 end

 for building in all(buildings) do
  if building.row==row_foreground then
   building.pos.x+=off/0.75
  elseif building.row==row_background then
   building.pos.x+=off/1.5
  else
   building.pos.x+=off
  end
  if building.pos.x>cull_end or building.pos.x<cull_start then
   del(buildings,building)
  end
 end

 if (off==128) add_elts(cull_start,128)
 if (off==-128) add_elts(cull_end,128)
end

function add_elts(off,w)
 local boff=0
 while boff<w do
  local b=v2(boff+off,60+flr(rnd(60)))
  boff+=30+flr(rnd(50))
  cls_building.init(b,row_background)
 end

 boff=0
 while boff<w do
  local b=v2(boff+off,20+flr(rnd(40)))
  boff+=30+flr(rnd(50))
  cls_building.init(b,row_foreground)
 end

 boff=0
 while boff<w do
  local b=v2(boff+off,60+flr(rnd(60)))
  boff+=20+flr(rnd(40))
  cls_tether.init(v2(b.x,128-b.y))
  cls_building.init(b,row_middleground)
 end
end

function _init()
 player=cls_player.init(v2(player_field_start+64,10))

 add_elts(0,player_field_width*2+128)

 main_camera=cls_camera.init()
 main_camera:set_target(player)
end

function _update()
 dt=time()-lasttime
 lasttime=time()
 tick_crs(crs)

 player:update()
 for tether in all(tethers) do
  tether:update()
 end

 main_camera:update()

 cull_elts()
end

function _draw()
 frame+=1

 cls()
 local p=main_camera:compute_position()
 camera(p.x/1.5,p.y/1.5)
 for building in all(buildings) do
  if (building.row==row_background) building:draw()
 end
 -- parallax background

 camera(p.x,p.y)
 rectfill(-128,120,player_field_width*2+256,128,13)
 for building in all(buildings) do
  if (building.row==row_middleground) building:draw()
 end
 for tether in all(tethers) do
  tether:draw()
 end
 player:draw()

 -- foreground
 camera(p.x/0.75,p.y/0.75)
 for building in all(buildings) do
  if (building.row==row_foreground) building:draw()
 end

 camera(0,0)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008880000088800000888000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002820000028200000282000002820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008880000888880008888080808888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000081718000817180008171800081718000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000081118000011100000111000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008080000080800000808000008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088800000888000000000000000008000882080000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088200000882008000008000008001000288100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088808000888780000008000000811180087100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001780000001110008287180000711100011110000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001100000001111808881100082811000801080000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008080000000110008880080088800000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000080000000000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000000000000000f0500f050000000f0500f0500000010050100500000010050110501205014050160501a0501f05023050280502e0503305000000000000000000000000000000000000000000000000000
