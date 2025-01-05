# Parse args
new version that is implemented by `ast`, which is slightly faster. It is mainly more reliable, as the [earlier version](https://github.com/nushell/nu_scripts/blob/main/modules/argx/mod.nu) actually overlooked some parsing details, such as not strictly matching parentheses (after all, it wouldn't execute if there were issues).

In the new version, the `ast` directly provides the relevant information. There is also a `--pos` parameter for parsing **name** of positional arguments (which is often unnecessary, making it faster).

---
[Others](https://github.com/fj0r/nushell/blob/main/README.md)
