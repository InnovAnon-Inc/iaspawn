local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME) .. "/"
local MODMEM  = minetest.get_mod_storage()
local S       = minetest.get_translator(MODNAME)
local schem   = MODPATH.."/schematics/spawn_ship.mts"

iaspawn = { }

local spawn_ship = dofile(MODPATH .. "newspawn.lua")
dofile(MODPATH .. "dead.lua")
dofile(MODPATH .. "mem.lua")
--dofile(MODPATH .. "items.lua")
local utils = dofile(MODPATH .. "utils.lua")

local function is_alive(saved_data)
   -- Check the relevant data to determine if the entity is alive
   local entity = saved_data.entity
   if entity and entity:is_player() then
      return true  -- Entity is a player
   elseif entity and not entity:is_player() and minetest.get_object_or_nil(entity) then
      return true  -- Entity is alive
   else
      return false  -- Entity is not alive
   end
end

-- TODO not working
function iaspawn.register_soul(objref, mother, father)
   assert(objref ~= nil)
   assert(objref:is_player())
   -- TODO testing
   assert(mother == nil)
   assert(father == nil)

   local player_name = objref:get_player_name()
   assert(type(player_name) == "string")
   if iaspawn.souls[player_name] then
      -- The soul with the given player name already exists
      return false
   end
 
   if false then -- TODO testing


   if minetest.is_player(objref) then end


   if objref.get_luaentity ~= nil and objref:get_luaentity() ~= nil and objref:get_luaentity().is_fake_player == true then
      print('registering fake player')
      -- Register the soul in the souls database
      iaspawn.souls[player_name] = {
        entity = objref.object,
        --player = nil,
        mother = mother,
        father = father,
      }
   else
      print('registering player')
      -- Register the soul in the souls database
      iaspawn.souls[player_name] = {
        entity = nil,
        --player = objref,
        mother = mother,
        father = father,
      }
   end
   assert(type(iaspawn.souls[player_name].entity) ~= "userdata")
   assert(     iaspawn.souls[player_name].player  == nil)
  
   end
   return true
end







-- TODO minetest registered entities on_activate(self, staticdata, dtime_s)
-- TODO on activate, register entity in lineage table
-- TODO when a player is created, register player in lineage table
-- TODO when a player spawns an entity, create link in lineage table
-- TODO when an entity spawns an entity, create link... how ?







iaspawn.replace_standin_with_player = function(player, saved_data)
    assert(player     ~= nil)
    assert(saved_data ~= nil)
    local player_meta = player:get_meta()
    
    local entity = iaspawn.get_entity(saved_data)
    local entity_meta = entity:get_meta()
    
    -- Copy metadata from entity to player
    utils.transfer_metadata(entity_meta, player_meta)
    
    -- Copy inventory from entity to player
    local entity_inv = entity:get_inventory()
    local player_inv = player:get_inventory()
    utils.transfer_inventory(entity_inv, player_inv)
    
    -- Save relevant data so we can restore this mob later
    iaspawn.remember_standin_restore_data(entity)
    
    -- Remove the entity since the player has logged back in
    entity:remove()
end
iaspawn.replace_player_with_standin = function(player)
	assert(player ~= nil)
	local player_meta = player:get_meta()
	-- Restore relevant data that we saved for this mob earlier
	local entity = iaspawn.restore_standin_remembered_data(player)
        local entity_meta = entity:get_meta()

        -- Copy metadata from player to entity
        utils.transfer_metadata(player_meta, entity_meta)

        -- Copy inventory from player to entity
        local entity_inv = entity:get_inventory()
        local player_inv = player:get_inventory()
        utils.transfer_inventory(player_inv, entity_inv)
end

