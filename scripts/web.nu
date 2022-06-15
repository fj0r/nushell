module web {
    export alias site-mirror = wget -m -k -E -p -np -e robots=off
}

use web *
