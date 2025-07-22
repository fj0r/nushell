export def feed-parse-file [] {
    $in
    | get content
    | where tag == 'body'
    | get 0.content
    | each {|x|
        let g = $x.attributes.text
        $x.content.attributes
        | each {|c|
            { group: $g, title: $c.title, xmlUrl: $c.xmlUrl, htmlUrl: $c.htmlUrl }
        }
    }
    | flatten
}

def tomd [] {
    $in | ^($env.HTML_TO_MARKDOWN? | default 'html2markdown')
}

export def feed-parse-body [] {
    let x = $in
    if ($x.attributes | get -o version) == '2.0' {
        let e = $x
        | get content.0.content
        | where tag == 'item'
        | get content
        | feed-parse-content
        $e
    } else {
        let x = $x.content
        let u = $x | where tag == 'updated' | get -o 0.content.0.content
        let t = $x | where tag == 'title' | get -o 0.content.0.content
        let e = $x
        | where tag == 'entry'
        | get content
        | feed-parse-content
        $e
    }
}

export def feed-parse-content [] {
    $in
    | each {|x|
        $x
        | reduce -f {} {|y, a|
            let d = match $y.tag {
                link => [
                    link
                    ($y.attributes | get -o href | default {$y| get -o content.0.content})
                ]
                encoded | content => [
                    content
                    ($y | get -o content.0.content | tomd)
                ]
                description => [
                    description
                    ($y | get -o content.0.content | tomd)
                ]
                thumbnail => [
                    thumbnail
                    $y.attributes.url
                ]
                author => [
                    author
                    ($y | get -o content.0.content)
                ]
                updated | pubDate => [
                    updated
                    ($y | get -o content.0.content | into datetime)
                ]
                id | guid => [
                    id
                    ($y | get -o content.0.content)
                ]
                _ => [
                    $y.tag
                    ($y | get -o content.0.content)
                ]
            }
            $a | upsert $d.0 $d.1
        }
        | update id {|x| $x.id | default { random uuid }}
    }
}

export def feed-fetch [url] {
    http get -r $url | from xml | feed-parse-body
}
