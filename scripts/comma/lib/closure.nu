export def parameters [clz] {
    view source $clz
    | parse -r '\{\s*(\|(?<a>.+?)\|)?.*'
    | get a.0?
    | split row -r '[\s,]+'
}
