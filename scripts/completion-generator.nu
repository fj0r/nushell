def resolve-closure [args] {
    if ($in | describe -d | get type) == 'closure' {
        do $in $args
    } else {
        $in
    }
}

export def 'from tree' [
    schema
    --cmd-len(-c) = 1
    --selector = {value: 'value', description: 'description', next: 'next'}
] {
    let ctx = $in
    let argv = $ctx.0
        | str substring 0..$ctx.1
        | split row -r '\s+'
        | range $cmd_len..
        | where not ($it | str starts-with '-')
    let menu = $argv
        | reduce -f {schema: $schema, path: []} {|x, acc|
            let acc = $acc | update path ($acc.path | append $x)
            if ($x | is-empty) {
                $acc
            } else {
                match ($acc.schema | describe -d | get type) {
                    record => {
                        if $x in $acc.schema {
                            $acc | update schema ($acc.schema | get $x | resolve-closure $acc.path)
                        } else {
                            $acc
                        }
                    }
                    list => {
                        let fst = $acc.schema.0? | describe -d | get type
                        if not ($fst in ['list', 'record'])  {
                            $acc
                        } else {
                            let r = $acc.schema | filter {|i| ($i | get $selector.value) == $x}
                            if ($r | is-empty) {
                                $acc
                            } else {
                                $acc | update schema ($r | first | get $selector.next | resolve-closure $acc.path)
                            }
                        }
                    }
                    _ => {
                        $acc
                    }
                }
            }
        }
    match ($menu.schema | describe -d | get type) {
        record => {
            $menu.schema
            | transpose k v
            | each {|i|
                if ($i.v | describe -d | get type) == 'string' {
                    { value: $i.k, description: $i.v }
                } else {
                    $i.k
                }
            }
        }
        list => {
            if ($menu.schema.0? | describe -d | get type) == 'record' {
                $menu.schema
                | each {|x| {$selector.value: null, $selector.description: null} | merge $x }
                | select $selector.value $selector.description
                | rename value description
            } else {
                $menu.schema
            }
        }
    }
}

export def flare [...args:string@comflare] {
    print ($args | str join ' -> ')
}

def comflare [...context] {
    if not ('~/.cache/flare.json' | path exists) {
        http get https://gist.githubusercontent.com/curran/d2656e98b489648ab3e2071479ced4b1/raw/9f2499d63e971c2110e52b3fa2066ebed234828c/flare-2.json
        | to json
        | save ~/.cache/flare.json
    }
    let data = open ~/.cache/flare.json
    $context | from tree -c 2 --selector {value: name, description: value, next: children } [$data]
}

export def math [...args:string@commath] {
    print ($args | str join ' -> ')
}

def commath [...context] {
    $context | from tree -c 2 [
        {
            value: Count
            description: closure
            next: {|path| $path}
        }
        {
            value: PureMathematics
            next: {
                NumberSystems: [
                    { value: NaturalNumbers, description: '1, 2, 3, 4, 5', next: [Arithmetic ] }
                    { value: Integer, description: '-2, -1, 0, 1, 2' }
                    { value: RationalNumbers, description: '-7, 1/2, 2.32' }
                    { value: RealNumbers, description: '-4pi, sqrt(2), e' }
                    { value: ComplexNumbers, description: '3, i, 4+3i, -4i' }
                ]
                Structures: {
                    Algebra: {
                        Equation: null
                        LinearAlgebra: [ Vector Matrices ]
                    }
                    NumberTheory: 数论
                    Combinatorics: [Tree Graph]
                    GroupTheory: 群论
                    OrderTheory: 序理论
                }
                Space: {
                    Geometry: {
                        Trigonometry: 三角学
                        FractalGeometry: 分形几何
                    }
                    Topology: 拓扑学
                    MeasureTheory: 测度论
                    DifferentialGeometry: 微分几何
                }
                Changes: {
                    Calculus: {
                        Differentials: 微分
                        Integrals: 积分
                        Gradients: 梯度
                    }
                    VectorCalculus: 矢量微积分
                    DynamicalSystems: {
                        FluidFlows: 流体流动
                        Ecosystems: 生态系统
                        ChaosTheory: 混沌理论
                    }
                    ComplexAnalysis: 复分析
                }
            }
        }
        {
            value: AppiledMathematics
            next: {
                Physics: {
                    TheoreticalPhysics: 理论物理学
                }
                MathematicalChemistry: 数学化学
                Biomathematics: 生物数学
                Engineering : {
                    ControlTheory: 控制论
                }
                NumericalAnalysis: 数值分析
                GameTheory: 博弈论
                Economics: 经济学
                Probability: 概率论
                Statistics: 统计学
                MathematicalFinance: 数学金融
                Optimization: 优化
                ComputerScience: {
                    MachineLearning: 机器学习
                }
                Cryptography: 密码学
            }
        }
        {
            value: Foundations
            next: {
                FundamentalRules: { GodelIncompletenessTheorems: null }
                MathematicalLogic: 数理逻辑
                SetTheory: 集合论
                CategoryTheory: 范畴论
                TheoryOfComputation: 计算理论
            }
        }
    ]
}

