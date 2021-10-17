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
    module.required["core.keybinds"].register_keybinds(module.name, { "promote", "demote", "promote-recursive", "demote-recursive" })
end

module.config.private = {
    -- To be used in the future
    promote_whitelist = {
        "paragraph"
    }
}

module.public = {
    promote = function(node)
        local node_text = module.required["core.integrations.treesitter"].get_node_text(node)
        local prefix = node_text:sub(0, 1)

        local tab = (function()
            if not vim.opt_local.expandtab then
                return "	"
            else
                return string.rep(" ", vim.opt_local.tabstop:get())
            end
        end)()

        if vim.tbl_contains({
            "-",
            "*",
            ">",
            "~",
        }, prefix) then
            return tab .. prefix .. node_text
        end

        return tab .. node_text
    end
}

module.on_event = function(event)
    local ts_utils = module.required["core.integrations.treesitter"].get_ts_utils()

    -- nvim_feedkeys doesn't seem to work with `^` properly
    if vim.api.nvim_win_get_cursor(0)[2] <= vim.api.nvim_get_current_line():match("^%s*"):len() then
        vim.cmd("norm! ^")
    end

    if vim.endswith(event.type, "promote-recursive") then
        local node = module.required["core.integrations.treesitter"].get_whole_node(ts_utils.get_node_at_cursor())

        if not node or not node:named_child(0) or not vim.endswith(node:named_child(0):type(), "prefix") then
            vim.api.nvim_feedkeys(">>", "n", false)
            return
        end

        for child in node:iter_children() do
            local range_for_child = module.required["core.integrations.treesitter"].get_node_range(child)
            vim.api.nvim_buf_set_text(0, range_for_child.row_start, range_for_child.column_start, range_for_child.row_end, range_for_child.column_end, vim.split(module.public.promote(child), "\n", true))
        end
    end
end

module.events.subscribed = {
    ["core.keybinds"] = {
        [module.name .. ".promote"] = true,
        [module.name .. ".demote"] = true,
        [module.name .. ".promote-recursive"] = true,
        [module.name .. ".demote-recursive"] = true,
    }
}

return module
