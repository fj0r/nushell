$env.comma_scope = {|_|{
    created: '{{time}}'
}}

'dbfile'
| comma val null 'status.db'

'selector foo'
| comma val null {
    nav: { q: '.pagination-block > a', a: 'href' }
    ttl: { q: 'header > h1'}
    elm: { q: 'div.image-container > p > a', a: 'href'}
}


$env.comma = {|_|{
    .: {
        inspect: {|a,s| { index: $_, scope: $s, args: $a } | table -e }
    }
}}

'db init'
| comma fun {|a,s|
   '
    create table titles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title text not null unique
    );
    create table pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title_id integer references titles(id),
        url text not null,
        status integer,
        unique(title_id, url)
    );
    create table elements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page_id integer references pages(id),
        url text not null,
        status integer,
        unique(page_id, url)
    );
   '
   | sqlite3 $s.dbfile
} {
    d: {|a,s| $'init `($env.PWD)/($s.dbfile)`' }
}

def list-titles [s] {
    'select id, title from titles;'
    | sqlite3 -json $s.dbfile
    | from json
    | rename value description
}

'db reset'
| comma fun {|a,s|
    let tid = $a.0
    $"
    update pages set status = null where title_id = ($tid);
    update elements set status = null where page_id in \(select id from pages where title_id = ($tid)\);
    "
    | sqlite3 $s.dbfile
} {
    cmp: {|a,s|
        match ($a | length) {
            1 => { list-titles $s }
        }
    }
}

'db list'
| comma fun {|a,s|
    let obj = $a.0
    let tid = $a.1
    match $obj {
        pages => $"select * from pages where title_id = ($tid);"
        elements => $"select * from elements as e join pages as p on e.page_id = p.id where p.title_id = ($tid);"
    }
    | sqlite3 -json $s.dbfile
    | from json
} {
    cmp: {|a,s|
        match ($a | length) {
            1 => [pages elements]
            2 => { list-titles $s }
        }
    }
}

def handler-page [s, url, -n: record, -t: record, -e: record] {
    let url = $url | str trim
    lg level 4 {url: $url} start

    #let html = open x.html
    let html = http get $url
    let links = $html
    | query web -q $n.q -a ($n.a? | default '')
    | str trim
    let title = $html
    | query web -q $t.q -a ($t.a? | default '')
    | first
    | first
    | str trim

    lg level 4 {title: $title} get

    mkdir $title

    $"insert into titles \(title\) values \('($title)'\) on conflict \(title\) do nothing;"
    | sqlite3 $s.dbfile

    let tid = $"select id from titles where title = '($title)'"
    | sqlite3 $s.dbfile

    $"insert into pages \(title_id, url\) values \(($tid), '($url)'\) on conflict \(title_id, url\) do nothing;"
    | sqlite3 $s.dbfile

    let pid = $"select id from pages where title_id = ($tid) and url = '($url)'"
    | sqlite3 $s.dbfile
    lg level 4 {tid: $tid, pid: $pid} query

    for i in $links {
        $"insert into pages \(title_id, url\) values \(($tid), '($i)'\) on conflict \(title_id, url\) do nothing;"
        | sqlite3 $s.dbfile
    }

    lg level 4 get elements
    let el = $html
    | query web -q $e.q -a ($e.a? | default '')
    | str trim
    for i in $el {
        $"insert into elements \(page_id, url\) values \(($pid), '($i)'\) on conflict  do nothing;"
        | sqlite3 $s.dbfile
    }

    let j = $"select url from elements where page_id = ($pid) and status is null;"
    | sqlite3 $s.dbfile
    | lines
    for i in $j {
        let n = $i | path parse | $"($in.stem).($in.extension)"
        let t = [$title $n] | path join
        lg level 3 {title: $title, page: $pid, file: $n }
        let r = wget -c $i -O $t --content-on-error | complete
        if $r.exit_code == 0 {
            $"update elements set status = 1 where page_id = ($pid) and url = '($i)';"
            | sqlite3 $s.dbfile
        } else {
            lg level 5 {title: $title, page: $pid, file: $n } err
        }
    }
    $"update pages set status = 1 where title_id = ($tid) and url = '($url)'"
    | sqlite3 $s.dbfile

    let ns = $"select url from pages where title_id = ($tid) and status is null;"
    | sqlite3 $s.dbfile
    | lines

    for x in $ns {
        handler-page $s $x -n $n -t $t -e $e
    }
}

'crawl'
| comma fun {|a,s,_|
    let prs = $s.selector | get $a.0
    let url = $a.1
    handler-page $s $url -n $prs.nav -t $prs.ttl -e $prs.elm
} {
    d: '<site> <url>'
    cmp: {|a,s|
        match ($a | length) {
            1 => { $s.selector | columns }
        }
    }
}
