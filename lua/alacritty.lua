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

function M.alacritty_msg_set_bg(bg)
  return vim.system({
    "alacritty",
    "msg",
    "config",
    string.format('colors.background="%s"', bg),
  })
end

function M.set_alacritty_cursor()
  local cursor_color = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
  if cursor_color.fg and cursor_color.bg then
    local fg = string.format("#%06x", cursor_color.fg)
    local bg = string.format("#%06x", cursor_color.bg)

    vim.schedule(function()
      alacritty_msg_cursor_color(fg, bg)
    end)
  end
end

function M.setup()
  if os.getenv("ALACRITTY_WINDOW_ID") == nil then
    return
  end

  -- for further colorscheme changes, set up an autocommand
  vim.api.nvim_create_autocmd("Colorscheme", {
    group = vim.api.nvim_create_augroup("alacritty_cursor_grp", { clear = true }),
    callback = M.set_alacritty_cursor,
  })

  M.set_alacritty_cursor()

  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      alacritty_msg_cursor_color("CellBackground", "CellForeground"):wait()
    end,
  })
end

return M
