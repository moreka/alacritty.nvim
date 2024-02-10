local M = {}

local function alacritty_set_color(fg, bg)
  return vim.system({
    "alacritty",
    "msg",
    "config",
    string.format('colors.cursor.foreground="%s"', fg),
    string.format('colors.cursor.background="%s"', bg),
  })
end

function M.setup()
  local cursor_color = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })

  local fg = string.format("#%06x", cursor_color.fg)
  local bg = string.format("#%06x", cursor_color.bg)

  vim.schedule(function()
    alacritty_set_color(fg, bg)
  end)

  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      alacritty_set_color("CellBackground", "CellForeground")
    end,
  })
end

return M
