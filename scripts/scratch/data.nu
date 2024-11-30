use libs *
use common.nu *
use libs/files.nu *

export def seed [] {
    let _ = "
    - name: txt
      entry: scratch.txt
      comment: '# '
      runner: ''
    - name: md
      entry: scratch.md
      comment: '# '
      runner: ''
    - name: markdown
      entry: scratch.md
      comment: '# '
      runner: ''
    - name: nuon
      entry: 'scratch.nuon'
      comment: '# '
      cmd: ''
      runner: 'data'
    - name: yaml
      entry: 'scratch.yaml'
      comment: '# '
      cmd: ''
      runner: 'data'
    - name: json
      entry: 'scratch.json'
      comment: '# '
      cmd: ''
      runner: 'data'
    - name: jsonl
      entry: 'scratch.jsonl'
      cmd: 'open {} | from json -o'
      comment: '# '
      runner: 'data'
    - name: toml
      entry: 'scratch.toml'
      comment: '# '
      cmd: ''
      runner: 'data'
    - name: csv
      entry: 'scratch.csv'
      comment: '# '
      cmd: ''
      runner: 'data'
    - name: tsv
      entry: 'scratch.tsv'
      comment: '# '
      cmd: ''
      runner: 'data'
    - name: xml
      entry: 'scratch.xml'
      comment: '# '
      cmd: ''
      runner: 'data'
    - name: lines
      entry: 'scratch'
      comment: '# '
      cmd: 'open {} | lines'
      runner: 'data'
    - name: nushell
      entry: scratch.nu
      comment: '# '
      runner: file
      cmd: ''
    - name: bash
      entry: scratch.bash
      comment: '# '
      runner: file
      cmd: 'open {stdin} | bash {} {args}'
    - name: python
      entry: scratch.py
      comment: '# '
      runner: file
      cmd: 'open {stdin} | python3 {} {args}'
      pos: 9
    - name: javascript
      entry: index.js
      comment: '// '
      runner: file
      cmd: node {} {args}
    - name: typescript
      entry: index.ts
      comment: '// '
      runner: file
    - name: rust
      entry: src/main.rs
      comment: '// '
      runner: dir
      cmd: 'cargo run {args}'
      pos: 2
    - name: haskell
      entry: app/Main.hs
      comment: '-- '
      runner: dir
      pos: 6
      cmd: 'stack run'
    - name: lua
      entry: init.lua
      comment: '-- '
      runner: file
      cmd: lua {}
    - name: postgresql
      entry: scratch.sql
      comment: '-- '
      runner: file
      cmd: |-
        $env.PGPASSWORD = '{password}'
        psql -U {username} -d {database} -h {host} -p {port} -f {} --csv | from csv
    - name: sqlite
      entry: scratch.sql
      comment: '-- '
      runner: file
      cmd: open {file} | query db (open {})
    - name: surreal
      entry: scratch.surql
      comment: '-- '
      runner: file
      cmd: |-
        let auth = [
            -u '{username}:{password}'
            -H 'surreal-ns: {ns}'
            -H 'surreal-db: {db}'
            -H 'Accept: application/json'
        ]
        let url = '{protocol}://{host}:{port}/sql'
        open -r {}
        | curl -sSL -X POST ...$auth $url --data-binary @-
        | from json
    - name: mysql
      entry: scratch.sql
      comment: '-- '
      runner: file
      cmd: |-
        # pip install pymysql
        let o = open {}
        '_: |-
          import sys
          import yaml
          import pymysql.cursors

          data = sys.stdin.readlines()
          data = \"\\n\".join(data)

          exts = {\"ssl\": {\"any_non_empty_dict\": True}} if {ssl} else { }

          connection = pymysql.connect(
            host=\"{host}\",
            port={port},
            user=\"{username}\",
            password=\"{password}\",
            charset=\"utf8mb4\",
            cursorclass=pymysql.cursors.DictCursor,
            **exts
          )

          with connection:
              with connection.cursor() as cursor:
                  cursor.execute(data, { })
                  r = cursor.fetchall()
                  print(yaml.dump(r))
        '
        | from yaml | get _
        | save -f query.py

        [{args}]
        | enumerate
        | reduce -f $o {|i,a|
          let x = if ($i.item | describe -d).type == 'string' {$\"\\"($i.item)\\"\"} else { $i.item }
          $a | str replace -a $\"%($i.index + 1)\" $\"($x)\"
        }
        | python3 query.py
        | from yaml
    " | from yaml | each { $in | upsert-kind }
    "
    - kind: sqlite
      name: scratch
      data: |-
        file: ~/.local/share/nushell/scratch.db
    - kind: postgresql
      name: localhost
      data: |-
        host: localhost
        port: 5432
        database: foo
        username: foo
        password: foo
    - kind: surreal
      name: localhost
      data: |-
        protocol: http
        host: localhost
        port: 8000
        db: foo
        ns: foo
        username: foo
        password: foo
    " | from yaml | each { $in | upsert-kind-preset }
    "
    - kind: python
      hash: 8zaPPnuWAjW4KLF9b9kTp+5HvCpQEZ5jfCSXDixlKWs=
      parent: ''
      stem: scratch
      extension: py
      body: B2oAAMD/5dh+y/SwQR0SWoVrir2tQeRz6FcuvDu7/60kGpapKaecWYDUFlgCOXewA94OHsNrj1MJ4//nw5qyIomRZMe7Cwu4S4oPmR8bi4oxI08IzsdK+a0tFi/aiea+xvGM0Q/aGgA4uJPMuuWIz9cYP4EousBEsBYlUXA+EpWd5fAaYZGkmVk5PqviersU9RBhX6vs0rg8P7tT28exZh+1yrUBAw==
    - kind: rust
      hash: +AY8hpE2ROFEO6c6THhiJzLAG6/ZwP3lriL3FDPOaf4=
      parent: ''
      stem: Cargo
      extension: toml
      body: BycAAMDaZv+SnqeL2g1xIYnheY9NxpyoLKS+kqiloMZ/5KF264lCXR9wYlk2ddsl9GGu9nZOLN4F54VQ265FH4MQ5YqBXtGtYRUDAw==
    - kind: rust
      hash: BZbFgAMTiFwaSIbitF9jibxXPJSH2JLwIRnX8fDd9Xk=
      parent: src
      stem: main
      extension: rs
      body: hxaA2SxmbiBtYWluKCkgewogICAgcHJpbnRsbiEoIkhlbGxvLCB3b3JsZCEiKTsKfQM=
    - kind: haskell
      hash: yME4ZjEYAzaLD1h7G8pZ2Aqy5EKJlSzruWAhxUGRBSs=
      parent: ''
      stem: CHANGELOG
      extension: md
      body: B50AAMD/qTRcs0wPunhgk7qJm3iDIAc3qFAO4X6T3yQ2zQ9JVBymVaecCCTaAoHmyQF/lIMFHrImJJhv/t88DHgOlD0n8Vil4tpspW7DVamnlJCl05IYtnjV0AU9xIZS5Yttx29MCQvDif3eOXd2iFkda0yslXoLjFXqTh2xYaHGDpJxeWUuIIL4eRt6L+3RmI25kM1+tZXdcDb3etKTOdwpyg4cIhe48lWwurxQ2zglnMlu5BkfXFuUHLPHWVK0f3csP0WHyVBL9eaglRoGvOfKiamxszBpAI8R8zzP4+k0Ho8D
    - kind: haskell
      hash: f9Ma42XSuz8Jfbm67EeFx4shDIF3gkJ6SambnF458bY=
      parent: ''
      stem: LICENSE
      extension: ''
      body: h+YCAMB/VUynLFqmh0wJIDjttVMz0eK39QGZVEnKjkedREcELNEg6TNuGOYOW/3PGzi83WSLNuzCgL59mWC38zgI4pY1C7suWATFSUFEAWB3QW4mfgqD/QpWk9Of///Lf018fKbweyl4++Ptb4hnWWLCNq4ei0++qoyfQy4pvD9LiBvGbcYze4QNOT7T5DFuM97DNqZP3GJac41XKAtiwiuUJT5LtcY53MI0lhC3GmPyePi0hlL8jEeKH2H2M8oyFpTF4xbv9/gK229McZtDCXHLGJPH6ss/VfXnDjB+DrnoKjPiTdCqKc4e6zMXJF/GsKEsHuN7/PCY3N63xRImX6MsIVcAcA+5IN7Q1LPNUHTSHPJ0H8Pq066q3pRUwwYWMtp+pDg/J//hr7UsIUcGk2yO03P1W6GMiheN2/wjJsSy+IR1LD6F8Z6JY0x47toI7Krqrx2gfHial8Uvg4m3To72riXeZ5+wxUQMgoaSMcWtqI0J8Abr+Il3j2f2M0qE3+aYskdMeKS4xuKBKVYyZp/Ch59xS3GFwnK8ldeYfDX92qnJyA8/hVuY8EghJrxSKMVvWCybs5kvdy1bWH1wF2EIbNEbfWZJEvsrXEtodH81fGwdWt1JMhZCSTRaOcP7wWlj8VVYsP0KoWQl1BX0qzdkLbQBn/qOSeIijBHKMdkarJpukKyONfaDg9IOHZ/YkYTTNVxL4FPfMcnqIowRyjFZ6ANOZJpWKCf23LG7innBB3aKrMVBGwj0wjhuhk4Y9IPptSUIQ5Vk23SCTyR3YAWlQWdSDrYVXefUA21OeE/oWOw7wkGb2CHZUONqsLota1iScqKrYXtqWHQ16Bed+k6Ya133USz9O5ByLDpIcRJHstU3LMl7o5vB0ImUgz7ADnvr2A2OcNRaWmgDS+bMDdmfVactMT5YqiGFE81He6MP7OxPaIP9YBncLFaOjBl6x1p9R6svdCaDRgyWJGGjlV3uWtLmCn3gEOeO3bXGpSXXkgErWkdE42pYZ7hxqc3awGnjfKaGomPHR1INQRto15K5sKXvEIYtqyNYQagrLuIKPdimriUMlq4F22prVT3NIfABQp7ZksyihF5byzoEtp6mhRQncaSdAQM=
    - kind: haskell
      hash: WhJGn6aEknr6WlH/kbqeaElC0QYRmQQsI5v4bD+szCE=
      parent: ''
      stem: README
      extension: md
      body: hwSAqSMgc2NyYXRjaAM=
    - kind: haskell
      hash: +7tdy5zrHlQ5rmkt6Tw26+N9ZrWyqsRdt5BzB81V5mM=
      parent: ''
      stem: Setup
      extension: hs
      body: BxeA2S1pbXBvcnQgRGlzdHJpYnV0aW9uLlNpbXBsZQptYWluID0gZGVmYXVsdE1haW4D
    - kind: haskell
      hash: vLCM/gscTDcMPYhNexx5iO0x2gFu0b9nMRFyU0DAXJo=
      parent: ''
      stem: package
      extension: yaml
      body: B7ICAMBSKy1ywiQqrABH5kj+YGBhG5ZtQQpOvsPpAMc9ZO+woSGbYDet3SBK73IXWlkp8iCsrq2iOInT3HlCkarTVr2q/ELbKdU5zRQWSmNz7WE1XR9neBwEqPf/q7VR5SO6C0uDPJXwh4eJNoyDm+XtcrPchE28zHVf4rBTTuNxzaR1CLskbmbKx+9PP+P7+GOnaRxoetHBJ27bN2hUGYUHH0IlaU7SGN8+8Jlq3/nb+s6StB5C0n4ZshX3csbh3c27D+A+VuCzD4qmcySOJ9nZjiHi37vbn493S80h4sfD7a/7u7/+vl9qDuEKj+yUyQnTOOOlcEOf6y5WpG246BzolJ5p43AFuzTtJnYEgNnLp6LDkdnSkO6iDXpSDkzkvOm42P7NawhX+E9Bf1Qy8uy7JHLO4NNJhxukIWualZsTPYVaRmbapW14ES/wYkNq1bcs2gx6AteVc5a24YFy1vSMSuN5dkgzyYxEK+2IUv0NxCHG9F7VBld0leaYxsPgCi8cSK45XsJPd9Jz8p+dyRjGrGcKbbgXf5gryPG5uHc7Xl+XWbYkrZ+g4oyuBlOu/DWEzJ1b5pYkofSVjPH1Cz4sn/D6NT7jYwhbSVHd4bAi/qZ9X1eS1k4+EMncXFzYRKLF7RF2joOTjhxnz+QIbDaJndx5tMeHKmbStsjnrsPjLuZ9pWjlWDXPnRHvNFxojyfhPeN3GJxny9Q8Jm3mg6S5hbDLOmhcjgEoZEqWYUfYSCHwmdN0Wis7OeHXRT7zMQBAJTnnCwAeSdpSDARp40lR7wAYxy0AiIheBlPmLGsON+1uV/4iXuTqS/w1elIWgiNvp0JwNjf/U2dzi8Mv+1Pn9ANn83AbAw==
    - kind: haskell
      hash: /siSsufsnPFSVPpb9aMjrkDHH5Mt5VBpnozx/Ksod4Q=
      parent: ''
      stem: scratch
      extension: cabal
      body: BwUEAOBW/7pr2ctpQOjJeXlNK4VQxVpDK9QqVshR5u1O3g7dHzuzmhxOVy9voLrzDWh3k8Fgd4vCirpoCXbdBRImUd1F32QtCAs0kCAPsMsSTSwL0DI3loIgFEDUPm+7tsL/FxeeFkr4l7tKLTvYTlvnEOF3FIWjJIZICgtzgZULdzIOcOw1QyP/RitPZ8oJljPERv4Ngs0J83R9O82TQ3SIoMw7iGZNd5vNKhbHMvmaN1rTxrfCuUKZd/BIqO9kPjp0ZPbO09U0T7MLrL5LM/0l/UxMyqDMYJHh1/7+6/c91AKPYk9jATK4Q4E//aHcN6ca33WmkPmTizVzoxVZahH2xy1jxc6tdtPdMmxEdbA6GhZrT5vCvWwQFMoMkTu7TFKMpLBhjE+UW+LP78Dka3a+tnOXNVqsgu28vdklSTwXrX7Xl9eveI0PiYYaSDxKqgT8/O1h//K6d8uQFNDOrT4Wr5JbYscn64RaR/d+Ad05AOCDTzlIgIen+5fH/fOPxykH5zwsOreqYrWfITIFB3BCyyrmAFL1RLZ+KUc7l2Tp1M8OgE+tKgfMNQxQ2wI8y+IAqkXu6tBPsqh/wtUFQMPqysWURc1eBOlXk3bvANbosf6ut6k7wAOlBHjwNTcywIMELiYmrIAHKb7mltgYO/vaA44WyPQnGEWwkRn3ooCHLKpSVuRTq90wiZpKxZo51UUBD426CSU8CqeggIfOYZRAxdDXotZJiqkD4DoSuHEJyU9eSBk+fbyZbuHyEu4+OIDARxrJMFFZR9e4PpG+cUrb+Wp2jk/sh9GSuLP/fuQTO4BMUlB0B99JyhSVllem1oY7oMXOFDgAdtPaTAH/iUVJVh/xhbocwHuomA6RKGM11CHmGat16wF8EvM1MKoFqXg1zSR/4rWxHwTak74NAw==
    - kind: haskell
      hash: M1w5fHe8vKOuzbirAgdQxckagr6e6XEXPQXZyYvhGik=
      parent: ''
      stem: stack
      extension: yaml
      body: B0kEAMDPlM+1yE31FBfXxPa/f5e740sgRQkkHRIJUERRNN4de5db75iZ2f/vgyh6+prfX1zo4d1/L9y/K1DuNoFK8D8//NudIZgJopmgaiZUf8rfEb5mI9ymCN2majehwGmuwcRhOvtBOXz2/7/7r8fnlA1LLowLGai5bOQ5UClXrFxZyTlivuLGnMIzcs1+0/Vdj0+yMYJsm9RyRTOOkN2zVEOiM2NmrogS2sbVOYIMQbaNqxtyhTe/19j1+FkUFM9UA0c0Y1CNCLLtyomr5TOj2qPIs1TIAk+MRXQjf429MBnDmE9dj+S+22maogQbE9kzl4LgolF0nbhO5jQXnq60lW9B6pLXprULm7qux1vc2M4hLznc4JNTeKaVYZV2S+IQBc23PxdWnFktSx1zKc6ubFLOrIg5ODnbxEMTAanRE8PYIQv2dknrerhgZmLdF1HsKn9ycETeuUauIbONzGn8Qtte+LQWnOHVE4rbcDyOx6cvJda8Ji/X4Xg43g+Hx+HwJkRfUxi+Hx/Gh4Lq58QoEjifIBosgSpmxq5yzpHXy0lIsiialpE6AWTWNkyDBUZlumx5TY6QqK78GpfEygFR00LnO5oGRhQ2VPGxg5sep9DMZRtG3ByvtBVwKApGWGcMsk0RVZsYad0Oh9tserd0QNNSwk3pMq7ZU5ubsQapztULgrjbGjIVydUm0w5NdoZNG5mzTsVtOh6n+0NHtevxm7EKgL25c8vFx67H76RZmsk9NP5BHjoZLMml4k6FLAgJMxe5cIW6cjp1PQaYbDzErBxc9HqMAFk+QCpiEZlm0mmmv4fDeBiPo5OO699dD8DaHLMWjYDBNnqHtkdyPl27UO5a9w8Yux7vxTv1Cvb6vZXCEYvKhrabK9MGT+QgZVRxgEgmH/WZNAZX18y0WJUXVq6BIcuSQzax9N7mki1xvKpfYCDDhUsBWddjEX02TMh12FVWZbPoj9pzrRzhAsKaHYks3TudX1xpiLyz4jKAwsbDls1yYRsO492X+TVL0dPRrKN4muOandG/G2Tbsp/Aj/Pd3e1yez+HZZmf7h4eQ3zztMxLeJrvDxweH+6Pt4cDjfWL+PK163r8cmbVHBmRF2rFsRRacabS2EyGFrRINcKrdH3WETvhn3+7rsdPL66UcBMiOc1kbAhSnXLNdcVaZKYibRqNHTaGOE9ofyfVVQouiT2x4uJ+4I7mDx/f4cJYco0QLbju5KnrYVdz3oY1hRNcG6M/8Cv/1bIyCC6OO40hi5+rr9Es1/VbrFRtl2u+PywhGFINJwxUr+jxnrwxY8VXP/5wN96+eojyPE8M0pCyc/Cmrl6fr+P4PCro1dqMl1YgFX/kGuXinFkN6YR89/RwILw8PXx7uO/kLQJv9JLM1gF2m5lbLjHXVRlCrqG0aASn7YQv006eJpcpZv0qn1VKnoNK6nq8LUUuIFS+sGLLVZToXT58fAdPdG9xJfA/wF+hPITE4flUrGvYchU1AAM=
    - kind: haskell
      hash: Wafl8qPldGE24fYVPTibZDOd47ejrkdntmH+10Re4gg=
      parent: ''
      stem: stack.yaml
      extension: lock
      body: Bw8BAMCaSglfqqhTDFybt3z++OwTfYomaUIIYS2tLWFZMto1z6WoygSkken1/29fbvgZk2BNmfFJArq0bly4kXLA8sIPJb935oZf9YLEeuWAUhUckkJjEqwpM5YXIpXQmRu+14ajNkYqa20HaarlK87MJAxhhkZGqP46uChpqgWkztwARNVTnLWheukiyc45i5Lfu9o2y8WK0pLZ5ur3v2vKLMac5HfaWBx+/zFS6JRYVZx5h6/HmVk5OAMAEmkYHw7jcO/75xLmeZ6ey+P5/FhpGZlGWvjOPND48QxrmNkPYfWTH6f+PtHMxHznaV4MAEj6xw7T0A+PwQDA1bJDVD3FWdvos9uSxmu5hJuvRblo5+thfT0Obj5RjiQ752xFye+08bsUOiVWFXuQKDebVeww2G9996IjG6C2tKVC2RmgGgM=
    - kind: haskell
      hash: vI+oXfBjm1gZueR/MDv+a8l1mU+VIaSutvQKOr2F3HI=
      parent: app
      stem: Main
      extension: hs
      body: ByIAAMBcW19JF/9DffgkCIJiyFMHDtwmr48hZUsgluI5/2Bx9EuwsDqSsXrGd0oTIrU72otZNyJjdZSCaUXKqHjCZOy+GwM=
    - kind: haskell
      hash: EHgSGB3FyO8aLYcChePmXfOxCNuvV2KBxWuZ+e1tRwU=
      parent: src
      stem: Lib
      extension: hs
      body: BywAAACiufUv6VjaQh1YBWFgMNjVBwW3ydxjSFnYgAP3FFIOaJFbeCrM86+5HnYr6doEwPPWrKOVHQe+U5uKlCJGphkfnAOP9aW3VHADnAED
    - kind: haskell
      hash: 8zJ+Jy0Ayo5h8ufGhqAhK9uKQqUNXZw9SYX8CFZKTY4=
      parent: test
      stem: Spec
      extension: hs
      body: hx8AAMCaW19Jx5KGOtAuCAYNRfDCg/8OdwuGFK2FRIqH/+ynBUrBsmEY05xQu3a9ayAfbELrJiIe4aNgXm86Q7yyAQM=
    " | from yaml | each { scratch-files-import $in }
}

export def --env init [] {
    init-db SCRATCH_STATE ([$nu.data-dir 'scratch.db'] | path join) {|sqlx, Q|
        for s in [
            "CREATE TABLE IF NOT EXISTS person (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                info TEXT default ''
            );"
            "CREATE TABLE IF NOT EXISTS tag (
                id INTEGER PRIMARY KEY,
                parent_id INTEGER DEFAULT -1,
                name TEXT NOT NULL,
                alias TEXT NOT NULL DEFAULT '',
                hidden BOOLEAN DEFAULT 0,
                UNIQUE(parent_id, name)
            );"
            "CREATE TABLE IF NOT EXISTS scratch (
                id INTEGER PRIMARY KEY,
                parent_id INTEGER DEFAULT -1,
                kind TEXT DEFAULT '',
                title TEXT NOT NULL DEFAULT '',
                body TEXT DEFAULT '',
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%f','now')),
                updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%f','now')),
                deleted TEXT DEFAULT '',
                deadline TEXT,
                important INTEGER DEFAULT -1,
                urgent INTEGER DEFAULT -1,
                challenge INTEGER DEFAULT -1,
                value REAL DEFAULT 0,
                done BOOLEAN DEFAULT 0,
                relevant INTEGER -- REFERENCES person(id)
            );"
            "CREATE TABLE IF NOT EXISTS scratch_tag (
                scratch_id INTEGER NOT NULL,
                tag_id INTEGER NOT NULL,
                PRIMARY KEY (scratch_id, tag_id)
            );"
            "CREATE TABLE IF NOT EXISTS kind (
                name TEXT PRIMARY KEY,
                entry TEXT NOT NULL,
                comment TEXT NOT NULL DEFAULT '# ',
                runner TEXT NOT NULL DEFAULT '',
                cmd TEXT NOT NULL DEFAULT '',
                pos INTEGER NOT NULL DEFAULT 1,
                created TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                updated TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%S','now')),
                deleted TEXT DEFAULT ''
            );"
            "CREATE TABLE IF NOT EXISTS kind_preset (
                kind TEXT NOT NULL,
                name TEXT NOT NULL,
                data TEXT NOT NULL DEFAULT '',
                PRIMARY KEY (kind, name)
            );"
            "CREATE TABLE IF NOT EXISTS scratch_preset (
                scratch_id INTEGER NOT NULL,
                preset TEXT NOT NULL,
                PRIMARY KEY (scratch_id)
            );"
            "CREATE TABLE IF NOT EXISTS kind_file (
                kind TEXT NOT NULL,
                parent TEXT NOT NULL DEFAULT '.',
                stem TEXT NOT NULL,
                extension TEXT NOT NULL,
                hash TEXT NOT NULL,
                PRIMARY KEY (kind, parent, stem, extension)
            );"
            "CREATE TABLE IF NOT EXISTS file (
                hash TEXT PRIMARY KEY,
                body TEXT NOT NULL DEFAULT ''
            );"
        ] {
            do $sqlx $s
        }
        seed
    }
}