minetest.register_on_newplayer(function(player)
    assert(player ~= nil)
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()

    -- Check if the player's data exists in the saved player data
    if iaspawn.souls[player_name] then
	player_meta:set_int("spawn_no", 1) -- set flag to indicate that this is not a new player

        local saved_data = iaspawn.souls[player_name]
        if not iaspawn.is_alive(saved_data) then
            -- player joining with a non-unique name
	    -- but the player or entity is already dead
	    meta:set_int("dead", 1) -- set flag to indicate that this player is dead
	else
            -- player joining with a non-unique name
	    -- and the target entity is alive
	    iaspawn.replace_standin_with_player(player, saved_data)
        end
    else
        -- player joining with a unique name
	iaspawn.register_soul(player)
    end
end)

minetest.register_on_joinplayer(function(player)
	assert(player ~= nil)
        local name = player:get_player_name()
        local meta = player:get_meta()
        if meta:get_int("dead") == 1 then -- player is already dead
                minetest.kick_player(name, "You died on a hardcore server.")
		return
        end

	local spawn_no = meta:get_int("spawn_no")
	if spawn_no ~= nil and spawn_no > 0 then -- not the first time joining
		local spawn_pos = meta:get_string("spawn_at") -- respawn in same position (eg fairy jar)
		local spawn_random = meta:get_int("spawn_random") -- respawn in same position (eg fairy jar)
		if spawn_pos ~= nil then
			spawn_pos = minetest.deserialize(spawn_pos)
		end
		if spawn_pos ~= nil and spawn_pos ~= "" then
			--if spawn_pos == "random" then
			--	local x = math.random(-31000, 31000)
			--	local y = math.random(  0000,  2000) -- spawn on planet
			--	local z = math.random(-31000, 31000)

			--	spawn_pos = {x=x, y=y, z=z} --vector:new(x, y, z)
			--end
			player:set_pos(spawn_pos)
		elseif spawn_random ~= nil and spawn_random > 0 then
			local x = math.random(-31000, 31000)
			local y = math.random(  0000,  2000) -- spawn on planet
			local z = math.random(-31000, 31000)

			spawn_pos = {x=x, y=y, z=z} --vector:new(x, y, z)
			player:set_pos(spawn_pos)
		else
			if false then -- TODO testing
        		local saved_data = iaspawn.souls[name]
        		if not iaspawn.is_alive(saved_data) then -- the standin died while the player was away
				meta:set_int("dead", 1)
               	 	minetest.kick_player(name, "You died on a hardcore server.")
				return
			end

	    		iaspawn.replace_standin_with_player(player, saved_data)
			end
		end
		meta:set_string("spawn_at", "")

		return
	end

	-- first spawn with a unique player name
	spawn_ship(player)
	meta:set_int("spawn_no", 1)
end)

minetest.register_on_leaveplayer(function(objref, timed_out)
	assert(objref    ~= nil)
	assert(timed_out ~= nil)
	iaspawn.replace_player_with_standin(objref)
end)




--scroll named DUAM XNAHT
--local opt = math.random(1,2)
--local msg
--if opt == 1 and player_name ~= "Maud" then -- TODO match case
--  msg = "Who was that Maud person anyway?"
--elseif opt == 2 and player_name ~= "Maud" then
--  msg = "Thinking of Maud you forget everything else"
--elseif player_name == "Maud then
--  msg = "As your mind turns inward on itself, you forget everything else."
--elseif hallucinating then
--  msg = "Your mind releases itself from mundane concerns."
--end
--minetest.chat_send_player(player_name, msg)
--player_meta:set_int("spawn_no", 0)
--player:set_hp(-100)
--player_meta:set_int("dead", 1) -- TODO

-- TODO mobs won't attack when player stands on a node inscribed with Elbereth

-- TODO special names Croesus, Kroisos, Creosote
-- TODO special names Maud
-- TODO special names wizard




-- TODO compatible entities need to manaually register their "player name"
-- TODO when a player prejoins, check the name ? => set spawn pos to entity pos; remove entity





print ("[MOD] IA Spawn")
