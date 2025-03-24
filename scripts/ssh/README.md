```bash
# Initialize `index.toml`
ssh-index-init
ssh-switch <environment, default is default> -g <group, default is all>
```

Environment configuration as follows:

```toml
[groups.default.local.default]
HostName = "127.0.0.1"
[groups.default.local.vpn]
HostName = "10.0.0.1"
```
