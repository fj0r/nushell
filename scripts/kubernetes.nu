module kubectl {
    export env KUBECTL_EXTERNAL_DIFF { 'kubectl-neat-diff' }
    export env KUBERNETES_SCHEMA_URL { $"file:///($env.HOME)/.config/kubernetes-json-schema/all.json" }


    ### file
    export def kaf [p: path] {
        kubectl apply -f $p
    }
    
    export def kdf [p: path] {
        kubectl diff -f $p
    }

    export def kdelf [p: path] {
        kubectl delete -f $p
    }
    
    export def kak [p: path] {
        kubectl apply -k $p
    }
    
    export def kdk [p: path] {
        kubectl diff -k $p
    }

    export def kdelk [p: path] {
        kubectl delete -k $p
    }
    
    export def kk [p: path] {
        kubectl kustomize $p
    }
    
    ### ctx
    def "nu-complete kube ctx" [] { kubectx | lines}
    
    def "nu-complete kube ns" [] { kubens | lines }
    
    export def kcc [ctx: string@"nu-complete kube ctx"] {
        kubectx $ctx
    }
    
    export def kn [ns: string@"nu-complete kube ns"] {
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
            clusterissuer issuer
            certificate certificaterequest order.acme challenge.acme
        ]
    }
    
    def "nu-complete kube res" [context: string, offset: int] {
        let ctx = ($context | parse cmd)
        let def = ($ctx | get args | get 1)
        let ns = do -i { $ctx | get '-n' }
        let ns = if ($ns|empty?) { [] } else { [-n $ns] }
        kubectl get $ns $def | from ssv -a | get NAME
    }
    
    export def kg [
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
        kubectl get $n $r | from ssv -a
    }
    
    export def kc [
        r: string@"nu-complete kube def"
        -n: string@"nu-complete kube ns"
        name:string
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl create $n $r $name
    }
    
    export def ky [
        r: string@"nu-complete kube def"
        i: string@"nu-complete kube res"
        -n: string@"nu-complete kube ns"
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl get $n -o yaml $r $i
    }
    
    export def kd [
        r: string@"nu-complete kube def"
        i: string@"nu-complete kube res"
        -n: string@"nu-complete kube ns"
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl describe $n $r $i
    }
    
    export def ke [
        r: string@"nu-complete kube def"
        i: string@"nu-complete kube res"
        -n: string@"nu-complete kube ns"
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl edit $n $r $i
    }
    
    export def kdel [
        r: string@"nu-complete kube def"
        i: string@"nu-complete kube res"
        -n: string@"nu-complete kube ns"
        --force(-f): bool
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        let f = if $force { [--grace-period=0 --force] } else { [] }
        kubectl delete $n $f $r $i
    }
    

    ### node
    export def kgno [] {
        kubectl get nodes -o wide | from ssv -a
        | rename name status roles age version internal-ip external-ip os kernel runtime
    }
    
    ### pods
    def "nu-complete kube pods" [context: string, offset: int] {
        let ctx = ($context | parse cmd)
        let ns = do -i { $ctx | get '-n' }
        let ns = if ($ns|empty?) { [] } else { [-n $ns] }
        kubectl get $ns pods | from ssv -a | get NAME
    }
    
    export def kgpl [] {
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
                age: ($x.status.startTime | into datetime)
            }}
    }
    
    export def kgpa [] {
        kubectl get pods -o wide -A | from ssv -a
        | rename namespace name ready status restarts age ip node
        | each {|x| ($x| upsert restarts ($x.restarts|split row ' '| get 0 | into int)) }
        | reject 'NOMINATED NODE' 'READINESS GATES'
    }
    
    export def kgp [-n: string@"nu-complete kube ns"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl get pods $n -o wide | from ssv -a
        | rename name ready status restarts age ip node
        | each {|x| ($x| upsert restarts ($x.restarts|split row ' '| get 0 | into int)) }
        | reject 'NOMINATED NODE' 'READINESS GATES'
    }
    
    export def kgpw [] {
        kubectl get pods --watch
    }
    
    export def kep [-n: string@"nu-complete kube ns", pod: string@"nu-complete kube pods"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl edit pod $n $pod
    }
    
    export def kdp [-n: string@"nu-complete kube ns", pod: string@"nu-complete kube pods"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl describe pod $n $pod
    }
    
    export def ka [
        pod: string@"nu-complete kube pods"
        -n: string@"nu-complete kube ns"
        ...args
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl exec $n -it $pod -- (if ($args|empty?) { 'bash' } else { $args })
    }
    
    export def kl [
        pod: string@"nu-complete kube pods"
        -n: string@"nu-complete kube ns"
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl logs $n $pod
    }
    
    export def klf [
        pod: string@"nu-complete kube pods"
        -n: string@"nu-complete kube ns"
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl logs $n -f $pod
    }
    
    def "nu-complete port forward type" [] {
        [pod svc]
    }
    export def kpf [
        res: string@"nu-complete port forward type"
        target: string@"nu-complete kube res"
        -n: string@"nu-complete kube ns"
        port: string    ### reflect port num
    ] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl port-forward $n $res $target $port
    }
    
    export def kcp [
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
        kubectl get $ns services | from ssv -a | get NAME
    }
    
    export def kgs [-n: string@"nu-complete kube ns"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl get $n services | from ssv -a
        | rename name type cluster-ip external-ip ports age selector
    }
    
    export def kes [svc: string@"nu-complete kube service", -n: string@"nu-complete kube ns"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl edit $n service $svc
    }
    
    export def kdels [svc: string@"nu-complete kube service", -n: string@"nu-complete kube ns"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl delete $n service $svc
    }
    
    ### deployments
    def "nu-complete kube deployments" [context: string, offset: int] {
        let ctx = ($context | parse cmd)
        let ns = do -i { $ctx | get '-n' }
        let ns = if ($ns|empty?) { [] } else { [-n $ns] }
        kubectl get $ns deployments | from ssv -a | get NAME
    }
    
    export def kgd [-n: string@"nu-complete kube ns"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl get $n deployments -o wide | from ssv -a
        | rename name ready up-to-date available age containers images selector
        | reject selector
    }
    
    export def ked [d: string@"nu-complete kube deployments", -n: string@"nu-complete kube ns"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl edit $n deployments $d
    }
    
    def "nu-complete num9" [] { [1 2 3] }
    export def ksd [
        d: string@"nu-complete kube deployments"
        num: int@"nu-complete num9"
        -n: string@"nu-complete kube ns"
    ] {
        if $num > 9 {
            "too large"
        } else {
            let n = if ($n|empty?) { [] } else { [-n $n] }
            kubectl scale $n deployments $d --replicas $num
        }
    }

    export alias krsd = kubectl rollout status deployment
    export alias kgrs = kubectl get rs
    export alias krh = kubectl rollout history
    export alias kru = kubectl rollout undo
    export alias ksss = kubectl scale statefulset
    export alias krsss = kubectl rollout status statefulset
    
    ### kubecto top pod
    export def ktp [-n: string@"nu-complete kube ns"] {
        let n = if ($n|empty?) { [] } else { [-n $n] }
        kubectl top pod $n | from ssv -a | rename name cpu mem
        | each {|x| {
            name: $x.name
            cpu: ($x.cpu| str substring ',-1' | into decimal)
            mem: ($x.mem | str substring ',-2' | into decimal)
        } }
    }

    export def ktpa [] {
        kubectl top pod -A | from ssv -a | rename namespace name cpu mem
        | each {|x| {
            namespace: $x.namespace
            name: $x.name
            cpu: ($x.cpu| str substring ',-1' | into decimal)
            mem: ($x.mem | str substring ',-2' | into decimal)
        } }
    }
    
    ### kube top node
    export def ktn [] {
        kubectl top node | from ssv -a | rename name cpu pcpu mem pmem
        | each {|x| {
            name: $x.name
            cpu: ($x.cpu| str substring ',-1' | into decimal)
            cpu%: (($x.pcpu| str substring ',-1' | into decimal) / 100)
            mem: ($x.mem | str substring ',-2' | into decimal)
            mem%: (($x.pmem | str substring ',-1' | into decimal) / 100)
        } }
    }

    ###
    export def "kclean evicted" [] {
        kubectl get pods -A
        | from ssv -a
        | where STATUS == Evicted
        | each { |x| kdel pod -n $x.NAMESPACE $x.NAME }
    }

    ### fixme:
    export def "kclean stucked ns" [ns: string] {
        kubectl get namespace $ns -o json \
        | tr -d "\n"
        | sed 's/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/' \
        | kubectl replace --raw /api/v1/namespaces/$1/finalize -f -
    }

    export alias "kclean finalizer" = kubectl patch -p '{\"metadata\":{\"finalizers\":null}}'

    ### cert-manager
    export def kgcert [] {
        kubectl get certificates -o wide | from ssv | rename certificates
        kubectl get certificaterequests -o wide | from ssv | rename certificaterequests
        kubectl get order.acme -o wide | from ssv | rename order.acme
        kubectl get challenges.acme -o wide | from ssv | rename challenges.acme
    }


}

use kubectl *
