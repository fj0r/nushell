use data.nu *

export def 'todo scratch' [
    id?:int
    --nth(-n):int=0
    --type(-t):string='txt'
    --output(-o)
] {
    if $output {

    } else {
        if ($id | is-empty) {
            let input = $"" | block-edit $"scratch-XXX.todo"

        } else {

        }
    }
}
