local M = {}

---@class CursorColor
---A cursor color with foreground and background. Allowed values are hexadecimal
---colors like `"#ff00ff"`, or `"CellForeground"`/`"CellBackground"`, which
---references the affected cell.
---
---@field bg string
---@field fg string

---Notifies (at DEBUG level) when verbose is set to true
---
---@param msg string the message to be logged
function M.dbg(msg)
  if M.verbose then
    vim.notify(msg, vim.log.levels.DEBUG)
  end
end

---Sends Alacritty an IPC message to change its cursor color
---
---@param color CursorColor
---@return vim.SystemCompleted
function M.send_cursor_color_msg(color)
  M.dbg("Setting cursor color to " .. vim.inspect(color))
  return vim
    .system({
      "alacritty",
      "msg",
      "config",
      string.format('colors.cursor.foreground="%s"', color.fg),
      string.format('colors.cursor.background="%s"', color.bg),
    })
    :wait()
end

---Gets the current Alacritty cursor color via IPC. As a fallback, returns the
---default CellForeground and CellBackground
---
---**NOTE:** this IPC message was introduced in Alacritty 0.16.
---
---@return CursorColor
function M.get_cursor_color()
  local alacritty_config =
    vim.system({ "alacritty", "msg", "get-config" }):wait()
  local colors = nil

  if alacritty_config.code == 0 and alacritty_config.stdout then
    local cfg = vim.json.decode(alacritty_config.stdout)
    colors =
      { bg = cfg.colors.cursor.background, fg = cfg.colors.cursor.foreground }
  else
    M.dbg("Alacritty IPC get-config didn't work. Falling back to default.")
    colors = { bg = "CellForeground", fg = "CellBackground" }
  end

  M.dbg("Current Alacritty colors: " .. vim.inspect(colors))
  return colors
end

---Gets the Cursor highlight group defined in the colorscheme.
---As a fallback, based on the `'background'`, it uses a B&W default.
function M.set_cursor_color_from_colorscheme()
  local cursor_color = nil

  local cs_cursor_hlgroup =
    vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
  if cs_cursor_hlgroup.fg and cs_cursor_hlgroup.bg then
    local fg = string.format("#%06x", cs_cursor_hlgroup.fg)
    local bg = string.format("#%06x", cs_cursor_hlgroup.bg)
    if cs_cursor_hlgroup.reverse then
      cursor_color = { fg = bg, bg = fg }
    else
      cursor_color = { fg = fg, bg = bg }
    end
  else
    M.dbg(
      "Your colorscheme does not define the highlight group `Cursor` with a "
        .. "`guibg` and `guifg`. Falling back to B&W default."
    )
    if vim.o.background == "light" then
      cursor_color = { fg = "#FFFFFF", bg = "#000000" }
    else
      cursor_color = { bg = "#FFFFFF", fg = "#000000" }
    end
  end
  vim.schedule(function() M.send_cursor_color_msg(cursor_color) end)
end

---@param opts { verbose: boolean }? options for `alacritty.nvim`
function M.setup(opts)
  opts = opts or { verbose = false }

  M.verbose = opts.verbose

  if vim.env.ALACRITTY_WINDOW_ID == nil then
    M.dbg("Not running Alacritty. This plugin has no effect.")
    return
  end

  local grp =
    vim.api.nvim_create_augroup("alacritty_cursor_grp", { clear = true })

  vim.api.nvim_create_autocmd({ "ColorScheme", "VimResume" }, {
    group = grp,
    callback = M.set_cursor_color_from_colorscheme,
    desc = "Sets Alacritty cursor color to match the current colorscheme",
  })

  local current_cursor_color = M.get_cursor_color()
  vim.schedule(function() M.set_cursor_color_from_colorscheme() end)

  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
    group = grp,
    callback = function()
      vim.schedule(function()
        M.send_cursor_color_msg(current_cursor_color)
      end)
    end,
    desc = "Resets the Alacritty cursor color to its original value",
  })
end

return M
