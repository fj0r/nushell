export def qemu-run [
    disk: path
    --core: int = 4
    --mem: int = 4
    --dry-run
    --port: record = {}
    --boot: path
    --iso: list<string>
    --usb: list<string> = []
    --bios: path = /usr/share/OVMF/x64/OVMF.4m.fd
    --readonly
    --clipboard
    --spice
] {
    let net = $port
    | transpose k v
    | each {|x|
        mut l = $x.k | split row ':'
        let p = $l | last
        $l = $l | slice 0..-2
        let o = $l | first | default 'tcp'
        $l = $l | slice 1..
        let a = $l | first
        $"hostfwd=($o):($a):($p)-:($x.v)"
    }
    | prepend user
    | str join ','

    let ext = ($disk | path parse | get extension | str downcase)
    let interface = if $ext == "qcow2" { "virtio" } else { "sata" }
    let drive = $'file=($disk),if=($interface),format=($ext)'

    let display_arg = if $spice {
        [-display spice-app]
    } else {
        [-display 'sdl,gl=on']
    }

    mut args = [
        -enable-kvm
        -m $'($mem)G'
        -smp $core
        -cpu host
        -vga virtio
        -drive $drive
        -net 'nic,model=virtio' -net $net
        -device virtio-balloon-pci
    ]

    $args ++= $display_arg

    # ====== Smart USB Controller and Peripheral Passthrough Logic ======
    # Initialize USB bus whenever --usb is specified, or when spice is off (which needs usb-tablet)
    let need_usb_bus = (not $spice) or ($usb | is-not-empty)

    if $need_usb_bus {
        $args ++= [-device qemu-xhci] # Fix previous error: provision the USB 3.0 bus first
    }

    if not $spice {
        $args ++= [-device usb-tablet] # Safe mouse mounting in SDL window mode
    }

    # Parse and append user-specified physical USB devices
    if ($usb | is-not-empty) {
        let usb_devices = $usb | each {|dev|
            # Split "045e:028e" into vendorid and productid
            let ids = $dev | split row ':'
            if ($ids | length) == 2 {
                [-device $'usb-host,vendorid=0x(($ids | first)),productid=0x(($ids | last))']
            } else {
                [] # Graceful fallback for malformed IDs
            }
        } | flatten
        $args ++= $usb_devices
    }
    # ==========================================

    if ($bios | is-not-empty) {
        $args ++= [-bios $bios]
    }

    if $readonly {
        $args ++= [-snapshot]
    }

    if ($boot | is-not-empty) {
        $args ++= [
            -drive $'file=($boot),media=cdrom'
            -boot d
        ]
    }

    if ($iso | is-not-empty) {
        let a = $iso | each {|x| [-drive $'file=($x),media=cdrom']} | flatten
        $args ++= $a
    }

    if $clipboard {
        $args ++= [
            -device virtio-serial-pci
            -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0
            -chardev spicevmc,id=spicechannel0,name=vdagent
            -spice port=5900,addr=127.0.0.1,disable-ticketing=on
        ]
    }

    if $dry_run {
        $'qemu-system-x86_64 ($args | str join " ")'
    } else {
        qemu-system-x86_64 ...$args
    }
}

export def qemu-create [disk --size:int = 60] {
  let safe_name = if ($disk | str ends-with '.qcow2') { $disk } else { $'($disk).qcow2' }
  qemu-img create -f qcow2 $safe_name $'($size)G'
}
