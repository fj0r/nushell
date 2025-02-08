$env.AI_TOOLS = $env.AI_TOOLS | merge deep {
    search_product: {
        config: {
            embedding: {
                url: 'http://172.178.5.123:11434/v1/embeddings'
            }
            surreal: {
                url: 'http://surreal.s/sql'
                ns: 'foo'
                db: 'foo'
                token: 'Zm9vOmZvbw=='
            }
        }
        schema: {
            "description": "This function allows you to search for products in a product library based on provided criteria such as keywords, price, sales ranking, and more.",
            "parameters": {
              "type": "object",
              "properties": {
                "raw": {
                  "type": "string",
                  "description": "The original query string containing all search terms and conditions."
                },
                "keyword": {
                  "type": "string",
                  "description": "The main keyword or phrase to match against product categories and tags."
                },
                "price": {
                  "type": "number",
                  "description": "The specific price value to filter products by."
                },
                "sort_by_price": {
                  "type": "string",
                  "description": "Sort the results by price in ascending or descending order.",
                  "enum": ["asc", "desc"]
                },
                "sort_by_sales": {
                  "type": "string",
                  "description": "Sort the results by sales volume in ascending or descending order.",
                  "enum": ["asc", "desc"]
                },
                "limit": {
                  "type": "number",
                  "description": "The maximum number of results to return. Default is 10, maximum is 20.",
                  "default": 10,
                  "minimum": 1,
                  "maximum": 20
                }
              },
              "required": [
                "raw"
              ]
            }
        }
        handler: {|x, config|

            mut fields = [
                'goods_name', 'goods_id as id', 'goods_sn', 'cover', 'comp_price as price', 'sales_amount as sales'
            ]
            mut orders = []
            mut conditions = ['goods_status = 1', 'is_main_show = 1']

            if 'keyword' in $x {
                $conditions ++= ['embedding <|50|> $e']
            }

            if 'price' in $x {
                $fields ++= ['(sales ?? 10).log10().floor() as _sales']
                $orders ++= ['_sales']

                $fields ++= [$"math::abs\(comp_price ?? 0 - ($x.price)\).log10\(\).floor\(\) as _price_diff"]
                $orders ++= ['_price_diff']
            }

            if 'sort_by_price' in $x {
                $orders ++= [$"price ($x.sort_by_price)"]
            }


            if 'sort_by_sales' in $x {
                $orders ++= [$"sales ($x.sort_by_sales)"]
            }

            let limit = if 'limit' in $x {
                $"limit ($x.limit)"
            } else {
                "limit 10"
            }

            let order_by = if ($orders | is-empty) {
                ''
            } else {
                $"order by ($orders | str join ', ')"
            }

            let q = $"
                let $kw = \"($x.keyword? | default '')\";
                let $url = '($config.embedding.url)';
                let $e = if string::len\($kw\) > 0 then
                    http::post\($url, {
                        \"model\":\"bge-m3:latest\",
                        \"input\":[$kw],
                        \"encoding_format\":\"float\"
                    }).data[0].embedding
                end;
                let $r = select ($fields | str join ', ')
                from goods WHERE ($conditions | str join ' and ')
                ($order_by) ($limit);
                select * omit _sales, _price_diff from $r;
            "
            let sdb_url = $config.surreal.url
            let r = http post -H [
                'surreal-ns' $config.surreal.ns
                'surreal-db' $config.surreal.db
                'Authorization' $'Basic ($config.surreal.token)'
                'Accept' 'application/json'
            ] $sdb_url $q

            let r = $r | last | get result | to yaml
            print $"(ansi darkblue)($r)(ansi reset)"
            return $r
        }
    }
    query_orders: {
        schema: {
            "description": "This function queries orders from the database. The user ID is obtained from the context and does not need to be provided as a parameter.",
            "parameters": {
              "type": "object",
              "properties": {
                "order_status": {
                  "type": "string",
                  "description": "The status of the orders to filter by (e.g., 'pending', 'shipped', 'delivered')"
                },
                "start_date": {
                  "type": "string",
                  "description": "The start date to filter orders (format: YYYY-MM-DD)"
                },
                "end_date": {
                  "type": "string",
                  "description": "The end date to filter orders (format: YYYY-MM-DD)"
                },
                "limit": {
                  "type": "number",
                  "description": "The maximum number of orders to return"
                }
              },
              "required": []
            }
        }
        handler: {|x, config|
            return 'not found'
        }
    }
}

let prompt = "
  #### Goals
  - To assist users in navigating a shopping mall's website or application effectively.
  - To provide information about products, promotions, and customer service options.
  - To guide users through the purchasing process and help them make informed decisions.

  #### Constraints
  - Keep responses concise and clear.
  - Ensure all information provided is accurate and up-to-date.
  - Follow a friendly and helpful tone at all times.
  - Limit the response length to 200 words for quick readability.

  #### Attention
  - Pay close attention to user queries and provide relevant information.
  - Offer additional resources or links if necessary.
  - Always ask if the user needs further assistance after providing an answer.

  #### OutputFormat
  Markdown

  ---

  ### Role
  **Role**: Shopping Mall Assistant
  **Background**: You are an AI assistant designed to help customers find products, understand promotions, and navigate the shopping experience on a virtual mall platform.
  **Skills**: Knowledgeable about product details, promotional offers, and customer service procedures. Capable of guiding users through the purchase process and answering common questions.
  **Suggestions**: Always greet the user warmly and ensure your responses are clear and concise. Encourage users to explore different sections of the mall and offer assistance in finding specific items or deals.

  ### Workflow
  **Workflow**:
  1. Greet the user and ask how you can assist them.
  2. Provide relevant information based on their query.
  3. Offer additional resources or links if needed.
  4. Ask if they require any more help.
  5. Farewell the user politely.

  **Initialization**:
  - Familiarize yourself with the latest product catalog and promotional offers.
  - Ensure you have access to all necessary links and resources for quick reference.
"

{
  name: shop
  system: $prompt
  template: '{{}}'
  placeholder: '{}'
  description: ''
} | ai-config-upsert-prompt

ai-config-alloc-tools shop -t [query_orders, search_product, search_web, get_weather]
