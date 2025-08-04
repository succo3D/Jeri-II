pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main--

function _init()

	cheat=false --turn this on for editing
	
	#include jeri2_enemy_data.p8l
	enemy_data=split(enemy_data,";")
	for i,data in inext,enemy_data do
		enemy_data[i]=data=="" and {} or split(data)
	end

	--constants
	
	fade_pals=generate_fade_pals()

	cycle_pals=split"13,14,9,10,11,12"
	
	pause=false
	
	pause,max_num=false,32767
	
	title,gameplay,ending=0,1,2
	
	opposite_dir={[0]=0.5,[0.25]=0.75,[0.5]=0,[0.75]=0.25}
	
	--global
	
	end_level=false

	cam_x,cam_y,cam_tx,cam_ty=0,0,0,0
	
	stars_create()
	
	last_music_change=-1
	
	global_timer=0
	
	medal_timer=0
	current_medal=0
	
	level_time,level_deaths,total_time,total_deaths,total_swaps=0,0,0,0,0
	
	last_mode=false
	player_is_blue=false
	
	fade_level=0
	fade_speed=0
	
	fuse_timer=-1
	
	pal_cycle=0
	
	last_toilet_level=30
	toilet_compulsion=true
	
	--set so btnp doesn't repeat if held
	poke(0x5f5c,255)
	--inverted circle
	poke(0x5f34,0x2)
	--mouse enable
	poke(0x5f2d,1)
	
	if cheat then
		load_level(current_level)
		state=gameplay
	else
		current_level=1
		state=title
		fade_in()
	end

end

function _update60()

	fade_update()
	
	mouse_update()
	
	if state==title then
		title_update()
	elseif state==gameplay then
		gameplay_update()
	elseif state==ending then
		ending_update()
	end

	--increment looping global timer--
	
	global_timer=max(global_timer+1, 0)

end

function _draw()

	pal()

	if state==title then
		title_draw()
	elseif state==gameplay then
		gameplay_draw()
	elseif state==ending then
		ending_draw()
	end
	
	pal(fade_pals[flr(fade_level)],1)
	
	draw_medals()
	
	spr_center(15,mouse_x,mouse_y-2)
	
end



function gameplay_update()

	if end_level then
		end_screen_update()
	end
	
	if fuse_timer>0 then
		fuse_timer-=1
		sfx(53,3)
		if fuse_timer%3==0 then
			p_enemydust_create({x=door_x+((120-fuse_timer)/120)*2,y=door_y-2+((120-fuse_timer)/120)*4,pal={8,9}},-1,1)
		end
		if fuse_timer==0 then
			unlock_medal(4)
			end_screen_create()
		end
	end

	if pause then
		return
	elseif level_time<max_num then
		level_time+=1/60
	end
	
	for particle in all(particles) do
		particle_update(particle)
	end
	
	for player_bullet in all(player_bullets) do
		playerbullet_update(player_bullet)
	end
	
	for enemy_bullet in all(enemies_bullets) do
		enemybullet_update(enemy_bullet)
	end
	
	for enemy in all(enemies) do
		enemy_update(enemy)
	end
	
	player_update()
	
	if current_level!=31 then
		door_update()
	end
	

	
	if cheat then
		
		if btnp(➡️) then
			last_mode=player_is_blue
			next_level()
		end
		
		if btnp(⬅️) then
			last_mode=player_is_blue
			prev_level()
		end
		
		if btnp(⬇️) then
			last_mode=player_is_blue
			restart_level()
		end
	
	end
end

function gameplay_draw()

	cls()
	
	if current_level<19 then
		for x=0,15 do
			for y=1,15 do
				spr(current_level>8 and 65 or 64,cam_x+x*8,cam_y+y*8)
			end
		end
	end
	
	if current_level>18 and current_level!=31 then
		stars_draw()
		pal_cycle+=0.05
		pal_cycle%=#cycle_pals
		pal(13,cycle_pals[flr(pal_cycle+1)])
	end
	
	map()
	
	pal()

	spr_center(door_spr,door_x,door_y)
	
	for particle in all(particles) do
		particle_draw(particle)
	end
	
	for enemy in all(enemies) do
		enemy_draw(enemy)
	end
	
	for player_bullet in all(player_bullets) do
		playerbullet_draw(player_bullet)
	end
	
	player_draw()
	
	for enemy_bullet in all(enemies_bullets) do
		enemybullet_draw(enemy_bullet)
	end
	
	print(level_taglines[current_level*2+tonum(player_is_blue)-1],cam_x+1,cam_y+1,7)
	
	if end_level then
		end_screen_draw()
	end
	
end


function title_update()
	if fade_level==6 then
		gameplay_init()
	end
	if not pause and mouse_left_pressed and mouse_x<104 and mouse_x>24 and mouse_y>70 and mouse_y<90 then
		sfx(63)
		fade_out()
	end
	if not cheat and btn(⬆️) and btn(⬆️,1) and btn(❎,1) and btn(🅾️,1) then
		cheat=true
		sfx(54)
	end
end

function title_draw()
	cls(8)

	print_with_shadow("\^t\^wjeri ii",38,44)
	print_with_shadow("tower's end",44,58)
	print_with_shadow("click here to start",28,78)

	if cheat then
		print_with_shadow("practice mode enabled!",2,114)
		print_with_shadow("⬅️:prev,➡️:next,⬇️:reset level",2,122)
	end
end

function gameplay_init()
	load_level(current_level)
	state=gameplay
end

function stars_create()
	stars={}
	for i=1,32 do
		star={
			x=rnd(128),
			y=rnd(120)+8,
			vx=rnd(2.0)+0.5,
		}
		add(stars,star)
	end
end

function stars_draw()
	for star in all(stars) do
		star.x-=star.vx
		if star.x<0 then
			star.x+=128
			star.y=rnd(120)+8
			star.vx=rnd(2.0)+0.25
		end
		pset(star.x+cam_x,star.y+cam_y,5)
	end
end
-->8
--helpful helpers--

function print_with_shadow(str,x,y,shadow)
	print(str,x-1,y+1,shadow or 2)
	print(str,x,y,7)
end

function format_time(sec)

	local hours=sec/60\60
	local mins=sec\60%60
	local secs=sec%60
	
	local str=""
	if hours>0 then
		str=str..hours..":"
	end
	
	if mins<10 then
		str=str.."0"
	end
	
	str=str..mins..":"
	
	local str_secs=tostr(secs)
	
	if secs<10 then
		str_secs="0"..str_secs
	end
	
	if #str_secs>5 then
		str_secs=sub(str_secs,0,5)
	end
	
	while #str_secs<5 do
		str_secs=str_secs.."0"
	end
	
	str_secs=sub(str_secs,1,2).."."..sub(str_secs,4,5)
	
	return str..str_secs
	
end

function spr_center(s,x,y,fx,fy)
	spr(s,x-4,y-4,1,1,fx or false,fy or false)
end

mouse_x,mouse_y,mouse_left_time,mouse_right_time,mouse_left_pressed,mouse_left_held,mouse_right_pressed,mouse_right_held=0,0,0,0,false,false,false,false

function mouse_update()

	mouse_x,mouse_y=stat(32)+cam_x,stat(33)+cam_y
	
	if stat(34)&1!=0 then
		mouse_left_time+=1
	else
		mouse_left_time=0
	end
	
	if stat(34)&2!=0 then
		mouse_right_time+=1
	else
		mouse_right_time=0
	end
	
	mouse_left_pressed,mouse_left_held,mouse_right_pressed,mouse_right_held=mouse_left_time==1,mouse_left_time>1,mouse_right_time==1,mouse_right_time>1
	
end

function to_cardinal_dir(dir)
	return flr(dir*4+0.5)%4/4
end

function spd_dir(a,spd,dir)
	a.vx=cos(dir)*spd
	a.vy=sin(dir)*spd
end

function apply_speed(a)
	a.x+=a.vx
	a.y+=a.vy
end

--check if two actors are colliding
function actors_colliding(a1,a2,a1size,a2size)
	local a1size,a2size=a1size or 2,a2size or 2
	return
		a1!=a2 and
		a1.x-a1size<a2.x+a2size and
		a1.x+a1size>a2.x-a2size and
		a1.y-a1size<a2.y+a2size and
		a1.y+a1size>a2.y-a2size
		--rectangle collision stuff
end

--check if this tile is solid--
function check_solid_at(tx,ty)
	--get the tile num @ map pos
	return fget(mget(tx,ty),0)
	--if flag 0 is set, true
	--else, not a solid tile
end


--check if actor in solid tile--
function colliding_with_solid(a)
	local tx,ty=a.x/8-0.25,a.y/8-0.25
	return
		check_solid_at(tx,ty) or
		check_solid_at(tx+0.5,ty) or
		check_solid_at(tx,ty+0.5) or
		check_solid_at(tx+0.5,ty+0.5)
		--check all corners,
		--return true if in solid
end


--collect coin at tile pos--
function collect_coin_at(tx,ty)
	if fget(mget(tx,ty),1) then
		--if the tile has flag 1
		level_coins-=1
		mset(tx,ty,0)
		--increment coin count
		p_starsparkle_create(flr(tx)*8+4,flr(ty)*8+4,0,0)
		sfx(47)
		
	end
end

--actor collect coins--
function collect_coins(a)
	local tx,ty=a.x/8-0.25,a.y/8-0.25
	--divide pos by 8 to get tilemap pos

	collect_coin_at(tx,ty)
	collect_coin_at(tx+0.5,ty)
	collect_coin_at(tx,ty+0.5)
	collect_coin_at(tx+0.5,ty+0.5)
	--collect coins at all corners
end


--check if spike at origin--
function colliding_with_spike(a)
	local tx,ty=a.x/8,a.y/8
	--divide pos by 8 to get tilemap pos
	
	local sprover=mget(tx,ty)
	--get tile index at pos
	return fget(sprover,2)
	--if flag 2 is set (spike),
	--return true
end

--break tile at tilemap pos
function break_block_at(tx,ty)
	local sprover=mget(tx,ty)
	--get index at pos
	if fget(sprover,7) then
		--if flag 7 (breakable) is set
		
		mset(tx,ty,0)
		--delete the tile
		
		sfx(52)
		if sprover<101 then
			p_dirt_create(flr(tx)*8,flr(ty)*8)
		else
			p_dirt_create(flr(tx)*8,flr(ty)*8,true)
		end
		
		if sprover==107 then
			statue_count-=1
			if statue_count==0 then
				destroy_golden_statues()
			end
		end
		
		if sprover==101 then 
			toilet_count-=1
			if toilet_compulsion and toilet_count==0 and current_level==31 then
				unlock_medal(1)
			end
		end
		
		return true
		--did break a block!
		
	end
	
	return false
	--didn't break a block...
end

--break blocks (only for intangible)
function break_blocks(self)
	local tx,ty=self.x/8-0.25,self.y/8-0.25

	break_block_at(tx,ty)
	break_block_at(tx+0.5,ty)
	break_block_at(tx,ty+0.5)
	break_block_at(tx+0.5,ty+0.5)
	
	--checks for and destroys tiles at each corner

end

--break blocks (only for intangible)
function break_a_block(self)
	local tx,ty=self.x/8-0.25,self.y/8-0.25
	--environment collider

	return
		break_block_at(tx,ty) or
		break_block_at(tx+0.5,ty) or
		break_block_at(tx,ty+0.5) or
		break_block_at(tx+0.5,ty+0.5)
	
	--checks for and destroys tiles at each corner

end

function destroy_golden_statues()
	for tx=cam_tx,cam_tx+15 do
		for ty=cam_ty,cam_ty+15 do
			if mget(tx,ty)==91 then
				mset(tx,ty,0)
				p_dirt_create(tx*8,ty*8)
				sfx(38)
			end
		end
	end
end


-->8
--player--

--constants

--combinations of head and body
--at each index
--    sprite 1 2 3 4 ... etc.
player_head=split"2,2,2,2,2,3,3,3,3,-2,-2,-2,-2,-2,1,1,1,1"
player_body=split"5,6,3,7,9,0,4,1,4,7,8,9,-7,-9,0,1,4,2"

--player animations
player_anim_idle={
{1},
{6},
{10},
{15}
}

player_anim_walk={
{2,1,2,1},
{7,6,8,6},
{11,10,11,10},
{16,15,17,15}
}


player_anim_attack={
{3},
{9},
{12},
{18}
}
--player animations end

player_gun_spr=split"2,3,0,-3,-2,-1,0,1"


--functions!

