def run [...x: any] {
    let script = $"($env.PWD)/.nu"
    nu $script ...$x
}
