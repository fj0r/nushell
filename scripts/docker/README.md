
### dx
Run a container with preset using `dx`

Presets can be defined in the `$env.CONTCONFIG` file, with the content as follows:

```yaml
preset:
- name: rust
  image: rust
  cmd: []
  env:
    CARGO_HOME: /opt/cargo
  volumn:
    .: /world
    ~/.cargo: /opt/cargo
  port:
    '8000': 80
```
