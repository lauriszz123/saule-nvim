-- The `.sau` entry for nvim-web-devicons: a sun glyph in the Saule orange,
-- shown by the file tree, the tabline, the statusline and every picker.
--
-- A terminal cannot draw the real logo, so this is as close as the mark gets
-- inside Neovim. Without it `.sau` falls through to the default file glyph in
-- default grey, which is what upstream devicons has for an extension it has
-- never heard of.
--
-- Registering has to happen at startup, not when a `.sau` buffer opens: the
-- tree draws the icon while you are still browsing the directory, long before
-- anything is opened. That is why this is NOT called from `ftplugin/` and why
-- the README asks for it in the devicons spec instead — requiring it from a
-- lazy-loaded plugin's `init` would drag the whole plugin in at startup.

local M = {}

--- The extension entry, exposed so it can be dropped straight into
--- `override_by_extension` without loading this module at all.
M.icon = {
  -- U+F185, the Font Awesome sun, present in every Nerd Font patch. Written
  -- as an escape rather than the literal glyph on purpose: it lives in the
  -- Private Use Area, and PUA characters get silently eaten by editors,
  -- clipboards and web forms that normalise text. The escape always survives.
  -- If your font is unpatched you get a replacement box; `icon = "S"` is fine.
  icon = "\u{F185}",
  color = "#F7A224",
  cterm_color = "214",
  name = "Saule",
}

--- Register the icon. Safe to call more than once, and a no-op when
--- nvim-web-devicons is not installed.
function M.setup()
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return false
  end
  devicons.set_icon({ sau = M.icon })
  return true
end

return M
