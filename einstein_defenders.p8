pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- move with left/right, jump with up, shoot gravity wells with x/z

--# constants
GRAVITY=0.6
JUMP_FORCE=-10
SPEED=1.8
SHOOT_COOLDOWN=16
GRAVITY_WELL_SPEED=2
GRAVITY_WELL_RADIUS=8
GRAVITY_WELL_PULL=0.15

--# init
function _init()
 srand(7)
 mode="title"
 t=0
 p={x=60,y=60,w=6,h=8,vx=0,vy=0,on_ground=false,shoot_cd=0,facing=1}
 test_bullets={}
 for i=1,3 do
  add(test_bullets,{x=20+i*30,y=80,vx=0.3,vy=0,life=300})
 end
 wells={}
 particles={}
end

function reset()
 init()
end

--# world update
function _update()
 t+=1
 if mode=="title" then
  if btn(4) or btn(5) or btn(0) or btn(1) or btn(2) or btn(3) then
   mode="play"
  end
  return
 end
 if mode=="play" then
  update_player()
  update_wells()
  update_test_bullets()
  update_particles()
 end
end

function update_player()
 if btn(0) then
  p.vx-=SPEED
  p.facing=-1
 end
 if btn(1) then
  p.vx+=SPEED
  p.facing=1
 end
 if not btn(0) and not btn(1) then
  p.vx*=0.84
 end
 if (btn(2) or btnp(2)) and p.on_ground then
  p.vy=JUMP_FORCE
  p.on_ground=false
  make_jump_particles()
  sfx(1,40,8,"sine")
 end
 if p.shoot_cd<=0 and (btn(4) or btn(5)) then
  shoot_well()
  p.shoot_cd=SHOOT_COOLDOWN
 end
 if p.shoot_cd>0 then p.shoot_cd-=1 end
 p.vy+=GRAVITY
 p.x+=p.vx
 p.y+=p.vy
 p.x=min(124,max(4,p.x))
 if p.x<4 then p.vx=0 end
 if p.x>124 then p.vx=0 end
 if p.y>=108 then
  p.y=108
  p.vy=0
  p.on_ground=true
 else
  p.on_ground=false
 end
 if p.x<2 then p.x=126
 elseif p.x>126 then p.x=2
 end
end

function update_test_bullets()
 for i=#test_bullets,1,-1 do
  local b=test_bullets[i]
  b.x+=b.vx
  b.y+=b.vy
  if b.x<0 or b.x>128 then
   b.vx*=-1
  end
  if b.y>108 then b.vy=-b.vy*0.7 b.vx*=0.95 end
  b.vy+=0.2
 end
end

function update_wells()
 for i=#wells,1,-1 do
  local w=wells[i]
  w.x+=w.vx
  w.y+=w.vy
  w.life-=1
  for e in all(test_bullets) do
   local dx=e.x-w.x
   local dy=e.y-w.y
   local dist=sqrt(dx*dx+dy*dy)
   if dist>0 and dist<GRAVITY_WELL_RADIUS*2 then
    local pull=GRAVITY_WELL_PULL*(GRAVITY_WELL_RADIUS/dist)
    e.vx-=dx/dist*pull
    e.vy-=dy/dist*pull
   end
  end
  if w.life<=0 then
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
function _draw()
 cls(0)
 if mode=="title" then
  draw_title()
  return
 end
 draw_world()
 draw_hud()
end

function draw_title()
 print("einstein defenders",26,40,5)
 print("left/right: move",20,55,7)
 print("up: jump",52,63,7)
 print("x/z: gravity well",10,71,7)
 print("press any key",32,90,8)
end

function draw_world()
 for i=1,5 do
  local sx=(t*0.3)%128
  local sy=i*18+sin(t*0.02)*3
  rectfill(sx,sy,sx+3,sy+1,10)
 end
 rectfill(0,109,127,109,5)
 rectfill(0,110,127,110,13)
 draw_einstein(p.x,p.y,p.facing)
 for b in all(test_bullets) do
  circfill(b.x,b.y,2,9)
 end
 for w in all(wells) do
  circfill(w.x,w.y,GRAVITY_WELL_RADIUS,0)
  circfill(w.x,w.y,3,1)
  circfill(w.x,w.y,2,0)
 end
 for pt in all(particles) do
  pset(pt.x,pt.y,pt.c)
 end
end

function draw_einstein(x,y,facing)
 circfill(x,y-5,3,13)
 circfill(x-1,y-6,1,0)
 circfill(x+1,y-6,1,0)
 rectfill(x-3,y-3,x+3,y+6,4)
 rectfill(x-4,y-5,x-2,y-2,4)
 rectfill(x+2,y-5,x+4,y-2,4)
 line(x-3,y-6,x+3,y-6,4)
 line(x-2,y+1,x+2,y+1,4)
 line(x-2,y+2,x+2,y+2,4)
 if facing==-1 then
  line(x-4,y-1,x-6,y,4)
 else
  line(x+4,y-1,x+6,y,4)
 end
 line(x-2,y+6,x-1,y+8,4)
 line(x+2,y+6,x+1,y+8,4)
end

function draw_hud()
 print("wells: "..#wells,5,5,7)
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
 if btn(2) then
  vx=0
  vy=-GRAVITY_WELL_SPEED
 end
 table.insert(wells,{
  x=p.x,y=p.y+2,
  vx=vx,vy=vy,
  life=120
 })
 make_shoot_particles()
 sfx(10,30,10,"square")
end

function make_jump_particles()
 for i=1,8 do
  add(particles,{
   x=p.x,y=p.y+4,
   vx=rnd(-1.5,1.5),
   vy=rnd(-0.5,-2),
   life=15,c=rnd(0,1)
  })
 end
end

function make_shoot_particles()
 for i=1,6 do
  add(particles,{
   x=p.x,y=p.y,
   vx=rnd(-1,1),
   vy=rnd(-1,1),
   life=12,c=7
  })
 end
end

function make_well_destroy_particles(x,y)
 for i=1,6 do
  add(particles,{
   x=x,y=y,
   vx=rnd(-1.5,1.5),
   vy=rnd(-1.5,1.5),
   life=15,c=rnd(2,3)
  })
 end
end

--# entry point
_init()
