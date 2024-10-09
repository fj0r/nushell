use data.nu *

export def 'todo scratch' [
    id?:int
    --nth(-n):int=0
    --type(-t):string='txt'
    --output(-o)
] {
    if ($id | is-empty) {
        todo add -t [:scratch] -e

    } else {

    }
}