function player_init(x,y,mode)

	player_x,
	player_y,
	player_vx,
	player_vy,
	player_is_blue,
	player_facing_dir,
	player_grounded,
	player_can_double_jump,
	player_anim,
	player_anim_speed,
	player_anim_frame,
	player_swap_timer,
	player_blink_timer,
	player_move_time,
	player_charge_time,
	player_move_lock,
	player_move_lock_time,
	player_dead_timer,
	player_sword=
	
	x, --player_x
	y, --player_y
	0, --player_vx
	0, --player_vy
	mode, --player_is_blue
	0.75, --player_facing_dir
	false, --player_grounded
	true,  --player_can_double_jump
	player_anim_idle, --player_anim
	0.1, --player_anim_speed
	1,   --player_anim_frame
	0, --player_swap_timer
	rnd(90)+60, --player_blink_timer
	0, --player_move_timer
	0, --player_charge_time
	false, --player_move_lock
	0, --player_move_time
	0 --player_dead_time
	--player_sword=nil
	player_update_gun_pos()
	player_pos={x=player_x,y=player_y}
end

function player_die()
	level_deaths+=1
	player_dead_timer=50
	p_playerdust_create()
	sfx(31)
end

function player_update_gun_pos()
	player_facing_dir=atan2(mouse_x-player_x,mouse_y-player_y)
	player_gun_x,player_gun_y=flr(player_x)+cos(player_facing_dir)*5.75,flr(player_y)+sin(player_facing_dir)*4.25-1
end


function player_update()

	if player_dead_timer>0 then
		player_dead_timer-=1
		if player_dead_timer==20 then
			fade_out()
		end
		if player_dead_timer==0 then
			restart_level()
		end
		return
	end

	if colliding_with_spike(player_pos) or colliding_with_enemybullet(player_pos) then
		player_die()
		return
	end
	
	if player_move_lock_time>0 then
		player_move_lock_time-=1
		if player_move_lock_time==0 and (not player_is_blue or player_grounded) then
			player_move_lock=false
		end
	end

	local ix=tonum(btn(➡️,1))-tonum(btn(⬅️,1))
	local iy=tonum(btn(⬇️,1))-tonum(btn(⬆️,1))
	
	if player_swap_timer==0 and player_sword==nil and btnp(🅾️,1) then
		player_swap_timer=30
		player_move_lock=false
		sfx(45)
	elseif player_swap_timer>0 then
		player_swap_timer-=1
		if player_swap_timer==15 then
			player_is_blue=not player_is_blue
			if total_swaps<max_num then
				total_swaps+=1
			end
			update_swap_blocks()
		end
	end

	if not player_is_blue then
	
		if player_swap_timer==0 and player_sword==nil and mouse_right_pressed then
			player_vx,player_vy=0,0
			player_set_anim(player_anim_attack)
			attack_sword_create()
			sfx(39)
		end
	
		if player_sword!=nil then
			attack_sword_update()
			player_move_time=0
		end

		local moving=(ix!=0 or iy!=0)
		
		if player_sword==nil then
			if not player_move_lock and moving and player_swap_timer==0 then
				player_move_time+=1
				player_set_anim(player_anim_walk)
				if player_vx!=0 and player_vy!=0 then
					player_anim_speed=0.14
				else
					player_anim_speed=0.1
				end
			else
				player_move_time=0
				player_set_anim(player_anim_idle)
				player_anim_speed=0.1
			end
		end
		
		if player_move_time==1 then
			player_vx,player_vy=ix,iy
		elseif player_move_time>3 then
			player_vx=0.67*ix
			player_vy=0.67*iy
		elseif not player_move_lock then
			player_vx=0
			player_vy=0
		end
		
		if colliding_with_enemy(player_pos) then
			player_die()
			return
		end
		
	else
	
		local moving=(ix!=0)
		
		if player_swap_timer==0 and not player_move_lock and moving then
			player_move_time+=1
		else
			player_move_time=0
		end
		
		if moving or not player_grounded then
			if player_vy<0 then
				player_anim_speed=0.3
			else
				player_anim_speed=0.15
			end
			player_set_anim(player_anim_walk)
		else
			player_anim_speed=0.1
			player_set_anim(player_anim_idle)
		end
		
		
		if player_swap_timer==0 or player_grounded then
			if not player_move_lock and (player_move_time>3 or not player_grounded) then
				player_vx=0.67*ix
			elseif player_move_time==1 then
				player_vx=ix
			elseif not player_move_lock then
				player_vx=0
			end
		end
			
		
		if player_grounded then
		
			if colliding_with_enemy() then
				player_die()
				return
			end
		
			if player_vy>=0 then
				player_can_double_jump=true
			end
			
			if player_swap_timer==0 and (btnp(⬆️,1) or mouse_right_pressed) then
				sfx(44)
				player_vy=-1.45
			end
		
		else

			if airborne_colliding_with_enemy() then
				player_die()
				return
			end
		
			if player_swap_timer==0 and (btnp(⬆️,1) or mouse_right_pressed) and player_can_double_jump then
				sfx(46)
				player_move_lock=false
				player_vy=-1.45
				player_can_double_jump=false
				for i=0,1 do
					p_spark_create(player_x,player_y,1.33,0.625+0.25*i)
				end
			end
		
			if player_move_lock then
				player_vy+=0.08
			elseif btn(⬆️,1) or mouse_right_held then
				player_vy+=0.06
			else
				player_vy+=0.1
			end
		
		end
	
	end
	
	player_move_collide()
	
	collect_coins(player_pos)

	if player_sword==nil then
		player_gun_update()
	end

	player_anim_frame+=player_anim_speed
	
	player_blink_timer-=1
	if player_blink_timer<=0 then
		player_blink_timer=rnd(90)+60
	end

end

function player_draw()

	if player_dead_timer>0 then
		return
	end
	
	if player_sword!=nil then
		playerbullet_draw(player_sword)
	end
	
	local behind=(player_facing_dir<0.5)
	
	if behind and not end_level then
		player_gun_draw()
	end

	local eye_color=2
	if player_blink_timer<6 then
		eye_color=15
	end

	if player_swap_timer%4>=2 then
		pal(hit_pal)
		eye_color=7
	elseif player_is_blue then
		pal(4, 12)
	else
		pal(4, 14)
	end
	
	rectfill(player_x-3, player_y-3, player_x+2, player_y-1, eye_color)
		
	if end_level then
		sspr(78,0,10,8,player_x-6,player_y-5)
		pal()
		return
	end

	local anim=player_anim[to_cardinal_dir(player_facing_dir)*4+1]
	if player_anim_frame>#anim+1 then
		player_anim_frame-=#anim
	end
	
	local frm=anim[flr(player_anim_frame)]
	
	player_body_head_draw(frm,player_x-4,player_y-4)
	
	pal()

	if not behind then
		--line(player_x,player_y,player_gun_x,player_gun_y+1,13)
		player_gun_draw()

	end

end

function player_gun_update(self)
	player_update_gun_pos()
	
	if mouse_left_held then
		player_charge_time+=1
		if player_charge_time==12 then
			sfx(30,2)
		end
	elseif player_swap_timer==0 then
		sfx(-1,2)
		if player_charge_time>=60 then
			for i=0,1 do
				p_poof_create(player_gun_x,player_gun_y,1,player_facing_dir+0.875+0.25*i)
			end
			pb_chargeshot_create()
			sfx(23)
			player_vx=cos(player_facing_dir)*-2.5
			player_vy=sin(player_facing_dir)*-2.5
			player_move_lock=true
			if (player_is_blue and player_vy>=0 and player_grounded) or not player_is_blue then
				player_move_lock_time=4
			end
		end
		player_charge_time=0
	end
	
	if mouse_left_pressed and player_swap_timer==0 and #player_bullets<3 then
		sfx(22)
		pb_shot_create()
	end
end

function player_gun_draw()

	if player_sword!=nil then
		return
	end

	if (player_charge_time>10 and player_charge_time<60 and global_timer%8<2) or (player_charge_time>60 and global_timer%4<2) then
		pal(11,7)
		pal(3,6)
	end

	local gun_spr=player_gun_spr[flr(player_facing_dir*8+0.5)%8+1]
	local flip_x=false
	
	if gun_spr<0 then
		gun_spr*=-1
		flip_x=true
	end
	
	local s_x=88+gun_spr*4
	local s_y=0
	if gun_spr>1 then
		s_x-=8
		s_y+=4
	end
	
	sspr(s_x,s_y,4,4,player_gun_x-1.5,player_gun_y-2,4,4,flip_x)
	
	pal()

end

function player_set_anim(anim)
	if player_anim==anim then
		return
	end
	player_anim=anim
	player_anim_frame=1
end

function player_body_head_draw(frame,x,y)

	y-=1

	local head_flip=false
	local body_flip=false
	local body_row=0

	--if head index is -, flip x
	local head=player_head[flr(frame)]
	if head<0 then
		head*=-1
		head_flip=true
	end
	
	--if body index is -, flip x
	local body=player_body[flr(frame)]
	if body<0 then
		body*=-1
		body_flip=true
	end
	
	if body>4 then
		body-=5
		body_row=1
	end
	
	if head!=3 then
		spr(head,x,y,1,1,head_flip)
	end
	
	if frame==6 then
		sspr(6*8+body*6+1,body_row*4,4,4,x+2,y+4,4,4,body_flip)
	else
		sspr(6*8+body*6,body_row*4,6,4,x+1,y+4,6,4,body_flip)
	end
	
	if head==3 then
		spr(head,x,y,1,1,head_flip)
	end
	
end

function player_move_collide()

	if colliding_with_solid(player_pos) then
		player_die()
		return
	end

	player_pos.x+=player_vx
	--move to new x position
	if colliding_with_solid(player_pos) then
		--if inside a solid
		repeat
			player_pos.x-=sgn(player_vx)
		until not colliding_with_solid(player_pos)
		--subtract 1 until out of solid
		player_vx=0
		--set x velocity to 0
	end
	
	player_pos.y+=player_vy
	--move to new y position
	if colliding_with_solid(player_pos) then
		--if inside a solid
		if player_is_blue then
			player_break_blocks_with_head()
			--if we're blue, break blocks with head
		end

		repeat
			player_pos.y-=sgn(player_vy)
		until not colliding_with_solid(player_pos)
		--subract 1 until out of solid
		player_vy=0
		--set y velocity to 0
	end
	
	player_x,player_y=player_pos.x,player_pos.y
	
	if player_is_blue then
		if not player_grounded and player_on_ground() then
			player_move_lock=false
		end
		player_grounded=player_on_ground()
	end
end

--check if on ground (gravity)--
function player_on_ground()
	local tx,ty=player_x/8,(player_y+3)/8
	return
		player_vy>=0 and
		(check_solid_at(tx-0.25,ty) or
		check_solid_at(tx+0.25,ty))
		--check two bottom corners
end

--function for player to hit blocks
function player_break_blocks_with_head()
	local tx,ty=player_x/8,(player_pos.y-2)/8
	--use ty at top of hitbox

	return
		break_block_at(tx+0.25,ty) or
		break_block_at(tx-0.25,ty)
		--check at both top corners
end

function colliding_with_enemy()
	for enemy in all(enemies) do
		if not enemy.invuln and actors_colliding(player_pos,enemy) then
			return true
		end
	end
	return false
end

function airborne_colliding_with_enemy()
	local bounce=false
	local died=false

	for enemy in all(enemies) do
		if not enemy.invuln and actors_colliding(player_pos,enemy) then
			if (player_vy<=0 and player_y>enemy.y) or not enemy:stomped_func(self) then
				died=true
				break
			end
			
			bounce=true
			
		end
	end
	
	if bounce then
		player_bounce()
	end
	return died
end

function player_bounce()
	if mouse_right_held	or btn(⬆️,1) then
		player_vy=min(-player_vy, -1.45)
	else
		player_vy=-1.45
	end
	player_move_lock=false
	player_can_double_jump=true
	player_move_collide()
end

function colliding_with_enemybullet()
	for bullet in all(enemies_bullets) do
		if actors_colliding(player_pos,bullet) then
			return true
		end
	end
	for bullet in all(player_bullets) do
		if bullet.deflected and actors_colliding(player_pos,bullet) then
			return true
		end
	end
	return false
end
-->8
--bullets--

eight_dir_spr=split"0,1,2,1,0,1,2,1"

function playerbullet_create(x,y,spd,dir,big)

	local self={
	
		x=x,y=y,
		dir=dir,
		spr=16+tonum(big)*3,
		big=big,
		dmg=1+tonum(big)*2,
		deflected=false,
		flip_x=dir>0.25 and dir<0.75,
		flip_y=dir<0.5,
		pal_timer=0,
	
	}
	
	self.spr+=eight_dir_spr[flr(self.dir*8+0.5)%8+1]
	
	spd_dir(self,spd,dir)
	
	add(player_bullets,self)
	
	playerbullet_update(self)
	
	return self

