def __cwdhist_menu [] {
    {
      name: cwdhist_menu
      only_buffer_difference: true
      marker: "| "
      type: {
          layout: columnar
          page_size: 20
      }
      style: {
          text: green
          selected_text: green_reverse
          description_text: yellow
      }
      source: { |buffer, position|
        let stmt = if ($buffer | is-empty) {
        #:FIXME: empty cwdhist
           $"select cwd as value, count as description
            from cwd_history order by count desc
            limit 20"
        } else {
           $"select cwd as value, count as description
            from cwd_history where cwd like '%($buffer)%'
            order by count desc
            limit 20"
        }
        open $nu.history-path | query db $stmt
      }
    }
}

def __cwdhist_keybinding [] {
    {
      name: cwdhist_menu
      modifier: control
      keycode: char_o
      mode: [emacs, vi_normal, vi_insert]
      event: [
        { send: menu name: cwdhist_menu }
      ]
    }
}

def __edit_keybinding [] {
    {
      name: edit
      modifier: alt
      keycode: char_e
      mode: [emacs, vi_normal, vi_insert]
      event: [
        { send: OpenEditor }
      ]
    }
}

export-env {
    if not ('cwdhist' in $env) {
        $env.cwdhist = true

        open ([($nu.history-path | path dirname), 'history.sqlite3'] | path  join)
        | query db "create table if not exists cwd_history (
            cwd text primary key,
            count int default 1,
            recent datetime default (datetime('now', 'localtime'))
          );"

        $env.config = ($env.config | update hooks.env_change.PWD ($env.config.hooks.env_change.PWD | append {|_, dir|
          open $nu.history-path
          | query db $"insert into cwd_history\(cwd\) values \('($dir)'\)
            on conflict\(cwd\) do
            update set count = count + 1,
                       recent = datetime\('now', 'localtime'\);"
        }))
    }


    $env.config  = ($env.config
                  | upsert menus ($env.config.menus | append (__cwdhist_menu))
                  | upsert keybindings ($env.config.keybindings | append [(__cwdhist_keybinding) (__edit_keybinding)])
                  )
}
