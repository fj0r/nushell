export def from-all [type] {
    let o = $in
    match $type {
        json => { $o | from json }
        jsonl => { $o | from json -o }
        yaml => { $o | from yaml }
        toml => { $o | from toml }
        nuon => { $o | from nuon }
        csv => { $o | from csv }
        tsv => { $o | from tsv }
        xml => { $o | from xml }
        lines => { $o | lines }
        _ => $o
    }
}

export def to-all [type] {
    let o = $in
    match $type {
        json => { $o | to json }
        jsonl => { $o | each { $in | to json -r } | str join (char newline) }
        yaml => { $o | to yaml }
        toml => { $o | to toml }
        nuon => { $o | to nuon }
        csv => { $o | to csv }
        tsv => { $o | to tsv }
        xml => { $o | to xml }
        lines => { $o | str join (char newline) }
        _ => $o
    }
}
