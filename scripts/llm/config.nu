use data.nu
use completion.nu *

export def 'ai config add provider' [o] {
    let o = $o | select name baseurl api_key model_default org_id project_id temp_max
    data query $"insert into provider \(($o | columns | str join ',')\)
        VALUES \(($o | values | each {$"'($in)'"} | str join ',')\)
        ON CONFLICT\(name\) DO NOTHING;"
}

export def 'ai config switch provider' [o] {
    let o = $o | select name baseurl api_key model_default org_id project_id temp_max
    data query $"insert into provider \(($o | columns | str join ',')\)
        VALUES \(($o | values | each {$"'($in)'"} | str join ',')\)
        ON CONFLICT\(name\) DO NOTHING;"
}

export def 'ai config set model' [
    model: string@"nu-complete models"
    --global(-g)
] {
    if $global {
        data query $"update provider set model_default = '($model)'
            where name = \(select provider from sessions where created = '($env.OPENAI_SESSION)'\)"
    } else {
        data query $"update session set model = '($model)'
            where created = '($env.OPENAI_SESSION)'"
    }
}


export def "ai config edit" [
    table: string@"nu-complete config"
    pk: string@"nu-complete config"
] {
    data edit $table $pk
}
