export:
  #!/usr/local/bin/nu
  for s in [docker kubernetes ssh git just nvim] {
    cp $"scripts/($s).nu" $"($env.HOME)/world/nu_scripts/($s)/($s).nu"
  }
  cp $"scripts/_prompt.nu" $"($env.HOME)/world/nu_scripts/prompt/git-k8s.nu"
