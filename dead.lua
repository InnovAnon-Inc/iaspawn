local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME) .. "/"
local MODMEM  = minetest.get_mod_storage()
local S       = minetest.get_translator(MODNAME)

minetest.register_on_dieplayer(function(objref)
	if minetest.get_modpath("iamedusa") then
		iamedusa.unfreeze(objref)
	end

	local name  = objref:get_player_name()
	if name == "Rasputin" then
		meta:set_int("spawn_random", 1)
		return
	end

	local meta  = objref:get_meta()
	local rasputin = meta:get_int("rasputin")
	if rasputin > 0 then
		meta:set_int("rasputin", rasputin - 1)
		meta:set_int("spawn_random", 1)
		return
	end

	local inv   = objref:get_inventory()
	local stack = ItemStack("iadiscordia:fairy_bottle")
	local items = inv:remove_item("main", stack)
	if not items:is_empty() then
		meta:set_string("spawn_at", minetest.serialize(objref:get_pos())) -- respawn in same position
		return
	end

       	meta:set_int("dead", 1)
       	minetest.kick_player(name, "You died on a hardcore server.")
end)

minetest.register_on_respawnplayer(function(objref)
	assert(false)
end)

