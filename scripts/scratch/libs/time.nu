export def fmt-date [] {
    $in | format date '%FT%H:%M:%S.%3f'
}
