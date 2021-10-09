--[[
-- Module for promoting and demoting headings
--]]

require('neorg.modules.base')

local module = neorg.modules.create("core.norg.esupports.promo")

module.setup = function()
    return {
        success = true,
        requires = {
            "core.keybinds",
            "core.integrations.treesitter"
        }
    }
end

module.load = function()
    module.required["core.keybinds"].register_keybinds(module.name, { "promote", "demote" })
end

module.public = {
    promote = function(node)
        -- Keep going up until we find a valid promotable node
        local type = tonumber(node:type():sub(-1, -1))

        while not type and node:type() ~= "document" do
            node = node:parent()
            type = tonumber(node:type():sub(-1, -1))
        end

        if not type then
            vim.api.nvim_feedkeys(">>", "n", false)
            return
        end

        local node_text = module.required["core.integrations.treesitter"].get_node_text(node:named_child(0))
        local char_to_duplicate = node_text:sub(0, 1)

        return node, char_to_duplicate .. node_text
    end
}

module.on_event = function(event)
    local ts_utils = module.required["core.integrations.treesitter"].get_ts_utils()

    -- nvim_feedkeys doesn't seem to work with `^` properly
    vim.cmd("norm! ^")

    if vim.endswith(event.type, "promote") then
        local node, promote = module.public.promote(ts_utils.get_node_at_cursor())

        if not promote then
            return
        end

        local range_for_prefix = module.required["core.integrations.treesitter"].get_node_range(node:named_child(0))
        local range_for_main_node = module.required["core.integrations.treesitter"].get_node_range(node)

        vim.api.nvim_buf_set_text(0, range_for_prefix.row_start, range_for_prefix.column_start, range_for_prefix.row_end, range_for_prefix.column_end, { promote })

        vim.api.nvim_feedkeys(tostring((range_for_main_node.row_end - range_for_main_node.row_start) + 1) .. "==", "n", false)
    end
end

module.events.subscribed = {
    ["core.keybinds"] = {
        [module.name .. ".promote"] = true,
        [module.name .. ".demote"] = true,
    }
}

return module
