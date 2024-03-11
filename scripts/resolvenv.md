When there are multiple workplaces, such as at home, office, conference room, coffee shop,
there may be different, place-specific settings. The most convenient way to detect the place
is to detect the SSID of the wifi (I think most laptops do not have GPS)

A typical example is external display devices, assuming they are connected to HDMI ports,
then the WiFi SSID needs to be detected to determine the place,
and both need to be detected at the same time.


```
use resolvenv.nu
resolvenv select wlan0 [
    [{screen: {port: 'hdmi'}, wifi: 'pandorabox'}, {
        NEOVIM_LINE_SPACE: '2'
        NEOVIDE_SCALE_FACTOR: '0.7'
    }]
    [{screen: {port: 'dp-2'}}, {
        NEOVIM_LINE_SPACE: '2'
        NEOVIDE_SCALE_FACTOR: '0.5'
    }]
    [_, { print $in }]
]
```
