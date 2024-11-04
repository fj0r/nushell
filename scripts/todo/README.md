migrate to [scratch.nu](https://github.com/fj0r/scratch.nu)

Quick Start:
- `todo-cat-add` to add a category
    - Supports multiple tags under the same category: `category:tag1/tag2/tag3`
- `todo-add -t [A:1/2] 'hello'` to add a todo
- `todo-list A:1` to view
    - Default to hide the `:trash` tag.
    - Category without a tag acts as a wildcard `*`, for instance: `project:` is equivalent to `project:*`
    - Utilize `&` and `!` as prefixes to denote `and`, `not`, respectively, for example: `plan:a &plan:b !plan:c`
    - `--markdown` output in markdown format
    - View trash: `todo-list :trash --all` (`todo trash` in `shortcut.nu`)

best practice:
    - write a todo before coding, generate and update TODO.md after finish, and relevant todos as commit messages. `todo-commit proj:todo -f scripts/todo/TODO.md -t 87`
