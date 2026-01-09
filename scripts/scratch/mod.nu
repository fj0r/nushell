use data.nu
export-env {
    data init
    data theme
    $env.SCRATCH_BACKUP_DIR = $'($env.HOME)/.cache/scratch-backup'
}

export use core.nu *
export use tag.nu *
export use stat.nu *
export use shortcut.nu *
export use libs/files.nu *
export use integration/backup.nu *
