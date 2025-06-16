export def selfsigned-certificate [
    ...common_name: string
    --server: string="default"
    --state: string="State"
    --city: string="City"
    --company: string="Company"
    --company-section: string="CompanySection"
    --country: string="US"
] {
    let sr = $"($server).key"
    if not ($sr | path exists) {
        openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out $sr
        chmod 400 $sr
    }

    let subj = {
        C: $country
        ST: $state
        L: $city
        O: $company
        OU: $company_section
        CN: ($common_name | str join ',')
    }
    | items {|k, v| $"/($k)=($v)"}
    | str join ''

    let fn = $"($server)-($common_name | first | str replace '*' '_')"

    openssl req -x509 -key $sr -keyout $"($fn).key.pem" -out $"($fn).cert.pem" -sha256 -days 3650 -nodes -subj $subj
}