export def --env theme [] {
    $env.SCRATCH_THEME = {
        color: {
            title: default
            id: xterm_grey39
            value: {
                positive: xterm_green
                negative: xterm_red
            }
            tag: xterm_wheat4
            important: yellow
            urgent: red
            challenge: blue
            deadline: xterm_rosybrown
            created: xterm_paleturquoise4
            updated: xterm_lightsalmon3a
            body: grey
            branch: xterm_wheat1
        }
        symbol: {
            box: [['☐' '🗹' '☒' '*'],['[ ]' '[x]' '[-]' '']]
            md_list: '-'
        }
        formatter: {
            created: {|x| $x | into datetime | date humanize }
            updated: {|x| $x | into datetime | date humanize }
            deadline: {|x, o|
                let t = $x | into datetime
                let s = $t | date humanize
                if ($t - (date now) | into int) > 0 { $s } else { $"(ansi purple_reverse)($s)(ansi reset)" }
            }
            important: {|x| '' | fill -c '☆ ' -w $x }
            urgent: {|x| '' | fill -c '🔥' -w $x }
            challenge: {|x| '' | fill -c '⚡' -w $x }
        }
    }
    $env.SCRATCH_ACCUMULATOR = {
        sum: {
            sum: [{ $in.value | math sum }, { $in | math sum }]
        }
        done: {
            done: [{ $in.done | filter { $in == 1 } | length }, { $in | math sum }]
        }
        count: {
            count: [{ $in | length }, { $in | math sum }]
        }
    }
}
