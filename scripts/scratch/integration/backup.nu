export def 'scratch backup' [] {
    mkdir $env.SCRATCH_BACKUP_DIR
    cp $env.SCRATCH_STATE ([$env.SCRATCH_BACKUP_DIR, (date now | format date "%y_%m_%d_%H_%M_%S")] | path join)
}

def cmpl-scratch_backup_file [] {
    ls $env.HISTORY_SCRATCH_DIR | each {|x| $x.name | path parse } | get stem | reverse
}

export def 'scratch restore' [name: string@cmpl-scratch_backup_file] {
    rm -f $env.SCRATCH_STATE
    cp ([$env.SCRATCH_BACKUP_DIR, $name] | path join) $env.SCRATCH_STATE
}
