--# title  Einstein Defenders - PICO-8

--# constants
local GRAVITY=0.6
local JUMP_FORCE=-10
local SPEED=1.8
local SHOOT_COOLDOWN=16
local BULLET_SPEED=3.5
local GRAVITY_WELL_SPEED=2
local GRAVITY_WELL_RADIUS=8
local GRAVITY_WELL_PULL=0.15

--# init
function init()
 srand(7)

 mode="title"
 t=0

 --# player
 p={x=60,y=60,w=6,h=8,vx=0,vy=0,on_ground=false,shoot_cd=0,facing=1}

 --# bullets
 bullets={}

 --# gravity wells
 wells={}

 --# particles
 particles={}

end

function reset()
 init()
end

--# world update
function update()
 t+=1

 if mode=="title" then
  if btn(4) or btn(5) or btn(0) or btn(1) or btn(2) or btn(3) then
   mode="play"
  end
  return
 end

 if mode=="play" then
  update_player()
  update_bullets()
  update_wells()
  update_particles()
 end
end

function update_player()
 --# movement
 if btn(0) then
  p.vx-=SPEED
  p.facing=-1
 end
 if btn(1) then
  p.vx+=SPEED
  p.facing=1
 end

 --# apply facing from horizontal input only
 if not btn(0) and not btn(1) then
  p.vx*=0.84
 end

 --# jump
 if (btn(2) or btnp(2)) and p.on_ground then
  p.vy=JUMP_FORCE
  p.on_ground=false
  make_jump_particles()
 end

 --# shoot
 if p.shoot_cd<=0 and (btn(4) or btn(5)) then
  shoot_well()
  p.shoot_cd=SHOOT_COOLDOWN
 end
 if p.shoot_cd>0 then p.shoot_cd-=1 end

 --# physics
 p.vy+=GRAVITY
 p.x+=p.vx
 p.y+=p.vy

 --# bounds
 p.x=clamp(p.x,6,122)
 if p.x<6 then p.vx=0 end
 if p.x>122 then p.vx=0 end

 --# ground
 if p.y>=110 then
  p.y=110
  p.vy=0
  p.on_ground=true
 else
  p.on_ground=false
 end

 --# wrap around level edge
 if p.x<2 then p.x=126
 elseif p.x>126 then p.x=2
 end
end

function update_bullets()
 for i=#bullets,1,-1 do
  local b=bullets[i]
  b.x+=b.vx
  b.y+=b.vy
  b.life-=1
  if b.x<0 or b.x>128 or b.y<0 or b.y>128 or b.life<=0 then
   table.remove(bullets,i)
  end
 end
end

function update_wells()
 for i=#wells,1,-1 do
  local w=wells[i]
  w.x+=w.vx
  w.y+=w.vy
  w.life-=1
  --# pull nearby entities
  for e in all(bullets) do
   local dx=e.x-w.x
   local dy=e.y-w.y
   local dist=sqrt(dx*dx+dy*dy)
   if dist<GRAVITY_WELL_RADIUS then
    e.vx-=dx/dist*GRAVITY_WELL_PULL
    e.vy-=dy/dist*GRAVITY_WELL_PULL
   end
  end
  if w.x<0 or w.x>128 or w.y<0 or w.y>128 or w.life<=0 then
   make_well_destroy_particles(w.x,w.y)
   table.remove(wells,i)
  end
 end
end

function update_particles()
 for i=#particles,1,-1 do
  local pt=particles[i]
  pt.x+=pt.vx
  pt.y+=pt.vy
  pt.life-=1
  if pt.life<=0 then
   table.remove(particles,i)
  end
 end
end

--# world draw
function draw()
 cls(0)

 if mode=="title" then
  draw_title()
  return
 end

 draw_world()
 draw_hud()
end

function draw_title()
 print("einstein defenders",32,40,5)
 print("move: left/right",28,55,7)
 print("jump: up",48,63,7)
 print("shoot: x/z",44,71,7)
 print("press any key",32,90,8)
end

function draw_world()
 --# parallax background
 for i=1,5 do
  local sx=(t*0.2)%128
  local sy=i*20+sin(t*0.03)*4
  rectfill(sx,sy,sx+3,sy+1,10)
 end

 --# player
 draw_einstein(p.x,p.y,p.facing)

 --# bullets
 for b in all(bullets) do
  circfill(b.x,b.y,2,9)
 end

 --# gravity wells
 for w in all(wells) do
  circfill(w.x,w.y,GRAVITY_WELL_RADIUS,w.team==1 and 1 or 8)
  circfill(w.x,w.y,3,w.team==1 and 7 or 7)
 end

 --# particles
 for pt in all(particles) do
  pset(pt.x,pt.y,pt.c)
 end
end

function draw_einstein(x,y,facing)
 --# head
 circfill(x,y-4,3,13)
 circfill(x,y-5,1,0)
 --# body
 rectfill(x-2,y-1,x+2,y+4,4)
 --# hair
 rectfill(x-3,y-5,x-2,y-2,4)
 rectfill(x+2,y-5,x+3,y-2,4)
 --# mustache
 line(x-2,y+1,x+2,y+1,4)
 rectfill(x-2,y+1,x+2,y+2,4)
 --# arms
 if facing==-1 then
  line(x-3,y-1,x-5,y-2,4)
 else
  line(x+3,y-1,x+5,y-2,4)
 end
 --# legs
 line(x-2,y+4,x-1,y+6,4)
 line(x+2,y+4,x+1,y+6,4)
 --# eyes
 pset(x-1,y-5,0)
 pset(x+1,y-5,0)
end

function draw_hud()
 print("bullets: "..#bullets,5,5,7)
 print("wells: "..#wells,5,12,7)
end

--# actions
function shoot_well()
 local vx=0
 local vy=0
 if p.facing==-1 then
  vx=-GRAVITY_WELL_SPEED
 elseif p.facing==1 then
  vx=GRAVITY_WELL_SPEED
 end
 --# allow aiming with up button
 if btn(2) then
  vx=0
  vy=-GRAVITY_WELL_SPEED
 end
 table.insert(wells,{
  x=p.x,y=p.y+4,
  vx=vx,vy=vy,
  life=120,team=1
 })
 make_shoot_particles()
 sfx(10,20,8,"square")
end

function make_jump_particles()
 for i=1,8 do
  table.insert(particles,{
   x=p.x,y=p.y+4,
   vx=rnd(-1.5,1.5),
   vy=rnd(-0.5,-2),
   life=12,c=rnd(0,1)
  })
 end
end

function make_shoot_particles()
 for i=1,4 do
  table.insert(particles,{
   x=p.x,y=p.y,
   vx=rnd(-0.8,0.8),
   vy=rnd(-0.8,0.8),
   life=10,c=7
  })
 end
end

function make_well_destroy_particles(x,y)
 for i=1,6 do
  table.insert(particles,{
   x=x,y=y,
   vx=rnd(-1.2,1.2),
   vy=rnd(-1.2,1.2),
   life=14,c=rnd(0,1)
  })
 end
end

--# entry point
init()
