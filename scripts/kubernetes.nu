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
    [
        pod deployment svc endpoints
        configmap secret event
        namespace node pv pvc
        job cronjob daemonset statefulset
        ingress gateway virtualservice
        clusterrole clusterrolebinding role serviceaccount rolebinding
        certificate clusterissuer issuer
    ]
}

def "nu-complete kube res" [context: string, offset: int] {
    let ctx = ($context | parse cmd)
    let def = ($ctx | get args | get 1)
    let ns = do -i { $ctx | get '-n' }
    let ns = if ($ns|empty?) { [] } else { [-n $ns] }
    kubectl $ns get $def | from ssv -a | get NAME
}

def kg [
    r: string@"nu-complete kube def"
    -n: string@"nu-complete kube ns"
    --all (-A):bool
] {
    let n = if $all {
                [-A]
            } else if ($n | empty?) {
                []
            } else {
                [-n $n]
            }
    #let h = ($d | columns | str kebab-case)
    #$d | rename ...$h
    kubectl $n get $r | from ssv -a
}

def kc [
    r: string@"nu-complete kube def"
    -n: string@"nu-complete kube ns"
    name:string
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl -n $n create $r $name
}

def ky [
    r: string@"nu-complete kube def"
    i: string@"nu-complete kube res"
    -n: string@"nu-complete kube ns"
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n get -o yaml $r $i
}

def kd [
    r: string@"nu-complete kube def"
    i: string@"nu-complete kube res"
    -n: string@"nu-complete kube ns"
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n describe $r $i
}

def ke [
    r: string@"nu-complete kube def"
    i: string@"nu-complete kube res"
    -n: string@"nu-complete kube ns"
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n edit $r $i
}

def kdel [
    r: string@"nu-complete kube def"
    i: string@"nu-complete kube res"
    -n: string@"nu-complete kube ns"
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n delete $r $i
}

### node
def kgno [] {
    kubectl get nodes -o wide | from ssv -a
    | rename name status roles age version internal-ip external-ip os kernel runtime
}

### pods
def "nu-complete kube pods" [context: string, offset: int] {
    let ctx = ($context | parse cmd)
    let ns = do -i { $ctx | get '-n' }
    let ns = if ($ns|empty?) { [] } else { [-n $ns] }
    kubectl $ns get pods | from ssv -a | get NAME
}

def kgpl [] {
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
    | each {|x| ($x| upsert restarts ($x.restarts|split row ' '| get 0 | into int)) }
    | reject 'NOMINATED NODE' 'READINESS GATES'
}

def kgp [-n: string@"nu-complete kube ns"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl get pods $n -o wide | from ssv -a
    | rename name ready status restarts age ip node
    | each {|x| ($x| upsert restarts ($x.restarts|split row ' '| get 0 | into int)) }
    | reject 'NOMINATED NODE' 'READINESS GATES'
}

def kgpw [] {
    kubectl get pods --watch
}

def kep [-n: string@"nu-complete kube ns", pod: string@"nu-complete kube pods"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl edit pod $n $pod
}

def kdp [-n: string@"nu-complete kube ns", pod: string@"nu-complete kube pods"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl describe pod $n $pod
}

def ka [
    pod: string@"nu-complete kube pods"
    -n: string@"nu-complete kube ns"
    ...args
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n exec -it $pod -- (if ($args|empty?) { 'bash' } else { $args })
}

def kl [
    pod: string@"nu-complete kube pods"
    -n: string@"nu-complete kube ns"
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n logs $pod
}

def klf [
    pod: string@"nu-complete kube pods"
    -n: string@"nu-complete kube ns"
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n logs -f $pod
}

def "nu-complete port forward type" [] {
    [pod svc]
}
def kpf [
    res: string@"nu-complete port forward type"
    target: string@"nu-complete kube res"
    -n: string@"nu-complete kube ns"
    port: string    ### reflect port num
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n port-forward $res $target $port
}

def kcp [
    lhs: string@"nu-complete kube pods"
    rhs: string@"nu-complete kube pods"
    -n: string@"nu-complete kube ns"
] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl cp $n $lhs $rhs
}

### service
def "nu-complete kube service" [context: string, offset: int] {
    let ctx = ($context | parse cmd)
    let ns = do -i { $ctx | get '-n' }
    let ns = if ($ns|empty?) { [] } else { [-n $ns] }
    kubectl $ns get services | from ssv -a | get NAME
}

def kgs [-n: string@"nu-complete kube ns"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl get $n services | from ssv -a
    | rename name type cluster-ip external-ip ports age selector
}

def kes [svc: string@"nu-complete kube service", -n: string@"nu-complete kube ns"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl edit $n service $svc
}

def kdels [svc: string@"nu-complete kube service", -n: string@"nu-complete kube ns"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl delete $n service $svc
}

### deployments
def "nu-complete kube deployments" [context: string, offset: int] {
    let ctx = ($context | parse cmd)
    let ns = do -i { $ctx | get '-n' }
    let ns = if ($ns|empty?) { [] } else { [-n $ns] }
    kubectl $ns get deployments | from ssv -a | get NAME
}

def kgd [-n: string@"nu-complete kube ns"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n get deployments -o wide | from ssv -a
    | rename name ready up-to-date available age containers images selector
    | reject selector
}

def ked [d: string@"nu-complete kube deployments", -n: string@"nu-complete kube ns"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n edit deployments $d
}

def "nu-complete num9" [] { [1 2 3] }
def ksd [
    d: string@"nu-complete kube deployments"
    num: int@"nu-complete num9"
    -n: string@"nu-complete kube ns"
] {
    if $num > 9 {
        "too large"
    } else {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl $n scale deployments $d --replicas $num
    }
}

### kubecto top pod
def ktp [-n: string@"nu-complete kube ns"] {
    let n = if ($n|empty?) { [] } else { [-n $n] }
    kubectl $n top pod | from ssv -a | rename name cpu mem
    | each {|x| {
        name: $x.name
        cpu: ($x.cpu| str substring ',-1' | into decimal)
        mem: ($x.mem | str substring ',-2' | into decimal)
    } }
}

### kubeto top node
def ktn [] {
    kubectl top node | from ssv -a | rename name cpu pcpu mem pmem
    | each {|x| {
        name: $x.name
        cpu: ($x.cpu| str substring ',-1' | into decimal)
        cpu%: (($x.pcpu| str substring ',-1' | into decimal) / 100)
        mem: ($x.mem | str substring ',-2' | into decimal)
        mem%: (($x.pmem | str substring ',-1' | into decimal) / 100)
    } }
}
