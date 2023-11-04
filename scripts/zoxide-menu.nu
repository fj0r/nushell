def __zoxide_menu [] {
    {
      name: zoxide_menu
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
          open $nu.history-path
          | query db $"select cwd as value, count\(*) as description
            from history where cwd like '%($buffer)%'
            group by cwd order by description desc
            limit 20"
          #zoxide query -ls $buffer | parse -r '(?P<description>[0-9]+) (?P<value>.+)'

# create trigger count_cwd
# after insert on history
# begin
#   update rec_info
#       set u_cnt = ( select COUNT(*) from rec_info  where username = new.username)
#   WHERE username = new.username;
# end
      }
    }
}

def __zoxide_keybinding [] {
    {
      name: zoxide_menu
      modifier: control
      keycode: char_o
      mode: [emacs, vi_normal, vi_insert]
      event: [
        { send: menu name: zoxide_menu }
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
    $env.config  = ($env.config
                  | upsert menus ($env.config.menus | append (__zoxide_menu))
                  | upsert keybindings ($env.config.keybindings | append [(__zoxide_keybinding) (__edit_keybinding)])
                  )
}
