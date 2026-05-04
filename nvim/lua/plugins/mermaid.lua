return {
  "3rd/diagram.nvim",
  dependencies = {
    { "3rd/image.nvim", opts = {} },
  },
  opts = {
    events = {
      render_buffer = {}, -- Leave blank so no auto rendering
      clear_buffer = { "BufLeave" },
    },
    renderer_options = {
      mermaid = {
        background = nil, -- nil | "transparent" | "white" | "#hex"
        theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
        scale = 3, -- nil | 1 (default) | 2  | 3 | ...
        width = nil, -- nil | 800 | 400 | ...
        height = nil, -- nil | 600 | 300 | ...
        cli_args = nil, -- nil | { "--no-sandbox" } | { "-p", "/path/to/puppeteer" } | ...
      },
      plantuml = {
        charset = nil,
        cli_args = nil, -- nil | { "-Djava.awt.headless=true" } | ...
      },
      d2 = {
        theme_id = nil,
        dark_theme_id = nil,
        scale = nil,
        layout = nil,
        sketch = nil,
        cli_args = nil, -- nil | { "--pad", "0" } | ...
      },
      gnuplot = {
        size = nil, -- nil | "800,600" | ...
        font = nil, -- nil | "Arial,12" | ...
        theme = nil, -- nil | "light" | "dark" | custom theme string
        cli_args = nil, -- nil | { "-p" } | { "-c", "config.plt" } | ...
      },
    },
  },
  keys = {
    {
      "<leader>mm",
      function()
        -- WORKAROUND: diagram.nvim's hover.show_in_tab() creates a new tab buffer
        -- with only 5 header lines, but places the image at y=5 (0-indexed), which
        -- means image.nvim calls screenpos(win, 6, 1). Since line 6 doesn't exist,
        -- Neovim throws E966: Invalid line number.
        --
        -- This monkey-patches nvim_buf_set_lines so that when the hover module writes
        -- its header (matched by "# ...Diagram"), we append enough blank lines to fill
        -- the window height. The patch is restored after 5s to cover async renders.
        --
        -- FRAGILE: This depends on diagram.nvim's hover header format matching
        -- "^# .*Diagram$". If the plugin changes that header text, the patch won't
        -- trigger and the original E966 error will return. To debug:
        --   1. Check ~/.local/share/nvim/lazy/diagram.nvim/lua/diagram/hover.lua
        --   2. Look at the header lines in show_in_tab() (~line 137)
        --   3. Update the pattern below to match the new header format
        local hover = require "diagram/hover"
        local original_show = hover.show_diagram_hover
        hover.show_diagram_hover = function(diagram, integrations, renderer_options)
          local orig_buf_set_lines = vim.api.nvim_buf_set_lines
          vim.api.nvim_buf_set_lines = function(buf, start, stop, strict, lines)
            orig_buf_set_lines(buf, start, stop, strict, lines)
            if #lines >= 4 and lines[1] and lines[1]:match "^# .*Diagram$" then
              local win_height = vim.api.nvim_win_get_height(0)
              local padding = {}
              for _ = 1, win_height do
                padding[#padding + 1] = ""
              end
              orig_buf_set_lines(buf, -1, -1, false, padding)
            end
          end
          original_show(diagram, integrations, renderer_options)
          vim.defer_fn(function() vim.api.nvim_buf_set_lines = orig_buf_set_lines end, 5000)
        end
        require("diagram").show_diagram_hover()
      end,
      mode = "n",
      ft = { "markdown", "norg" },
      desc = "Show diagram in new tab",
    },
  },
}
