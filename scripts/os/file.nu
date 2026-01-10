export def is-text-file [$f] {
    open -r $f | into binary | first 512 | bytes index-of 0x[00] | $in < 0
}
