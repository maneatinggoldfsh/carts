pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function class (typ,init)
  local c = {}
  c.__index = c
  c._ctr=init
  c.typ=typ
  function c.init (...)
    local self = setmetatable({},c)
    c._ctr(self,...)
    self.destroyed=false
    return self
  end
  c.destroy=function(self)
   self.destroyed=true
  end
  return c
end

function subclass(typ,parent,init)
 local c=class(typ,init)
 return setmetatable(c,parent)
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

function v2mt.__eq(a,b)
 return a.x==b.x and a.y==b.y
end

function v2mt:magnitude()
 return sqrt(self.x^2+self.y^2)
end

function v2mt:str()
 return "["..tostr(self.x)..","..tostr(self.y).."]"
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

function bboxvt:collide(other)
 return other.bb.x > self.aa.x and
   other.bb.y > self.aa.y and
   other.aa.x < self.bb.x and
   other.aa.y < self.bb.y
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

-- functions
function appr(val,target,amount)
    return (val>target and max(val-amount,target)) or min(val+amount,target)
end

function sign(v)
    return v>0 and 1 or v<0 and -1 or 0
end

function round(x)
    return flr(x+0.5)
end
actors={}

cls_actor=class(typ,function(self,pos)
    self.pos=pos
    self.spd=v2(0,0)
    self.rem=v2(0,0)
end)

function cls_actor:move(o)
    self.pos+=o
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

cls_bubble=subclass(typ_bubble,cls_actor,function(self,pos,dir)
    cls_actor._ctr(self,pos)
    self.spd=v2(-dir*rnd(0.2),-rnd(0.2))
    self.life=10
end)

function cls_bubble:draw()
    local size=4-self.life/3
    circ(self.pos.x,self.pos.y,size,6)
end

function cls_bubble:update()
    self.life*=0.9
    self:move(self.spd)
    if (self.life<0.1) then
        del(actors,self)
    end
end

frame=0
dt=0
lasttime=time()

cls_player=subclass(typ_player,cls_actor,function(self)
    cls_actor._ctr(self,v2(0,6*8))
    self.flip=v2(false,false)
    self.spr=1
end)

function cls_player:update()
    local input=btn(1) and 1 or (btn(0) and -1 or 0)
    -- from celeste's player class
    local maxrun=1
    local accel=0.5
    local decel=0.2

    if abs(self.spd.x)>maxrun then
        self.spd.x=appr(self.spd.x,sign(self.spd.x)*maxrun,decel)
    else
        self.spd.x=appr(self.spd.x,input*maxrun,accel)
    end

    self:move(self.spd)

    if self.spd.x!=0 then
        self.flip.x=self.spd.x<0
    end

    if abs(self.spd.x)>0.9 and rnd(1)>0.93 then
        add(actors,cls_bubble.init(self.pos+v2(0,4),input))
    end

    if input==0 then
        self.spr=1
    else
        self.spr=1+flr(frame/4)%3
    end
end

function cls_player:draw()
    spr(self.spr,self.pos.x,self.pos.y,1,1,self.flip.x,self.flip.y)

    print(self.spd:str(),64,64)
end

player=cls_player.init()

function _init()
end

function _draw()
    frame+=1

    cls()
    draw_actors()
    player:draw()
end

function _update60()
    dt=time()-lasttime
    lasttime=time()
    player:update()
    update_actors()
end


__gfx__
0000000000ddd0000000000000ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000dd7670000ddd0000dd76700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700dd7575700dd76700dd757570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007757570dd75757007757570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007777000775757000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000990000077770000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000600600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
33333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44433544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94445544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444449000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44594444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44459444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