end

function playerbullet_update(self)

	apply_speed(self)
	
	self.pal_timer+=1
	
	if self.big then
		break_blocks(self)
	end
	
	if playerbullet_hit_enemies(self) or (not self.big and break_a_block(self)) or colliding_with_solid(self) then
		p_explosion_create(self.x,self.y,0.25,self.dir)
		sfx(53)
		del(player_bullets,self)
	end

end

function playerbullet_deflect(self,new_dir)
	local new_spd=2.5+tonum(self.big)*0.5
	self.dir=new_dir
	self.spr=16+eight_dir_spr[flr(new_dir*8+0.5)%8+1]+tonum(self.big)*3
	self.flip_x=(new_dir>0.25 and new_dir<0.75)
	self.flip_y=(new_dir<0.5)
	spd_dir(self,new_spd,new_dir)
	self.deflected=true
end


function playerbullet_draw(self)
	if self.pal_timer!=nil and self.pal_timer%6<3 then
		pal(6,7)
		pal(7,player_is_blue and 12 or 14)
	else
		pal(6,player_is_blue and 12 or 14)
	end
	spr_center(self.spr,self.x,self.y,self.flip_x,self.flip_y)
	pal()
end

function playerbullet_hit_enemies(self)
	local die=false
	for enemy in all(enemies) do
		if not enemy.invuln and actors_colliding(self,enemy,5) then
			if enemy:shot_func(self) then
				if not self.big then
					die=true
				end
			elseif not self.deflected then
				die=true
			end
		end
	end
	return die
end


function pb_shot_create()
	playerbullet_create(player_gun_x,player_gun_y,2,player_facing_dir,false)
end

function pb_chargeshot_create()
	playerbullet_create(player_gun_x,player_gun_y,2.5,player_facing_dir,true)
end



function attack_sword_create()

	local dir=to_cardinal_dir(player_facing_dir)
	local spr=12+tonum(dir%0.5!=0)
	
	player_sword={
		x=flr(player_x), y=flr(player_y),
		vx=0,vy=0,
		dir=dir,
		spr=spr,
		lifetime=0,
		flip_x=dir==0.5,
		flip_y=dir==0.25,
	}
	
	spd_dir(player_sword,2.25,dir)

end

function attack_sword_update()

	if player_sword.lifetime<4 or (player_sword.lifetime>12 and player_sword.lifetime<18) then
		apply_speed(player_sword)
	elseif player_sword.lifetime==12 then
		spd_dir(player_sword,-1.4,player_sword.dir)
	elseif player_sword.lifetime==18 then
		player_sword=nil
		return
	end
	
	if player_sword.lifetime<7 then
		attack_sword_hit_enemies()
	end
	break_blocks(player_sword)
	collect_coins(player_sword)
	
	player_sword.lifetime+=1

end

function attack_sword_hit_enemies()
	for enemy in all(enemies) do
		if not enemy.invuln and actors_colliding(player_sword,enemy,4) then
			enemy:stabbed_func(player_sword)
		end
	end
end
-->8
--level and tilemap--

level_taglines={
"e,s,d,f:move       w/shift:swap!",
"s,f:move  e:jumpX2 w/shift:swap!",
"click to shoot! hold to charge!",
"click to shoot! hold to charge!",
"right click to use your sword!",
"use your charge shot for uppies.",
"a charge shot will set them off.",
"stomp them! hold jump to bounce!",
"watch the shield, bub.",
"watch the shield, bub.",
"burrowed fellows deep in yellow.",
"burrowed fellows deep in yellow.",
"return of booger bars! uh-oh!",
"return of booger bars! uh-oh!",
"beat this one for some green.",
"beat this one for some green.",
"play the game outside!",
"play the game outside!",
"these guys are weak in the face.",
"these guys are weak in the face.",
"it doesn't like being shot, duh.",
"it likes being jumped on, awww!",
"are you clock-wise, clock-dumb?",
"use double jump after you boost.",
"you've entered nippy's domain.",
"you've entered nippy's domain.",
"bust the busts. it's a must!",
"bust the busts. it's a must!",
"welcome to blipstonville!",
"welcome to blipstonville!",
"there's a darkness in the ruins.",
"there's a darkness in the ruins.",
"it's my prized rock collection.",
"it's my prized rock collection.",
"careful with the flowers, plz.",
"careful with the flowers, plz.",
"reeling into the end.",
"reeling into the end.",
"watch for patrolling goons...",
"watch for patrolling goons...",
"you may have to put out fires.",
"jumpin' and shootin'!",
"rate 5 stars if u remember...",
"rate 5 stars if u remember...",
"and now, she must bounce.",
"and now, she must bounce.",
"watch your feet little guys :(",
"watch your feet little guys :(",
"pinwheel of booger returns!!",
"pinwheel of booger returns!!",
"use your boost to get through!",
"aim for brown, blast from star.",
"critter catcher ii!",
"critter catcher ii!",
"the end part 1",
"the end part 1",
"the end part 2",
"the end part 2",
"the end part 3",
"the end part 3",
"gotta light that fuse!",
"gotta light that fuse!",
}
musics=split"0,42,20"

function load_level(num)

	local tiny_num=1+tonum(num>8)+tonum(num>18)

	if last_music_change!=tiny_num then
		music(musics[tiny_num])
		last_music_change=tiny_num
	end

	reload(0x1000,0x1000,0x2000)
	--put back tiles in old level

	current_level=num

	cam_x,cam_y=(num-1)*128,0
	
	while cam_x>1023 do
		cam_x-=1024
		cam_y+=128
	end
	
	cam_tx,cam_ty=cam_x\8,cam_y\8
	--set camera pos for level
	
	camera(cam_x,cam_y)
	
	mouse_x,mouse_y=stat(32)+cam_x,stat(33)+cam_y
	
	init_level()
	--turn start pos tiles into actors
	
end

function next_level()
	if current_level<31 then
		load_level(current_level+1)
	end
end

function prev_level()
	if current_level>1 then
		load_level(current_level-1)
	end
end

function restart_level()
	load_level(current_level)
end

function init_level()

	if cheat then
		level_time=0
		level_deaths=0
	end

	fuse_timer=-1
	toilet_count,level_coins,statue_count,pal_cycle=0,0,0,0
	enemies,enemies_bullets,player_bullets,particles={},{},{},{}
	
	for tx=cam_tx,cam_tx+15 do
		for ty=cam_ty+1,cam_ty+15 do
		
			x,y=tx*8+4,ty*8+4
		
			local tile=mget(tx,ty)
			
			if tile==108 then
				player_init(x,y+1,player_is_blue)
				mset(tx,ty,0)
			elseif tile==109 then
				level_coins+=1
			elseif tile==110 then
				door_create(x,y)
				mset(tx,ty,0)
			elseif tile==107 then
				statue_count+=1
			elseif tile==101 then
				toilet_count+=1
			end
			
		end
	end
	
	for a in all(enemy_data[current_level]) do
		spawn_actor_from_data(a\0x1000%0x10,a\0x100%0x10,a\0x10%0x10,a%0x10)
	end
	
	if level_coins==0 then
		door_spr,door_open=14,true
	end
	
	if current_level==31 then
		door_open=false
		door_spr=59
	end
	
	update_swap_blocks()
	
	fade_in()
	
end

function spawn_actor_from_data(id,x,y,dir)
	enemy_manifestation(id,cam_x+x*8+4,cam_y+y*8+4,dir/16)
end

function update_swap_blocks()
	for tx=cam_tx,cam_tx+15 do
		for ty=cam_ty+1,cam_ty+15 do
			local tile=mget(tx,ty)
			if player_is_blue then
				if tile<78 and tile>75 then
					tile+=16
				elseif tile>93 and tile<96 then
					tile-=16
				end
			else
				if tile>77 and tile<80 then
					tile+=16
				elseif tile>91 and tile<94 then
					tile-=16
				end
			end
			mset(tx,ty,tile)
		end
	end
end

-->8
--enemies--

function enemy_manifestation(id,x,y,dir)
	if id<2 then
		e_joe_create(x,y,dir,id==1)
	elseif id<4 then
		e_robot_create(x,y,dir,id==3)
	elseif id<6 then
		e_ashley_create(x,y,dir,id==5)
	elseif id<10 then
		e_boogerbar_create(x,y,dir,id%2==1 and 1 or -1,id>7)
	elseif id<12 then
		e_nippy_create(x,y,dir,id==11)
	elseif id<14 then
		e_spectre_create(x,y,id==13)
	elseif id==14 then
		e_mushroom_create(x,y)
	elseif id==15 then
		e_fakestar_create(x,y)
	end
end

function e_dummy()
	return false
end

function enemy_create(x,y,dir,hp,spr,pal,update,stab,shot,stomp)
	local enemy={
		x=x,y=y,
		vx=0,vy=0,
		dir=dir,
		hp=hp,
		
		spr=spr,
		pal=pal or {},
		flip=false,
		
		update_func=update,
		stomped_func=stomp or e_dummy,
		stabbed_func=stab or e_dummy,
		shot_func=shot or e_dummy,
		
		hit_timer=0,
		invuln=false,
	
	}
	add(enemies,enemy)
	return enemy
end

function enemy_update(self)
	if self.hit_timer>0 then
		self.hit_timer-=1
	end
	self:update_func()
end

hit_pal=split"7,7,7,7,7,7,7,7,7,7,7,7,7,7,7"

function enemy_draw(self)
	pal(self.hit_timer>0 and hit_pal or self.pal)
	spr_center(self.spr,self.x,self.y,self.flip)
	pal()
end

--move respecting walls--
function enemy_move_collide(a)

	local hit_wall=false

	a.x+=a.vx
	--move to new x pos
	if colliding_with_solid(a) then
		--if hit wall, go back
		a.x-=a.vx
		--and reverse x speed
		a.vx*=-1
		
		hit_wall=true
		
	end
	
	a.y+=a.vy
	--move to new y pos
	if colliding_with_solid(a) then
		--if hit wall, go back
		a.y-=a.vy
		--and reverse y speed
		a.vy*=-1
		
		hit_wall=true
	end
	
	return hit_wall
	
end

function enemy_try_turning(self,spd)

	if self.turn_dir!=0 then

		if (self.vx!=0 and (self.x-4)%8==0) or (self.vy!=0 and (self.y-4)%8==0) then
			self.dir=atan2(self.vx,self.vy)
			
			local old_vx,old_vy,old_dir=self.vx,self.vy,self.dir

			self.dir=(self.dir+1.0+self.turn_dir*0.25)%1
			
			spd_dir(self,spd,self.dir)
			
			if check_solid_at((self.x+self.vx*16)/8,(self.y+self.vy*16)/8) then
				self.vx,self.vy,self.dir=old_vx,old_vy,old_dir
			end
			
		end
	end
	
end

function dir_to_player(a)
	return atan2(player_x-a.x,player_y-a.y)
end

function dist_to_player(a)
	return sqrt((player_x-a.x)^2+(player_y-a.y)^2)
end

function e_joe_create(x,y,dir,turn)

	local right_turning=dir%0.25!=0
	
	if right_turning then
		dir=(dir+0.125)%1
	end

	local self=enemy_create(x,y,dir,6,24,turn and split"4,2" or split"13,5",e_joe_update,e_joe_stabbed,e_joe_shot,e_joe_stomped)
	
	self.turn_dir=turn and (right_turning and -1 or 1) or 0
	
	self.startle_dir=-1
	self.startle_timer=0
	
	spd_dir(self,0.5,dir)
	
	self.spr=joe_sprites[self.dir\0.25+1]+tonum(global_timer%28>13)
	self.flip=self.dir==0.5
end

joe_sprites=split"22,24,22,26"

function e_joe_update(self)

	if self.startle_timer>0 then
		self.startle_timer-=1
		if self.startle_timer==12 then
			self.dir=self.startle_dir
			spd_dir(self,0.5,self.dir)
		end
	else
	
		if enemy_move_collide(self) then
			if self.turn_dir==0 then
				self.dir=(self.dir+0.5)%1
			end
		end
		
		enemy_try_turning(self,0.5)
		
	end

	self.spr=joe_sprites[self.dir\0.25+1]+tonum(global_timer%28>13)
	self.flip=self.dir==0.5

end



function e_joe_stabbed(self,sword)

	if sword.dir==opposite_dir[self.dir] then
		sfx(37)
		return false
	end

	p_enemydust_create(self,sword.dir,8)
	del(enemies,self)
	sfx(38)
	return true
