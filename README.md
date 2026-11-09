# sleepless_interact

A FiveM library for creating 3D DUI world interactions

![](https://img.shields.io/github/downloads/Sleepless-Development/sleepless_interact/total?logo=github)
![](https://img.shields.io/github/downloads/Sleepless-Development/sleepless_interact/latest/total?logo=github)
![](https://img.shields.io/github/contributors/Sleepless-Development/sleepless_interact?logo=github)
![](https://img.shields.io/github/v/release/Sleepless-Development/sleepless_interact?logo=github)\
[![](https://badges.5metrics.dev/sleepless_interact/serverRank.svg?style=for-the-badge)](https://5metrics.dev/resource/sleepless_interact)
[![](https://badges.5metrics.dev/sleepless_interact/servers.svg?style=for-the-badge)](https://5metrics.dev/resource/sleepless_interact)
[![](https://badges.5metrics.dev/sleepless_interact/players.svg?style=for-the-badge)](https://5metrics.dev/resource/sleepless_interact)


## thanks
v2 uses a lot of code from ox_target to help ensure feature parity. so a big thanks to linden for that. [ox_target](https://github.com/overextended/ox_target)

## 📃 Documentation

- [docs](https://sleeplessdevelopment.dev/docs/interact)

## 💾 Download

[seleepless_interact.zip](https://github.com/Sleepless-Development/sleepless_interact/releases/latest/download/sleepless_interact.zip)

## UI accent color

Set a shared accent in server.cfg before starting the resources:

~~~cfg
setr sleepless:ui:primary "#31a4fc"
~~~

To override only this resource:

~~~cfg
setr sleepless_interact:ui:primary "#e87935"
~~~

Use a six-digit hex color. The resource convar overrides the shared convar; when neither is set, the existing palette/config remains the fallback. An empty value inherits again. Invalid values fall back to the next valid setting. Restart the affected resource after changing convars. This changes the UI accent, while error, rarity, and explicitly supplied item/waypoint colors keep their meaning. Browser previews support ?uiPrimary=%23e87935.
