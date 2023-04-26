export:
  #!/usr/local/bin/nu
  let dest = $"($env.HOME)/world/nu_scripts"
  for n in [docker kubernetes git nvim after] {
    cp $"scripts/($n).nu" $"($dest)/modules/($n)/($n).nu"
  }
  for n in [ssh] {
    cp $"scripts/($n).nu" $"($dest)/modules/network/($n).nu"
  }
  for n in [just] {
    cp $"scripts/($n).nu" $"($dest)/custom-completions/($n)/($n).nu"
  }

  let prt = 'prompt/powerline'
  for s in [power power_git power_kube] {
    cp $"scripts/($s).nu" $"($dest)/modules/($prt)/($s).nu"
  }
  cp $"scripts/power.md" $"($dest)/modules/($prt)/README.md"