end

function e_joe_stomped(self)

	if self.dir==0.25 then
		self.dir=0.75
		spd_dir(self,0.5,0.75)
		sfx(37)
		return true
	end

	for i=0,1 do
		p_poof_create(self.x,self.y+2,2,0.5*i)
	end
	p_corpse_create(self)
	del(enemies,self)
	sfx(38)
	return true
end

function e_joe_shot(self,bullet)

	local bullet_dir=to_cardinal_dir(atan2(self.x-bullet.x,self.y-bullet.y))
	
	--bullet hit shield
	if bullet_dir==opposite_dir[self.dir] then
		playerbullet_deflect(bullet,self.dir)
		apply_speed(bullet)
		apply_speed(bullet)
		p_poof_create(bullet.x,bullet.y,0,0)
		sfx(37)
		return false
	end
	
	self.hp-=bullet.dmg
	
	--bullet hit but didn't kill
	if self.hp>0 then
		self.hit_timer=6
		self.startle_dir=opposite_dir[bullet_dir]
		if self.startle_timer==0 then
			self.startle_timer=32
		end
		p_enemydust_create(self,bullet.dir,bullet.dmg*2)
		return false
	end
	
	--bullet killed
	p_enemydust_create(self,bullet.dir,8)
	del(enemies,self)
	sfx(38)
	return true

end

function e_robot_create(x,y,dir,fast)
	local self=enemy_create(x,y,dir,6,28,fast and {[12]=9} or {},e_robot_update,e_robot_stabbed,e_robot_shot,e_robot_stomped)
	
	self.chase=false
	self.dist=0
	self.dist_thresh=24
	self.pal[3]=1
	
	self.spd=fast and 0.8 or 0.6
	
	self.flip_time=flr(16-self.spd*10)
	
	spd_dir(self,self.spd,self.dir)
	
	return self
	
end



function e_robot_update(self)

	if self.hit_timer>0 then
		return
	end

	self.dist+=abs(self.vx)+abs(self.vy)
	if self.dist>=self.dist_thresh then
		if self.chase then
			self.dir=to_cardinal_dir(dir_to_player(self))
			spd_dir(self,self.spd,self.dir)
		else
			self.vx*=-1
			self.vy*=-1
		end
		self.dist=0
	end
	
	if global_timer%self.flip_time==0 then
		self.flip=not self.flip
	end
	
	enemy_move_collide(self)
end

function e_robot_stabbed(self,sword)
	sfx(37)
	return false
end

function e_robot_stomped(self)
	for i=0,3 do
		p_spark_create(self.x,self.y+2,2,0.125+0.25*i)
	end
	p_corpse_create(self)
	del(enemies,self)
	sfx(38)
	return true
end

function e_robot_shot(self,bullet)
	if bullet.big then
		self.hp-=3
		if self.hp>0 then
			self.chase,self.dist_thresh,self.hit_timer,self.pal[3]=true,16,6,8
			self.spd+=0.1
			self.hit_timer=6
			self.flip_time-=3
			sfx(55)
			for i=0,3 do
				p_explosion_create(self.x,self.y+2,-0.66,-1)
			end
			return false
		else
			for i=0,9 do
				p_explosion_create(self.x,self.y+2,-0.66,-1)
			end
			del(enemies,self)
			sfx(55)
			return true
		end
	else
		sfx(37)
		return false
	end
end

function e_ashley_create(x,y,dir,idle)
	local self=enemy_create(x,y,dir,3,29,split"8,9",e_ashley_update,e_ashley_stabbed,e_ashley_shot)
	
	self.vanish_timer=0

	if not idle then
		spd_dir(self,dir%0.25!=0 and 0.9333809 or 0.75,dir)
	end
	
	return self
end

function e_ashley_update(self)

	if self.vanish_timer>0 then
		self.vanish_timer-=1
		self.spr=34+tonum(self.vanish_timer%15>7)
		if self.vanish_timer==0 then
			self.spr,self.hit_timer,self.invuln=29,2,false
		end
	end

	if global_timer%10==0 then
		self.flip=not self.flip
	end
	
	enemy_move_collide(self)
	
	if current_level==31 and fuse_timer==-1 and actors_colliding(self,{x=door_x,y=door_y}) then
		fuse_timer=120
	end
	
end

function e_ashley_stabbed(self,sword)
	p_enemydust_create(self,sword.dir,8)
	del(enemies,self)
	sfx(38)
	return true
end

function e_ashley_shot(self,bullet)
	self.hp-=bullet.dmg
	if self.hp>0 then
		self.hit_timer=6
		p_enemydust_create(self,bullet.dir,2)
		return false
	end
	self.hp,self.invuln,self.vanish_timer=3,true,120
	p_enemydust_create(self,bullet.dir,8)
	sfx(53)
	return true
end

function e_boogerbar_create(x,y,dir,turn_dir,long)
	local self=enemy_create(x,y,dir,0,30,{},e_boogerbar_update)
	
	self.invuln=true
	self.turn_dir=turn_dir
	self.turn_spd=long and 0.0035 or 0.007
	self.boogers={}
	for i=1,long and 7 or 3 do
		add(self.boogers,eb_booger_create(x+cos(dir)*5*i+0.5,y+sin(dir)*5*i+0.5))
	end

	--return self
end

function e_boogerbar_update(self)
	local booger
	for i=1,#self.boogers do
		--booger=self.boogers[i]
		self.boogers[i].x=self.x+cos(self.dir)*5*i+0.5
		self.boogers[i].y=self.y+sin(self.dir)*5*i+0.5
	end
	self.dir+=self.turn_spd*self.turn_dir
end

function e_nippy_create(x,y,dir,fast)
	local self=enemy_create(x,y,dir,7,50,fast and split"12,12,1,4" or split"4,4,2,13",e_nippy_update,e_nippy_stabbed,e_nippy_shot)
	spd_dir(self,fast and 0.6 or 0.4,dir)
	self.anim_spd=fast and 10 or 22
	e_nippy_animate(self)
end

nippy_sprites=split"50,53,50,52"

function e_nippy_animate(self)
	self.spr=nippy_sprites[self.dir\0.25+1]+tonum(self.dir%0.5==0 and global_timer%self.anim_spd<self.anim_spd/2)
	self.flip=self.dir==0.5 or self.dir!=0 and global_timer%self.anim_spd<self.anim_spd/2
end

function e_nippy_update(self)

	if enemy_move_collide(self) then
		self.dir=(self.dir+0.5)%1
	end

	e_nippy_animate(self)

end

function e_nippy_stabbed(self,sword)

	if sword.dir!=opposite_dir[self.dir] then
		sfx(37)
		return false
	end

	p_enemydust_create(self,sword.dir,8)
	del(enemies,self)
	sfx(38)
	return true
end

function e_nippy_shot(self,bullet)

	local bullet_dir=to_cardinal_dir(bullet.dir)
	
	if bullet_dir!=opposite_dir[self.dir] then
		return false
	end
	
	self.hp-=bullet.dmg
	
	--bullet hit but didn't kill
	if self.hp>0 then
		self.hit_timer=6
		p_enemydust_create(self,bullet.dir,bullet.dmg*2)
		return false
	end
	
	--bullet killed
	p_enemydust_create(self,bullet.dir,8)
	del(enemies,self)
	sfx(38)
	return true

end

function e_spectre_create(x,y,white)
	local self=enemy_create(x,y,0,0,34,white and {7,7} or {1,1},e_spectre_update,e_spectre_stabbed,e_spectre_shot)
	self.chase_timer,self.stun_timer,self.wakeup_timer,self.white,self.invuln,self.spd=
	-1,
	0,
	0,
	white,
	true,
	white and 0.3 or 0.5
end

function e_spectre_update(self)

	if self.wakeup_timer>0 then
		self.wakeup_timer-=1
		self.spr=54
		if self.wakeup_timer==0 then
			self.chase_timer=1
			self.invuln=false
		end
		return
	end

	if self.stun_timer>0 then
		if self.stun_timer>90 then
			self.stun_timer=90
		end
		self.stun_timer-=1
		return
	end

	if self.chase_timer>0 then
		self.chase_timer-=1
		if self.chase_timer==0 then
			spd_dir(self,self.spd,dir_to_player(self)+rnd(rnd_table))
			self.chase_timer=20
		end
	elseif dist_to_player(self)<24 then
		self.wakeup_timer=30
		self.flip=player_x-self.x<0
		self.y+=2
		p_enemydust_create(self,0.25,6)
		self.y-=2
	end
	
	if self.chase_timer==-1 then
		self.spr=34+tonum(global_timer%15>7)
	else
		self.flip=self.vx<0
		self.spr=48+tonum(self.chase_timer%20<10)
	end
	
	apply_speed(self)
	
end

function e_spectre_stabbed(self,sword)
	p_enemydust_create(self,sword.dir,1)
	if not self.white then
		self.stun_timer=90
	else
		self.spd=min(self.spd+0.1,1)
	end
end

function e_spectre_shot(self,bullet)
	p_enemydust_create(self,bullet.dir,bullet.dmg*2)
	if not self.white then
		self.stun_timer+=10+tonum(bullet.big)*50
	else
		self.spd=min(self.spd+0.05,1)
	end
end

function e_fakestar_create(x,y)
	local self=enemy_create(x,y,0,0,109,{},e_fakestar_update)
	self.invuln=true
	self.run_timer=0
	self.run_threshold=16
	level_coins+=1
end

rnd_table=split"0.9,0,0.1"

function e_fakestar_update(self)
	if self.run_timer>0 then
		self.run_timer-=1
		self.spr=55+tonum(global_timer%8>3)
		if enemy_move_collide(self) then
			spd_dir(self,0.4,(dir_to_player(self)+rnd(rnd_table)+rnd{0.25,0.75})%1)
		end
	elseif dist_to_player(self)<self.run_threshold then
		spd_dir(self,0.4,(dir_to_player(self)+rnd(rnd_table)+0.5)%1)
		self.run_timer=60
		self.run_threshold=32
		
	else
		self.spr=109
	end
	if actors_colliding(self,player_pos) or (player_sword!=nil and actors_colliding(self,player_sword)) then
		sfx(47)
		level_coins-=1
		p_starsparkle_create(self.x,self.y,0,0)
		del(enemies,self)
	end
end

function e_mushroom_create(x,y)
	local self=enemy_create(x,y,0,3,58,{4,2,1},e_mushroom_update,e_mushroom_stabbed,e_mushroom_shot,e_mushroom_stomped)
	self.hiding,self.hiding_timer=false,0
end

function e_mushroom_update(self)

	if self.hiding_timer>0 then
		self.hiding_timer-=1
		return
	end

	if (abs(self.x-player_x)<24 and abs(self.y-player_y)<24) and player_dead_timer==0 then
		self.spr=57
		if not self.hiding then
			for i=0,2 do
				p_endingdirt_create(self.x,self.y+2,rnd(0.25)+0.125)
			end
		self.hiding=true
		end
	else
		self.hiding=false
		self.spr=58
		self.flip=global_timer%20<10
	end
	
	

end

function e_mushroom_stabbed(self,sword)
	sfx(37)
	return false
end

function e_mushroom_shot(self,bullet)
	if self.hiding then
		sfx(37)
		return false
	else
		self.hp-=bullet.dmg
		local spd=0.85
		local dir=atan2(player_x+player_vx-self.x,player_y+player_vy-self.y)
		if bullet.dmg==1 then
			enemybullet_create(self.x,self.y,spd,dir,31)
		else
			for i=0,2 do
				enemybullet_create(self.x,self.y,spd,(dir+0.925+0.075*i)%1,31)
			end
		end
		if self.hp>0 then
			p_enemydust_create(self,bullet.dir,bullet.dmg*2)
			self.hit_timer,self.hiding,self.spr,self.hiding_timer=6,true,57,20
			return false
		else
			sfx(38)
			del(enemies,self)
			p_enemydust_create(self,bullet.dir,8)
			return false
		end
	end
end

function e_mushroom_stomped(self)
	sfx(37)
	return true
end

-->8
--enemy bullets--
function enemybullet_create(x,y,spd,dir,spr)
	local self={
		x=x,y=y,
		vx=0,vy=0,
		spr=spr,
	}
	spd_dir(self,spd,dir)
	add(enemies_bullets,self)
	return self
end

function enemybullet_destroy(self)
	p_poof_create(self.x,self.y,0,0,{4,4})
	del(enemies_bullets,self)
end

function enemybullet_update(self)
	if self.vx!=0 or self.vy!=0 then
		apply_speed(self)
		if colliding_with_solid(self) then
			enemybullet_destroy(self)
		end
	end
