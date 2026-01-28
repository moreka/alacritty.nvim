if vim.env.ALACRITTY_WINDOW_ID == nil then return end

local grp = vim.api.nvim_create_augroup("alacritty_cursor_grp", { clear = true })

vim.api.nvim_create_autocmd({ "ColorScheme", "VimResume" }, {
  group = grp,
  callback = function()
    require("alacritty").set_cursor_color_from_colorscheme()
  end,
  desc = "Sets Alacritty cursor color to match the current colorscheme",
})

vim.api.nvim_create_autocmd("UIEnter", {
  group = grp,
  callback = function()
    local alacritty = require("alacritty")
    vim.g.alacritty_current_cursor_color = alacritty.get_cursor_color()
    vim.schedule(function() alacritty.set_cursor_color_from_colorscheme() end)
  end,
  desc = "Sets Alacritty cursor color to match the current colorscheme",
})

vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, {
  group = grp,
  callback = function()
    vim.schedule(function()
      if vim.g.alacritty_current_cursor_color then
        require("alacritty").send_cursor_color_msg(vim.g.alacritty_current_cursor_color)
      end
    end)
  end,
  desc = "Resets the Alacritty cursor color to its original value",
})
