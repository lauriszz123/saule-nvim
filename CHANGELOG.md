# Changelog

## 26.20

### Security

- A project's own `target/debug/saule-lsp` is no longer run just because the project was opened. The installed toolchain is used instead, and running a project's build is now an opt-in setting.
- Relative `PATH` entries are no longer searched.

### Added

- `~/.saule/bin` is searched after `PATH`, so an editor started from a launcher finds the toolchain without any setup.
- Highlighting and indentation for `finally`, and highlighting for `byte` and `bytes`.

### Changed

- To use a checkout's build, set `vim.g.saule_use_project_build = true`.
