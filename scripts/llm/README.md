OpenAI and Ollama Clients

- Streaming output
- The OpenAI interface employs the `ai` prefix for user-friendly input.
- Option for controllable return values
- Supports chat context retention
- Customizable prompt functionality for `ai do`
  - Refer to [prompt.nu](prompt.nu) for definition guidelines
  - Default model can be overridden using `--model`
  - line containing placeholders in the prompt can only include `{}` and quotation marks
  - [x] template placeholders default ""
- [ ] output language
- Importing and exporting of Ollama models
- Connection details managed through environment variables
- [x] ai do support input long text using editor
- [x] system context setting
- [x] temperature range
- [x] API management
    - [x] sqlite
    - [x] switching
    - [x] del provider/prompt

Control some options with the following code.
