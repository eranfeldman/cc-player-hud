# HUD FOV Bridge

Client/server NeoForge addon for Minecraft 1.21.1. It captures the world camera FOV after FOV event handlers such as TaCZ, sends it to the server, and exposes it to the owner's pocket computer as the `hudfovbridge.fov` Lua API.

Install the latest jar on the server and on each client using the HUD. Other clients may omit it and connect normally; the FOV payload is optional, and only those clients' HUDs lack automatic FOV samples. The client sends the world-camera FOV after TaCZ's event handler, at most 10 times per second; the server returns a sample only to the matching player and expires it after 2 seconds.

The pocket HUD uses `require("hudfovbridge.fov").getFov()`. A `nil` result means no recent client sample, so the HUD can fall back to its configured FOV.

Build with `gradlew.bat build`. The jar is written to `build/libs`.
