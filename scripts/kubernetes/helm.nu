use complete.nu *
use common.nu *
use argx

export def record-to-set-json [value] {
    $value | transpose k v
    | each {|x| $"($x.k)=($x.v | to json -r)"}
    | str join ','
}

def cmpl-helm-list [context: string, offset: int] {
    let ctx = $context | argx parse
    kube-get-helm -n $ctx.opt.namespace? | each {|x| {value: $x.name  description: $x.updated} }
}

def cmpl-helm-charts [context: string, offset: int] {
    let ctx = $context | argx parse
    let path = $ctx | get pos.chart?
    let paths = do -i { ls ($"($path)*/**/Chart.yaml" | into glob) | each { $in.name | path dirname } }
    helm repo list | from ssv -a | rename value description
    | append $paths
}


# helm list and get
export def kube-get-helm [
    name?: string@cmpl-helm-list
    --namespace (-n): string@cmpl-kube-ns
    --manifest (-m)
    --values(-v)
    --all (-a)
] {
    if ($name | is-empty) {
        let ns = if $all { [--all] } else { $namespace | with-flag -n }
        helm list ...$ns --output json
        | from json
        | update updated {|x|
            $x.updated
            | str substring ..<-4
            | into datetime -f '%Y-%m-%d %H:%M:%S.%f %z'
        }
    } else {
        if $manifest {
            helm get manifest $name ...($namespace | with-flag -n)
        } else if $values {
            helm get values $name ...($namespace | with-flag -n)
        } else {
            helm get notes $name ...($namespace | with-flag -n)
        }
    }
}

# helm install or upgrade via values file
export def kube-apply-helm [
    name: string@cmpl-helm-list
    chart: string@cmpl-helm-charts
    valuefile: path
    --values (-v): any
    --namespace (-n): string@cmpl-kube-ns
    --ignore-image (-i) # for kdh
] {
    let update = $name in (
        helm list ...($namespace | with-flag -n) --output json
        | from json | get name
    )
    let act = if $update { [upgrade] } else { [install] }
    let values = if ($values | is-empty) { [] } else { [--set-json (record-to-set-json $values)] }
    helm ...$act $name $chart -f $valuefile ...$values ...($namespace | with-flag -n)
}

# helm diff
export def kube-diff-helm [
    name: string@cmpl-helm-list
    chart: string@cmpl-helm-charts
    valuefile: path
    --values (-v): any
    --namespace (-n): string@cmpl-kube-ns
    --ignore-image (-i)
    --has-plugin (-h)
] {
    if $has_plugin {
        helm diff $name $chart -f $valuefile ...($namespace | with-flag -n)
    } else {
        let update = $name in (
            helm list ...($namespace | with-flag -n) --output json
            | from json | get name
        )
        if not $update {
            echo "new installation"
            return
        }

        let values = if ($values | is-empty) { [] } else { [--set-json (record-to-set-json $values)] }
        let target = mktemp -t 'helm.XXX.out.yaml'
        let tg = helm template --debug $name $chart -f $valuefile ...$values ...($namespace | with-flag -n)
        | from yaml
        let img_p = [spec template spec containers 0 image] | into cell-path
        $tg | each {|x|
            if $ignore_image and ($x | get -i $img_p | is-not-empty) {
                $x | reject $img_p
            } else {
                $x
            }
            | to yaml
        }
        | str join $"(char newline)---(char newline)"
        | save -f $target
        kubectl diff -f $target
    }
}

# helm delete
export def kube-delete-helm [
    name: string@cmpl-helm-list
    --namespace (-n): string@cmpl-kube-ns
] {
    helm uninstall $name ...($namespace | with-flag -n)
}

# helm template
export def kube-helm [
    chart: string@cmpl-helm-charts
    valuefile: path
    --values (-v): any
    --namespace (-n): string@cmpl-kube-ns='test'
    --app (-a): string='test'
] {
    let values = if ($values | is-empty) { [] } else { [--set-json (record-to-set-json $values)] }
    let target = $valuefile | split row '.' | slice ..-2 | append [out yaml] | str join '.'
    if (not ($target | path exists)) and (([yes no] | input list $'create ($target)?') in [no]) { return }
    helm template --debug $app $chart -f $valuefile ...$values ...($namespace | with-flag -n)
    | save -f $target
}
