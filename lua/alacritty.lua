local M = {}

local function alacritty_msg_cursor_color(fg, bg)
  return vim.system({
    "alacritty",
    "msg",
    "config",
    string.format('colors.cursor.foreground="%s"', fg),
    string.format('colors.cursor.background="%s"', bg),
  })
end

local function set_alacritty_cursor()
  local cursor_color = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })

  local fg = string.format("#%06x", cursor_color.fg)
  local bg = string.format("#%06x", cursor_color.bg)

  vim.schedule(function()
    alacritty_msg_cursor_color(fg, bg)
  end)
end

function M.setup()
  if os.getenv("ALACRITTY_WINDOW_ID") == nil then
    return
  end

  -- for further colorscheme changes, set up an autocommand
  vim.api.nvim_create_autocmd("Colorscheme", {
    group = vim.api.nvim_create_augroup("alacritty_cursor_grp", { clear = true }),
    callback = set_alacritty_cursor,
  })

  set_alacritty_cursor()

  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      alacritty_msg_cursor_color("CellBackground", "CellForeground"):wait()
    end,
  })
end

return M
