use common.nu *
use complete.nu *

def get-context [$cond] {
    run $"select s.name, s.options, sk.user,
            k.type as key_type, k.public_key, k.private_key,
            h.type as host_type, h.address, h.port
        from ssh as s
        join ssh_key as sk on sk.ssh_name = s.name
        join key as k on sk.key_name = k.name
        join ssh_host as sh on sh.ssh_name = s.name
        join host as h on sh.host_name = h.name
        where sk.env_name = ($env.SSH_ENV)
            and sh.env_name = ($env.SSH_ENV)
            and ($cond)
    "
}

export def ssh-login [
    host: string@cmpl-ssh
    ...cmd
    -v
] {
    get-context $"s.name = (Q $host)"

}

export def ssh-install [
] {
    get-context "s.permanent != ''"
}

export def ssh-forward [
    host: string@cmpl-ssh
] {

}

export def ssh-sync [
    host: string@cmpl-ssh
] {

}

