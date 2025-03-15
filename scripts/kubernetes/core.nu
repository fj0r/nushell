use common.nu *
use conf.nu *
use complete.nu *

def krefine [kind] {
    let obj = $in
    let conf = $env.KUBERNETES_REFINE
    let kind = if $kind in $conf.shortnames {
        $conf.shortnames | get $kind
    } else {
        $kind
    }
    let tg = [cluster_resources cluster_status resources status]
    | reduce -f {} {|i,a|
        let r = $conf | get $i
        if $kind in $r {
            $a | merge ($r | get $kind)
        } else {
            $a
        }
    }
    if ($tg | is-empty) {
        $obj
    } else {
        refine $tg $obj
    }
}


# kubectl apply -f
export def kube-apply-file [file: path] {
    kubectl apply -f $file
}

# kubectl diff -f
export def kube-diff-file [file: path] {
    kubectl diff -f $file
}

# kubectl delete -f
export def kube-delete-file [file: path] {
    kubectl delete -f $file
}

# kubectl apply -k (kustomize)
export def kube-apply-kustomize [file: path] {
    kubectl apply -k $file
}

# kubectl diff -k (kustomize)
export def kube-diff-kustomize [file: path] {
    kubectl diff -k $file
}

# kubectl delete -k (kustomize)
export def kube-delete-kustomize [file: path] {
    kubectl delete -k $file
}

# kubectl kustomize (template)
export def kube-kustomize [file: path] {
    kubectl kustomize $file
}



# kubectl change context
export def --env kube-change-context [
    context: string@cmpl-kube-ctx
    --session(-s)
] {
    if $session {
        let td = '/tmp/kubeconfig'
        if not ($td | path exists) {
            mkdir $td
        }
        let dist = mktemp -p $td $"(history session).XXX"
        kube-conf-export $context | save -fr $dist
        $env.KUBECONFIG = $dist
    } else {
        kubectl config use-context $context
    }
}

# kubectl change namespace
export def kube-change-namespace [namespace: string@cmpl-kube-ns] {
    if not ($namespace in (kubectl get namespace | from ssv -a | get NAME)) {
        if ([no yes] | input list $"namespace '($namespace)' doesn't exist, create it?") in [yes] {
            kubectl create namespace $namespace
        } else {
            return
        }
    }
    kubectl config set-context --current $"--namespace=($namespace)"
}


# kubectl get
export def kube-get [
    kind: string@cmpl-kube-kind
    resource?: string@cmpl-kube-res
    --namespace (-n): string@cmpl-kube-ns
    --jsonpath (-p): string@cmpl-kube-jsonpath
    --selector (-l): string
    --verbose (-v)
    --wide (-w)
    --watch (-W)
    --all (-a)
] {
    let ns = if $all {
        [-A]
    } else if ($namespace | is-empty) {
        []
    } else {
        [-n $namespace]
    }
    if ($resource | is-empty) {
        let l = $selector | with-flag -l

        let wide = if $wide {[-o wide]} else {[]}
        if $verbose {
            kubectl get -o json ...$ns $kind ...$l | from json
            | get items
            | krefine $kind
        } else if $watch {
            kubectl get ...$ns $kind ...$l ...$wide --watch
        } else {
            kubectl get ...$ns $kind ...$l ...$wide | from ssv -a | normalize-column-names
        }
    } else {
        if ($jsonpath | is-empty) {
            let o = kubectl get ...$ns $kind $resource -o json | from json
            if $verbose { $o } else { $o | krefine $kind }
        } else {
            kubectl get ...$ns $kind $resource $"--output=jsonpath={($jsonpath)}" | from json
        }
    }
}

# kubectl describe
export def kube-describe [
    kind: string@cmpl-kube-kind
    resource: string@cmpl-kube-res
    --namespace (-n): string@cmpl-kube-ns
] {
    kubectl describe ...($namespace | with-flag -n) $kind $resource
}

# kubectl create
export def kube-create [
    kind: string@cmpl-kube-kind
    --namespace (-n): string@cmpl-kube-ns
    name:string
] {
    kubectl create ...($namespace | with-flag -n) $kind $name
}

