use data.nu
use common.nu *
use completion.nu *

export def 'ai show session' [] {
    data session
}

export def 'ai show history' [] {
    open $env.OPENAI_DB
    | query db $"select session_id, role, content, created from messages where session_id = (Q $env.OPENAI_SESSION) and tag = ''"
}

export def 'ai show tools history' [num=10] {
    open $env.OPENAI_DB
    | query db $"select session_id, role, content, created from messages where tag = 'tool' order by created desc limit (Q $num)"
}

export def 'ai config add provider' [o] {
    let o = $o | select name baseurl api_key model_default org_id project_id temp_max
    data query $"insert into provider \(($o | columns | str join ',')\)
        VALUES \(($o | values | each {Q $in} | str join ',')\)
        ON CONFLICT\(name\) DO NOTHING;"
}

export def 'ai config switch provider' [
    o: string@"nu-complete provider"
    --global(-g)
] {
    if $global {
        let tx = $"BEGIN;
            update provider set active = 0;
            update provider set active = 1 where name = '($o)';
            COMMIT;"
        data query $"update provider set active = 0;"
        data query $"update provider set active = 1 where name = '($o)';"
    } else {
        data query $"update sessions set provider = '($o)'
            where created = '($env.OPENAI_SESSION)'"
    }
}

export def 'ai config switch model' [
    model: string@"nu-complete models"
    --global(-g)
] {
    if $global {
        data query $"update provider set model_default = '($model)'
            where name = \(select provider from sessions where created = '($env.OPENAI_SESSION)'\)"
    } else {
        data query $"update sessions set model = '($model)'
            where created = '($env.OPENAI_SESSION)'"
    }
}


export def "ai config edit" [
    table: string@"nu-complete config"
    pk: string@"nu-complete config"
] {
    data edit $table $pk
}
