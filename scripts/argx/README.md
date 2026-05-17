# argx.nu 🚀

A language-aware, signature-driven, and completely unopinionated argument parsing engine built exclusively for Nushell autocomplete closures.
Instead of hacking fragile text-splitters or managing bloated external multi-shell engines, argx.nu interacts directly with Nushell's live internal Abstract Syntax Tree (AST) contexts and runtime command signatures. It dynamically maps an unordered, chaotic terminal input stream into a clean, normalized, and strongly-typed Record that is immediately actionable.

## ✨ Features

- 🧠 Language-Aware AST Tokenization: Correctly extracts complex Nushell types, nested quotes, and closures/subexpressions (e.g., blocks like {KEY: VALUE}) without breaking your completion pipe on white spaces or special characters.
- 🎯 Deep Alias Bypassing: [Core Advantage] Transparently penetrates user-defined aliases. Even if a shortcut alias (like dr) is typed in the terminal, argx.nu traces back to the underlying base command and outputs the true semantic intent in the tag field (e.g., container-create), saving your completion scripts from handling endless alias variations.
- 🔄 Signature-Driven Argument Normalization:
- Options (Flags): Automatically resolves command definitions to normalize short flags (e.g., -e, -p) into their canonical long-form parameter names (e.g., envs, ports), eliminating duplicate alias-handling logic in your code.
   - Positional Arguments: Maps raw positional strings into their exact variable names defined in the command's original signature (e.g., mapping localhost/... to pos.image). This completely solves the common "index-shifting" problem caused by omitted optional positionals or rearranged inputs.
- 🛡️ Execution-Safe (Zero Side-Effects): Keeps nested commands and closures frozen as raw AST structures during the Tab-completion phase, ensuring you never accidentally trigger heavy or dangerous sub-commands.
- 🏷️ High-Fidelity Semantic Mapping: Structurizes tokens cleanly into named options (opt), raw post-arguments (args), typed positional fields (pos), and inferred operation intent identifiers (tag).
- 🪶 Zero-DSL Philosophy: No proprietary wrapper commands or rigid state-machine APIs to learn. It returns a pure Nushell Record so you can use 100% of your existing Nushell skills (match, if, get, where).

## 🔍 How It Works (The Ultimate Debug DX)
One of the cleanest developer experiences with argx.nu is that you can perfectly snapshot, test, and introspect your live autocomplete logic as a static data frame directly in your prompt by simply passing your CLI line as a string.
Notice in the example below how the shortcut alias dr is decoded, short flags -e and -p are mapped to long forms, and the anonymous positional path string is cleanly resolved to its signature parameter name:

```nu
'dr -e {OPENAI_API_KEY: (asn --all | get api_key)} -p {8000:8000} skill:latest' | argx parse
```

## 📦 Actual Output Schema
argx.nu instantly extracts the developer's exact intent into this clear data structure:

```yml
args:
  - localhost/test-skill:latest
opt:
  envs:  # 👈 Automatically normalized from short flag -e to signature long-form 'envs'
    OPENAI_API_KEY: (asn --all | get api_key)  # Safely captured as a block/AST structure without invocation
  ports: # 👈 Automatically normalized from short flag -p to signature long-form 'ports'
    '8000': 8000
  sshuser: root
tag: container-create  # 👈 Bypasses the typed alias 'dr' to reveal the true underlying command intent
pos:  # 👈 Maps raw positionals into stable, semantic signature parameter names
  image: skill:latest
  cmd: []
```

# TODO
- [x] parse `parameter_default` (get-sign)
- [x] select the corresponding item in the `pipelines` based on the `offset` (get-ast)
- [x] parse filepath type
---
[Others](https://github.com/fj0r/nushell/blob/main/README.md)
