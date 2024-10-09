export alias kaf = kube-apply-file
export alias kdf = kube-diff-file
export alias kdelf = kube-delete-file
export alias kak = kube-apply-kustomize
export alias kdk = kube-diff-kustomize
export alias kdelk = kube-delete-kustomize
export alias kk = kube-kustomize
export alias kcc = kube-change-context
export alias kccc = kube-change-context-clone
export alias kn = kube-change-namespace
export alias kg = kube-get
export alias kd = kube-describe
export alias kc = kube-create
export alias ky = kube-get-as-yaml
export alias ke = kube-edit
export alias kdel = kube-delete
export alias kgno = kube-get-node
export alias kgp = kube-get pods
export alias kwp = kube-get pods -w
export alias kep = kube-edit pod
export alias kdp = kube-describe pod
export alias ka = kube-attach
export alias kl = kube-log
export alias kpf = kube-port-forward
export alias kcp = kube-copy
export alias kgs = kube-get services
export alias kes = kube-edit services
export alias kdels = kube-delete services
export alias kgd = kube-get deployments
export alias ked = kube-edit deployments
export alias ksd = kube-scale-deployment
export alias ksss = kubectl scale statefulset
export alias krsss = kubectl rollout status statefulset
export alias krd = kube-redistribution-deployment
export alias krh = kube-rollout-history
export alias kru = kube-rollout-undo
# kubectl rollout status deployment
export alias krsd = kubectl rollout status deployment
# kubectl get rs
export alias kgrs = kubectl get rs
export alias ksi = kube-set-image
export alias ktp = kube-top-pod
export alias ktno = kube-top-node
export alias kcev = kube-clean-evicted
export alias kcsn = kube-clean-stucked-ns
export alias kcf = kube-clean-finalizer
export alias kgh = kube-get-helm
export alias kah = kube-apply-helm
export alias kdh = kube-diff-helm
export alias kdelh = kube-delete-helm
export alias kh = kube-helm

### cert-manager
export def kgcert [] {
    kubectl get certificates -o wide | from ssv | rename certificates
    kubectl get certificaterequests -o wide | from ssv | rename certificaterequests
    kubectl get order.acme -o wide | from ssv | rename order.acme
    kubectl get challenges.acme -o wide | from ssv | rename challenges.acme
}
