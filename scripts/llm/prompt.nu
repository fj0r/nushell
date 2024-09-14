export-env {
    $env.OPENAI_PROMPT = {
        'json2SQL': {
            prompt: [
                "分析以下json内容，转换为创建表的SQL语句:"
                "```"
                "{}"
                "```"
            ]
            model: 'qwen2:1.5b'
            description: '分析json内容，转换为创建表的SQL语句'
        }
        'zh2en': {
            prompt: [
                "将以下内容翻译成英文:"
                "{}"
            ]
            model: 'qwen2:1.5b'
            description: '翻译成英文'
        }

    }
}
