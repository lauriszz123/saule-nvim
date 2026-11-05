-- Which binary gets run, and above all which one does not. Needs an editor for
-- `vim.fs` and `vim.fn`, so unlike the other specs it runs under Neovim. From
-- the repository root:
--
--   nvim -l tests/toolchain_spec.lua

package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local toolchain = require("saule.toolchain")

local passed, failed = 0, 0

local function check(name, ok, detail)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL " .. name .. (detail and (": " .. tostring(detail)) or ""))
  end
end

local function write_executable(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ "#!/bin/sh" }, path)
  vim.fn.setfperm(path, "rwxr-xr-x")
end

local root = vim.fn.resolve(vim.fn.tempname())
local project = root .. "/project"
local nested = project .. "/examples/demo"
vim.fn.mkdir(nested, "p")
local planted = project .. "/target/debug/saule-lsp"
local on_path = root .. "/bin/saule-lsp"
local installed = root .. "/home/bin/saule-lsp"
write_executable(planted)

local exe = "saule-lsp"
local function locate()
  return toolchain.locate(exe, { start = nested })
end

vim.env.SAULE_HOME = root .. "/home"
vim.env.PATH = "/nonexistent"
vim.g.saule_use_project_build = nil

local found = locate()
check("a project's binary is not run by default", not found.found and found.command ~= planted, found.command)

write_executable(installed)
found = locate()
check("the install directory is found without PATH", found.command == installed, found.command)

write_executable(on_path)
vim.env.PATH = root .. "/bin"
found = locate()
check("PATH comes before the install directory", found.command == on_path, found.command)

vim.g.saule_use_project_build = true
found = locate()
check("opting in finds the project's build", found.command == planted, found.command)
check("and runs it from the project root", found.working_dir == project, found.working_dir)
vim.g.saule_use_project_build = nil

vim.fn.delete(on_path)
vim.fn.delete(installed)
local here = vim.fn.getcwd()
vim.fn.mkdir(project .. "/bin", "p")
write_executable(project .. "/saule-lsp")
vim.cmd.cd(project)
vim.env.PATH = "."
found = locate()
vim.cmd.cd(here)
check("a relative PATH entry is not searched", not found.found, found.command)

found = toolchain.locate(exe, { start = nested, cmd = "/nope/saule-lsp" })
check("a configured path that does not exist reports not found", not found.found)

vim.fn.delete(root, "rf")

print(string.format("%d checks, %d failure(s)", passed + failed, failed))
os.exit(failed == 0 and 0 or 1)
