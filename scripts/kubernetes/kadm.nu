export def "kadm update certs" [] {
    sudo kubeadm certs check-expiration
    if ([n y] | input list 'renew all') == 'y' {
        sudo kubeadm certs renew all
    }
}

export def "kadm update sans" [] {
    kubectl -n kube-system get configmap kubeadm-config -o jsonpath='{.data.ClusterConfiguration}'
    | save -f kubeadm.yaml
    ^$env.EDITOR kubeadm.yaml
    for k in [crt, key] {
        sudo mv $"/etc/kubernetes/pki/apiserver.($k)" .
    }
    kubeadm init phase certs apiserver --config kubeadm.yaml
    let p = kgp -n kube-system
    | where { $in.name | str starts-with kube-apiserver }
    | first
    | get name
    let a = [yes no] | input list 'kill pod/kube-apiserver in kube-system'
    if $a == 'yes' {
        kubectl delete pod $p --force --grace-period=0
    } else {
        print $p
    }
}
