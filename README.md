# Alacritty.nvim

Small plugin to change the alacritty cursor color to the colorscheme that is used by neovim.
This makes light themes usable and solves the problem of invisible cursor.

## Installation (via Lazy)

```lua
return {
    "moreka/alacritty.nvim",
    lazy = true,
    event = "Colorscheme",
    opts = {},
}
```
