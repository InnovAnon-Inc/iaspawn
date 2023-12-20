local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME) .. "/"
local MODMEM  = minetest.get_mod_storage()
local S       = minetest.get_translator(MODNAME)

-- Load saved player data from storage on server startup
local serialized_data = MODMEM:get_string("player_data")
if serialized_data and serialized_data ~= "" then
    iaspawn.souls = minetest.deserialize(serialized_data) or {}
else
    iaspawn.souls = {}
end

-- Save the player data to storage on server shutdown
minetest.register_on_shutdown(function()
    local serialized_data = minetest.serialize(iaspawn.souls)
    MODMEM:set_string("player_data", serialized_data)
end)

