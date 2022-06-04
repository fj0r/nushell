let __zoxide_menu = {
  name: zoxide_menu
  only_buffer_difference: true
  marker: "^ "
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
      zoxide query -ls $buffer
      | parse -r '(?P<description>[0-9]+) (?P<value>.+)'
  }
}

let __zoxide_keybinding = {
  name: zoxide_menu
  modifier: alt
  keycode: char_o
  mode: [emacs, vi_normal, vi_insert]
  event: { send: menu name: zoxide_menu }
}
