export use ../scripts/git/stat.nu *
export use ../scripts/git/utils.nu *
export use ../scripts/git/core.nu *
export use ../scripts/git/histogram.nu *
export use ../scripts/git/git-flow.nu *
export use ../scripts/git/shortcut.nu *

export-env {
    $env.GIT_COMMIT_TYPE = {
        feat: 'feat: {}'
        fix: 'fix: {}'
        docs: 'docs: {}'
        style: 'style: {}'
        refactor: 'refactor: {}'
        perf: 'perf: {}'
        test: 'test: {}'
        chore: 'chore: {}'
    }
    export use ../scripts/git/git-flow.nu
}
