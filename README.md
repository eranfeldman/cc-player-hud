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

The program tracks up to 10 other online players. Players in another dimension are labeled with that dimension because direction and distance are not comparable across dimensions.
