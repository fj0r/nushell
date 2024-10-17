def override_key [bindings] {
    let y = $in
    let a = $bindings | where modifier == $y.modifier? and keycode == $y.keycode
    if ($a | is-not-empty) {
        $y | merge ($a | first)
    } else {
        $y
    }
}

def --env prefer_alt_env [] {
    let prefer_alt = $env.PREFER_ALT? | default '0' | into int
    let include_chars = $env.PREFER_ALT_EXCLUED? | default (
        [a e f b n p w u] | each { $"char_($in)" }
    )
    let modifieries = {
        control: 'alt'
        control_shift: 'shift_alt'
        alt: 'control'
        shift_alt: 'control_shift'
    }
    let bindings = [
        {
            modifier: alt
            keycode: char_f
            event: {
                until: [
                    { send: historyhintcomplete }
                    { send: menuright }
                    { edit: movewordright }
                ]
            }
        }
        {
            modifier: control
            keycode: char_f
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    { send: right }
                ]
            }
        }
        {
            modifier: alt
            keycode: char_b
            event: {
                until: [
                    { send: menuleft }
                    { edit: movewordleft }
                ]
            }
        }
        {
            modifier: control
            keycode: char_b
            event: { send: left }
        }
    ]
    if $prefer_alt > 0 {
        let new_ks = $env.config.keybindings
        | each {|x|
            if $x.modifier? in $modifieries and $x.keycode in $include_chars  {
                $x | update modifier ($modifieries | get $x.modifier)
            } else {
                $x
            }
            | override_key $bindings
        }
        if ($new_ks | describe) == list<error> {
            print $"(ansi red)__prefer_alt failed(ansi reset)"
            print ($new_ks | table -e)
        } else {
            $env.config.keybindings = $new_ks
        }
    }
}

prefer_alt_env
