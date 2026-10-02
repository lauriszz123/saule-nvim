-- Package spec. lazy.nvim reads a `lazy.lua` from a plugin's root and folds it
-- into the user's spec (`pkg.enabled` defaults to true, with "lazy" first in
-- `pkg.sources`), so this applies on install with nothing for the user to copy
-- into their config.
--
-- All it does is teach nvim-web-devicons about `.sau`, so the file tree,
-- tabline, statusline and pickers show a sun instead of the default grey file
-- glyph. That cannot live in this plugin's own Lua: the tree draws the icon
-- while you are still browsing a directory, long before an `ft = "saule"`
-- plugin has any reason to load.
--
-- It is done imperatively, from `init`, rather than by contributing
-- `opts.override_by_extension` to the devicons spec. Contributing opts looks
-- tidier and does not work: lazy.nvim folds fragments with
-- `ret = values(root, ret) or ret`, so a distribution whose devicons spec uses
-- an `opts` *function* that returns a fresh table — NvChad does exactly this —
-- discards everything merged before it, and the pkg fragment is folded first.
-- Measured, not assumed: with the opts form the icon resolved to
-- DevIconDefault under NvChad.
--
-- `User LazyLoad` fires after a plugin's `config` has run, so registering
-- there lands after devicons' own `setup()` has built its tables, whoever
-- called it and whatever they passed.
--
-- Keep the values in step with `lua/saule/devicons.lua`, the manual path for
-- people not on lazy.nvim. They are duplicated on purpose: requiring the
-- module from here would need this plugin's `lua/` on the runtimepath, which
-- at spec-resolution time it is not — and would force the plugin to load.

local ICON = {
  -- U+F185, the Font Awesome sun. An escape rather than the glyph: it lives in
  -- the Private Use Area, where anything that normalises text silently eats it.
  icon = "\u{F185}",
  color = "#F7A224",
  cterm_color = "214",
  name = "Saule",
}

local function register()
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return false
  end
  devicons.set_icon({ sau = ICON })
  return true
end

return {
  {
    "lauriszz123/saule-nvim",
    init = function()
      -- Already up (eagerly loaded, or another plugin pulled it in).
      if package.loaded["nvim-web-devicons"] and register() then
        return
      end
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        callback = function(event)
          if event.data == "nvim-web-devicons" then
            register()
            return true -- one shot; delete the autocmd
          end
        end,
      })
    end,
  },
}
