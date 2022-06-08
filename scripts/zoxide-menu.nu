let __zoxide_menu = {
  name: zoxide_menu
  only_buffer_difference: true
  marker: "┊ "
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
      zoxide query -ls $buffer
      | parse -r '(?P<description>[0-9]+) (?P<value>.+)'
  }
}

let __zoxide_keybinding = {
  name: zoxide_menu
  modifier: control
  keycode: char_o
  mode: [emacs, vi_normal, vi_insert]
  event: [
    { send: menu name: zoxide_menu }
  ]
}

let __edit_keybinding = {
  name: edit
  modifier: alt
  keycode: char_o
  mode: [emacs, vi_normal, vi_insert]
  event: [
    { send: OpenEditor }
  ]
}

let-env config = ($env.config
               | update menus ($env.config.menus | append $__zoxide_menu)
               | update keybindings ($env.config.keybindings | append [$__zoxide_keybinding $__edit_keybinding])
               )
