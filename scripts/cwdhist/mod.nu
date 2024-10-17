def quote [...t] {
    let s = $t | str join '' | str replace -a "'" "''"
    $"'($s)'"
}

export def 'cwd history delete' [cwd] {
    open $env.CWD_HISTORY_FILE
    | query db $"delete from cwd_history where cwd = (quote $cwd);"
}

export-env {
    $env.CWD_HISTORY_FULL = false
    $env.CWD_HISTORY_FILE = $nu.data-dir | path join 'cwd_history.sqlite'

    if not ($env.CWD_HISTORY_FILE | path exists) {
        {_: '.'} | into sqlite -t _ $env.CWD_HISTORY_FILE
        print $"(ansi grey)created database: $env.CWD_HISTORY_FILE(ansi reset)"
        open $env.CWD_HISTORY_FILE | query db "create table if not exists cwd_history (
            cwd text primary key,
            count int default 1,
            recent datetime default (datetime('now', 'localtime'))
        );"
    }

    $env.config.hooks.env_change.PWD ++= {|_, dir|
        if $dir == $nu.home-path { return }
        let suffix = (do --ignore-errors { $dir | path relative-to  $nu.home-path })
        let path = if ($suffix | is-empty) {
            $dir
        } else {
            ['~', $suffix] | path join
        }
        open $env.CWD_HISTORY_FILE
        | query db $"
            insert into cwd_history\(cwd\)
                values \((quote $path)\)
            on conflict\(cwd\)
            do update set
                count = count + 1,
                recent = datetime\('now', 'localtime');"
    }

    $env.config.menus ++= {
        name: cwdhist_menu
        only_buffer_difference: true
        marker: "| "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: { |buffer, position|
            #$"[($position)]($buffer);(char newline)" | save -a ~/.cache/cwdhist.log
            let t = quote '%' ($buffer | split row ' ' | last) '%'
            if $env.CWD_HISTORY_FULL {
                open $nu.history-path | query db $"
                    select cwd as value, count\(*\) as cnt
                    from history
                    where cwd like ($t)
                    group by cwd
                    order by cnt desc
                    limit 50
                    ;"
            } else {
                open $env.CWD_HISTORY_FILE | query db $"
                    select cwd as value, count
                    from cwd_history
                    where cwd like ($t)
                    order by count desc
                    limit 50
                    ;"
            }
        }
    }
    $env.config.keybindings ++= [
        {
            name: cwdhist_menu
            modifier: control
            keycode: char_o
            mode: [emacs, vi_normal, vi_insert]
            event: [
                { send: menu name: cwdhist_menu }
            ]
        }
        {
            name: cwdhist_switching
            modifier: shift_alt
            keycode: char_o
            mode: [emacs, vi_normal, vi_insert]
            event: [
                { send: ExecuteHostCommand, cmd: '$env.CWD_HISTORY_FULL = (not $env.CWD_HISTORY_FULL)' }
            ]
        }
    ]
}
