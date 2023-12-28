local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)
local MODMEM  = minetest.get_mod_storage()
local S       = minetest.get_translator(MODPATH)
local schem   = MODPATH.."/schematics/spawn_ship.mts"

-- TODO midas effect (player named midas is gonna have a great time till he tries to eat)
-- TODO captain (player named "captain" spawns on a raft)
-- TODO aladin (player spawns on a carpet; it does not fly)

local function boom(np, r, intensity)
	assert(np        ~= nil)
	assert(r         ~= nil)
	assert(intensity ~= nil)

	local particle_texture = nil

	if minetest.is_protected(np, "") then
		return -- fail fast
	end

	local n = minetest.get_node_or_nil(np)

	if n and n.name ~= "air" then
		local node_def = minetest.registered_nodes[n.name]
	
		if node_def and node_def.tiles and node_def.tiles[1] then
			particle_texture = node_def.tiles[1]
		end

		if node_def.on_blast then
			-- custom on_blast
			node_def.on_blast(np, intensity)

		else
			-- default behavior
			--local resilience = iaspacecannon.node_resilience[n.name] or 1
			--if resilience <= 1 or math.random(resilience) == resilience then
				minetest.set_node(np, {name="air"})
				local itemstacks = minetest.get_node_drops(n.name)
				for _, itemname in ipairs(itemstacks) do
					if math.random(5) == 5 then
						-- chance drop
						minetest.add_item(np, itemname)
					end
				end
			--end
		end
	end

	minetest.sound_play("tnt_explode", {pos = np, gain = 1.5, max_hear_distance = math.min(r * 20, 128)})
end

local function avalanche(pos, r)
	assert(pos ~= nil)
	assert(r   ~= nil)

	for x=pos.x-r,pos.x+r,1 do
		for y=pos.y-r,pos.y+r,1 do
			for z=pos.z-r,pos.z+r,1 do
				--local np = vector:new(x,y,z)
				local np = {x=x, y=y, z=z}
				minetest.spawn_falling_node(np)
			end
		end
	end
end

local function boom_spawn_ship(pos, r)
	assert(pos ~= nil)
	assert(r   ~= nil)

	--local minp = vector:new(pos.x - r, pos.y - r, pos.z - r)
	local minp = {x=pos.x - r, y=pos.y - r, z=pos.z - r}
	--local maxp = vector:new(pos.x + r, pos.y + r, pos.z + r)
	local maxp = {x=pos.x + r, y=pos.y + r, z=pos.z + r}
	local nps  = minetest.find_nodes_in_area(minp, maxp, {"beds:bed_bottom", "beds:bed_top", "default:chest", "default:chest_open", "doors:door_glass_a", "doors:door_glass_b", "doors:door_glass_c", "doors:door_glass_d",})
	local intensity = 4
	for _, np in ipairs(nps) do
		boom(np, r, intensity)
	end

	avalanche(pos, r)
end

local function add_to_chest(chest_inv, stackstring)
	local stack     = ItemStack(stackstring)
	local leftover  = chest_inv:add_item("main", stack);
	assert(leftover:is_empty())
end
local function chest_with_suit(pos, r)
	assert(pos ~= nil)
	assert(r   ~= nil)

	if not minetest.get_modpath("spacesuit") then return end

	local chest  = minetest.find_node_near(pos, r, {"default:chest",})
	assert(chest ~= nil)

	local meta      = minetest.get_meta(chest)
	local chest_inv = meta:get_inventory()

	local res = chest_inv:set_size("main", 4*8) -- TODO necesssary ?
	assert(res ~= false)

	add_to_chest(chest_inv, "spacesuit:helmet 1")
	add_to_chest(chest_inv, "spacesuit:chestplate 1")
	add_to_chest(chest_inv, "spacesuit:pants 1")
	add_to_chest(chest_inv, "spacesuit:boots 1")
end

local function spawn_ship(objref)
	assert(objref ~= nil)
	--if objref:get_pos() ~= nil then print('objref already has pos') end

	local pos  = nil
	local ymin, ymax
	if minetest.get_modpath("multidimensions") then
		ymin =  200 -- TODO
		ymax = 1000
	else
		ymin =  200
		ymax = 1000
	end
	while pos == nil do -- find a place where the ship can be spawned
		local x = math.random(-31000, 31000)
		local y = math.random(  ymin,  ymax) -- spawn in low orbit
		local z = math.random(-31000, 31000)

		pos = {x=x, y=y, z=z} --vector:new(x, y, z)

		--if not iaspacecannon.can_destroy(pos) then
		--	pos = nil
		--end
		
		if minetest.place_schematic(pos, schem,"random",nil,false) == nil then
			pos = nil
		end
	end

	-- set player in the middle of the ship
	local r = 7
	pos = {x = pos.x + 2, y = pos.y + 1, z = pos.z + 2}
	objref:set_pos(pos)

	-- put a spacesuit in the chest so he can survive in space
	chest_with_suit(pos, r)

	-- give the player some exposition
	if minetest.get_modpath("ianews") then
		local player_inv = objref:get_inventory()
		local stack      = ItemStack("ianews:newspaper_newplayer 1")
		local leftover   = player_inv:add_item("main", stack)
		assert(leftover:is_empty())
	end

	-- give the player some time for exposition
	local wait = 90 + math.random(0, 60)
	minetest.after(wait, boom_spawn_ship, pos, r)
end

return spawn_ship



