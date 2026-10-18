# HUD FOV Bridge

Client/server NeoForge addon for Minecraft 1.21.1. It captures the world camera FOV after FOV event handlers such as TaCZ, applies the player's final FOV modifier, sends the effective view FOV to the server, and exposes it to the owner's pocket computer as the `hud_fov` peripheral.

Both the client and server must install the same jar. The client sends a validated FOV sample at most 10 times per second; the server only returns the sample to the matching player's pocket upgrade and expires it after 2 seconds.

In the Lua program, equip the `HUD FOV Link` pocket upgrade inside the Unlimited Pocket and call `hud_fov.getFov()`. A `nil` result means no recent client sample, so the HUD can fall back to its configured FOV.

Build with `gradlew.bat build`. The jar is written to `build/libs`.