# kubectl get -o yaml
export def kube-get-as-yaml [
    kind: string@cmpl-kube-kind
    resource: string@cmpl-kube-res
    --namespace (-n): string@cmpl-kube-ns
] {
    kubectl get ...($namespace | with-flag -n) -o yaml $kind $resource
}

# kubectl edit
export def kube-edit [
    kind: string@cmpl-kube-kind
    resource?: string@cmpl-kube-res
    --namespace (-n): string@cmpl-kube-ns
    --selector(-l): string
] {
    let n = $namespace | with-flag -n
    let r = if ($selector | is-empty) { $resource } else {
        let res = kubectl get $kind ...$n -l $selector | from ssv -a | each {|x| $x.NAME}
        if ($res | length) == 1 {
            $res.0
        } else if ($res | length) == 0 {
            return
        } else {
            $res | input list $'select ($kind) '
        }
    }
    kubectl edit ...$n $kind $r
}

# kubectl delete
export def kube-delete [
    kind: string@cmpl-kube-kind
    resource: string@cmpl-kube-res
    --namespace (-n): string@cmpl-kube-ns
    --force(-f)
] {
    kubectl delete ...($namespace | with-flag -n) ...(if $force {[--grace-period=0 --force]} else {[]}) $kind $resource
}


# kubectl get nodes
export def kube-get-node [] {
    kubectl get nodes -o wide | from ssv -a
    | rename name status roles age version internal-ip external-ip os kernel runtime
}



# kubectl attach (exec -it)
export def --wrapped kube-attach [
    pod?: string@cmpl-kube-deploys-and-pods
    --namespace (-n): string@cmpl-kube-ns
    --container(-c): string@cmpl-kube-ctns
    --selector(-l): string
    --all-pods(-a) # for completion
    ...args
] {
    let stdin = $in
    let n = if ($namespace | is-empty) { [] } else { [-n $namespace] }
    let pod = if ($selector | is-empty) {
        if ($pod | str ends-with '-') {
            $"deployment/($pod | str trim --char '-' --right)"
        } else {
            $pod
        }
        } else {
        let pods = kubectl get pods ...$n -o wide -l $selector
            | from ssv -a
            | where STATUS == Running
            | select NAME IP NODE
            | rename name ip node
        if ($pods | length) == 1 {
            ($pods.0).name
        } else if ($pods | length) == 0 {
            return
        } else {
            ($pods | input list 'select pod ').name
        }
    }
    let c = if ($container | is-empty) {
        if ($selector | is-empty)  { [] } else {
            let cs = kubectl get pods ...$n $pod --output=jsonpath={.spec.containers[*].name} | split row ' '
            let ctn = if ($cs | length) == 1 {
                $cs.0
            } else {
                $cs | input list 'select container '
            }
            [-c $ctn]
        }
    } else {
        [-c $container]
    }
    let args = if ($args | is-empty) {
        let cmd = [
            '/usr/local/bin/nu'
            '/bin/nu'
            '/bin/bash'
            '/bin/sh'
        ]
        | str join ' '
        | $"for sh in ($in); do if [ -e $sh ]; then exec $sh; fi; done"
        ['/bin/sh' -c $cmd]
    } else {
        $args
    }
    if ($stdin | is-empty) {
        kubectl exec ...$n -it $pod ...$c -- ...$args
    } else {
        $stdin | kubectl exec ...$n -i $pod ...$c -- ...$args
    }
}

# kubectl logs
export def kube-log [
    pod: string@cmpl-kube-deploys-and-pods
    --namespace(-n): string@cmpl-kube-ns
    --container(-c): string@cmpl-kube-ctns
    --follow(-f)
    --previous(-p)
    --all-pods(-a) # for completion
] {
    let n = $namespace | with-flag -n
    let c = $container | with-flag -c
    let f = if $follow {[-f]} else {[]}
    let p = if $previous {[-p]} else {[]}
    let trg = if ($pod | str ends-with '-') {
        $"deployment/($pod | str substring ..<-1)"
        } else {
            $pod
        }
    kubectl logs ...$n ...$f ...$p $trg ...$c
}

