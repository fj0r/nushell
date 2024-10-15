- Default to hide the `:trash` label.
- Supports multiple tags under the same category: `category:tag1/tag2/tag3`
    - Category without tag is equivalent to all tags: `project:`


- todo list
    - --markdown output in markdown format
    - view trash: `todo list :trash --all`

best practice:
    - write a todo before coding, generate and update TODO.md after finish, and relevant todos as commit messages. `todo commit proj:todo -f scripts/todo/TODO.md -t 87`
