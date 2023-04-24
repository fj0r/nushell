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
