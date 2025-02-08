$env.AI_TOOLS = $env.AI_TOOLS | merge deep {
    query_knowledge_base: {
        config: {
            ragit_dir: ~/world/ragit
            ragit_log: {|query, dir|
                let m = [
                    $"(ansi grey)ragit query"
                    $"(ansi yellow)($query)"
                    $"(ansi grey) in `($dir)`"
                    (ansi reset)
                ]
                | str join ' '
                print -e $m
            }
        }
        schema:  {
            name: query_knowledge_base
            description: "This function allows you to query information from a knowledge base. It can be used to retrieve specific data or answers based on provided keywords or questions."
            parameters: {
                type: object
                properties: {
                    query: {
                        type: string
                        description: "The search terms or question to query the knowledge base"
                    }
                    num_results: {
                        type: number
                        description: "The number of results to return (optional)"
                    }
                    language: {
                        type: string
                        description: "The language of the query and results (optional)"
                    }
                    category: {
                        type: string
                        description: "The category of information to search within"
                        enum: {|config|
                            cd $config.ragit_dir
                            let r = ls | where type == dir | get name
                            $r
                        }
                    }
                }
                required: [
                    query
                    category
                ]
            }
        }
        handler: {|x, config|
            let dir = [$config.ragit_dir $x.category] | path join
            do $config.ragit_log $x.query $dir
            cd $dir
            ragit query $x.query
        }
    }
}

ai-config-alloc-tools programming-expert -t [query_knowledge_base]
