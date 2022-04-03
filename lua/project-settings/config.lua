local M = {}
local state = {}

local merge = function(defaults, override)
  return vim.tbl_deep_extend(
    'force',
    {},
    defaults,
    override
  )
end

M.get = function()
  return state
end

M.defaults = function()
  return {
    allow = {},
    settings = {
      notify_unregistered = true,
      notify_changed = true,
      file_pattern = './.vimrc.json',
      file_register = vim.fn.stdpath('data') .. '/project-settings.info.json',
      danger_zone = {
        check_integrity = true
      }
    },
  }
end

M.set_defaults = function()
  for key, val in pairs(M.defaults()) do
    state[key] = val
  end
end

M.update = function(opts)
  for key, val in pairs(state) do
    if opts[key] then
      state[key] = merge(state[key], opts[key])
    end
  end
end

M.setup = function(opts)
  opts = opts or {}
  M.set_defaults()
  M.update(opts)
end

return M

