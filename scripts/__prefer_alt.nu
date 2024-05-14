export def --env prefer_alt_env [prefer_alt] {
    let prefer_alt = $prefer_alt | default '0' | into int
    if $prefer_alt > 0 {
        let acts = [
            # f
            #move_right_or_take_history_hint
            #move_one_word_right_or_take_history_hint
            # b
            #move_left
            #move_one_word_left
            # a
            move_to_line_start
            # e
            move_to_line_end_or_take_history_hint
            # r
            history_menu
            # p
            move_up
            # t -> n
            move_down
            # w
            delete_one_word_backward
            # u
            cut_line_from_start
            upper_case_word
            # d
            #quit_shell
            #cut_word_to_right
            # c
            #cancel_command
            #capitalize_char
            #z
            undo_change
            undo_or_previous_page_menu
        ]
        $env.config.keybindings = (
            $env.config.keybindings
            | each {|x|
                let x = if $x.name == 'move_down' and $x.keycode == 'char_t' {
                    $x | update keycode 'char_n'
                } else {
                    $x
                }
                if ($x.name? in $acts) and ($x.modifier? in ['control' 'alt']) {
                    $x | update modifier (
                        if $x.modifier == 'control' {
                            'alt'
                        } else if $prefer_alt > 1 {
                            'shift_alt'
                        } else {
                            'control'
                        }
                    )
                } else if $x.keycode == 'char_f' {
                    if ($x.event.until? | is-empty) { $x } else {
                        let r = $x.event.until
                        | each {|z|
                            if 'send' in $z {
                                $z | update send {|u|
                                    match $u.send {
                                        'historyhintcomplete' => 'historyhintwordcomplete'
                                        'historyhintwordcomplete' => 'historyhintcomplete'
                                        _ => $u.send
                                    }
                                }
                            } else {
                                $z
                            }
                        }
                        $x | update event.until $r
                    }
                } else {
                    $x
                }
            })
    }
}

