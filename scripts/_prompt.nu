# my_git
# An opinionated Git prompt for Nushell, styled after posh-git
#
# Quick Start:
# - Download this script (my_git.nu)
# - In your Nushell config:
#   - Source this script
#   - Set my_git as your prompt command
#   - Disable the separate prompt indicator by setting it to an empty string
# - For example, with this script in your home directory:
#     source ~/my_git.nu
#     let-env PROMPT_COMMAND = { my_git }
#     let-env PROMPT_INDICATOR = { "" }
# - Restart Nushell
#
# For more documentation or to file an issue, see https://github.com/ehdevries/my_git

def bright_cyan [] {
  each { |it| $"(ansi -e '96m')($it)(ansi reset)" }
}

def bright_green [] {
  each { |it| $"(ansi -e '92m')($it)(ansi reset)" }
}

def bright_red [] {
  each { |it| $"(ansi -e '91m')($it)(ansi reset)" }
}

def bright_yellow [] {
  each { |it| $"(ansi -e '93m')($it)(ansi reset)" }
}

def green [] {
  each { |it| $"(ansi green)($it)(ansi reset)" }
}

def red [] {
  each { |it| $"(ansi red)($it)(ansi reset)" }
}

# Internal commands for building up the my_git shell prompt
def DIR_COMP_ABBR [] { 5 }

# Get the current directory with home abbreviated
export def "my_git dir" [] {
  let current_dir = ($env.PWD)

  let current_dir_abbreviated = if ($current_dir == $nu.home-path) {
      "~"
  } else {
      let current_dir_relative_to_home = (
          do --ignore-errors { $current_dir | path relative-to $nu.home-path }
      )
      if ($current_dir_relative_to_home | is-empty) {
          $current_dir
      } else {
          $'~(char separator)($current_dir_relative_to_home)'
      }
  }

  let dir_comp = ($current_dir_abbreviated | split row (char separator))
  let dir_comp = if ($dir_comp | length) > (DIR_COMP_ABBR) {
      let first = ($dir_comp | first)
      let last = ($dir_comp | last)
      let body = (
          $dir_comp
          |range 1..-2
          |each {|x| $x | str substring ',2' }
          )
      [$first $body $last] | flatten
  } else {
      $dir_comp
  }
  let dir_comp = if ($dir_comp | get 0) == '~' {
      $dir_comp | str join (char separator)
  } else {
      $"/($dir_comp | str join (char separator))"
  }

  $dir_comp
}

