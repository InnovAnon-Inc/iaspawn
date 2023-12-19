local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)
local MODMEM  = minetest.get_mod_storage()
local S       = minetest.get_translator(MODPATH)
local schem   = MODPATH.."/schematics/spawn_ship.mts"

iaspawn = {
	souls = {}, -- list of player names
}

-- TODO remember souls data
--minetest.deserialize( MODMEM.get("souls") )
--

-- Save the souls table during server shutdown
minetest.register_on_shutdown(function()
    local serialized_souls = minetest.serialize(iaspawn.souls)
    -- Save the serialized string to a file using standard file I/O
    local file = io.open("souls_data.txt", "w")
    if file then
        file:write(serialized_souls)
        file:close()
    end
end)

-- Load and recreate the souls table on server startup
local file = io.open("souls_data.txt", "r")
if file then
    local serialized_souls = file:read("*a")
    file:close()
    iaspawn.souls = minetest.deserialize(serialized_souls)
end













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

	local pos = nil
	while pos == nil do -- find a place where the ship can be spawned
		local x = math.random(-31000, 31000)
		local y = math.random(  2000,  4000) -- spawn in low orbit
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
	minetest.after(120, boom_spawn_ship, pos, r)
end



-- TODO spawn dummy player entity
--minetest.register_on_leaveplayer(func(ObjectRef, timed_out))
--minetest.register_on_prejoinplayer(func(name, ip))








-- TODO minetest registered entities on_activate(self, staticdata, dtime_s)
-- TODO on activate, register entity in lineage table
-- TODO when a player is created, register player in lineage table
-- TODO when a player spawns an entity, create link in lineage table
-- TODO when an entity spawns an entity, create link... how ?

minetest.register_on_newplayer(function(objref)
	assert(objref:get_pos() ~= nil) -- testing


	local player_name = objref:get_player_name()
	assert(player_name ~= nil)

	local soul = iaspawn.souls[name]
	if soul ~= nil then -- old soul
		-- TODO check whether entity is still alive
		-- if entity is alive, then the new player "becomes" the entity
		-- remove the entity
		-- transfer any inventory to the player
		-- return
		-- otherwise
		--
        	local meta = player:get_meta()
        	meta:set_int("dead", 1)
		return
	end

	-- new soul
	iaspawn.souls[player_name] = {
		-- TODO register this name so it can be used to track lineage later
		mother = nil,
		father = nil,
	}
end)

minetest.register_on_joinplayer(function(player)
        local meta = player:get_meta()
        if meta:get_int("dead") == 1 then
                local name = player:get_player_name()
                minetest.kick_player(name, "You died on a hardcore server.")
        end

	-- TODO give the player a newspaper
	spawn_ship(player)
end)

minetest.register_on_dieplayer(function(objref)
	local meta = objref:get_meta()
       	meta:set_int("dead", 1)
       	minetest.kick_player(name, "You died on a hardcore server.")
end)

minetest.register_on_respawnplayer(function(objref)
	assert(false)
end)






-- TODO compatible entities need to manaually register their "player name"
-- TODO when a player prejoins, check the name ? => set spawn pos to entity pos; remove entity




-- NPCs
--dofile(path .. "lib.lua") -- TenPlus1
--dofile(path .. "npc.lua") -- TenPlus1



--iaspawn.register_soul = function(name, parents)
--	assert(name ~= nil)
--	-- list of parents is optional
--	
--end



-- TODO new players need a expositional newspaper
-- TODO put a space suit into the chest



--local funcion old_add_entity = minetest.add_entity
--minetest.add_entity = function(pos, name, staticdata)
--	assert(pos ~= nil)
--	assert(name ~= nil)
--	-- staticdata is optional
--
--	local objref = old_add_entity(pos, name, staticdata)
--	if objref == nil then return nil end -- operation failed
--
--	local player_name = objref:get_player_name()
--	if player_name == nil
--	or player_name == "" then
--		return objref -- not a player TODO may need to be manually registered
--	end
--
--	local parents = -- TODO
--	iaspawn.register_soul(player_name)
--end

print ("[MOD] IA Spawn")
