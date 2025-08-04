pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include jeri2_enemy_data.p8l

function _init()
	enemy_data=split(enemy_data,";")
	for i,data in inext,enemy_data do
		enemy_data[i]=data=="" and {} or split(data)
	end
	reload(0x0000,0x0000,0x3000,"jeri2.p8")
	camera_pos={}
	camera_pos.x=0
	camera_pos.y=0
	global_timer=0
	start_editor()
end

function _update60()
	update_editor()
	global_timer=max(global_timer+1, 0)
end

function _draw()
	draw_editor()
end

enemy_defs={
	[0]={icon=22,dir_inc=4,pal_swap={13,5}},
	{icon=22,dir_inc=2,pal_swap={4,2}},
	{icon=28,dir_inc=4,pal_swap={}},
	{icon=28,dir_inc=4,pal_swap={[12]=9}},
	{icon=29,dir_inc=2,pal_swap={8,9}},
	{icon=29,dir_inc=0,pal_swap={8,9}},
	{icon=30,dir_inc=1,pal_swap={}},
	{icon=30,dir_inc=1,pal_swap={}},
	{icon=30,dir_inc=1,pal_swap={}},
	{icon=30,dir_inc=1,pal_swap={}},
	{icon=52,dir_inc=4,pal_swap={4,4,1,13}},
	{icon=52,dir_inc=4,pal_swap={12,12,1,4}},
	{icon=49,dir_inc=0,pal_swap={}},
	{icon=49,dir_inc=0,pal_swap={7}},
	{icon=58,dir_inc=0,pal_swap={4}},
	{icon=55,dir_inc=0,pal_swap={}},
}

function mouse_update()
	mouse.x=stat(32)
	mouse.y=stat(33)
	if stat(34)==1 then
		mouse.left_held+=1
	else
		mouse.left_held=0
	end
	if stat(34)==2 then
		mouse.right_held+=1
	else
		mouse.right_held=0
	end
end

function mouse_draw()
	rect(mouse.x,mouse.y,mouse.x,mouse.y,7)
end

function mouse_left_pressed()
	return mouse.left_held==1
end

function mouse_left_held()
	return mouse.left_held>1
end

function mouse_right_pressed()
	return mouse.right_held==1
end

function mouse_right_held()
	return mouse.right_held>1
end

function setup_editor()
	mouse={x=0,y=0,left_held=0,right_held=0}

	poke(0x5f2d,1)
	--enable mouse
	
	testing=true

	enemy_mode=false
	tile_mode=true

	enemy_selection=0
	enemy_rotation=0

	tile_index=0
	tile_page=1
	tiles_changed=false
	editor_mode=tile_mode
end

function start_editor()
	setup_editor()
	camera()
	editor_change_level(current_level)
	if cursor_pos==nil then
		cursor_pos={x=7,y=7}
	end
end

function update_editor()

	mouse_update()
	
	if mouse.x>0 and mouse.x<128 then
		cursor_pos.x=flr(mouse.x/8)
	end
	
	if mouse.y>0 and mouse.y<128 then
		cursor_pos.y=flr(mouse.y/8)
	end
	
	if btnp(🅾️,1) then
		editor_mode=not editor_mode
	end
	
	if btnp(⬅️,1) then
		save_enemy_data()
		save_tile_data()
	end
	
	if btnp(➡️,1) then
		editor_next_level()
	end
	
	if btnp(⬇️,1) then
		editor_prev_level()
	end
	
	if editor_mode==enemy_mode then
		update_editor_enemy_mode()
	end
	
	if editor_mode==tile_mode then
		update_editor_tile_mode()
	end
	
end

