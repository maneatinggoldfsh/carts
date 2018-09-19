pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
end

frame=0

function _update()
 if peek(0x5f80)==0 then
  poke(0x5f81,peek(0x5f81)+peek(0x5f82))
  poke(0x5f80,1)
 end
end

function _draw()
 frame+=1
 cls()
 rectfill(10,10,20,20,7)
 print(tostr(peek(0x5f84)),64,64,7)
 print(tostr(peek(0x5f85)),64,70,7)
 print(tostr(peek(0x5f86)),64,76,7)
 print(tostr(peek(0x5f87)),64,82,7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
