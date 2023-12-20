local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME) .. "/"
local MODMEM  = minetest.get_mod_storage()
local S       = minetest.get_translator(MODNAME)

minetest.register_on_dieplayer(function(objref)
	local meta = objref:get_meta()
       	meta:set_int("dead", 1)
       	minetest.kick_player(name, "You died on a hardcore server.")
end)

minetest.register_on_respawnplayer(function(objref)
	assert(false)
end)

