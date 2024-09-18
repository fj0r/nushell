export-env {
    let expert = {
        rust: 'You are a Rust language expert.'
        js: 'You are a Javascript language expert.'
        python: 'You are a Python language expert.'
        nushell: 'You are a Nushell language expert.'
    }
    $env.OPENAI_API = {
        ollama: {
            baseurl: "http://localhost:11434/v1"
            temperature:  0.5
            api_key: ''
            org_id: ''
            project_id: ''
        }
            chat: [
                {
                    model: 'xx'
                    role: 'user'
                    message: ''
                    time: '2024-09-16T14:02:04.423250121'
                    token: 11
                }
            ]
    }
    $env.OPENAI_PROMPT = {
        'json-to-jsonschema': {
            prompt: [
                "Analyze the following JSON data to convert it into a jsonschema:"
                "```{}```"
            ]
            model: '',
            description: 'Analyze JSON content, converting it into a jsonschema'
        }
        'json-to-sql': {
            prompt: [
                "Analyze the following JSON data to convert it into a SQL statement for creating a table, using {} dialect, do not explain.:"
                "```"
                "{}"
                "```"
            ],
            placeholder: [
                {
                    postgres: PostgreSQL
                    mysql: Mysql
                    sqlite: Sqlite
                }
            ]
            model: 'qwen2:1.5b',
            description: 'Analyze JSON content, converting it into a SQL create table statement'
        }
        'git-diff-summary': {
            prompt: [
                "Extract commit logs from git differences, summarizing only the content changes in files while ignoring hash changes, and generate a title."
                "```"
                "{}"
                "```"
            ]
            description: 'Summarize from git differences'
        }
        'api-doc': {
            prompt: [
                "{} Inquire about the usage of the API and provide an example."
                "```"
                "{}"
                "```"
            ]
            placeholder: [ $expert ]
        }
        'debug': {
            prompt: [
                "{} Analyze the causes of the error and provide suggestions for correction."
                "```"
                "{}"
                "```"
            ]
            placeholder: [ $expert ]
            description: 'Programming language experts help you debug.'
        }
        'trans-to-en': {
            prompt: [
                "Translate the following text into English:"
                "```"
                "{}"
                "```"
            ],
            model: 'qwen2:1.5b',
            description: 'Translation to English'
        }
    }
}
