use mod.nu *
use completion.nu *
use tag_base.nu *

export alias sl = scratch-list
export alias sa = scratch-add
export alias se = scratch-edit
export alias sm = scratch-move
export alias st = scratch-attrs
export alias sdn = scratch-done
export alias sda = scratch-data
export alias stm = scratch-tag-move
export alias stt = scratch-tag-toggle
export alias sdel = scratch-delete
export alias sclean = scratch-clean
export alias stclean = scratch-tag-clean
export alias sthide = scratch-tag-hidden
export alias strename = scratch-tag-rename
export alias sactivities = scratch-activities

export alias so = scratch-out
export alias si = scratch-in
export alias sp = scratch-upsert


export def scratch-trash [] {
    scratch-list --trash
}

export def scratch-today [
    ...xtags:string@cmpl-tag-3
    --trash(-T)
    --md
    --md-list
    --raw
    --done(-x): int
    --untagged(-U)
    --deadline
] {
    let t = (date now) - (date now | format date '%FT00:00:00' | into datetime)

    (scratch-list
        ...$xtags --trash=$trash
        --created $t --updated $t --deadline $t
        --md-list=$md_list --md=$md --raw=$raw
        --done $done
        )
}

export alias sto = scratch-today
