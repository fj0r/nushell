### file
def kaf [p: path] {
    kubectl apply -f $p
}

def kak [p: path] {
    kubectl apply -k $p
}

def kk [p: path] {
    kubectl kustomize $p
}

### ctx
def "nu-complete kube ctx" [] { kubectx | lines}

def "nu-complete kube ns" [] { kubens | lines }

def kcc [ctx: string@"nu-complete kube ctx"] {
    kubectx $ctx
}

def kn [ns: string@"nu-complete kube ns"] {
    kubens $ns
}

### common
def "nu-complete kube def" [] {
    [ pods deployments svc endpoints
      configmaps secrets events
      namespaces nodes pv pvc
      jobs cronjobs daemonsets statefulsets
      ingress gateways virtualservice
      clusterroles clusterrolebindings roles serviceaccounts rolebindings
      certificates clusterissuers issuers
    ]
}

def filter-list [list, idx] {
    $list | reduce -f [] -n {|it, acc| if $it.index not-in $idx { $acc.item | append $it.item} else { $acc.item }}
}

def "parse cmd" [cmd: string] {
    $cmd | split row ' '
    | reduce -f { cmd: [], sw: '' } {|it, acc|
        if ($acc.sw|empty?) {
            if ($it|str starts-with '-') {
                $acc | update sw $it
            } else {
                let cmd = ($acc.cmd | append $it)
                $acc | update cmd $cmd
            }
        } else {
            if ($it|str starts-with '-') {
                $acc
                | insert $acc.sw true
                | update sw $it
            } else {
                $acc | insert $acc.sw $it | update sw ''
            }
        }
    }
    | reject sw
}

def "nu-complete kube res" [context: string, offset: int] {
    let ctx = ($context | split row ' ')
    let ns = ($ctx | each -n {|x| if $x.item == '-n' { $x.index }} )
    let ns = if ($ns | empty?) { -1 } else { $ns | get 0 }
    if $ns < 0 {
        kubectl get ($ctx | last) | from ssv -a | get NAME
    } else {
        let n = ($ctx | get ($ns + 1))
        let def = (filter-list $ctx [$ns ($ns + 1)])
        kubectl -n $n get ($def | last) | from ssv -a | get NAME
    }
}

def kg [
    r: string@"nu-complete kube def",
    -n: string@"nu-complete kube ns",
    --all (-A):bool
] {
    let d = (if $all {
                 kubectl get -A $r
             } else if ($n | empty?) {
                 kubectl get $r
             } else {
                 kubectl -n $n get $r
             } | from ssv -a)
    let h = ($d | columns | str kebab-case)
    #$d | rename ...$h
    $d
}

def kd [
    r: string@"nu-complete kube def",
    i: string@"nu-complete kube res",
    -n: string@"nu-complete kube ns"
] {
    if ($n|empty?) {
        kubectl describe $r $i
    } else {
        kubectl -n $n describe $r $i
    }
}

def ke [
    r: string@"nu-complete kube def",
    i: string@"nu-complete kube res",
    -n: string@"nu-complete kube ns"
] {
    if ($n|empty?) {
        kubectl edit $r $i
    } else {
        kubectl -n $n edit $r $i
    }
}

def kdel [
    r: string@"nu-complete kube def",
    i: string@"nu-complete kube res",
    -n: string@"nu-complete kube ns"
] {
    if ($n|empty?) {
        kubectl delete $r $i
    } else {
        kubectl -n $n delete $r $i
    }
}

### node
def kgno [] {
    kubectl get nodes -o wide | from ssv -a
    | rename name status roles age version internal-ip external-ip os kernel runtime
}

### pods
def "nu-complete kube pods" [context: string, offset: int] {
    let ctx = ($context | split row ' ')
    let ns = ($ctx | each -n {|x| if $x.item == '-n' { $x.index }} )
    let ns = if ($ns | empty?) { -1 } else { $ns | get 0 }
    if $ns < 0 {
        kubectl get pods | from ssv -a | get NAME
    } else {
        let n = ($ctx | get ($ns + 1))
        kubectl -n $n get pods | from ssv -a | get NAME
    }
}

def kgpo [] {
    kubectl get pods -o json
    | from json
    | get items
    | each {|x|
        let rs = $x.status.containerStatuses.0.restartCount
        {
            namespace: $x.metadata.namespace,
            name: $x.metadata.name,
            status: $x.status.phase,
            restarts: ($rs | split row ' '| get 0 | into int),
            age: ((date now) - ($x.status.startTime | into datetime))
        }}
}

def kgpa [] {
    kubectl get pods -o wide -A | from ssv -a
    | rename namespace name ready status restarts age ip node
    | each {|x| ($x| update restarts ($x.restarts|split row ' '| get 0 | into int)) }
    | reject 'NOMINATED NODE' 'READINESS GATES'
}

def kgp [] {
    kubectl get pods -o wide | from ssv -a
    | rename name ready status restarts age ip node
    | each {|x| ($x| update restarts ($x.restarts|split row ' '| get 0 | into int)) }
    | reject 'NOMINATED NODE' 'READINESS GATES'
}

def kep [pod: string@"nu-complete kube pods"] {
    kubectl edit pod $pod
}

def kdp [pod: string@"nu-complete kube pods"] {
    kubectl describe pod $pod
}

def ka [pod: string@"nu-complete kube pods", -n: string@"nu-complete kube ns", ...args] {
    if ($n|empty?) {
        kubectl exec -it $pod -- (if ($args|empty?) { 'bash' } else { $args })
    } else {
        kubectl -n $n exec -it $pod -- (if ($args|empty?) { 'bash' } else { $args })
    }
}

def kl [pod: string@"nu-complete kube pods", -n: string@"nu-complete kube ns"] {
    if ($n|empty?) {
        kubectl logs $pod
    } else {
        kubectl -n $n logs $pod
    }
}

def klf [pod: string@"nu-complete kube pods", -n: string@"nu-complete kube ns"] {
    if ($n|empty?) {
        kubectl logs -f $pod
    } else {
        kubectl -n $n logs -f $pod
    }
}

### service
def "nu-complete kube service" [] {
    kubectl get services | from ssv -a | get NAME
}

def kgs [] {
    kubectl get services | from ssv -a
    | rename name type cluster-ip external-ip ports age selector
}

def kes [svc: string@"nu-complete kube service"] {
    kubectl edit service $svc
}

def kdels [svc: string@"nu-complete kube service"] {
    kubectl delete service $svc
}

### deployments
def "nu-complete kube deployments" [] {
    kubectl get deployments | from ssv -a | get NAME
}

def kgd [] {
    kubectl get deployments -o wide | from ssv -a
    | rename name ready up-to-date available age containers images selector
    | reject selector
}

def ked [d: string@"nu-complete kube deployments"] {
    kubectl edit deployments $d
}

def "nu-complete num9" [] { [1 2 3] }
def ksd [d: string@"nu-complete kube deployments", n: int@"nu-complete num9"] {
    if $n > 9 {
        "too large"
    } else {
        kubectl scale deployments $d --replicas $n
    }
}