end

function enemybullet_draw(self)
	spr_center(self.spr,self.x,self.y)
end

function eb_booger_create(x,y)
	return enemybullet_create(x,y,0,0,30)
end

-->8
--door--
function door_create(x,y)
	door_x,door_y,door_spr,door_open=x,y,110,false
end

function door_update()
	
	if not door_open and level_coins==0 then
		door_spr,door_open=14,true
		sfx(36,3)
		for i=1,6 do
			p_starsparkle_create(door_x,door_y,-0.7,0.1666*i)
		end
	end
	
	if door_open and actors_colliding({x=door_x,y=door_y},player_pos) then
		end_screen_create()
	end

end
-->8
--particles--

function particle_create(x,y,spd,dir,spr,max_frm,spr_delay,pal,lifetime,loop)
	local self={
		x=x,y=y,
		spr=spr,frm=0,
		pal=pal,
		max_frm=max_frm,
		spr_delay=spr_delay,
		lifetime=1,
		max_lifetime=lifetime,
		loop=loop or false,
	}
	
	spd_dir(self,spd<0 and rnd(abs(spd))+spd/-2 or spd,dir<0 and rnd(1) or dir)
	
	add(particles,self)
	return self
end

function particle_update(self)
	
	apply_speed(self)
	
	if self.spr_delay!=0 and self.lifetime%self.spr_delay==0 then
		self.frm+=sgn(self.max_frm)
		if self.frm==self.max_frm then
			if self.loop then
				self.frm=0
			else
				del(particles,self)
			end
		end
	end
	
	self.lifetime+=1
	if self.lifetime>=self.max_lifetime then
		del(particles,self)
	end
	
end

function particle_draw(self)
	pal(self.pal)
	spr_center(self.spr+self.frm,self.x,self.y)
	pal()
end

function p_poof_create(x,y,spd,dir,pal)
	particle_create(x,y,spd,dir,43,-2,3,pal or split"6,13",1000,false)
end

function p_starsparkle_create(x,y,spd,dir)
	particle_create(x,y,spd,dir,38,2,flr(rnd(2)+3),split"7,10,11",20,true)
end

function p_explosion_create(x,y,spd,dir)
	particle_create(x,y,spd,dir,42,3,5,split"10,8,2",1000,false)
end

function p_spark_create(x,y,spd,dir)
	return particle_create(x,y,spd,dir,40,2,5,{7},100,false)
end

function p_playerdust_create()
	for i=1,32 do
		particle_create(player_x,player_y,-0.9,-1,45,3,4+flr(rnd(2)),split"7,8,8,2,2",100,false)
	end
end

function p_dirt_create(x,y,white)
	for i=1,6 do
		particle_create(x+4,y+4,-0.66,-1,45,3,5,white and split"7,7,6,6,13" or split"7,10,10,9,4",100,false)
	end
end

function p_endingdirt_create(x,y,dir)
	particle_create(x,y,-0.66,dir or rnd(0.5),46,2,5,split"2,2,2,2,2",100,false)
end

function p_enemydust_create(x,y,dir,amt,pal)
	for i=1,amt do
		particle_create(x,y,-1,dir+0.835+(0.33/amt)*rnd(amt+1),36,2,7+flr(rnd(1)+0.5),pal or {},30,false)
	end
end

function p_enemydust_create(e,dir,amt)
	for i=1,amt do
		particle_create(e.x,e.y,-1,dir+0.835+(0.33/amt)*rnd(amt+1),36,2,7+flr(rnd(1)+0.5),e.pal,30,false)
	end
end

function p_corpse_create(e)
	particle_create(e.x,e.y,0,0,e.spr==28 and 33 or 32,0,0,e.pal,60,false)
end

-->8
--screen effectz--
function generate_fade_pals()
	local fadeout=split"0,0,1,1,2,1,13,6,2,4,9,3,13,5,2,14"
	local fadepals={[0]=split"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15"}
	for i=1,6 do
		fadepals[i]={}
		for col=1,15 do
			fadepals[i][col]=fadeout[fadepals[i-1][col]+1]
		end
	end
	return fadepals
end

function fade_update()
	if fade_speed!=0 then
		fade_level+=fade_speed
		if fade_level<=0 then
			fade_level=0
			fade_speed=0
			pause=false
		elseif fade_level>=6 then
			fade_level=6
			fade_speed=0
			pause=false
		end
	end
end

function fade_in()
	fade_level=6
	fade_speed=-0.33
	pause=true
end

function fade_out()
	fade_level=0
	fade_speed=0.33
	pause=true
end
-->8
--end screen....--
function end_screen_create()
	
	pause=true
	
	if current_level==8 or current_level==18 or (current_level==31 and not cheat) then
		music(-1,1000)
	end
	
	sfx(15,3)
	
	end_timer,end_radius,end_done=0,92+sqrt( (door_x-cam_x-64)^2 + (door_y-cam_y-64)^2 ),false
	end_level=true
end


