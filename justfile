export:
  #!/usr/local/bin/nu
  for s in [docker kubernetes ssh git just nvim] {
    cp $"scripts/($s).nu" $"($env.HOME)/world/nu_scripts/($s)/($s).nu"
  }
  cp $"scripts/power.nu" $"($env.HOME)/world/nu_scripts/prompt/power.nu"
