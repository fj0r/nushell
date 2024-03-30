export def add [...num: number] {
    $num | reduce -f 0 {|i,a| $a + $i }
}
