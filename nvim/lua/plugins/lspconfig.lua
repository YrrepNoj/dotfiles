return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local lspconfig = require "lspconfig"
      local configs = require "lspconfig.configs"

      -- define golangci-lint if it doesn’t already exist
      if not configs.golangcilsp then
        configs.golangcilsp = {
          default_config = {
            cmd = { "golangci-lint-langserver" },
            root_dir = lspconfig.util.root_pattern(".git", "go.mod"),
            init_options = {
              command = {
                "golangci-lint",
                "run",
                "--output.json.path",
                "stdout",
                "--show-stats=false",
                "--issues-exit-code=1",
              },
            },
          },
        }
      end

      -- register the server
      lspconfig.golangcilsp.setup {
        filetypes = { "go", "gomod" },
      }
    end,
  },
}
