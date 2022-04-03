local M = {utils = {}}
local s = {}
local uv = vim.loop

s.status = {loaded = false, file_state = 'unknown'}
local config = require('project-settings.config')

M.setup = function(opts)
  opts = opts or {}

  if vim.tbl_isempty(config.get()) == false then
    config.update(opts)
    return
  end

  config.setup(opts)
  M.load({verbose = false})
end

M.load = function(opts)
  opts = opts or {}

  local path = config.get().settings.file_pattern
  if vim.fn.filereadable(path) == 1 then
    s.status = s.execute(path)
  elseif opts.verbose == true then
    vim.notify('No settings file available', vim.log.levels.WARN)
  end
end

M.is_available = function()
  return vim.fn.filereadable(config.get().settings.file_pattern) == 1
end

M.register = function()
  if not M.is_available() then return end

  local user_settings = config.get().settings
  local info_path = user_settings.file_register
  local current = vim.fn.fnamemodify(user_settings.file_pattern, ':p')

  -- User **needs** to review the file
  if vim.fn.expand('%:p') ~= current then
    return
  end

  local checksum = vim.fn.sha256(s.read_file(current))

  if vim.fn.filereadable(info_path) == 0 then
    local data = vim.json.encode({
      ['file-settings'] = {
        [current] = checksum
      }
    })

    s.write_file(info_path, data)
    return
  end

  local register = vim.json.decode(s.read_file(info_path))
  local msg = nil

  if register['file-settings'][current] then
    msg = 'File register updated'
  else
    msg = 'File added to register'
  end

  register['file-settings'][current] = checksum

  s.write_file(info_path, vim.json.encode(register))

  vim.notify(msg, vim.log.levels.INFO)
end

M.edit = function()
  local current = vim.fn.fnamemodify(config.get().settings.file_pattern, ':p')
  vim.cmd('edit ' .. current)
end

M.set_config = config.setup

M.allow = function(opts)
  opts = opts or {}
  config.update({allow = opts})
end

M.check_status = function()
  if s.status.loaded then
    return vim.notify('Loaded')
  end

  local state = s.status.file_state

  local msg = 'Not loaded. '

  if state == 'unregistered' then
    msg = msg .. 'Settings file not registered.'
  elseif state == 'mismatch' then
    msg = msg .. 'Settings file has changed since last access.'
  elseif state == 'unknown' then
    if M.is_available() then
      msg = 'Available.'
    else
      msg = 'No settings file available.'
    end
  end

  vim.notify(msg)
end

M.utils.enable = function(fn)
  return function(enabled)
    if enabled == true then
      fn()
    end
  end
end

M.utils.section = function(fns)
  return function(user_opts)
    for name, args in pairs(user_opts) do
      if fns[name] then
        fns[name](args)
      end
    end
  end
end

s.execute = function(filepath)
  local global_opts = config.get()
  local content = s.read_file(filepath)
  local file_state = 'dont_care' 

  if global_opts.settings.danger_zone.check_integrity then
    file_state = s.check_integrity(filepath, content)
  end

  if file_state == 'unregistered' then
    if global_opts.settings.notify_unregistered == false then return end

    local msg = "[project-settings] Trying read a settings file that is not registered:\n%s"
      .. "\n\nPlease review the file then register it using using the command"
      .. " `ProjectSettingsRegister`."

    vim.fn.confirm(msg:format(filepath))

    return {loaded = false, file_state = file_state}
  elseif file_state == 'mismatch' then
    if global_opts.settings.notify_changed == false then return end

    local msg = '[project-settings] Settings file has change since last access.\n'
      .. 'Please review the file and update the register using the command `ProjectSettingsRegister`.\n\n'
      .. 'Path to file: %s'

    vim.fn.confirm(msg:format(filepath))

    return {loaded = false, file_state = file_state}
  end

  local data = vim.json.decode(content)

  for name, fn in pairs(global_opts.allow) do
    if data[name] then
      fn(data[name])
    end
  end

  return {loaded = true, file_state = file_state}
end

s.check_integrity = function(filepath, content)
  local full_path = vim.fn.fnamemodify(filepath, ':p')
  local info_path = config.get().settings.file_register

  if vim.fn.filereadable(info_path) == 0 then
    s.write_file(info_path, '{"file-settings":{}}')
    return 'unregistered'
  end

  local info = vim.json.decode(s.read_file(info_path))
  local record = info['file-settings'][full_path]

  if record == nil then
    return 'unregistered'
  end

  if vim.fn.sha256(content) == record then
    return 'unchanged'
  else
    return 'mismatch'
  end
end

s.write_file = function(path, contents)
  local fd = assert(uv.fs_open(path, 'w', 438))
  uv.fs_write(fd, contents, -1)
  assert(uv.fs_close(fd))
end

s.read_file = function(path)
  local fd = assert(uv.fs_open(path, 'r', 438))
  local fstat = assert(uv.fs_fstat(fd))
  local contents = assert(uv.fs_read(fd, fstat.size, 0))
  assert(uv.fs_close(fd))
  return contents
end

return M

