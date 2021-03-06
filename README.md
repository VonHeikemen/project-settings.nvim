# Project Settings

Define your "schema" using lua, write your settings in a JSON file.

## Getting Started

Make sure you have [Neovim v0.7.0](https://github.com/neovim/neovim/releases/tag/v0.7.0) or greater.

### Installation

Use your favorite plugin manager. For example.

With `vim-plug`:

```vim
Plug 'VonHeikemen/project-settings.nvim'
```

With `packer`:

```lua
use {'VonHeikemen/project-settings.nvim'}
```

With `paq`:

```lua
'VonHeikemen/project-settings.nvim';
```

## Usage

First thing you'll want to do is setup your schema in your config file. The idea is that each `key` is associated to a lua function. For example.

```lua
require('project-settings').setup({
  allow = {
    greeting = function(opts)
      if opts.spanish == true then
        print('Hola')
      end

      if opts.english == true then
        print('Hello')
      end
    end,

    another = function(opts)
      print(vim.inspect(opts))
    end
  },
})
```

> If you interested in more useful examples check out the wiki: [Examples](https://github.com/VonHeikemen/project-settings.nvim/wiki/Examples).

By default `project-settings` will look for a `.vimrc.json` in the current working directory. This file, for our particular case, can look like this.

```json
{
  "greeting": {
    "spanish": true,
    "english": true
  },
  "another": {
    "whatever": "I want"
  }
}
```

What's going to happen here is that the function in `allow.greeting` will receive whatever value we have in the `greeting` property in the json file. Same thing will happen with `another`.

Not a very useful example, I know. The point is, you can build the schema you like, with the features you want.

Since it's really easy to allow arbitrary code execution with this plugin, by default no settings file will be executed until you "register" it. So, when you create a local settings file make sure to use the `ProjectSettingsRegister` to register the file. You also need to register every change made in the file.

If you fail to register a settings file, or any update, a message will appear telling you the reason why the file was not loaded.

You can register automatically a settings file with an autocommand. This requires neovim v0.7.

```lua
local project_cmds = vim.api.nvim_create_augroup('project_cmds', {clear = true})
local autocmd = vim.api.nvim_create_autocmd

autocmd('BufWritePost', {
  pattern = '.vimrc.json',
  group = project_cmds,
  command = 'ProjectSettingsRegister'
})
```

## Configuration

These are the defaults.

```lua
{
  settings = {
    file_pattern = './.vimrc.json',
    notify_changed = true,
    notify_unregistered = true,
    autoload_on_dir_change = false,
    danger_zone = {
      check_integrity = true
    }
  },
  parser = vim.json.decode,
  allow = {}
}
```

You can pass this table to the `.setup()` or `.set_config()` functions to tweak the behaviour of the plugin at startup.

* `settings.file_pattern`: Path of the settings file relative to the current working directory.

* `settings.notify_changed`: Show a message when the settings file has an unregistered change.

* `settings.notify_unregistered`: Show a message if the settings file is not registered.

* `settings.autoload_on_dir_change`: Load new settings file automatically if current working directory changes. If equal to `true` it will only try to read a settings file once. If equal to the string `'always'` it will try to load a settings file even if it was loaded on a previous occasion.

* `settings.danger_zone.check_integrity`: Enable integrity check of the settings file.

* `parser`: Function that takes the content of the settings files and returns a lua table. This function will be used to read the settings file.

* `allow`: List of functions that will be executed after the settings file is read.

## Commands

* `ProjectSettingsLoad`: Execute the settings file present in the current working directory.

* `ProjectSettingsStatus`: Show message with the status of the settings file.

* `ProjectSettingsRegister`: Register a settings file. It also recent changes to a file.

* `ProjectSettingsEdit`: Open the settings file present in the current working directory.

## Lua api

### `.setup({opts})`

Sets the initial configuration, reads and loads the settings file.

### `.set_config({opts})`

Sets the initial configuration for the plugin. When this is used it is assumed you will load the settings file at a later time using the `.load()` function.

### `.load({opts})`

Load the settings file present in the current working directory.

`{opts}` can accept the following parameters:

* `verbose`: Boolean, defaults to `false`. Show a message if it can't read the settings file.
* `force`: Boolean, defaults to `false`. Load settings file even if it was read before.

### `.is_available()`

Returns a boolean that indicates whether or not there is a settings file available.

### `.allow({opts})`

Updates the "schema" of functions that will be used to read the settings file.

### `.register()`

"Register" a settings file.

### `.edit()`

Open the settings file present in the current working directory.

### `.check_status()`

Show message with the status of the settings file.

### `.utils.enable({callback})`

It wraps `{callback}` so that it is only executed if the value in the settings file is equal to `true`.

```lua
local project_settings = require('project-settings')
local enable = project_settings.utils.enable

project_settings.setup({
  allow = {
    this = enable(function()
      print('only when {"this": true}')
    end)
  }
})
```

### `.utils.section({opts})`

Used to create a nested section of callbacks.

```lua
local project_settings = require('project-settings')
local section = project_settings.utils.section

project_settings.setup({
  allow = {
    here = section({
      this = function()
        print('here.this')
      end,
      that = function()
        print('here.that')
      end
    })
  }
})
```

## Support

If you find this tool useful and want to support my efforts, [buy me a coffee ???](https://www.buymeacoffee.com/vonheikemen).

[![buy me a coffee](https://res.cloudinary.com/vonheikemen/image/upload/v1618466522/buy-me-coffee_ah0uzh.png)](https://www.buymeacoffee.com/vonheikemen)

