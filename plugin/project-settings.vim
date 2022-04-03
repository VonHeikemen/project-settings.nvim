if exists('g:loaded_project_settings')
  finish
endif
let g:loaded_project_settings = 1

command! ProjectSettingsLoad lua require('project-settings').load({verbose = true})

command! ProjectSettingsStatus lua require('project-settings').check_status()

command! ProjectSettingsRegister lua require('project-settings').register()

command! ProjectSettingsEdit lua require('project-settings').edit()

