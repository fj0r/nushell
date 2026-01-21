use ../scripts/scratch/data.nu
export-env {
    data init
    data theme
    $env.SCRATCH_BACKUP_DIR = $'($env.HOME)/.cache/scratch-backup'
}

export use ../scripts/scratch/core.nu *
export use ../scripts/scratch/tag.nu *
export use ../scripts/scratch/stat.nu *
export use ../scripts/scratch/libs/files.nu *
export use ../scripts/scratch/integration/backup.nu *
