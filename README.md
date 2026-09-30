<img src="assets/saule-logo.png" alt="Saule" width="128" align="right">

# Saule for Neovim / NvChad

Neovim support for the [Saule](https://github.com/lauriszz123/saule)
programming language (`.sau`): syntax, indentation, and a client for the
`saule-lsp` language server.

This repository is a Neovim plugin, laid out the way plugin managers expect —
point one at `lauriszz123/saule-nvim` and you are done.

1. **Syntax + filetype detection** — `ftdetect/`, `ftplugin/`, `syntax/`.
2. **Indentation** — `indent/`, backed by the shared indent model in
   `lua/saule/indent.lua`.
3. **LSP client glue** — `lsp/saule.lua` (Neovim 0.11+) and
   `lua/saule/lsp.lua` (nvim-lspconfig), which locate and register
   `saule-lsp` for you.
4. **Run commands** — `:SauleRun`, `:SauleRunFile`.

Behaviour is kept at parity with the [IntelliJ
plugin](https://github.com/lauriszz123/saule-intellij) and the [VS Code
extension](https://github.com/lauriszz123/saule-vscode); see [Editor
parity](#editor-parity) for the details.

## 1. Install the toolchain (one time)

The plugin needs the `saule-lsp` binary. The installer puts it, and the `saule`
CLI, in `~/.saule/bin` and adds that to your `PATH`:

```bash
curl -fsSL https://lauriszz123.github.io/saule/install.sh | sh
```

If you build the language from source instead, `cargo build --release` in a
[saule](https://github.com/lauriszz123/saule) checkout produces both binaries
in `target/release/`; the Lua helpers find them by walking up from the file you
are editing, so nothing else is needed while you work inside that checkout.

## 2. Install the plugin

### lazy.nvim

In your NvChad `lua/plugins/init.lua` (or wherever you list extra plugins):

```lua
return {
  -- existing entries …
  {
    "lauriszz123/saule-nvim",
    ft = "saule",
  },
}
```

### packer.nvim

```lua
use { "lauriszz123/saule-nvim", ft = "saule" }
```

### From a local clone

Any manager that takes a directory works too — the point is to get this
repository onto Neovim's runtimepath so the `saule` filetype, the syntax and
indent files, and `require("saule.lsp")` all resolve:

```lua
{
  dir = "~/Documents/rust/saule-nvim",
  name = "saule-nvim",
  ft = "saule",
}
```

## 3. Enable the LSP

### Neovim 0.11+ (built-in)

```lua
vim.lsp.enable("saule")
```

`lsp/saule.lua` is picked up from the runtimepath automatically.

### NvChad / nvim-lspconfig

Edit `~/.config/nvim/lua/configs/lspconfig.lua` and add a single line:

```lua
require("nvchad.configs.lspconfig").defaults()

-- your other servers …

require("saule.lsp").setup()
```

The helper will:

* Locate the server binary (see [Finding the toolchain](#finding-the-toolchain)).
* Pick up NvChad's shared `on_attach` / `capabilities` so the buffer gets the
  same keymaps and completion source as the rest of your LSP setup.
* Detect the project root via `saule.config` / `Cargo.toml` / `.git`, with
  `single_file_support = true` for scratch files.

## Finding the toolchain

`saule-lsp` and `saule` are resolved in the same order as in the IntelliJ
plugin and the VS Code extension, so every editor picks the same binary in the
same project:

1. `$SAULE_LSP_PATH` / `$SAULE_PATH`.
2. `vim.g.saule_lsp_path` / `vim.g.saule_cli_path`, or `vim.g.saule_toolchain_dir`.
3. Cargo build output, walking **up** from the file's directory looking for
   `target/release` then `target/debug`. Walking up is what lets you open a
   sub-folder (say `examples/todo-app`) and still find the workspace-root build
   output — and the directory holding that `target/` becomes the server's
   working directory.
4. `$PATH` — where the installer puts it.

If nothing is found you get a warning explaining how to build it; syntax
highlighting and indentation keep working regardless.

```lua
-- Override explicitly:
vim.g.saule_lsp_path = "/abs/path/to/saule-lsp"

-- Or, through the lspconfig helper:
require("saule.lsp").setup({
  repo = "/some/other/clone/of/saule",  -- search from here
  profile = "debug",                    -- prefer the debug build
  -- cmd = { "/abs/path/to/saule-lsp" },-- bypass detection entirely
})
```

## What you get

From `saule-lsp`: diagnostics (lex, parse, semantic and type errors), hover,
go-to-definition, find references, document highlights and symbols, inlay
hints, signature help, and formatting.

Editor-side, without the server:

* **Indentation** — `o`/`O`, `=`, and `gg=G` use the same model as the other
  editors and as `saule fmt`. Block-closing keywords dedent as you type them:
  `end`, `until`, `else`, `elseif`, `catch` and `case` snap to the right level
  the moment they are finished, because Saule closes blocks with words rather
  than braces and there is no `}` for the usual dedent to hook onto.
* **Indentation that matches what the file will be saved as** — two spaces by
  default, matching `FmtOptions::default()` in `saule-fmt`, but resolved per
  buffer through the same chain the printer uses: the canonical default, then
  what the file is already written with, then `indent_style` / `indent_width`
  from the nearest `saule.config`. That last one wins for `saule fmt` and for
  the server's formatting *on purpose* — the style belongs to the project, not
  to whoever opened the file — so the editor has to agree or every Enter, `>>`
  and `=` is at odds with the next save, and the first format rewrites the
  whole file. Reading the file's existing indentation covers the projects that
  declare nothing, the way VS Code's `editor.detectIndentation` does.
  `vim.g.saule_project_indent = false` opts out and keeps the two-space
  default.
* **`%` between block delimiters** — `class`/`fn`/`if`/… ↔ `else`/`case`/… ↔
  `end`/`until`, via the bundled matchit plugin. A trailing block's `do`
  (`Canvas() do … end`) counts as an opener; the `do` ending a `for`/`while`
  header, an `fn` writing a type, and an interface's bare signatures do not,
  since no `end` comes for them.
* **Inlay hints** — the ghost text showing inferred local types (`: integer`)
  and parameter names (`left:`, `right:`) at call sites. Neovim has the
  feature but leaves it off until something enables it, so the ftplugin does,
  the way IntelliJ and VS Code do out of the box. `:SauleInlayHints` toggles
  the current buffer; `vim.g.saule_inlay_hints = false` opts out entirely.
* **No word-scraped completions** — completion plugins ship a source that
  harvests words out of the open buffers (`buffer` for nvim-cmp) and offers
  them independently of the server. That lands hardest where `saule-lsp`
  deliberately answers with nothing: a declaration name. Naming a new `fn`,
  `class`, `local`, parameter, field or enum variant is you *inventing* a
  name, so the names already in scope are exactly the wrong suggestions —
  and a word scraper puts them straight back. Saule buffers drop those
  sources; every other source you have configured is kept, in order, and no
  other filetype is touched. VS Code does the same with
  `editor.wordBasedSuggestions: "off"`. `vim.g.saule_word_completion = true`
  keeps them.
* **The server's ranking, honoured** — nvim-cmp sorts by LSP *kind* before it
  looks at `sortText`, and kinds are compared by their protocol number, so a
  method (2) always outranks a field (5) however irrelevant it is: at
  `VStack(ali…)` the inherited `aligned()` came out above the `alignment:`
  parameter being asked for. `saule-lsp` ranks by what the cursor is actually
  doing — the parameters of the call you are inside, then whatever fits the
  *type* of the slot you are filling (`alignment: ⟨caret⟩` puts
  `StackAlignment` first), then locals, members, module functions, classes,
  the stdlib, keywords — and carries all of it in `sortText`. Saule buffers
  move `sortText` ahead of `kind` and leave the rest of the chain alone, so
  `offset` and `exact` still win and the fuzzy `score` still orders whatever
  the server ranked equally.
* **Signature help follows the cursor** — the hint pops whenever the cursor is
  inside a call's parens, not only when `(` is typed. Turn it off with
  `vim.g.saule_auto_signature_help = false`.
* **Comments** — `--` line, `--[[ … ]]` block, wired into `commentstring` so
  `gc` works with any commenting plugin.

### Formatting on save

Off by default, matching the other editors. To enable:

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.sau",
  callback = function() vim.lsp.buf.format({ async = false }) end,
})
```

## Running

```vim
:SauleRun               " saule run          — project mode
:SauleRunFile           " saule run <file>   — single file, writes it first
:SauleRunFile --flag x  " arguments after the command go to the script
```

Both open a terminal split. They resolve the `saule` binary the same way the
server is resolved, and run it from the workspace root.

## Editor parity

`lua/saule/indent.lua` is a port of the IntelliJ plugin's `SauleIndentModel`
and shares its test corpus with the VS Code extension's `src/indent.ts`. All
three are derived from the printer in `crates/saule-fmt/src/lib.rs` in the
[saule](https://github.com/lauriszz123/saule) repository. The three clients
live in separate repositories now, so changing one is a change to all three:
update [saule-intellij](https://github.com/lauriszz123/saule-intellij) and
[saule-vscode](https://github.com/lauriszz123/saule-vscode) alongside it and
re-run every suite.

```bash
lua tests/indent_spec.lua
```

`lua/saule/style.lua` is the other half of the same agreement — it is a port of
`ConfigIndent` in `crates/saule-fmt/src/config.rs`, so the editor resolves a
project's declared indentation exactly as the printer does:

```bash
lua tests/style_spec.lua
```

## Future: tree-sitter

For more accurate highlighting, a `tree-sitter-saule` grammar can later replace
the Vim regex highlighter; nvim-treesitter would then auto-pick it up. The
indent model is independent of it and would stay as-is.

## License

MIT — see [LICENSE](LICENSE).