function update_editor_enemy_mode()

	if btnp(❎) then
		enemy_rotation-=enemy_defs[enemy_selection].dir_inc
		if enemy_rotation<0 then
			enemy_rotation+=16
		end
	end	
	
	if btnp(🅾️) then
		enemy_rotation+=enemy_defs[enemy_selection].dir_inc
		if enemy_rotation>=16 then
			enemy_rotation-=16
		end
	end
	
	if cursor_pos.y>0 then
	
		if mouse_left_pressed() then
			place_actor(enemy_selection, cursor_pos.x, cursor_pos.y, enemy_rotation)
			update_enemy_placement()
		end
	
		if mouse_right_held() then
			delete_actor_at(cursor_pos.x, cursor_pos.y)
			update_enemy_placement()
		end

	else
		if mouse_left_pressed() then
			enemy_selection=min(cursor_pos.x,#enemy_defs)
			
			while enemy_rotation%enemy_defs[enemy_selection].dir_inc!=0 do
				enemy_rotation+=1
				if enemy_rotation>=16 then
					enemy_rotation-=16
				end
			end
			
		end
	end

end

function update_editor_tile_mode()
	if btnp(❎) then
		tile_page+=1
		if tile_page==3 then
			tile_page=0
		end
	end	
	
	if btnp(🅾️) then
		tile_page-=1
		if tile_page==-1 then
			tile_page=2
		end
	end
	
	if cursor_pos.y>0 then
		if mouse_left_held() then
			mset(camera_pos.x+cursor_pos.x,camera_pos.y+cursor_pos.y,64+tile_index+tile_page*16)
			tiles_changed=true
		end
		if mouse_right_held() then
			mset(camera_pos.x+cursor_pos.x,camera_pos.y+cursor_pos.y,0)
			tiles_changed=true
		end
	else
		if mouse_left_pressed() then
			tile_index=(cursor_pos.x)
		end
	end
end

function save_enemy_data()
	local str='enemy_data="'
	for l in all(enemy_data) do
		str=str..''
		for i,a in ipairs(l) do
			str=str..sub(tostr(a,true),1,6)
			if i!=#l then
				str=str..","
			end
		end
		str=str..';'
	end
	
	str=str..'"'
	printh(str, "jeri2_enemy_data", true)
	printh("current_level="..current_level, "jeri2_enemy_data", false)
end

function save_tile_data()
	if tiles_changed then
		cstore(0x1000,0x1000,0x2000,"jeri2.p8")
		tiles_changed=false
	end
end

function draw_editor()

	cls()
	
	map(camera_pos.x,camera_pos.y)
	
	if editor_mode==enemy_mode then
		draw_editor_enemy_mode()
	end
	
	if editor_mode==tile_mode then
		draw_editor_tile_mode()
	end
	
	draw_placed_actors()
	
	if global_timer%30<15 then
		rect(cursor_pos.x*8,cursor_pos.y*8,cursor_pos.x*8+7,cursor_pos.y*8+7)
	end
	
	mouse_draw()
	
end

function draw_editor_enemy_mode()
	color(6)
	draw_enemy_icon(enemy_selection,cursor_pos.x*8,cursor_pos.y*8)
	if enemy_defs[enemy_selection].dir_inc!=0 then
		draw_enemy_dir_line(enemy_selection,cursor_pos.x,cursor_pos.y,enemy_rotation)
	end
	draw_enemy_bar()
	rect(enemy_selection*8,0,enemy_selection*8+7,7,7,7)
end

function draw_editor_tile_mode()
	spr(64+tile_index+tile_page*16,cursor_pos.x*8,cursor_pos.y*8)
	spr(64+tile_page*16,0,0,16,1)
	rect(tile_index*8,0,tile_index*8+7,7,7,7)
end

function draw_enemy_bar()
	for i=0,#enemy_defs do
		draw_enemy_icon(i,i*8,0)
	end
end

function update_enemy_placement()
	enemy_data[current_level]={}
	for a in all(placed_actors) do
		value=flr(a.rot)
		value+=a.y*0x10
		value+=a.x*0x100
		value+=a.id*0x1000
		add(enemy_data[current_level],value)
	end
end

function load_placed_actors()
	placed_actors={}
	for a in all(enemy_data[current_level]) do
		place_actor(a\0x1000%0x10,a\0x100%0x10,a\0x10%0x10,a%0x10)
	end
end

function place_actor(enemy,x,y,rot)
	a={id=enemy,x=x,y=y,rot=rot}
	add(placed_actors, a)
end

function delete_actor_at(x,y)
	for a in all(placed_actors) do
		if a.x==x and a.y==y then
			del(placed_actors,a)
			return
		end
	end
end

function draw_enemy_icon(id,x,y)
	pal(enemy_defs[id].pal_swap)
	spr(enemy_defs[id].icon,x,y)
	if id>7 and id<10 then
		print("L",x,y,8)
	end
	pal()
end

function draw_enemy_dir_line(id,x,y,dir)

	local x,y=x*8+4,y*8+4
	local dir=dir/16
	
	local turn_dir=0
	if id==1 then
		local right_turning=dir%0.25!=0
		turn_dir=right_turning and -1 or 1
		dir=to_cardinal_dir(dir)
	elseif id>5 and id<10 then
		local right_turning=id%2==0
		turn_dir=right_turning and -1 or 1
	end
	
	local dest_x,dest_y=x+cos(dir)*8,y+sin(dir)*8
	
	line(x,y,dest_x,dest_y,7)
	
	turn_dir=(dir+1+turn_dir*0.25)%1
	
	if turn_dir!=dir then
		line(dest_x,dest_y,dest_x+cos(turn_dir)*3,dest_y+sin(turn_dir)*3,9)
	end
	
end

function to_cardinal_dir(dir)
	return flr(dir*4+0.5)%4/4
end

function draw_placed_actors()
	for a in all(placed_actors) do
		if a.id<6 or a.id>9 then
			draw_enemy_icon(a.id,a.x*8,a.y*8)
		end
		if enemy_defs[a.id].dir_inc!=0 then
			draw_enemy_dir_line(a.id,a.x,a.y,a.rot)
		end
		if a.id>5 and a.id<10 then
			draw_booger_bar(a.id,a.x*8,a.y*8,a.rot/16)
		end
	end
end

function draw_booger_bar(id,x,y,dir)
	local length=id>7 and 7 or 3
	for i=0,length do
		spr(30,x+cos(dir)*5*i+0.5,y+sin(dir)*5*i+0.5)
	end
end

function editor_change_level(num)

	if num<1 or num>31 then
		return
	end
	
	current_level=num
	
	load_placed_actors()

	camera_pos.x=(num-1)*16
	camera_pos.y=0
	
	while camera_pos.x>=128 do
		camera_pos.x-=128
		camera_pos.y+=16
	end
	--set camera_pos pos for level
	
end

function editor_next_level()
	if current_level+1>31 then
		return
	end
	editor_change_level(current_level+1)
end

function editor_prev_level()
	if current_level-1<1 then
		return
	end
	editor_change_level(current_level-1)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
