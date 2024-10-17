export def --env prefer_alt_env [] {
    let prefer_alt = $env.PREFER_ALT? | default '0' | into int
    let exclude_chars = $env.PREFER_ALT_EXCLUED? | default (
        ['f' 'b' 'c' 'd'] | each { $"char_($in)" }
    )
    let modifieries = {
        control: 'alt'
        control_shift: 'shift_alt'
        alt: 'control'
        shift_alt: 'control_shift'
    }
    if $prefer_alt > 0 {
        let new_ks = $env.config.keybindings
        | each {|x|
            if $x.modifier? in $modifieries and $x.keycode not-in $exclude_chars  {
                $x | update modifier ($modifieries | get $x.modifier) 
            } else {
                $x
            }
        }
        if ($new_ks | describe) == list<error> {
            print $"(ansi red)__prefer_alt failed(ansi reset)"
        } else {
            $env.config.keybindings = $new_ks
        }
    }
}

