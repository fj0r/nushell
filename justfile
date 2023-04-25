export:
  #!/usr/local/bin/nu
  let dest = $"($env.HOME)/world/nu_scripts"
  for s in [docker kubernetes ssh git just nvim] {
    cp $"scripts/($s).nu" $"($dest)/($s)/($s).nu"
  }
  let prt = 'prompt/powerline'
  for s in [power power_git power_kube] {
    cp $"scripts/($s).nu" $"($dest)/($prt)/($s).nu"
  }
  cp $"scripts/power.md" $"($dest)/($prt)/README.md"

test:
  #!/usr/local/bin/nu
  let theme = { context: white }
  let kind = 'kube'
  let-env NU_POWER_THEME = {
    kube: {
        context: red
        separator: yello
        namespace: cyan
    }
  }

  let prev_theme = ($env.NU_POWER_THEME | get $kind)
  let prev_cols = ($prev_theme | columns)
  let next_theme = ($theme | transpose k v)
  for n in $next_theme {
      if $n.k in $prev_cols {
          let-env NU_POWER_THEME = (
              $env.NU_POWER_THEME | update $kind {|conf|
                $conf | get $kind | update $n.k $n.v
              }
          )
      }
  }

  echo $env.NU_POWER_THEME | to json
