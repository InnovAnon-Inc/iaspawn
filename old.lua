local MODNAME = minetest.get_current_modname()
-- Translation support
local S = minetest.get_translator("iaspawn")

local mcl = minetest.get_modpath("mcl_core") ~= nil


-- Npc by TenPlus1


--	on_spawn = function(self)
--		local myRandomName = getname.genderlessName()
--    		local newname = getname.forename() .. ' ' .. getname.surname()
--		self:update_tag(newname)
--		get_inventory(self)
--	end,
--
--	on_die = function(self, pos)
--		-- TODO spawn a corpse, type depending on height
--		-- TODO drop inventory
--		drop_inventory(self)
--	end,

local children = {}
local parents  = {}

function breed(mother, father)
	assert(mother ~= father)
	local mp  = minetest.get_player_by_name(mother)
	assert(mp ~= nil)
	local pos = mp:get_pos()
	assert(pos ~= nil)
	local res = mobs:add_mob(pos, {
                name  = "iaspawn:spawn",
                child = true,
                owner = mother,
                --nametag = "Bessy",
                ignore_count = true -- ignores mob count per map area
        })
	if not res then
		print("guess it's stillborn")
		return false
	end
	local fp  = minetest.get_player_by_name(father)
	assert(fp ~= nil)
	-- TODO persistent props ?
	local ml  = mother:get_property("lineage") or mother
	local fl  = father:get_property("lineage") or father
	assert(ml ~= nil)
	assert(fl ~= nil)
	print('mother: '..ml)
	print('father: '..fl)
	assert(children[res] == nil)
	--children[res] = {mother=ml, father=fl}
	--mothers[mother].append(res)
	--fathers[father].append(res)
	parents[ml].append(res) -- TODO check syntax of append
	parents[fl].append(res)
end

local reasontbl = {
        set_hp = "lost their health",
        punch = "got their lights punched out",
        fall = "fell to their death",
        node_damage = "burnt to a crisp",
        drown = "swam with the fish",
        respawn = "tried to cheat death"
}

minetest.register_on_joinplayer(function(player)
        local meta = player:get_meta()
        if meta:get_int("dead") == 1 then
                local name = player:get_player_name()
                minetest.kick_player(name, "You died on a hardcore server.")
        end
end)

minetest.register_on_dieplayer(function(ref)
	local name = ref:get_player_name()
	assert(name ~= nil)
	-- iterate all children
	children = {}
	for _,child in ipairs(children[name]) do
		assert(child ~= nil)
		-- TODO check syntax of append()
		children.append(child) -- if still alive
		recursively_append(children, parents[child]) -- TODO write method
	end
	if #children == 0 then
        	local reasonstr = reasontbl[reason.type] or "expired"
        	minetest.chat_send_all(
                	"RIP " .. name .. ", who " .. reasonstr)
        	local meta = player:get_meta()
		-- TODO reenable
        	--meta:set_int("dead", 1)
        	--minetest.kick_player(name, "You died on a hardcore server.")
	end
	local child = children[math.random(#children)] -- TODO check syntax of random()
	-- TODO get child objectref by child name
	assert(child ~= nil)
	local pos   = child:get_pos()
	assert(pos ~= nil)
	mobs:remove(child, true)
	meta:set_property('spawn_at', pos)
end)

minetest.register_on_respawnplayer(function(ref)
	local meta = ref:get_meta()
	local pos  = meta:get_property("spawn_at")
	if pos then
		return true
	end
	ref:set_pos(pos)
	return false
end)