function end_screen_draw()

	local circ_size=max(end_radius-end_timer*2*(end_radius/92),0)

	if circ_size!=0 then
		circfill(door_x,door_y,circ_size,6144)
	else
		end_done=true
		rectfill(cam_x,cam_y,cam_x+127,cam_y+127,0)
	end
	
	if circ_size==0 then
		print_with_shadow("level "..current_level.." clear!",cam_x+42-#tostr(current_level)*3,cam_y+40,1)
		print_with_shadow("\nclear time: "..format_time(level_time),cam_x+25,cam_y+47,1)
		print_with_shadow("deaths: "..level_deaths,cam_x+25,cam_y+62,1)
		print_with_shadow("\n click to continue",cam_x+27,cam_y+73,1)
	end
	
end

function end_screen_update()

	end_timer=min(end_timer+1,9999)
	
	if mouse_left_pressed and end_done then
		sfx(-1,3)
		total_deaths+=level_deaths
		total_time+=level_time
		if total_time<0 then
			total_time=max_num
		end
		if total_deaths<0 then
			total_deaths=max_num
		end
		level_time,level_deaths=0,0
		toilet_compulsion=toilet_compulsion and toilet_count==0
		last_mode=player_is_blue
		if current_level==8 then
			--unlock wilderness medal
			unlock_medal(2)
		elseif current_level==18 then
			--unlock prism medal
			unlock_medal(3)
		end
		end_level=false
		if current_level<31 then
			if cheat then
				restart_level()
			else
				next_level()
			end
		else
			if cheat then
				restart_level()
			else
				ending_init()
			end
		end

	elseif mouse_left_pressed then
		end_done,end_timer=true,2000
	end
	
end
-->8
--ending--
function ending_init()
	state,
	ending_timer,
	tower_sprites,
	tower_angle,
	tower_progress,
	tower_table,
	cam_x,
	cam_y=
	ending,
	0,
	split"1,3,4,2,3,4,2,4,2,3",
	0,
	0,
	{{61,61},{62,62},{63,62},{62,63}},
	0,
	0
	camera()
	fade_in()
	time_str=format_time(total_time)
	

end

function ending_update()

	for particle in all(particles) do
		particle_update(particle)
	end

	if ending_timer+1<max_num then
		ending_timer+=1
	end
	
	tower_angle+=0.0222222
	tower_angle%=1
	
	if ending_timer<180 then
		sfx(55,1)
		local x,y=rnd(20)+6,100-(ending_timer/180)*64+rnd(8)-8
		p_explosion_create(x,y,0,0)
		p_endingdirt_create(x,y,-1)
	end
	
	if ending_timer>180 and tower_progress<73 then
		tower_progress+=0.1
		p_endingdirt_create(rnd(16)+8,97)
	end
	
	if ending_timer%15==1 and tower_progress<73 then
		sfx(55)
	end
	
	if ending_timer==900 then
		sfx(62)
	elseif ending_timer==950 then
		music(0)
	end
	
	--unlock turbo jeri
	if ending_timer==1910 and total_time<1500 then
		unlock_medal(5)
	end
	
	--unlock ms.perfect
	if ending_timer==2140 and total_deaths==0 then
		unlock_medal(6)
	end
	
end

function ending_draw()

	cls(14)

	
	tower_draw()
	
	
	for particle in all(particles) do
		particle_draw(particle)
	end
	
	local pile_y=max(88,96-(tower_progress/73*8))
	
	spr(60,8,pile_y)
	spr(60,16,pile_y,1,1,true)
	
	local hair=4
	if global_timer%12<6 then
		hair=5
	end
	
	pal(3,1)
	spr(117,32,96,1,1,true)
	spr(116,40,96,1,1,true)
	pal()
	
		--jeri hair
	spr(hair,104,64)
	
	draw_water()
	
	map(112,48)
	
	if ending_timer>1110 then
	
		if ending_timer<1335 then
			print_with_shadow("\^t\^wjeri ii",38,36)
			print_with_shadow("tower's end",44,50)
		elseif ending_timer<1590 then
			print_with_shadow("game by",52,37)
			print_with_shadow("\^w\^tsUcco",46,45)
			rect(54,45,55,45,7)
			rect(58,45,59,45,7)
			rect(53,46,54,46,2)
			rect(57,46,58,46,2)
		elseif ending_timer<1910 then
			print_with_shadow("music by",50,37)
			print_with_shadow("\^w\^towlbag",42,45)
		else
			print_with_shadow("completion time: "..time_str,30-2*(#time_str),39)
			print_with_shadow("total deaths: "..total_deaths,38-2*(#tostr(total_deaths)),48) 
			print_with_shadow("total swaps: "..total_swaps,40-2*(#tostr(total_swaps)),57)
		end
		
		if ending_timer>2140 then
			if total_deaths==0 then
				print_with_shadow("you are a super player!",19,24)
			else
				print_with_shadow("thank you for playing!",21,24)
			end
		end
		
		if ending_timer>2780 then
			print("q+w+e+⬆️ on title",60,122,5)
		end

	end

end

function tower_draw()

	for i,t in pairs(tower_sprites) do
	
		local y=24+(i-1)*8+tower_progress
		if y<96 then

			local angle=tower_angle+i/9
			angle%=1
			
			local x=8+cos(angle)*2
			local sprs=tower_table[t]
			
			spr(sprs[1],x,y)
			spr(sprs[2],x+8,y,1,1,true)
			
		end
	end

end

function draw_water()
	rectfill(0,104,127,104,9)
	rectfill(0,106,127,107)
	rectfill(0,110,127,112)
	rectfill(0,117,127,121)
end
-->8
--newgrounds inte--
function set_pin(pin,value)
	poke(0x5f80+pin, value)
end

function get_pin(pin)
	return peek(0x5f80+pin)
end

function unlock_medal(num)
	set_pin(2,num)
end

got_medals={false,false,false,false,false,false}
medals=split("jiggle the handle;grass toucher;look ma, no floor!;tower's end;easier with legs;ms.perfect ~eternal~",";")

function draw_medals()

	if medal_timer==0 then
		current_medal=get_pin(2)
		if current_medal!=0 and not got_medals[current_medal] then
			medal_timer=180
			set_pin(2,0)
			got_medals[current_medal]=true
			sfx(54,0)
		end
	else
		rectfill(cam_x,cam_y+122,cam_x+127,cam_y+127,1)
		print("medal get: "..medals[current_medal],cam_x,cam_y+123,7)
		medal_timer-=1
	end

end
__gfx__
00000000004444000044444000444400000000000000000000000000000000000000000000000000004444000bb00000000000000002f0004422424200000000
000000000444f44004444f440444444022000000200000000dddd00dfdd0fd00d0f0d0d00dddd0000444f4400bb0bb0000000000002222004111111400000000
00700700040ff0400440ff04044444402222200022200000fdddd00ddd200dddd22dddd002ddd000f40ff0400bb03bb0020000000008e0002661111200066000
0007700004ffff40044ffff4044444402222000022222000020020000220220022220220022000f0f4ffff400330f33022eeeee80008e000466dd11400600600
0007700044f88f44444f88f04444444442222200422200000000000000000000000000000000000feff88f4400000bb0f28888800008e000266dd55200600600
00700700040880400040880004044040421120004222220000ddd0f0ddd00ddd000ddd000d0d0d0efedd8d40bbbbbb30020000000008e000466dd55200066000
0000000000000000000000000000000022100000221220000dfdd02ddd220dddd022ddd20dddd20000ddddf033333300000000000008e000466dd55200000000
0000000000000000000000000000000021000000212200000022000200200022000200200220220002000220f000f00000000000000080002422222400000000
00000000000000000000000000066660006000000006060000000000011010000000000001101100000000000110110000c7c700000000000000000000000000
00000000000000000000000006667766600666000066666001101000001110c0011011000011100001101100001110000c7c7c70010010100000000000000000
000000000007000000007000666777760667676006676660001110c0011717c600111000c111110000111000017c666c0d6776d000111110000ab00000044000
070777000070700000070000066677760666777606776766011717c6111111c6c1111100c1111100017c666c011c666c0d3773d60171171000a7ab00004ff400
007077000007770000007000667777760677777606777776111111c6112111c6c111110011111110011c666c111c666cdd6776dd1722217000bab300004ff400
000000000000770000077000066777660677777606777776112111c6011110c611111110c1111100111c666c011c666c6d1551d0112222100003500000044000
000000000000000000077000006666600667766006677766011110c60011100cc111110001111100011c666c0111ccc00d676d50127772100000000000000000
0000000000000000000000000000000000666600006666601100010c001100000ccc0110111000001100ccc00000110005500000011711000000000000000000
00000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000022200000000000000000000000000
00000000000000000000000000000000000000000000000000000300000002000000000000000000000000000011000002000020000200000000000000000000
00000000000000000000000000000000001001000000000000003230000321230010001000000000000100000211211030000000001230000002000000000000
00000000000000000011110000000000000220000000100000300300000002000001010000010100000201000011112002000002022344000023400000040000
0010010007c0c0700100001000111100001210000000000000200000003003000000100000001000002120000021110003000033003450000004000000000000
00111100d117711d1000000101000010000101000000000032123000032300000001010000010100000010000212122020000000000400000000000000000000
177117710d6776d00100001000111100000000000000000000200000003000000010001000000000000000000020220030200030000000000000000000000000
00100100055005500011110000000000000000000000000000300000000000000000000000000000000000000000000000033000000000000000000000000000
00000000111010000000000000000000000100000000100000000111000300000003000000000000001ff1000000000000000000000000000002222200022222
11101000001181110110100000000000010110000001101001011110003a3000003a300000000000011111100000000000000000022000220002222200022222
001181110111111000110100111010000111101001011110111810103baaab303baaab3000000000122222210000600000000012022000220002222200022022
0111111001101010101111010111110110111110011111010111000003aaa30003aaa30000111100227227220000d00000012121022222220002222200020002
011010100110000001111110111111101111110000111111001111100030220002203000011ff110022ff2200000600000121212022222220002222200020002
0111110011100000111113700111137001377310011111100011100002200000000022001111111200f22ff00000d60002112121022222220002222200020002
111100001111100001117776111177760177670000411110001111000000000000000000211111220ff22f0000000ddd21221111002222220002222200020002
11100000011100000044400004400400044000000000044001111000000000000000000002222220000fff000000000021111111000222220002222200022222
1111111000010000000000000000020000000000dd000d0001001020201100002000000000000001000000000000000d00050000000000000002000000000000
10000000000000000000000000002020d000dd0220d0d0d00011002021011100200288000000000d000000000000000d00005000000000000000200000000000
10000000000000000030000000000200220d022002d020220000000020100f100008888000000001000000000000000d00050000000000000002000000000000
0000000000000000303000000040000002222008002202000008020001000001000288800000000d000000000000000d00000000000050000000000000002000
1110111110000000010000000404000002000002080000010802020001000001080082220000000d00000000000000d100050000005000500002000000200020
0000100000000000000030100040000000002002020020000202002000100010020022d20000000d000000000000dd1000000000000050000000000000002000
00001000000010000000010000000000010100000200020002000000800111000200022d0000000ddddddddddddd100000050000000000000002000000000000
00000000000000000000000000000000000f10800000020000000002000000020000000d0000000d000000000000000000000000000000000000000000000000
15151551100101011315135100666600f999999404440550053535500003b00000000000dd0d02025551151500a77a005ccccc50000000002888882000000000
51155555000001105113553506666660944444444441451553535330005bb30000166d00d0000000111111110a9aa9a0ccccccc00c00c00c8888888008008008
115115150101101111311513056666d094444444414445500b3b35b505bbbbb001677760000000020000010009aaaa905ccccc5005c0c0c52888882004808084
5511551111001100551135110dd5d5d02444444204442225052552505b3b3b300d76776dd0000000051001100949949051555150005c53501122211000484240
11555115011000111135311305ddddd1422222212042222200422400035353501d6d6dd100000005011005109499994955515550c53ccc002222222084288800
55511555000110003531135305d5d5d1422222210552424200244200053535301ddddd312000000005100510094444905511155000c5c3c52111112000848284
15115151101011011311513105d5d5d142222221515522200202202003b3b3b531dd1130000000050110011004988940151115100c0c00501211121008080040
51551551100100103153153100d5d5102111111255502200000000005b3b3b500011300020205050000000000048840000000000000000000000000000000000
1115511500011001111531156d556d559a9aa99000077700000000000533b53500000000d22d225d000000dd0077770000000000000300004422424200000000
15115551010011101311533111111111a9aa99a000d67770000ff000535bb35000161600dd00d0050d000dd506d77d600008c000003a3000411bb11406006006
5115511510011001511331130dd006d09a999a900006677000f44f0005bbbbb0016567602dd00d050dd0ddd50d6776d00008c0003baaab30211aa11205606065
6d6d66d6000000006d6d66d606d00dd099a9944006777660002ff2005b3b3b300d76d66d20dd00d1ddd25d25067777600008c00003aaa3224baaaab400565d50
d6d66d6d00000000d6d66d6d06d006d04994494067cc676000422400035353501d6d6dd1200dd00d2dd55222006dd6000888ccc00b333b2021baab1265d66600
6dd5d6d5000000006dd3d6d306d006d094494940067776d000244200053535301ddddd31d211dd110551222006d66d600088cc000322232041a11a1200656d65
d515151110101011d3131311055005504444442000d66d000202202003b3b3b531dd113000000000015122100d6dd6d00008c000002000204b1111b206060050
00000000000000000000000000000000000000000d66d5d0000000005b3b3b5000113000000000000011110000d66d0000000000000000002422222400000000
0000ff00000000000000000000000000000000000000030011313313111111113133111100000000000000000000001442000000000000000551015551111000
0000fff000000000000000000000000000000000003011031311313111111111013113110000000000000222000dd55445150000000000004450331155111000
00000fff0000000000000000000000000000100100101301331313131111111113131111000000000000242200555dd5555d5000000000104441231111144000
00000fff00000000000000000000000000000101301331311311131111111111311111110000000000000424000111d5d5110000000000011410412212244000
ff00ffff00000000000000000000000301001331131313131113111111111111113111110000000000000444000d515551110000000000221100412112200000
ffffffff0000000000000000000030030030311111311111131111311111111111111111000000f0000044440005115111150000000022101000122122230000
0ffffff00000100000010000003010310013331331111111311111111111111111111111000000000000044400d510dd55150000002210000102232132210000
00ffff00010011011011001003101013103111311111111111111111111111111111111100000000000002440055005d55115000121000000032213111313110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
85858585858585858585858585858585766565656565657565756565656565769595959595959595959595959595959595959595959595959595959595959595
95969696969696969596969696969695959696969696969696969696969696959596969696969696959696969696969595959595959595959595959595959595
8524242486d6d6d6d6d68524d6d6248576f524f534343465c66534f585f524769596969696969696969696969696969595969696969696969696969696969695
9500b6b6b6b6b600950035b6b6b60095950000000000000000000000000000959500b6b6b6b6b600e5f6f6f60000f695950000000000000000f6f6f6a6a6a695
8524242485d6858585d68624d6d62485763434243434342486243400342434769535350000000000000000000035359595350035003500000000350035003595
9500b6b6b6b6b600950000000000009595000000000000a6a6000000000000959500b6b6b6b6b600e5f6000000000095950000000000000000f6f6f6a6a6a695
8585c685850086d6d6d68586248586857634d6d6243434d6d6d63434243434769535e600a600a6a6a6a600a6000035959500c60000000000000000d6d6d60095
9500b6b6b6b6b600950000000000009595000000000000a6a6000000000000959500b6b6b6b6b600e5f6000000000095950035000000000000f6f6f6a6a6a695
85242424868685d685858624248524857634d6d6342434d6d6d634243434c5769500000000d6d6d6d6d6d600000000959500000000000000000000d6d6d60095
95e5e5e5e5e5e5e5950000959595959595f50000d600a6a6a6a600d60000f5959595959595959595950000000000009595000000000000009595959500000095
85242424242424d6248686d62486d6857634d6d63434243485342485343434769500a6a6a6a600a6a600a6a6a600009595350035003500000000350035003595
950000000000000096e5e596969696959500f5a6a6a6a600e6a6a6a6a6f500959596969696969696960000000000009595000000000000009696969600000095
8585868685858585248686d68586d6857634d6d634c53485e685343434343476950000000000d6d6d6d6000000000095959595959595f6f600f6959595959595
9500000000000000f50000b50000009595000000a6a6a60000a6a6a60000009595f6f6f6f6f6f6f6f60000f60000f69595f6f6f6000035000000000000350095
852424d6d6d624d6248586242424d6857634d6d634342434863424343400347695000000a6a6a600a6a6a6a6a6000095959595959595d5d500f6959595959595
9500000000000000f50000b500e600959500000000a6a60000a6a6000000009595f600f6f60000f6000000f6f600009595000000000000000000000000000095
85d6858686868585248685d68586858576348534342434342434342434348576950000d6d6d6000000d6d6d600000095959595959595d5f6f5f6959595959595
9500000000000000f50000b5000000959500d60000a600000000a60000d6009595f60000f500000000000000f600009595000000000000000000000000000095
85d685d624d6d6d6248686d686008585763434342434343485343434243434769500a6a6a6a6a600a6a600a6a6a60095959595959595d5d500f6959595959595
95000000c6000000f60000959595959595003500a6000000000000a60035009595000000f500000000000000f656f6959500000095a6a6a6959595a6a6a6a695
85d685d6858586858685852485d68685763434243434343424343434342434769500000000d6d6d6d6d6d60000000095959696969696f5f500f5969696969695
950000000000000095e5e5969696969595000000000000d6d6000000000000959500c600f500000000f6f6f6f6f6f6959500000095a6a600f6f6f600a635a695
85d686d6862424d6d6d6242486d686857634d6d6d63485342434853434342476950000a6a6a600a600a6a6a600c6009595350035003500000000350035003595
9500b6b6b6b6b600950000000000009595000000000000d6d60000000000009595b5b5b5f6f6f6f6f6f6f6f6f6f6f6959500000095a6a600f6f6f600a6a6a695
85d68586858585858686858685d6868576243434343434342434343434853476955600000000000000000000000035959500d6d6d60000000000000000e60095
9500000000000000950035b6b6b60095950000000000000000000000c600009595000000000000000000000000e600959500c60095a6a600f6f6f600a6e6a695
852424242424d6d6d6d6d62485e686857634f53434f534342434f5c53434f576953535000000000000000000003535959535d535d53500f600f635d535d53595
95f6f6f6f6f6f6f695f6f6f6f6f6f695950000000000d60000d600000000009595f6f6f6f6f6f6f6f6f6f6f6f6f6f6959500350095a6a600f6f6f600a6a6a695
85858585858585858585858585858585767575757575757575757575757575769595959595959595959595959595959595959595959595959595959595959595
95959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000970000000000000000009700
95959595959595959595959596969695959595959595959595959596969695959595959595959595959595959595959595959595959545969696969595969595
00000000000000000000000000000000959696969696969696969696969696951515151515151515151515151515151500070000000000000000000000000000
95969696969696969696969600c624959596969696969595959596d6d6d6969595969696959696969695969696969695959696969696f5f6f6f6f69696f69695
00959595959595959595959595959500950000000000000000000000000000951544544454445444544454445444541500000000000000009700000000000000
95d6d6d6d6d6d6d6d6d600002475009595000000000096969695f6d6d6d6f695950000c695000000009500000000569595f6f6f6f5f6f6000000f6f6f600f695
009596969696969696969696969695009500959595959595959595a6959500951564746474647464746474648464741500000000000000000000000000000000
95d6d6d6d6d6d6d6d6d62400756575954500c6000000f6f6f696f6d6d6d6f6959500000095000000009500000000009595f5f6f500000000f6f5f60000000095
0095d6d6d6d6d6d6d6d6d6d6d6d6950095a6959696969695969696009695a6951516161616161616161616a5a5a5a51500000000970000000000000000970000
95d6d62400000024d6d6002476e665959500000000d6f5f5f5f6f5f6d5f5f5959500363696e536c5e596c536e536c59595f6000000f6f5f6f6d6000000000095
0095d63535a6a63535a6a63535d6950095a6950000005695000000000095a69515c500c5e5000000c50000009400001500000000000000000000000000000000
95d6d60000550000d6d6f6f665a6f5959500c5000000f5f5f5f50000d5d5f5959500000000000000f600000000f6009595f50000f695969696d600f600000095
0095d635350000000000003535d6950095009500e600009600950035009500951500e50000e50000c500e6a4b400001597000000000000000000000000000000
95d6d60055555500d6d6f5f5f5f5f59595f6f6f6f6f6f6f6f5f500f5f5d5d595950000000000f6000000f600f500009595f5f5f5f595000000d600f6f600f695
0095d6d6d6000000000000d6d6d6950095a6950000000000009500000095a69515e5c50000c5e500c50000000000001500000000000000009700000000000097
95d6d60000550000d6d6f5f5f5f5f5959596969696959595f6f600000000d5959595959595959595959595950000f695950000d60095f6e6f6c500f600000095
00950000d600c5e6c6c500d60000950095a6953636363696969696009695a69515000000e500c5151616161616161615000000000000000000000000a7000000
95d6d62400000024d6d6f5f5f5f5f59595000000e6959696f6f6f50000f5f695959696969696969696969696f60000959500d6000095f6f6f6f6f6f636363695
0095e535d60000f5f50000d635e5950095a6950000003500003500000095a69515c5e500c50000150000e50000000015000000000000000000970000b7c70000
95d6d6d6d6d6d6d6d6d6f5f5f5c5f59595a6a6a6a696f6f6f5f500f60000009595f600f600000000f600000000000095950000d60096969696959595d6d6d695
00950000d6d6d60000d6d6d60000950095009500c6000000000000000095009515c500000000e5150000e500000000150000000000970000000000d7e7f70027
95d6d6d6d6d6d6d6d6d6f5f5f5f5f5559500000000f5f5f5f5f5d60000f500459500000000f6000000009536b53636959500d60000f6f6f6f696969500000095
009500000035d60000d635000000950095a695003500000000000035009500951500c5c5e500e515c5c515a5a5a5a51517271727000000000000475767675767
95f5f5f5f5c5f5f5f5f5f5c5f5f555559500000000f5f5f5f5f500f500000095953636c5369536e5363695e5000000959500000000f6000000f6f69636363695
009500d600e5d6d6d6d6e500d60095009500959595959595959595959595a6951500e50000c50016000015000000001577777777000000000047877777777777
95f5c5f5f5f5f5f5c5f5f5f5f5f5f5559500000000f5f5f5f6f600000000c59595e500000095000000c595e500e600959500c5c5f6f600f60000000000000095
009500f6f6e5f60000f6e500f60095009500f5d6d60000d6d6d600d6d6f5a69515e5c5e5c50000e500001500c600001500000000000000004787777777777777
95d5d5d5d5d5d5d5d5d5d5d5d5d5d5959500000000f6f6f69595f6f6f6f6f69595b6b6b6b695b6b6b6b695e50000009595d5d5d5d50000f6f6f6f6f6f6c6f695
0095959595959595959595959595950095a6f500d5d500d500d500d5d5f5009515000000e50000e50000150000f6561500000000000037578777777777777777
95959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595
00969696969696969696969696969600959595959595959595959595959595951515151515151515151515151515151500000000003767777777777777777777
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888668888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888886886888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888886886888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888668888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888777777887777778877777788777777888888888877777788777777888888888888888888888888888888888888
88888888888888888888888888888888888882777777827777778277777782777777888888888277777782777777888888888888888888888888888888888888
88888888888888888888888888888888888882227728827722288277227782227728888888888222772882227728888888888888888888888888888888888888
88888888888888888888888888888888888888827788827788888277827788827788888888888882778888827788888888888888888888888888888888888888
88888888888888888888888888888888888888827788827777888277772888827788888888888882778888827788888888888888888888888888888888888888
88888888888888888888888888888888888888827788827777888277778888827788888888888882778888827788888888888888888888888888888888888888
88888888888888888888888888888888888888827788827728888277287788827788888888888882778888827788888888888888888888888888888888888888
88888888888888888888888888888888888888827788827788888277827788827788888888888882778888827788888888888888888888888888888888888888
88888888888888888888888888888888888888777788827777778277827788777777888888888877777788777777888888888888888888888888888888888888
88888888888888888888888888888888888882777788827777778277827782777777888888888277777782777777888888888888888888888888888888888888
88888888888888888888888888888888888882222888822222288228822882222228888888888222222882222228888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888777887787878777877788788877888887778778877888888888888888888888888888888888888888888
88888888888888888888888888888888888888888882278872727272728272787888728888827282787278788888888888888888888888888888888888888888
88888888888888888888888888888888888888888888278272727272778277828882777888827782727272788888888888888888888888888888888888888888
88888888888888888888888888888888888888888888278272727772788278788882227888827882727272788888888888888888888888888888888888888888
88888888888888888888888888888888888888888888278277827772777272788888778888827772727277788888888888888888888888888888888888888888
88888888888888888888888888888888888888888888288228822282228282888882288888822282828222888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888778788877788778787888887878777877787778888877788778888887787778777877787778888888888888888888888888
88888888888888888888888888887282788227887282727888827272728272727288888227887278888872822782727272722788888888888888888888888888
88888888888888888888888888827882788827827882778888827772778277827788888827827278888277782782777277882788888888888888888888888888
88888888888888888888888888827882788827827882787888827272788278727888888827827278888222782782727278782788888888888888888888888888
88888888888888888888888888828772777877728772727888827272777272727778888827827788888877882782727272782788888888888888888888888888
88888888888888888888888888882282228222882282828888828282228282822288888828822888888228882882828282882888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101010401040101010181810101810181810002000400000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5052506260625062626062626060605052606262626050525252505262626250525252506260506060606060505262505260606050526062606262505252505250626260626262606062626262606250525252606363606363606260636362505052505252525052505250525252505250606060606060606060606060606050
5260600000536200005f5f0000000052506d6d6d650062606260525253005352506062620000506d6d6d6d6d5062655252530053625200000000655260605252520000006464646400000000006d6d525060620000005f0000536f53000000525250525250505454545454545454545050530000536d536d536d536554005350
52535d0000005d0000005f00006e0052526d6d645400000000005252000000505253006400006063636363636000005250006c0000626363636363605f5f6050500000006464646400000000006d6d5252006c000000000000000000005300505254545454545400000000000000545052006c00536d656d656d5300006e0052
505d005f00005d5d5352500000000050526d645c5c006d6d6d005052006c0050500000640000006d6d6d6d6d0000005050000000005f6d6d6d6d6d5f5f006d52526f006f525052526062646464626050505300000000000000000000006e005052545d5d5d5f0000006d00006d00545250000000000000000000005300000050
505e5e5e50525250606262606250525050645c005c006d6d6d00505000000052520000640000000000000000000000525250526000005f5f5f5f5f005f6d5f52505264526062606253000000006d6d505252500000536f5300005d00000000525254006c000000006d6d6d00000054505053535300006d006d00000053005350
5200005d60606262536f006f00626050525c00005c006d6d6d0052525e5e5e525200006260636363636363636363625250526200005f00005f00005f005d0052525000520000000000000000006d6d525250626363606262636362600000005050545f6e5f540000006d0000545f545052000000000000530000000000000052
50005c00006f00006f00000000000052500000005c000000000050526464645052005d0000000000005f00000000005250525f0000005f00005f005f0053645250520052000000000000000000005350506064646464646464646464000062525054005f005d5f000000005f5d0054525200000000006d006d00000000000052
5200000000000000000000000000005252000000545052000000525264646450520000006d0000006d506d005f6d5f5052505f5f006d005f6d00006d006f005052620060526c506062625060626260525253646d64646d6d6d6d64646464645252540000006d005f005400006d0054505000000000000000000000536f005350
5252525053006f00000053505e5e5e52500000005252505e5e5e525064646452500000006d00005f6252605d505e525050506f005f000000005f005f5d520050506f006f625060005f0062005f000052506d646d646464646464646464646452525400006d6d6d00000000006d00545250005300005363636353000000000052
50606262606260506f6f50520000005052646464505250646464606264646452505d0000000000006d606d005200625252506f6f00006f00006f00006f520052520000000062005f005f005f00526d505253646d646d006d006d006d646d64505054005f006d5f00006d000000005452520000006f6d6d6d6d6d6f00005f0050
50000000005300606260626200000052520000006262606464646464646464525263636362526d00005d00526000005052526f006f00006f00006f006f5000525200530000005f535f006d005f506d52506d646d64006d006d006d00646d645050540000005d005400000000545d5452505f005f00005f000000005f00540050
52006c0000000000000053000000005050006e00646464646d6d6d6d6d646450520000005360636363636360000000525250526f6f536f6f536f6f535062005250006e0000005352005f005f00526d505253646d646f5f6f6f5f6f6f646d645252546d540000000000005f6d6d6d5452506d005f005400005f545f005f000052
520000000000000000000000005c00525000000064646464646464646464645050006c000000000000000000006e00525260626062626262606262606200005052000000005352505d005f005d5253525265536464646464646464646454645250546f6f6f6f6f6f6f6f545454545450505f005c005f005c0000005c00000050
50525252500000530000000000000050525250525252526f6f6f6f6f6f6f505252000000535250505050505200530052506e0000006464646464640000005352526f6f6f53525052505d5d5d5052525250005d5d5d646d6d6d6d6d646464645052545454545454545454545052505252526f6f6f6f6f6f6f6f6f6f6f6f6f6d50
5252505050525050525250505052525050525250505052525252525250525050525250525052525052525050525250525250525252505250525052505252525250525252525052505252505052505250525050525252505052525050505250505052525252505052525250525252525050505250505052525052505050505250
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5040404052575757575757575757575757675767675656565667676766676767566656565656565656566666666666665757575757575757575757575656565757575757575667675767675767676757575756565762626262524256565757575757575757575757575757575757575752626252626252525252626262625266
606363636056565656565656565656676756565656006d6d4256565642565667576c0000004242426d6d665f5f5f5f666756565656565656565656564200426767565656566667676767675656565667675642425666666666626262665656675262626260626267675656565656566752426c526f6f626252626d6d6d6d6266
57000000000042420068004242420067676642426f426d6d424242424242576756665766000000006d6d665f5d6e5d66676d6d6d4300426d6d6800436d6d6d676742004200425667675656006d6d00676766660066000042005b004200424256520000000000536767526262546252675242535242006f6f62666d6d6d6d6666
67006c0000430000436800436d430067674365436f006d6d42006d6d6d00676766575642424200680068666d5f5d0066675757570000006d6d6842006d6d6d6767006c006e4342676742425d6d6d5d67676c004200426600425b0043006e006652006c0000004256566200006d00526752004262000042006666686668686666
67006600006d6d6d4258426d6f6d4267670043006f585858420000004200676757670000000000000000660000005f66675656560043006d6d580042575757676742680042005d565600425f6d6d5f676700426600000000005b4200420042525200000000004242425b006d6f6d526752006d6d6d0000000000000000000066
6743004200004200006800436d43006767666666586d6d6d585f6f6f425f676767676600430000424242665f005f00666700425f000057575757586856565667670042430066006d42005d5757575767676643420000420000526262626262626262625342424243425200006d005267526363520042006d6d6d000000000066
6742000000000000426842000042006767576f00006d686d000000004200676767670000000000000000665f00006d66674200425f0056565656004200424367674200005f006d686d424356565656676766006b006b000066626666666666665757576d424342424262626262626267520000520066006d6d6d000000660066
670000666643004200585858685857676767005858586d58585800004258676767674242000000006600666d5f00006667000000005f00575757006d6d004267675757570000426d0000420042424267676642000000426600424200424242666756566f6f426f424242434242425467626262620000006d6d6d006600000066
676f006666006f00424242006d6d6767676700006d6d6d6d6d0000584200676767566600004242420043660000005f6667436d4200425f676756006d6d000067675656564200000043005800005f0067676600006b4266004342426842426b6667526262605b6052576d426f6f42426766666666000000000000000000000066
6700430000004266666666576d6d5667676700006d6d6d6d6d0000004200676767434200000000000000665f005f5f6667006d0000000056565f426d6d005f67676d6d6d430042000042005f6f006f67676b6642000066420000004342424266675200006d0000526757526262534267666d6d6d00000066666666666d6d6d66
67420000000000666d6d6d565858586767560000005868684242424258586767676d5742420066000000665f006d5f6656426d00000000005800006d6d5f0067676d6d6d0042586800000042006e006767424200000042420042420068426b6667526d6d536d6d526767526e00004267666d6d6d00000066686868666d666d66
67665d66665f666642574242686e5867676c000000006d00000058586e585667676d6700000000424242000000005f666600540042000000005d5f425f0057676757575742005f5f426f6f6f6f6f6f67670042420042420062620042424242666752006d6d6d00526767526d6f0042676600660000000066686868666d6d6d66
674200424200420000565757585858676757424242426d424268686868585767676d5666666666660000665f5f5f5f66660042006f00006c00425d00005f566767676767576d6d6d6d57575757575767674300006b0066430042426842426b5767526d0000006d52675662626253426766000000000066666866686666666666
6757575757575757575767675757576767565757575757575757575757576767674268426d6d6d434257660000000066660000005743575757576f6f6e6f57676767676767576d6d576767676767676767656642000066686f6f6f6f6f6f6f56676262625462626267536b6b6b424267666d6f6f6f6d68686866686868686e66
5656565656565656565656565656565667576767676767676767565656675667565757575757575757676666666666666666666656665667675657576657565656565656566757576767676767676767675757575757575757575757575757576757575757575757676757575757576766666666666666666666666666666666
__sfx__
150a000005250052000525001200082500520005250012000a2500120003250012000325003250032300321005250052000525001200082500520005250012000a2500120011250012000b2500b2200a2500a210
150a000005250052000525001200082500520005250012000a25001200032500120003250032500323003210062500520006250012000625005200062500120007250012000c2500120000250002200425004210
150a000005250052000525001200082500520005250012000a2500120003250012000325003250032300321000250002500024000240002300023000220002200023000240002000020000200002000020000200
150a00000125005200012500120005250052000125001200072500120001250012000125001210012400121000250042000025000200042500420000250002000a250012000c250012000a2500a2200825008200
150a000001250052000125001200082500520005250012000a2500120005250012000b2500b2100c2400c210002500420000250002000425004200002500020007250012000c250012000b2500b2200c2500c220
150a00000a250002000a250002000a250002000a25000200082500020008250002000825000200082400020007250002000020000200002000020000250002500024000240002300023000220002100021000000
010a00000522005320052200532005330052300533005230053400524005350052500525005450052500545005440053400543005330054200532005420053200541005310054100531005415052150541505215
000a00000122001320012200132001330012300133001230013400124001350012500125001450012500145000440003400043000330004200032000420003200041000310004100031000415002150041500215
150a00001850011500115501c500115001d500115501d5001850011500115501c500115001d500115501d5001850011500115501c500115001d500115501d5001850011500115501c5000b5500b5500c5500c550
150a00001850011500115501c500115001d500115501d5001850011500115501c500115001d500115501d5001335013350133301333013320133201331013310133301334013300133000b5000b5000c5000c500
450a0000243001d3001d3000c30019330193301d30029300243001d30019330193301d300293001d3002930018330183101d300283001d3002930018330183301833018330183301833018320183201831018310
450a0000243001d3001d3000c30016330163301d30029300243001d30014330143301d300293001d3002930013330133101d300283001d3002930013330133301333013330133301333013320133201830018300
350a0000355553550029550355103055029500245503051029525005001d550295102b550005001f5502b51025555195001955025510245502950018550245102252500500165502251024550005001855024510
350a0000355553550029550355103055029500245503051029525005001d550295102b550005001f5502b5102b555195001f5502b5102c55029500205502c5102e52500500225502e5102c55000500205502c510
010a00000122001320012200132001330012300133001230013400124001350012500125001450012500145005440053400543005330054200532005420053200541005310054100531005415052150541505215
000600002755027522275122750027555295352b5502b5302b5101350013500135001f50013200162001c6651c600106001c6551c600106001066510600106001064510600106000c6450c600106000c64500000
350a00001d7501d7501d7501d7501d7321d7321d7221d7121d7501d7501d7501f7501f7501f75020750207101d7501d7501d7501d7501d7301d7301d7221d7121d7501d7501d7521f7501f7501f7502075020710
350a000027750277502775227752277322773225750257502575225712247502475024750247102275222752227522275222732227121d7001d70019720197102775227752277302772025752257522573025720
350a0000247502475024750247502473224732247222471224752247522475222750227502275020750207101d7521d7521d7521d7521d7301d7301d7201d7101d7501d7501d7501f7501f7521f7522075220712
350a000027750277502775027752277322773229752297522975229712257522575225750257102b7522b5522b5522b5522b4122b4122b3122b31219720197102c7502c5502c5322c5222e5502e4202e3122e312
350a00001b7501b7521b7521b75227700277001d7521d7421d7001d7001d7001d700115521132211422114221132211222111221112211222113221143211432114421154211742117521b7501b7101875018750
350a00003075230552305523055230412304123031230312303123031230212301123011030310303103021030017240002400024000240002400030000300002c7002c5002c5002c5002e5002e4002e3002e300
04010000253402b330003001332000300003000030000300003000030000300003000040000700007000070000600000000000000000000000000000000000000000000000000000000000000000000000000000
00020000146701b67023070150700a07004670026700a670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7d0a00002911029110291102911029110291102911029110291202912029120291202913029130291302913023100231002313523135231402312523150231302415011100291501d12023150231302215022150
7d0a0000241102411024110241102411024110241102411024120241202412024120241302413024130241301f1501f1301f10023100231002310023100231002410011100291001d10023100231002210022100
350a00001b7501b7501b7501b75027700277001d7501d7401d7001d7001d5501d75011700113001f4201f4201f3221f2221f1221f1221f2221f3221f4321f4322042220542207102071022752227522271022710
450a0000183001d3001d300203001d330203361d316203161d300200001d330203361d316203161d300200001c3301f3361c3161f3161d300200001c3301f3361c3161f3161c3161f3161c3161f3161c3001f300
450a0000183001d3001d300203001d330203361d316203161d300200001d330203361d316203161d300200001c3301f3361c3161f3161d300200002b3302b3302b3102b310283402833024340243402233022320
450a0000243001f30028200283001c3301f3361c3161f316180001c3001f330243361f316243161f00024000243302833624316283162430028300223301833622316183161f3301f3261c330283261c32628316
00040000194201b4201c4201d4301e4301f4302042021420224202442025420264202743028430294302a4302b4302c4302d4302d4202f4203042031420324303343034430354303543036430364303742038420
5a020000365702e570345702f5702f5702f5702f570336702e5702d570356702d670285703367023570376701b5703f67035670276702d6700857014670005701d67010650000000465013650000000665000000
1d0a00001d3501d3101d3001e300203512035020350203501d3501d3500a3000a3001b3501b3501d3500a30023350233202335023320233100a3002235022320223200a30020350203101d3501d350203500a300
1d0a00001d3000a3001d3501e300203512035020350203501d3501d3500a3000a3001b3501b3501d3500a30023320233102333023310233402332023350233302435011300293501d32023350233302235022350
1d0a0000113200a3001d3501e300203512035020350203501d3501d3500a3000a3001b3501b3501d3500a3002b555285552455018500245502455022555245551f5501f520105551355510550105400c5500c510
350a0000207502075020752207521d7321d7321d7221d71220712207221d7521d7521d7501d7501f7401f7501f7521f7521c7521c7521c7101c7101d7421d7301d7121d7121f7501f7521f7521f7521875218712
4c020101166501a6600f6601a66017660216600f660066600d6600565007250072500724008250092500b2500e250272501d2601f250242502a2601e2501a2502b25030250272602d260392603f2603b2601c000
4a01000033570335702f57026550285503d5000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
4801000023660166600d660086601766002660016600a660026600d1700d1600d1600e160101501115013150161601616013170111700f1700e1700d160000000000000000000000000000000000000000000000
4c0100000e46011460184601e47026470384701d46015460114600b46000470004600040000400004000060000600006000060000600006000000000000000000000000000000000000000000000000000000000
3d0a0000294502945029430294202942029410294102942029420294202943029420294102941029415004000040000400274202943024450244002345023450204402044024430244301d4501d4501b4501b450
3d0a00001d4501d4501b4501b41020450204502b400294002940029400182401820017240172001424014400172501440018250144001726014400182602340017270144001827023400164501d400144501b400
3d0a00001d4501d45020450204101d4501d4502b40029400294002940018240182001724017200142401440024250242502424024240242302423024220242201c225102251c235102351c245102451c25510255
3d0a00001d4501d45020450204101d4501d4502b400294002940029400182401820017240172001424014400182101c2101f2101c2201f220182201f220242302823024240282402b2501f2401f2201d2401d220
4801000007560095500d56014570375702b570225003b5002a500335002f5002a5000c7000f700107000b70007700067000670007700097000a70006700067000670006700067000770008700087000670006700
100200000f7500f75017560175601755018550175501575017750187402254022540225401f74020740285502855020750217500e53021530295300f53025530085402254009550235500b560275500655025540
480300002b76037760387602d76011760047700175000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480400001c32020320243202b3303a3303e3303430022100221000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
400a0000202502025020250202501d2501d2501d2201d22020250202401d2501d2201d2001d2001f2501f2501f2501f2201c2501c220182000a2001d2501d2201d2200a2001f2501f2501f2501c200182500a200
400a0000202502025020250202501d2511d2501d2501d25020250202401d2501d220232502325024250242101f2001f2001c2001c200182000a2001d2001d2001d2000a20018250182501b2501c2001c2500a200
400a0000202502025020250202501d2501d2501d2501d25022250222401d2501d22020250202501f2501f2101f2001f2001c2001c200182000a2001823018230182301823018250182501b2501c2001c2500a200
410a000022250222502225022250202502025020250202501f2501f2401d2501d2201c2501c25018250182101f2001f2001c2001c200182000a2001823018230182301823018250182501b2501c2001c2500a200
01020000196700f6702367017650116701d67011630266600f6500e650176500b6500006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170200002f6703c6702d6701d670116701760000600006000c5000050025500005002c50000500005003160034500000000000000000000000000000000000000000000000000000000000000000000000000000
970500001140031470314702c47031470364703440031400004000040000400004000040000700005000050000700007000000000000000000000000000000000000000000000000000000000000000000000000
53020000346702f67038670326702d67029670306703267021670336703a670206700e67019670346702d670136702a6700967036670046700000000000000000000000000000000000000000000000000000000
010a00001835300000376103761518353000003761037615183530000037610376151835300000376103761518353000003761037615183530000037610376151835300000376103761518353000001835337615
010a00001835300000376103761518353000003761037615183530000037610376151835300000376103761518353000003760037600183330000037610376001835300000376153760037615000003761037615
010a00001145305425376153760011453054253761537600114530542537615376001145305425376153760011453054253761537600114530542537615376001145305425376153760011453054251145305400
010a00000d4530142537610376150d4530142537610376150d4530142537610376150d453014250d453014250c4530042537610376150c4530042537610376150c4530042537610376150c453004250c45300425
010a00000d4530142537610376150d4530142537610376150d4530142537610376150d453014250d453014250c4530042537600376000c4000040037600376000c4000040037600376000c400004001140005400
010a00001835300000376003760037610376151835337600183000000037610376151835300000376103761518353000003760037600376103761518353376001830000000376103761518353000003761037615
4b060000336703067021670196701367013670156700f670116701467017670106700a6700d6700c67009670096700b6700a67005670036700467001670026700267001670016700007003670026700067000670
280300001d5601e56022560265602956029560295602c5002c5001750017500161001610015100141001510000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00580838
00 01180838
00 00600838
00 02190939
00 0028083a
00 01290838
00 0028083a
00 022a0939
00 0028083a
00 01290838
00 0028083a
00 022b0939
00 03300a3b
00 04310a3b
00 03300a3b
00 05320b3c
00 00200838
00 01210838
00 00200838
02 02220939
01 060c6162
00 060c6162
00 060c613a
00 060c613a
00 000c4c38
00 030d4d38
00 000c4c38
00 030d4d38
00 06100c38
00 07110d38
00 06120c38
00 07130d38
00 00140c38
00 03140d38
00 06140c38
00 071a0d38
00 00100c38
00 03110d38
00 00120c38
00 03130d38
00 0c4c5515
02 0d4d6162
01 031b0a3d
00 041c0a3d
00 031b0a3d
00 051d0b3d
00 03300a3d
00 04310a3d
00 03300a3d
00 05330b3d
00 07300a3d
00 0e310a3d
00 07300a3d
00 05330b3d
00 031b0a3d
00 041c0a3d
00 031b0a3d
00 051d0b3d
00 03230a3d
00 04110a3d
00 03230a3d
02 051a0b3d
00 375b4a7d
00 435b4a7d