# Get repository status as structured data
export def "my_git structured" [] {
  let in_git_repo = (do --ignore-errors { git rev-parse --abbrev-ref HEAD } | is-empty | nope)

  let status = (if $in_git_repo {
    git --no-optional-locks status --porcelain=2 --branch | lines
  } else {
    []
  })

  let on_named_branch = (if $in_git_repo {
    $status
    | where ($it | str starts-with '# branch.head')
    | first
    | str contains '(detached)'
    | nope
  } else {
    false
  })

  let branch_name = (if $on_named_branch {
    $status
    | where ($it | str starts-with '# branch.head')
    | split column ' ' col1 col2 branch
    | get branch
    | first
  } else {
    ''
  })

  let commit_hash = (if $in_git_repo {
    $status
    | where ($it | str starts-with '# branch.oid')
    | split column ' ' col1 col2 full_hash
    | get full_hash
    | first
    | str substring [0 7]
  } else {
    ''
  })

  let tracking_upstream_branch = (if $in_git_repo {
    $status
    | where ($it | str starts-with '# branch.upstream')
    | str join
    | is-empty
    | nope
  } else {
    false
  })

  let upstream_exists_on_remote = (if $in_git_repo {
    $status
    | where ($it | str starts-with '# branch.ab')
    | str join
    | is-empty
    | nope
  } else {
    false
  })

  let ahead_behind_table = (if $upstream_exists_on_remote {
    $status
    | where ($it | str starts-with '# branch.ab')
    | split column ' ' col1 col2 ahead behind
  } else {
    [[]]
  })

  let commits_ahead = (if $upstream_exists_on_remote {
    $ahead_behind_table
    | get ahead
    | first
    | into int
  } else {
    0
  })

  let commits_behind = (if $upstream_exists_on_remote {
    $ahead_behind_table
    | get behind
    | first
    | into int
    | math abs
  } else {
    0
  })

  let has_staging_or_worktree_changes = (if $in_git_repo {
    $status
    | where ($it | str starts-with '1') || ($it | str starts-with '2')
    | str join
    | is-empty
    | nope
  } else {
    false
  })

  let has_untracked_files = (if $in_git_repo {
    $status
    | where ($it | str starts-with '?')
    | str join
    | is-empty
    | nope
  } else {
    false
  })

  let has_unresolved_merge_conflicts = (if $in_git_repo {
    $status
    | where ($it | str starts-with 'u')
    | str join
    | is-empty
    | nope
  } else {
    false
  })

  let staging_worktree_table = (if $has_staging_or_worktree_changes {
    $status
    | where ($it | str starts-with '1') || ($it | str starts-with '2')
    | split column ' '
    | get column2
    | split column '' staging worktree --collapse-empty
  } else {
    [[]]
  })

  let staging_added_count = (if $has_staging_or_worktree_changes {
    $staging_worktree_table
    | where staging == 'A'
    | length
  } else {
    0
  })

  let staging_modified_count = (if $has_staging_or_worktree_changes {
    $staging_worktree_table
    | where staging in ['M', 'R']
    | length
  } else {
    0
  })

  let staging_deleted_count = (if $has_staging_or_worktree_changes {
    $staging_worktree_table
    | where staging == 'D'
    | length
  } else {
    0
  })

  let untracked_count = (if $has_untracked_files {
    $status
    | where ($it | str starts-with '?')
    | length
  } else {
    0
  })

  let worktree_modified_count = (if $has_staging_or_worktree_changes {
    $staging_worktree_table
    | where worktree in ['M', 'R']
    | length
  } else {
    0
  })

  let worktree_deleted_count = (if $has_staging_or_worktree_changes {
    $staging_worktree_table
    | where worktree == 'D'
    | length
  } else {
    0
  })

  let merge_conflict_count = (if $has_unresolved_merge_conflicts {
    $status
    | where ($it | str starts-with 'u')
    | length
  } else {
    0
  })

  {
    in_git_repo: $in_git_repo,
    on_named_branch: $on_named_branch,
    branch_name: $branch_name,
    commit_hash: $commit_hash,
    tracking_upstream_branch: $tracking_upstream_branch,
    upstream_exists_on_remote: $upstream_exists_on_remote,
    commits_ahead: $commits_ahead,
    commits_behind: $commits_behind,
    staging_added_count: $staging_added_count,
    staging_modified_count: $staging_modified_count,
    staging_deleted_count: $staging_deleted_count,
    untracked_count: $untracked_count,
    worktree_modified_count: $worktree_modified_count,
    worktree_deleted_count: $worktree_deleted_count,
    merge_conflict_count: $merge_conflict_count
  }
}

# Get repository status as a styled string
export def "my_git styled" [] {
  let status = (my_git structured)

  let is_local_only = ($status.tracking_upstream_branch != true)

  let upstream_deleted = (
    $status.tracking_upstream_branch &&
    $status.upstream_exists_on_remote != true
  )

  let is_up_to_date = (
    $status.upstream_exists_on_remote &&
    $status.commits_ahead == 0 &&
    $status.commits_behind == 0
  )

  let is_ahead = (
    $status.upstream_exists_on_remote &&
    $status.commits_ahead > 0 &&
    $status.commits_behind == 0
  )

  let is_behind = (
    $status.upstream_exists_on_remote &&
    $status.commits_ahead == 0 &&
    $status.commits_behind > 0
  )

  let is_ahead_and_behind = (
    $status.upstream_exists_on_remote &&
    $status.commits_ahead > 0 &&
    $status.commits_behind > 0
  )

  let branch_name = (if $status.in_git_repo {
    (if $status.on_named_branch {
      $status.branch_name
    } else {
      ['(' $status.commit_hash '...)'] | str join
    })
  } else {
    ''
  })

  let branch_styled = (if $status.in_git_repo {
    (if $is_local_only {
      (branch_local_only $branch_name)
    } else if $is_up_to_date {
      (branch_up_to_date $branch_name)
    } else if $is_ahead {
      (branch_ahead $branch_name $status.commits_ahead)
    } else if $is_behind {
      (branch_behind $branch_name $status.commits_behind)
    } else if $is_ahead_and_behind {
      (branch_ahead_and_behind $branch_name $status.commits_ahead $status.commits_behind)
    } else if $upstream_deleted {
      (branch_upstream_deleted $branch_name)
    } else {
      $branch_name
    })
  } else {
    ''
  })

  let has_staging_changes = (
    $status.staging_added_count > 0 ||
    $status.staging_modified_count > 0 ||
    $status.staging_deleted_count > 0
  )

  let has_worktree_changes = (
    $status.untracked_count > 0 ||
    $status.worktree_modified_count > 0 ||
    $status.worktree_deleted_count > 0 ||
    $status.merge_conflict_count > 0
  )

  let has_merge_conflicts = $status.merge_conflict_count > 0

  let staging_summary = (if $has_staging_changes {
    (staging_changes $status.staging_added_count $status.staging_modified_count $status.staging_deleted_count)
  } else {
    ''
  })

  let worktree_summary = (if $has_worktree_changes {
    (worktree_changes $status.untracked_count $status.worktree_modified_count $status.worktree_deleted_count)
  } else {
    ''
  })

  let merge_conflict_summary = (if $has_merge_conflicts {
    (unresolved_conflicts $status.merge_conflict_count)
  } else {
    ''
  })

  let delimiter = (if ($has_staging_changes && $has_worktree_changes) {
    ('|' | bright_yellow)
  } else {
    ''
  })

  let local_summary = (
    $'($staging_summary) ($delimiter) ($worktree_summary) ($merge_conflict_summary)' | str trim
  )

  let local_indicator = (if $status.in_git_repo {
    (if $has_worktree_changes {
      ('!' | red)
    } else if $has_staging_changes {
      ('~' | bright_cyan)
    } else {
      ''
    })
  } else {
    ''
  })

  let repo_summary = (
    $'($branch_styled) ($local_summary) ($local_indicator)' | str trim
  )

  let left_bracket = ('|' | bright_yellow)
  let right_bracket = ('' | bright_yellow)

  (if $status.in_git_repo {
    $'($left_bracket)($repo_summary)($right_bracket)'
  } else {
    ''
  })
}

