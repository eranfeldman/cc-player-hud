# CC Player HUD

ComputerCraft program for Pocket Unlimited, Advanced Peripherals, and HUD Glasses CC.

## Install

Copy `player_hud.lua` to the pocket computer and run `player_hud`. The launcher fetches the latest `player_hud_core.lua` from this repository every time it starts, saves a valid update locally, and runs it. If GitHub is unavailable, it runs the last cached core.

The ComputerCraft HTTP API must be enabled and allow `raw.githubusercontent.com`. The current modpack config already enables HTTP.

Equip the Advanced Peripherals Player Detector and HUD Glasses pocket upgrades through Pocket Unlimited before running the program.

For automatic TaCZ aiming alignment, install the latest `HUD FOV Bridge` jar on the server and the client running this HUD, then restart both. The program loads the bridge API automatically; no extra pocket upgrade is needed. Without the bridge it falls back to 110°. The bridge source and build instructions are in [`tacz-fov-bridge`](tacz-fov-bridge/README.md).

The built jar is available at [`downloads/hudfovbridge-1.0.0.jar`](downloads/hudfovbridge-1.0.0.jar). Put the same jar in the `mods` folder on the server and every client using the FOV HUD, then restart. This bridge is a separate NeoForge mod and does not auto-update with the Lua launcher.

## Controls

- `Up` / `Down`: select Toggle all, a player, or Quit
- `Enter`: activate the selected row
- `Left` / `Right`: decrease or increase HUD detail
- `T`: create or remove a temporary test marker at the center of the block cell below you
- Click/tap a row: activate it directly

The first row turns every player's dot on or off. Each player row toggles only that player's dot. Select **Quit** to close the program.

The pocket computer lists up to 10 other online players. If a player is listed with `*`, the detector returned their name but not usable position data. Press `T` to add a test marker at the center of the block cell below your feet, then look down to check its screen position; press `T` again to remove it. This uses coordinates only and does not inspect the block type. The HUD starts at 256×128 and refreshes detector data every 0.1 seconds (10 times per second). Use Left/Right to step through five detail levels, down to 80×28. Higher detail means smaller text and finer marker placement. The HUD skips unchanged frames and redraws only rows used by dots and labels; the pocket list also redraws only when its contents or selection change. It shows each enabled, same-dimension player's colored dot, with the name above and distance below it. Players outside your current view are not drawn, and players in another dimension cannot be projected onto your screen. Without the FOV bridge, projection assumes a 110-degree vertical FOV (Minecraft's Quake Pro setting); with it, projection uses the live camera FOV.

For FOV troubleshooting, run `wget https://raw.githubusercontent.com/eranfeldman/cc-player-hud/main/player_hud_fov_diag.lua fovdiag`, then `fovdiag` with ADS off. Close the Pocket PC during its 3-second countdown, aim down sights for the 10-second capture, then reopen it to read the delayed range and change result.
