-- Recommended Neovim settings for hoardCTI Go work (GO-EDT-003).
-- Put this in your own Neovim configuration; don't commit it to repositories
-- (GO-EDT-002). Requires nvim-lspconfig.

require("lspconfig").gopls.setup({
  settings = {
    gopls = {
      gofumpt = true, -- GO-FMT-001
      ["local"] = "github.com/hoardcti", -- Third import group (GO-IMP-001).
      staticcheck = false, -- Runs inside golangci-lint instead.
      semanticTokens = true,
      analyses = {
        shadow = true, -- GO-NAM-015
      },
    },
  },
})

-- Format and organise imports on save.
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
    for _, response in pairs(result or {}) do
      for _, action in pairs(response.result or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
        end
      end
    end
    vim.lsp.buf.format({ async = false })
  end,
})

-- 100-column guide (GO-FMT-002) and tabs for Go.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.opt_local.colorcolumn = "100"
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- golangci-lint through nvim-lint (optional):
-- require("lint").linters_by_ft = { go = { "golangcilint" } }
