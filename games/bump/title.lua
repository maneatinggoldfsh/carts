title_w=5*8
title_h=2*8
title_dx=20
title_dy=10

function draw_title()
 cls()
 local f=flr(frame/4)%3
 if f==1 then
  draw_title_frame1()
 else
  pal(7,12)
  srand(f)
  draw_title_frame2(-1)
  for i=0,5 do draw_random_line(7) end

  pal(7,8)
  srand(f)
  draw_title_frame2(1)
  srand(f+1)
  for i=0,5 do draw_random_line(7) end

  pal()
  srand(f)
  draw_title_frame2(0)
  srand(f+2)
  for i=0,10 do draw_random_line(0) end
 end
end

function draw_title_frame1()
 pal(7,12)
 sspr(11*8,12*8,title_w,title_h,title_dx-1,title_dy,title_w*2,2*title_h)
 pal(7,8)
 sspr(11*8,12*8,title_w,title_h,title_dx+1,title_dy,title_w*2,2*title_h)
 pal()
 sspr(11*8,12*8,title_w,title_h,title_dx,title_dy,title_w*2,2*title_h)
end

function draw_random_line(col)
 palt(col,false)
 local x=rnd(5*8+20)+title_dx
 local y=rnd(2*8+5)+title_dy+10
 local w=rnd(10)
 line(x,y,x+w,y,col)
 palt()
end

function draw_title_frame2(addx)
 local w=5*8
 local h=2*8
 local dx=20
 local dy=10

 local sy=0
 while sy<h do
  local sx=0
  local dh=min(title_h-sy,flr(rnd(3)+3))

  while sx<w do
   local dw=min(title_w-sx,flr(rnd(5)+5))
   local offx=mrnd(1)
   local offy=mrnd(1)
   sspr(11*8+sx,12*8+sy,dw,dh,title_dx+sx*2+offx+addx,title_dy+sy*2+offy,dw*2,dh*2)
   sx+=dw
  end

  sy+=dh
 end

end