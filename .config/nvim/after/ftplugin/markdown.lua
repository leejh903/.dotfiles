-- Follow markdown links (`[text](path.md)` and `[[wiki links]]`) under the
-- cursor regardless of whether the buffer is inside an obsidian.nvim
-- workspace. Runs on every markdown buffer via ftplugin; obsidian.nvim's own
-- BufEnter autocmd overrides this mapping later when the buffer *is* inside
-- a configured workspace, so vault-only behavior (checkbox toggling, note
-- creation) still takes precedence there.

local function link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  for open, close in line:gmatch("()%[%[.-%]%]()") do
    if col >= open and col <= close then
      local inner = line:sub(open + 2, close - 3)
      return inner:match("^(.-)|") or inner
    end
  end

  for open, target, close in line:gmatch("()%[.-%]%((.-)%)()") do
    if col >= open and col <= close then
      return target
    end
  end

  return nil
end

local function follow_link()
  local target = link_under_cursor()
  if not target then
    return vim.cmd.normal({ "gf", bang = true })
  end

  if target:match("^%a+://") then
    vim.ui.open(target)
    return
  end

  local path = target:gsub("#.*$", "")
  if path == "" then
    return
  end
  if not path:match("%.%w+$") then
    path = path .. ".md"
  end

  local full = vim.fs.normalize(vim.fn.expand("%:p:h") .. "/" .. path)
  if vim.fn.filereadable(full) == 1 then
    vim.cmd.edit(vim.fn.fnameescape(full))
  else
    vim.notify("Link target not found: " .. full, vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<CR>", follow_link, { buffer = true, desc = "Follow markdown link" })
