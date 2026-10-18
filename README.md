# CC Player HUD

ComputerCraft program for Pocket Unlimited, Advanced Peripherals, and HUD Glasses CC.

## Install

Copy `player_hud.lua` to the pocket computer and run `player_hud`. The launcher fetches the latest `player_hud_core.lua` from this repository every time it starts, saves a valid update locally, and runs it. If GitHub is unavailable, it runs the last cached core.

The ComputerCraft HTTP API must be enabled and allow `raw.githubusercontent.com`. The current modpack config already enables HTTP.

Equip the Advanced Peripherals Player Detector and HUD Glasses pocket upgrades through Pocket Unlimited before running the program.

## Controls

- `Up` / `Down`: select Toggle all, a player, or Quit
- `Enter`: activate the selected row
- `Left` / `Right`: decrease or increase HUD detail
- Click/tap a row: activate it directly

The first row turns every player's dot on or off. Each player row toggles only that player's dot. Select **Quit** to close the program.

The pocket computer lists up to 10 other online players. If a player is listed with `*`, the detector returned their name but not usable position data. The HUD starts at 256×128 and refreshes every 0.05 seconds (20 times per second). Use Left/Right to step through five detail levels, down to 80×28. Higher detail means smaller text and finer marker placement. The HUD redraws only rows used by dots and labels to reduce work at high detail. It shows each enabled, same-dimension player's colored dot, with the name above and distance below it. Players outside your current view are not drawn, and players in another dimension cannot be projected onto your screen. Projection assumes a 110-degree vertical FOV (Minecraft's Quake Pro setting), a 16:9 screen, and the HUD Glasses default FIT layout. Minecraft's dynamic FOV effects can shift markers slightly while active.
