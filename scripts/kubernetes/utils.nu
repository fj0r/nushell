use complete.nu *
use common.nu *

### cert-manager
export def kgcert [] {
    kubectl get certificates -o wide | from ssv | rename certificates
    kubectl get certificaterequests -o wide | from ssv | rename certificaterequests
    kubectl get order.acme -o wide | from ssv | rename order.acme
    kubectl get challenges.acme -o wide | from ssv | rename challenges.acme
}


# kubectl redistribution deployment
export def kube-redistribution-deployment [
    deployment: string@cmpl-kube-deploys
    ...nodes: string@cmpl-kube-nodes
    --namespace (-n): string@cmpl-kube-ns
] {
    mut args = []
    if ($namespace | is-not-empty) {
        $args ++= [-n $namespace]
    }
    let nums = kubectl get nodes | from ssv -a | length
    kubectl scale ...$args deployments $deployment --replicas $nums
    let labels = kubectl get ...$args deploy $deployment --output=json
    | from json
    | get spec.selector.matchLabels
    | transpose k v
    | each {|x| $"($x.k)=($x.v)"}
    | str join ','
    let pods = kubectl get ...$args pods -l $labels -o wide | from ssv -a
    for p in ($pods | where NODE not-in $nodes) {
        kubectl delete ...$args pod --grace-period=0 --force $p.NAME
    }
    kubectl scale ...$args deployments $deployment --replicas ($pods | where NODE in $nodes | length)
}


###
export def kube-clean-evicted [] {
    kubectl get pods -A
    | from ssv -a
    | where STATUS == Evicted
    | each { |x| kube-delete pod -n $x.NAMESPACE $x.NAME }
}

### FIXME:
export def kube-clean-stucked-ns [ns: string] {
    kubectl get namespace $ns -o json \
    | tr -d "\n"
    | sed 's/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/' \
    | kubectl replace --raw /api/v1/namespaces/$1/finalize -f -
}

export def kube-clean-finalizer [$r $n] {
    kubectl patch -p '{\"metadata\":{\"finalizers\":null}}' $r $n
}

