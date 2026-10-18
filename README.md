# CC Player HUD

ComputerCraft program for Pocket Unlimited, Advanced Peripherals, and HUD Glasses CC.

## Install

Copy `player_hud.lua` to the pocket computer and run `player_hud`. The launcher fetches the latest `player_hud_core.lua` from this repository every time it starts, saves a valid update locally, and runs it. If GitHub is unavailable, it runs the last cached core.

The ComputerCraft HTTP API must be enabled and allow `raw.githubusercontent.com`. The current modpack config already enables HTTP.

Equip the Advanced Peripherals Player Detector and HUD Glasses pocket upgrades through Pocket Unlimited before running the program.

## Controls

- `A`: show all tracked players
- `P`: cycle through players one at a time
- `H`: hide/show the HUD
- `Q`: quit

The HUD shows only small, contrasting dots projected into your view for up to 10 other online players in the same dimension. Players outside your current view are not drawn; players in another dimension cannot be placed on your screen. The display uses the HUD's character grid and an assumed 70-degree vertical field of view, so dot placement is approximate rather than pixel-perfect. The pocket computer itself shows the controls and current all-player/single-player selection.
