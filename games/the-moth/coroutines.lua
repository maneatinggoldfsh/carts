function tick_crs()
 for cr in all(crs) do
  if costatus(cr)!='dead' then
   coresume(cr)
  else
   del(crs,cr)
  end
 end
end

function add_cr(f)
 local cr=cocreate(f)
 add(crs,cr)
 return cr
end