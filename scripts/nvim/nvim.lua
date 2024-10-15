local vcs_root = require('lspconfig.util').root_pattern('.git/')
function HookPwdChanged(after, before)
    vim.b.pwd = after
    local git_dir = vcs_root(after)
    vim.api.nvim_command('silent tcd! '..(git_dir or after))
end

function OppositePwd()
    local tab = vim.api.nvim_get_current_tabpage()
    local wins = vim.api.nvim_tabpage_list_wins(tab)
    local cwin = vim.api.nvim_tabpage_get_win(tab)
    for _, w in ipairs(wins) do
        if cwin ~= w then
            local b = vim.api.nvim_win_get_buf(w)
            local pwd = vim.b[b].pwd
            if pwd then return pwd end
        end
    end
end

function ReadTempDrop(path, action)
    vim.api.nvim_command(action or 'botright vnew')
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_command('read '..path)
    vim.fn.delete(path)
end
