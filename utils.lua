-- Helper function to transfer metadata from one entity to another
local function transfer_metadata(from_meta, to_meta)
    local from_fields = from_meta:to_table().fields or {}
    local to_fields = to_meta:to_table().fields or {}

    for field, value in pairs(from_fields) do
        if field ~= "inventory" then
            to_fields[field] = value
        end
    end

    to_meta:from_table({ fields = to_fields })
end

-- Helper function to transfer inventory from one inventory to another
local function transfer_inventory(from_inv, to_inv)
    local from_lists = {
        "main",
        "armor",
        "clothes",
        "upgrades",
    }
    
    for _, listname in ipairs(from_lists) do
        local list = from_inv:get_list(listname)
        to_inv:set_list(listname, list)
    end
end

-- Export the utility functions
return {
    transfer_metadata = transfer_metadata,
    transfer_inventory = transfer_inventory
}