# Helper commands to encapsulate style and make everything else more readable

def nope [] {
  each { |it| $it == false }
}


def branch_local_only [
  branch: string
] {
  $branch | bright_cyan
}

def branch_upstream_deleted [
  branch: string
] {
  $'($branch)(char failed)' | bright_cyan
}

def branch_up_to_date [
  branch: string
] {
  $'($branch)(char identical_to)' | bright_cyan
}

def branch_ahead [
  branch: string
  ahead: int
] {
  $'($branch)(char branch_ahead)($ahead)' | bright_green
}

def branch_behind [
  branch: string
  behind: int
] {
  $'($branch)(char branch_behind)($behind)' | bright_red
}

def branch_ahead_and_behind [
  branch: string
  ahead: int
  behind: int
] {
  $'($branch)(char branch_behind)($behind)(char branch_ahead)($ahead)' | bright_yellow
}

def staging_changes [
  added: int
  modified: int
  deleted: int
] {
  $'+($added)~($modified)-($deleted)' | green
}

def worktree_changes [
  added: int
  modified: int
  deleted: int
] {
  $'+($added)~($modified)-($deleted)' | red
}

def unresolved_conflicts [
  conflicts: int
] {
  $'!($conflicts)' | red
}

### kubernetes
def "kube ctx" [] {
    do --ignore-errors {
       kubectl config get-contexts
       | from ssv -a
       | where CURRENT == '*'
       | rename curr name cluster authinfo namespace
       | get 0
    }
}

export def "kube prompt" [] {
    do -i {
        let ctx = kube ctx
        let left_bracket = ('' | bright_yellow)
        let right_bracket = ('|' | bright_yellow)
        let c = if $ctx.authinfo == $ctx.cluster {
                    $ctx.cluster
                } else {
                    $"($ctx.authinfo)@($ctx.cluster)"
                }
        let p = $"(ansi red)($c)(ansi yellow)/(ansi cyan_bold)($ctx.namespace)"
        $"($left_bracket)($p)($right_bracket)" | str trim
    }
}

### proxy
export def "proxy prompt" [] {
    if ('https_proxy' in (env).name) && (not ($env.https_proxy | is-empty)) {
        $"(ansi blue)|"
    } else {
        ""
    }
}

def host_abbr [] {
    let n = (hostname | str trim)
    let ucl = if (is-admin) {
            (ansi yellow)
        } else {
            (ansi dark_gray)
        }
    $"($ucl)($n)(ansi reset)(ansi dark_gray_bold):(ansi light_green_bold)"
}


def right_prompt [] {
    {
        let time_segment = ([
            (date now | date format '%m/%d/%Y %r')
        ] | str join)

        $"(proxy prompt)(kube prompt)(ansi purple_bold)($time_segment)"
    }
}

# An opinionated Git prompt for Nushell, styled after posh-git
def my_prompt [] {
    {
        $"(host_abbr)(my_git dir)(my_git styled)"
    }
}

export-env {
    let-env PROMPT_COMMAND = my_prompt
    let-env PROMPT_COMMAND_RIGHT = right_prompt
}