# kubectl port-forward
export def kube-port-forward [
    kind: string@cmpl-port-forward-type
    target: string@cmpl-kube-res
    port: string@cmpl-kube-port
    --local (-l): string
    --namespace (-n): string@cmpl-kube-ns
] {
    let ns = $namespace | with-flag -n
    let port = if ($local | is-empty) { $port } else { $"($local):($port)" }
    kubectl port-forward ...$ns $"($kind)/($target)" $port
}

# kubectl cp
export def kube-copy [
    lhs: string@cmpl-kube-cp
    rhs: string@cmpl-kube-cp
    --container (-c): string@cmpl-kube-ctns
    --namespace (-n): string@cmpl-kube-ns
] {
    kubectl cp ...($namespace | with-flag -n) $lhs ...($container | with-flag -c) $rhs
}


def cmpl-num9 [] { 1..9 | each {$in} }
# kubectl scale deployment
export def kube-scale-deployment [
    deployment: string@cmpl-kube-deploys
    num: int@cmpl-num9
    --namespace (-n): string@cmpl-kube-ns
    --reset(-r)
] {
    if $num < 0 {
        "too small"
    } else {
        let ns = $namespace | with-flag -n
        if $reset {
            kubectl scale ...$ns deployments $deployment --replicas 0
        }
        kubectl scale ...$ns deployments $deployment --replicas $num
    }
}

# kubectl set image
export def kube-set-image [
    kind: string@cmpl-kube-kind-with-image
    resource: string@cmpl-kube-res
    --namespace(-n): string@cmpl-kube-ns
    --dry-run
    act?: any
] {
    let ns = $namespace | with-flag -n
    let list = kubectl get ...$ns $kind $resource -o jsonpath="{.spec.template.spec}"
    | from json
    | get containers
    if ($act | describe -d).type == 'closure' {
        let s = $list
        | update image $act
        | select name image
        | each {|x| $"($x.name)=($x.image)" }
        | str join ' '

        print $"kubectl ($ns | str join ' ') set image \"($kind)/($resource)\" ($s)"
        if not $dry_run {
            kubectl ...$ns set image $"($kind)/($resource)" $s
        }
    } else {
        $list
    }
}

# kubectl rollout history
export def kube-rollout-history [
    --namespace (-n): string@cmpl-kube-ns
    --revision (-v): int
    deployment: string@cmpl-kube-deploys
] {
    let ns = $namespace | with-flag -n
    let v = if ($revision|is-empty) { [] } else { [ $"--revision=($revision)" ] }
    kubectl ...$ns rollout history $"deployment/($deployment)" ...$v
}

# kubectl rollout undo
export def kube-rollout-undo [
    --namespace (-n): string@cmpl-kube-ns
    --revision (-v): int
    deployment: string@cmpl-kube-deploys
] {
    let ns = $namespace | with-flag -n
    let v = if ($revision|is-empty) { [] } else { [ $"--to-revision=($revision)" ] }
    kubectl ...$ns rollout undo $"deployment/($deployment)" ...$v
}

# kubectl top pod
export def kube-top-pod [
    --namespace (-n): string@cmpl-kube-ns
    --all(-a)
] {
    if $all {
        kubectl top pod -A | from ssv -a | rename namespace name cpu mem
        | each {|x|
            {
                namespace: $x.namespace
                name: $x.name
                cpu: ($x.cpu| str substring ..<-1 | into float)
                mem: ($x.mem | str substring ..<-2 | into float)
            }
        }
    } else {
        let ns = $namespace | with-flag -n
        kubectl top pod ...$ns | from ssv -a | rename name cpu mem
        | each {|x|
            {
                name: $x.name
                cpu: ($x.cpu| str substring ..<-1 | into float)
                mem: ($x.mem | str substring ..<-2 | into float)
            }
        }
    }
}

# kubectl top node
export def kube-top-node [] {
    kubectl top node | from ssv -a | rename name cpu pcpu mem pmem
    | each {|x| {
        name: $x.name
        cpu: ($x.cpu| str substring ..<-1 | into float)
        cpu%: (($x.pcpu| str substring ..<-1 | into float) / 100)
        mem: ($x.mem | str substring ..<-2 | into float)
        mem%: (($x.pmem | str substring ..<-1 | into float) / 100)
    } }
}

